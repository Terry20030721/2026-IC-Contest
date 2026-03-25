module REFRACT(
    input  wire        CLK,
    input  wire        RST,
    input  wire [3:0]  RI,   
    output reg  [8:0]  SRAM_A,
    output reg  [15:0] SRAM_D,
    input  wire [15:0] SRAM_Q,   // unused
    output reg         SRAM_WE,
    output reg         DONE
);

localparam IDLE     = 3'd0;
localparam CALC     = 3'd1;
localparam WRITE_ZX = 3'd2;
localparam WRITE_ZY = 3'd3;
localparam DONE_ST  = 3'd4;

reg [2:0] current_state;
reg [2:0] next_state;
reg [3:0] cnt_x, cnt_y;
reg [3:0] ri_reg;

wire        math_done;      // 運算完成訊號 (例如除法器算完了)
wire [15:0] zx_result;      // 最終算好的 zx (Q4.12 格式)
wire [15:0] zy_result;      // 最終算好的 zy (Q4.12 格式)

reg [23:0] lut_eta;     // 折射率倒數 LUT 輸出 (Q8.16 格式)
reg [23:0] gx_val;      // gx 斜率 LUT輸出 (Q8.16 格式)
reg [23:0] gy_val;     // gy 斜率 LUT輸出 (Q8.16 格式)
reg [23:0] z_term_x;    // z_term 高度項 LUT 輸出 (Q8.16 格式)
reg [23:0] z_term_y;    // z_term 高度項 LUT輸出 (Q8.16 格式)


