module REFRACT(
    input  wire        CLK,
    input  wire        RST,
    input  wire [3:0]  RI,   
    output reg  [8:0]  SRAM_A,
    output reg  [15:0] SRAM_D,
    input  wire [15:0] SRAM_Q,
    output reg         SRAM_WE,
    output reg         DONE
);


// --- 狀態編碼宣告 ---
localparam IDLE     = 3'd0;
localparam CALC     = 3'd1;
localparam WRITE_ZX = 3'd2;
localparam WRITE_ZY = 3'd3;
localparam FINISH   = 3'd4;

reg [2:0] current_state, next_state;

// --- 計數器 ---
reg [3:0] cnt_x; // X 座標計數器
reg [3:0] cnt_y; // Y 座標計數器

// --- 計數器控制邏輯 ---
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        cnt_x <= 4'd0; 
        cnt_y <= 4'd0; 
    end else begin
        // 計數器只聽從 FSM 的狀態來決定要不要動作
        if (current_state == WRITE_ZY) begin
            if (cnt_x == 4'd15) begin
                cnt_y <= cnt_y + 4'd1;
                cnt_x <= 4'd0;
            end else begin
                cnt_x <= cnt_x + 4'd1;
            end
        end
    end
end


wire signed [3:0] sub_x = cnt_x - 4'd8; // X-8 的值，範圍是 -8 ~ +7
wire signed [3:0] sub_y = cnt_y - 4'd8; // Y-8 的值，範圍是 -8 ~ +7

// [註解]：我們設計者自己知道，A 和 B 現在的實體意義是帶有 3 位小數的 Q1.3 格式
// 所以它們代表的數值已經是 (X-8)/8 和 (Y-8)/8 了！
wire signed [3:0] A = sub_x; 
wire signed [3:0] B = sub_y;

// A^2 和 B^2 (結果 Q2.6)
wire signed [7:0] A_2 = A * A; 
wire signed [7:0] B_2 = B * B; 

// A^4 和 B^4 (結果 Q4.12)
wire signed [15:0] A_4 = A_2 * A_2; 
wire signed [15:0] B_4 = B_2 * B_2; 

// A^7 和 B^7
wire signed [23:0] A_6_full = A_4 * A_2; 
wire signed [27:0] A_7_full = A_6_full * A; 
wire signed [23:0] B_6_full = B_4 * B_2;
wire signed [27:0] B_7_full = B_6_full * B; 
// 退回 14 位小數 (Q7.14)
wire signed [20:0] A_7 = A_7_full[27:7]; 
wire signed [20:0] B_7 = B_7_full[27:7]; 

// A^8 和 B^8
wire signed [31:0] A_8_full = A_4 * A_4; 
wire signed [31:0] B_8_full = B_4 * B_4;
// 退回 14 位小數 (Q8.14)
wire signed [21:0] A_8 = A_8_full[31:10]; 
wire signed [21:0] B_8 = B_8_full[31:10]; 

// ==========================================
// 計算 Z = 6 - 2*(A^8) - 2*(B^8)
// ==========================================
wire signed [21:0] Z = (6<<14) - (A_8 << 1) - (B_8 << 1); 

// ==========================================
// 計算切平面法向量 gx = 2*(A^7), gy = 2*(B^7)
// ==========================================
wire signed [21:0] gx = A_7 << 1; 
wire signed [21:0] gy = B_7 << 1; 

// 算 g^2
wire signed [43:0] gx2 = gx * gx; // Q16.28
wire signed [43:0] gy2 = gy * gy; // Q16.28
wire signed [30:0] g2 = gx2[43:14] + gy2[43:14] + (31'sd1 <<< 14); // Q16.14

//==========================================
// 計算 eta 與 1/g^2 (小數點嚴格對齊 Qx.14)
// ==========================================
// eta (Q1.14)
wire signed [15:0] eta = 16'sd16384 / RI; 

// eta^2 (Q3.14)
wire signed [31:0] eta_2_full = eta * eta; 
wire signed [17:0] eta_2 = eta_2_full[31:14];

// ==========================================
// 🚀 Pipeline Stage 1 (Cycle 1 結束時的交接棒)
// ==========================================
// 我們要把後面算數學會用到的東西，還有最重要的座標，通通存起來！
reg signed [21:0] reg1_Z;
reg signed [21:0] reg1_gx;
reg signed [21:0] reg1_gy;
reg signed [30:0] reg1_g2;
reg signed [15:0] reg1_eta;
reg signed [17:0] reg1_eta_2;
reg [3:0] reg1_x; // 帶著座標跑！
reg [3:0] reg1_y;

always @(posedge CLK or posedge RST) begin
    if (RST) begin
        reg1_Z <= 0; reg1_gx <= 0; reg1_gy <= 0; reg1_g2 <= 0;
        reg1_eta <= 0; reg1_eta_2 <= 0; reg1_x <= 0; reg1_y <= 0;
    end else if (current_state == CALC) begin
        // 把上面用 wire 算好的組合邏輯結果，吃進暫存器裡
        reg1_Z     <= Z;
        reg1_gx    <= gx;
        reg1_gy    <= gy;
        reg1_g2    <= g2;
        reg1_eta   <= eta;
        reg1_eta_2 <= eta_2;
        reg1_x     <= cnt_x; // 抓取當下的座標
        reg1_y     <= cnt_y;
    end
end

// 呼叫 DW 除法器算 1 / g^2 (Q17.14)
// 【注意】這裡的分母要換成吃 reg1_g2，不再是原本的 g2 喔！
wire signed [31:0] inv_g2; 
DW_div #(32, 31, 1, 1) U_DIV_1_G2 (
    .a(32'sd268435456), 
    .b(reg1_g2),        // <--- 吃第一棒傳下來的資料
    .quotient(inv_g2)   
);

// ==========================================
// 計算 k 並呼叫 DW 開根號
// ==========================================
wire signed [31:0] bracket = 32'sd16384 - inv_g2; 
wire signed [49:0] eta_bracket_full = eta_2 * bracket;
wire signed [35:0] eta_bracket = eta_bracket_full[49:14];
// k = 1 - (eta^2 * bracket)
wire signed [35:0] k = 36'sd16384 - eta_bracket; 

// k * g^2 (利用第一棒傳下來的 g2)
wire signed [66:0] k_g2_full = k * reg1_g2; // <--- 吃第一棒的資料
wire [62:0] k_g2_chopped = k_g2_full[66:4];

// ==========================================
// 🚀 Pipeline Stage 2 的組合邏輯與暫存器 (Cycle 2)
// ==========================================
// --- Stage 2 交接棒 ---
// 把算好的 k_g2_chopped 和後面還會用到的東西繼續往下傳
reg [62:0] reg2_k_g2_chopped;
// 下面這些是純粹的「跟屁蟲」，因為後面還要用，只能跟著繼續跑
reg signed [21:0] reg2_Z;
reg signed [21:0] reg2_gx;
reg signed [21:0] reg2_gy;
reg signed [15:0] reg2_eta;
reg [3:0] reg2_x;
reg [3:0] reg2_y;

always @(posedge CLK or posedge RST) begin
    if (RST) begin
        reg2_k_g2_chopped <= 0; reg2_Z <= 0; reg2_gx <= 0; reg2_gy <= 0;
        reg2_eta <= 0; reg2_x <= 0; reg2_y <= 0;
    end else if (current_state == CALC) begin
        // 把第二棒算出來的東西吃進來
        reg2_k_g2_chopped <= k_g2_chopped;
        // 把第一棒傳下來、但第二棒沒用到，可是後面還要用的東西，照抄往下傳
        reg2_Z   <= reg1_Z;
        reg2_gx  <= reg1_gx;
        reg2_gy  <= reg1_gy;
        reg2_eta <= reg1_eta;
        reg2_x   <= reg1_x;
        reg2_y   <= reg1_y;
    end
end

// ==========================================
// 🚀 Pipeline Stage 3 (Cycle 3) - 專心開根號與準備分子分母
// ==========================================
wire [31:0] sqrt_k_g2; 
// 呼叫 DW 開根號，吃第二棒的資料！
DW_sqrt #(63, 0) U_SQRT_KG2 (
    .a(reg2_k_g2_chopped), // <--- 吃第二棒傳下來的
    .root(sqrt_k_g2)  
);

// 準備 Stage 4 除法器要用的分子與分母 (組合邏輯)
wire signed [34:0] coef = $signed({1'b0, sqrt_k_g2}) <<< 2; 
wire signed [35:0] denom = coef - reg2_eta; // <--- 吃第二棒的 eta
wire signed [57:0] num = (-reg2_Z) * coef;  // <--- 吃第二棒的 Z

// --- Stage 3 交接棒 ---
// 把算好的分子分母，還有後面會用到的跟屁蟲，繼續存進 reg3！
reg signed [57:0] reg3_num;
reg signed [35:0] reg3_denom;
reg signed [21:0] reg3_gx; // 跟屁蟲繼續跟！
reg signed [21:0] reg3_gy;
reg [3:0] reg3_x;          // 座標繼續跟！
reg [3:0] reg3_y;

always @(posedge CLK or posedge RST) begin
    if (RST) begin
        reg3_num <= 0; reg3_denom <= 0;
        reg3_gx <= 0; reg3_gy <= 0; 
        reg3_x <= 0; reg3_y <= 0;
    end else if (current_state == CALC) begin
        // 把第三棒算出來的東西吃進來
        reg3_num   <= num;
        reg3_denom <= denom;
        // 把第二棒傳下來的東西照抄往下傳
        reg3_gx    <= reg2_gx;
        reg3_gy    <= reg2_gy;
        reg3_x     <= reg2_x;
        reg3_y     <= reg2_y;
    end
end

// ==========================================
// 🚀 Pipeline Stage 4 (Cycle 4) - 專心做最後除法與產出最終答案！
// ==========================================
wire signed [57:0] term1; 
// 呼叫第二顆 DW 除法器，吃第三棒的資料！
DW_div #(58, 36, 1, 1) U_DIV_FINAL (
    .a(reg3_num),    // <--- 吃第三棒的分子      
    .b(reg3_denom),  // <--- 吃第三棒的分母      
    .quotient(term1)  
);

// 計算偏移量並砍回 14 位小數
wire signed [79:0] zx_offset_full = term1 * reg3_gx; // <--- 吃第三棒的 gx
wire signed [79:0] zy_offset_full = term1 * reg3_gy; // <--- 吃第三棒的 gy
wire signed [50:0] zx_offset = zx_offset_full[64:14];
wire signed [50:0] zy_offset = zy_offset_full[64:14];

// 加上第三棒傳下來的原始座標 X, Y (轉為 14 位小數格式)
wire signed [19:0] orig_X = $signed({1'b0, reg3_x}) <<< 14;
wire signed [19:0] orig_Y = $signed({1'b0, reg3_y}) <<< 14;

wire signed [51:0] zx_full = orig_X + zx_offset;
wire signed [51:0] zy_full = orig_Y + zy_offset;

// 終極大裁切：對接 SRAM 的 Q4.12 格式！
wire [15:0] SRAM_D_ZX = zx_full[17:2]; 
wire [15:0] SRAM_D_ZY = zy_full[17:2];

// --- Stage 4 交接棒 (最終衝線！) ---
// 這是我們最後一棒，我們要把它存在 "final" 暫存器裡，讓 FSM 可以安穩地寫進 SRAM
reg [15:0] final_zx;
reg [15:0] final_zy;
reg [3:0]  final_x; // 這個極度重要！這是當初一開始算的那一點的 X！
reg [3:0]  final_y; // 這個極度重要！這是當初一開始算的那一點的 Y！

always @(posedge CLK or posedge RST) begin
    if (RST) begin
        final_zx <= 0; final_zy <= 0;
        final_x <= 0; final_y <= 0;
    end else if (current_state == CALC) begin
        // 把最終答案存起來，等待 FSM 下達寫入指令！
        final_zx <= SRAM_D_ZX;
        final_zy <= SRAM_D_ZY;
        final_x  <= reg3_x; // 把歷經 4 個 Clock 千辛萬苦傳下來的原始座標存好
        final_y  <= reg3_y; 
    end
end

// ==========================================
// 這邊是為了讓上面計算管線話所設計的Pipeline Counter，讓我們的 FSM 知道什麼時候可以從 CALC 進入 WRITE 狀態
// ==========================================
// --- 管線化計時器 (Pipeline Counter) ---
reg [2:0] pipe_cnt; // 用來數 4 個 Clock

always @(posedge CLK or posedge RST) begin
    if (RST) begin
        pipe_cnt <= 3'd0;
    end else if (current_state == CALC) begin
        // 當進入 CALC 狀態時，開始數 Clock
        if (pipe_cnt == 3'd4) begin
            pipe_cnt <= 3'd0; // 數滿 4 個 Clock，歸零準備下一次
        end else begin
            pipe_cnt <= pipe_cnt + 3'd1;
        end
    end else begin
        pipe_cnt <= 3'd0; // 不在 CALC 狀態時，隨時保持歸零
    end
end

// 宣告並同時賦值！當計時器數到 4 的時候，拉高 calc_done
wire calc_done = (pipe_cnt == 3'd4); 

// 原本的 is_last_pixel 照舊保留在這裡
wire is_last_pixel = (cnt_x == 4'd15) && (cnt_y == 4'd15);



// ==========================================
// 第一段：狀態暫存器 (Current State Register)
// 負責在每個 Clock 正緣更新狀態，或處理 Reset
// ==========================================
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        current_state <= IDLE;
    end else begin
        current_state <= next_state;
    end
end

// ==========================================
// 第二段：次態邏輯 (Next State Logic)
// 純組合邏輯，根據「現在狀態」與「輸入訊號」決定下一個狀態
// ==========================================
always @(*) begin
    case (current_state)
        IDLE: begin
            next_state = CALC; // RST 結束後直接進入運算
        end
        CALC: begin
            // 假設有一個訊號叫 calc_done，代表 Datapath 算完了
            if (calc_done) next_state = WRITE_ZX;
            else           next_state = CALC;
        end
        WRITE_ZX: begin
             
            next_state = WRITE_ZY; // 寫完 ZX 下一個 Cycle 直接寫 ZY

        end
        WRITE_ZY: begin
            // 判斷是不是算到最後一點了 (X==15 且 Y==15)
            if (is_last_pixel) next_state = FINISH;
            else               next_state = CALC;
        end
        FINISH: begin
            next_state = FINISH; // 停在這裡等 Host 檢查
        end 
        default: next_state = IDLE;
    endcase
end

// ==========================================
// 第三段：輸出邏輯 (Output Logic)
// 根據狀態控制 SRAM 的 WE、ADDR、DATA 和 DONE 訊號
// ==========================================
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        // 初始化輸出訊號
        DONE    <= 1'b0;
        SRAM_WE <= 1'b0;
        SRAM_A  <= 9'd0;
        // ... 其他訊號歸零
    end else begin
        // 根據 current_state 或 next_state 來控制你的輸出
        // (這裡留給你發揮！)
        SRAM_WE <= 1'b0; // 預設 WE 為 0，只有在 WRITE_ZX 和 WRITE_ZY 狀態才拉高
        DONE   <= 1'b0; // 預設 DONE 為 0，只有在 FINISH 狀態才拉高
        case (current_state) 
            WRITE_ZX: begin
                // 把算好的 ZX 丟到資料線
                SRAM_D  <= final_zx; 
                // SRAM_A 格式: {Y座標(4bits), X座標(4bits), ZX寫0(1bit)}
                SRAM_A  <= {final_y, final_x, 1'b0}; 
                SRAM_WE <= 1'b1; // 拉高 WE 寫入
            end
            WRITE_ZY: begin
                // 把算好的 ZY 丟到資料線
                SRAM_D  <= final_zy; 
                // SRAM_A 格式: {Y座標(4bits), X座標(4bits), ZY寫1(1bit)}
                SRAM_A  <= {final_y, final_x, 1'b1}; 
                SRAM_WE <= 1'b1; // 拉高 WE 寫入
            end
            FINISH: begin
                DONE <= 1'b1; // 計算完成，拉高 DONE 給 Host 知道
            end

            default: begin
                SRAM_WE <= 1'b0; // 其他狀態下保持 WE 低，不寫入資料
            end
        endcase
    end
end


endmodule
