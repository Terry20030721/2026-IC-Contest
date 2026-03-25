# ==========================================
# REFRACT 題目 LUT Verilog 產生器 (Q8.16 格式)
# ==========================================

# 定義小數位數與放大倍率
FRAC_BITS = 16
SCALE = 2 ** FRAC_BITS
MASK_24BIT = 0xFFFFFF  # 用來做 24 bits 二補數轉換的遮罩

# 小工具：把浮點數轉換成 Verilog 24-bit 16進位字串
def float_to_hex24(real_val):
    # 1. 乘上放大倍率並四捨五入成整數
    fixed_val = int(round(real_val * SCALE))
    # 2. 轉成 24 bits 的二補數格式
    hex_val = fixed_val & MASK_24BIT
    # 3. 輸出成 6 位數的 16 進位字串 (大寫)
    return f"{hex_val:06X}"

print("// " + "="*40)
print("// 1. eta (折射率倒數) LUT - 輸入: RI (2~15)")
print("// " + "="*40)
print("always @(*) begin")
print("    case (ri_reg)")
for ri in range(2, 16):
    eta_real = 1.0 / ri
    hex_str = float_to_hex24(eta_real)
    print(f"        4'd{ri:2}: lut_eta = 24'sh{hex_str}; // 真實值: {eta_real:.6f}")
print("        default: lut_eta = 24'sh000000;")
print("    endcase")
print("end\n")

print("// " + "="*40)
print("// 2. gx / gy 斜率 LUT - 輸入: cnt_x 或 cnt_y (0~15)")
print("// " + "="*40)
print("always @(*) begin")
print("    case (cnt_x)") # 如果是 gy，把 cnt_x 改成 cnt_y 即可
for x in range(16):
    # 公式: 2 * ((X-8)/8)^7
    gx_real = 2.0 * (((x - 8) / 8.0) ** 7)
    hex_str = float_to_hex24(gx_real)
    print(f"        4'd{x:2}: gx_val = 24'sh{hex_str}; // 真實值: {gx_real:.6f}")
print("        default: gx_val = 24'sh000000;")
print("    endcase")
print("end\n")

print("// " + "="*40)
print("// 3. z_term 高度項 LUT - 輸入: cnt_x 或 cnt_y (0~15)")
print("// " + "="*40)
print("always @(*) begin")
print("    case (cnt_x)")
for x in range(16):
    # 公式: 2 * ((X-8)/8)^8
    z_real = 2.0 * (((x - 8) / 8.0) ** 8)
    hex_str = float_to_hex24(z_real)
    print(f"        4'd{x:2}: z_term_x = 24'sh{hex_str}; // 真實值: {z_real:.6f}")
print("        default: z_term_x = 24'sh000000;")
print("    endcase")
print("end\n")