always @(posedge CLK or posedge RST) begin
    if (RST) begin
        current_state <= IDLE;
        cnt_x <= 4'd0;
        cnt_y <= 4'd0;
        ri_reg <= 4'd0;
    end
    else begin
        current_state <= next_state;
        case (current_state)
            IDLE: begin
                if (RI != 0) begin
                    ri_reg <= RI;
                    cnt_x <= 0;
                    cnt_y <= 0;
                end
            end
            WRITE_ZY: begin
                // 當寫完 Y 座標後，準備換下一個點
                if (cnt_x == 4'd15 && cnt_y == 4'd15) begin
                    // 全部算完，保持原值準備進入 DONE_ST
                end else if (cnt_x == 4'd15) begin
                    cnt_x <= 4'd0;       // X 滿了歸零
                    cnt_y <= cnt_y + 1'b1; // Y 進位
                end else begin
                    cnt_x <= cnt_x + 1'b1; // 一般情況 X 加 1
                end
            end
        endcase
    end
end

// ==========================================
// 3. 第二段：下一個狀態的判斷邏輯 (Combinational Logic)
// ==========================================

always @(*) begin
    case (current_state)
        IDLE: 
            next_state = CALC; // Reset 一放開就直接進入計算
            
        CALC: 
            if (math_done) next_state = WRITE_ZX; // 算完才去寫 SRAM
            else           next_state = CALC;     // 還沒算完就繼續等
            
        WRITE_ZX: 
            next_state = WRITE_ZY; // 寫完 ZX 下一拍無條件寫 ZY
            
        WRITE_ZY: 
            if (cnt_x == 4'd15 && cnt_y == 4'd15) next_state = DONE_ST; // 256 個點全寫完
            else                                  next_state = CALC;    // 還沒寫完，回去算下一個點
            
        DONE_ST: 
            next_state = DONE_ST; // 停留在這裡直到下次 Reset
            
        default: 
            next_state = IDLE;
    endcase
end


// ==========================================
// 4. 第三段：SRAM 介面與 DONE 輸出控制 (Combinational Logic)
// ==========================================
always @(*) begin
    // 先給定預設值，避免產生 Latch
    SRAM_WE = 1'b0;
    SRAM_A  = 9'd0;
    SRAM_D  = 16'd0;
    DONE    = 1'b0;

    case (current_state)
        WRITE_ZX: begin
            SRAM_WE = 1'b1;
            SRAM_A  = {cnt_y, cnt_x, 1'b0}; // 結尾是 0 代表存 zx
            SRAM_D  = zx_result;
        end
        
        WRITE_ZY: begin
            SRAM_WE = 1'b1;
            SRAM_A  = {cnt_y, cnt_x, 1'b1}; // 結尾是 1 代表存 zy
            SRAM_D  = zy_result;
        end
        
        DONE_ST: begin
            DONE = 1'b1; // 拉高完成訊號通知 Host 收卷
        end
    endcase
end

reg [23:0] Z_val; // 真實的 Z 值 (Q8.16 格式)，用來計算誤差距離
reg [47:0] k;
reg [47:0] g_pow2; // gx^2 + z_term_x^2 的值 (Q8.16 格式)，用來計算誤差距離
reg [71:0] sqr_kgg; // kgg 的平方 (Q8.16 格式)，用來計算誤差距離

always @(*) begin
    Z_val = 24'd393216 - z_term_x - z_term_y; // Z_val = 6 - z_term_x - z_term_y
    g_pow2 = gx_val * gx_val + gy_val * gy_val + 48'd4294967296; // gx^2 + gy^2
end



// ========================================
// 1. eta (折射率倒數) LUT - 輸入: RI (2~15)
// ========================================
always @(*) begin
    case (ri_reg)
        4'd 2: lut_eta = 24'sh008000; // 真實值: 0.500000
        4'd 3: lut_eta = 24'sh005555; // 真實值: 0.333333
        4'd 4: lut_eta = 24'sh004000; // 真實值: 0.250000
        4'd 5: lut_eta = 24'sh003333; // 真實值: 0.200000
        4'd 6: lut_eta = 24'sh002AAB; // 真實值: 0.166667
        4'd 7: lut_eta = 24'sh002492; // 真實值: 0.142857
        4'd 8: lut_eta = 24'sh002000; // 真實值: 0.125000
        4'd 9: lut_eta = 24'sh001C72; // 真實值: 0.111111
        4'd10: lut_eta = 24'sh00199A; // 真實值: 0.100000
        4'd11: lut_eta = 24'sh001746; // 真實值: 0.090909
        4'd12: lut_eta = 24'sh001555; // 真實值: 0.083333
        4'd13: lut_eta = 24'sh0013B1; // 真實值: 0.076923
        4'd14: lut_eta = 24'sh001249; // 真實值: 0.071429
        4'd15: lut_eta = 24'sh001111; // 真實值: 0.066667
        default: lut_eta = 24'sh000000;
    endcase
end

// ========================================
// 2. gx / gy 斜率 LUT - 輸入: cnt_x 或 cnt_y (0~15)
// ========================================
always @(*) begin
    case (cnt_x)
        4'd 0: gx_val = 24'shFE0000; // 真實值: -2.000000
        4'd 1: gx_val = 24'shFF36F1; // 真實值: -0.785392
        4'd 2: gx_val = 24'shFFBBA8; // 真實值: -0.266968
        4'd 3: gx_val = 24'shFFECED; // 真實值: -0.074506
        4'd 4: gx_val = 24'shFFFC00; // 真實值: -0.015625
        4'd 5: gx_val = 24'shFFFF77; // 真實值: -0.002086
        4'd 6: gx_val = 24'shFFFFF8; // 真實值: -0.000122
        4'd 7: gx_val = 24'sh000000; // 真實值: -0.000001
        4'd 8: gx_val = 24'sh000000; // 真實值: 0.000000
        4'd 9: gx_val = 24'sh000000; // 真實值: 0.000001
        4'd10: gx_val = 24'sh000008; // 真實值: 0.000122
        4'd11: gx_val = 24'sh000089; // 真實值: 0.002086
        4'd12: gx_val = 24'sh000400; // 真實值: 0.015625
        4'd13: gx_val = 24'sh001313; // 真實值: 0.074506
        4'd14: gx_val = 24'sh004458; // 真實值: 0.266968
        4'd15: gx_val = 24'sh00C90F; // 真實值: 0.785392
        default: gx_val = 24'sh000000;
    endcase
end

// ========================================
// 3. z_term 高度項 LUT - 輸入: cnt_x 或 cnt_y (0~15)
// ========================================
always @(*) begin
    case (cnt_x)
        4'd 0: z_term_x = 24'sh020000; // 真實值: 2.000000
        4'd 1: z_term_x = 24'sh00AFEE; // 真實值: 0.687218
        4'd 2: z_term_x = 24'sh003342; // 真實值: 0.200226
        4'd 3: z_term_x = 24'sh000BEC; // 真實值: 0.046566
        4'd 4: z_term_x = 24'sh000200; // 真實值: 0.007812
        4'd 5: z_term_x = 24'sh000033; // 真實值: 0.000782
        4'd 6: z_term_x = 24'sh000002; // 真實值: 0.000031
        4'd 7: z_term_x = 24'sh000000; // 真實值: 0.000000
        4'd 8: z_term_x = 24'sh000000; // 真實值: 0.000000
        4'd 9: z_term_x = 24'sh000000; // 真實值: 0.000000
        4'd10: z_term_x = 24'sh000002; // 真實值: 0.000031
        4'd11: z_term_x = 24'sh000033; // 真實值: 0.000782
        4'd12: z_term_x = 24'sh000200; // 真實值: 0.007812
        4'd13: z_term_x = 24'sh000BEC; // 真實值: 0.046566
        4'd14: z_term_x = 24'sh003342; // 真實值: 0.200226
        4'd15: z_term_x = 24'sh00AFEE; // 真實值: 0.687218
        default: z_term_x = 24'sh000000;
    endcase
end



endmodule


