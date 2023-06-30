import types::*;

module gameandwatch (
    input wire clk_sys_99_287,
    input wire clk_vid_33_095,

    input wire reset,
    input wire pll_core_locked,

    // Inputs
    input wire button_a,
    input wire button_b,
    input wire button_x,
    input wire button_y,
    input wire button_trig_l,
    input wire button_trig_r,
    input wire button_start,
    input wire button_select,
    input wire dpad_up,
    input wire dpad_down,
    input wire dpad_left,
    input wire dpad_right,

    // Data in
    input wire        ioctl_download,
    input wire        ioctl_wr,
    input wire [24:0] ioctl_addr,
    input wire [15:0] ioctl_dout,

    // Video
    output wire hsync,
    output wire vsync,
    output wire hblank,
    output wire vblank,

    output wire de,
    output wire [23:0] rgb,

    // Sound
    output wire sound,

    // Settings
    input wire accurate_lcd_timing, // Use precise timing to update the cached LCD segments based on H timing. This doesn't look good, hence the setting
    input wire [7:0] lcd_off_alpha, // The alpha value of all disabled/off LCD segments. This allows the LCD to stay visible at all times

    // SDRAM
    inout  wire [15:0] SDRAM_DQ,
    output wire [12:0] SDRAM_A,
    output wire [ 1:0] SDRAM_DQM,
    output wire [ 1:0] SDRAM_BA,
    output wire        SDRAM_nCS,
    output wire        SDRAM_nWE,
    output wire        SDRAM_nRAS,
    output wire        SDRAM_nCAS,
    output wire        SDRAM_CKE,
    output wire        SDRAM_CLK
);
  ////////////////////////////////////////////////////////////////////////////////////////
  // Loading and config

  system_config sys_config;

  wire [24:0] base_addr;
  wire image_download;
  wire mask_config_download;
  wire rom_download;

  wire wr_8bit;
  wire [25:0] addr_8bit;
  wire [7:0] data_8bit;

  wire [3:0] cpu_id = sys_config.mpu[3:0];

  rom_loader rom_loader (
      .clk(clk_sys_99_287),

      .ioctl_download(ioctl_download),
      .ioctl_wr(ioctl_wr),
      .ioctl_addr(ioctl_addr),
      .ioctl_dout(ioctl_dout),

      .sys_config(sys_config),

      // Data signals
      .base_addr(base_addr),
      .image_download(image_download),
      .mask_config_download(mask_config_download),
      .rom_download(rom_download),

      // 8 bit bus
      .wr_8bit  (wr_8bit),
      .addr_8bit(addr_8bit),
      .data_8bit(data_8bit)
  );

  ////////////////////////////////////////////////////////////////////////////////////////
  // ROM

  wire [11:0] rom_addr;
  reg [7:0] rom_data = 0;

  reg [7:0] rom[4096];

  always @(posedge clk_sys_99_287) begin
    if (clk_en) begin
      rom_data <= rom[rom_addr];
    end
  end

  always @(posedge clk_sys_99_287) begin
    if (wr_8bit && rom_download) begin
      // ioctl_dout has flipped bytes, flip back by modifying address
      rom[{addr_8bit[25:1], ~addr_8bit[0]}] <= data_8bit;
    end
  end

  ////////////////////////////////////////////////////////////////////////////////////////
  // Input

  wire [7:0] output_shifter_s;
  wire [3:0] output_r;

  wire [3:0] input_k;

  wire input_beta;
  wire input_ba;

  // TODO: Unused
  wire input_acl;

  input_config input_config (
      .clk(clk_sys_99_287),

      .sys_config(sys_config),

      .cpu_id(cpu_id),

      // Input selection
      .output_shifter_s(output_shifter_s),
      .output_r(output_r),

      // Input
      .button_a(button_a),
      .button_b(button_b),
      .button_x(button_x),
      .button_y(button_y),
      .button_trig_l(button_trig_l),
      .button_trig_r(button_trig_r),
      .button_start(button_start),
      .button_select(button_select),
      .dpad_up(dpad_up),
      .dpad_down(dpad_down),
      .dpad_left(dpad_left),
      .dpad_right(dpad_right),

      // MPU Input
      .input_k(input_k),

      .input_beta(input_beta),
      .input_ba  (input_ba),
      .input_acl (input_acl)
  );

  ////////////////////////////////////////////////////////////////////////////////////////
  // Device/CPU

  // 1020 (the multiplier from 32.768kHz to vid clock) * 3
  localparam DIVIDER_RESET_VALUE = 12'hBF4 - 12'h1;
  reg [11:0] clock_divider = DIVIDER_RESET_VALUE;

  wire clk_en = clock_divider == 0;

  always @(posedge clk_sys_99_287) begin
    clock_divider <= clock_divider - 1;

    if (clock_divider == 0) begin
      clock_divider <= DIVIDER_RESET_VALUE;
    end
  end

  wire [1:0] output_lcd_h_index;

  wire [15:0] current_segment_a;
  wire [15:0] current_segment_b;
  wire current_segment_bs;

  wire [3:0] current_w_prime[9];
  wire [3:0] current_w_main[9];

  wire divider_1khz;

  sm510 sm510 (
      .clk(clk_sys_99_287),

      .clk_en(clk_en),

      .reset(reset),

      .cpu_id(cpu_id),

      .rom_data(rom_data),
      .rom_addr(rom_addr),

      .input_k(input_k),

      .input_ba  (input_ba),
      .input_beta(input_beta),

      .output_lcd_h_index(output_lcd_h_index),

      .output_shifter_s(output_shifter_s),

      .segment_a (current_segment_a),
      .segment_b (current_segment_b),
      .segment_bs(current_segment_bs),

      .w_prime(current_w_prime),
      .w_main (current_w_main),

      .output_r(output_r),

      // Settings
      .accurate_lcd_timing(accurate_lcd_timing),

      // Utility
      .divider_1khz(divider_1khz)
  );

  assign sound = output_r[0];

  ////////////////////////////////////////////////////////////////////////////////////////
  // Video

  wire        sd_data_available;
  wire [15:0] sd_out;
  wire        sd_end_burst;
  wire        sd_rd;
  wire [24:0] sd_rd_addr;

  video #(
      .CLOCK_RATIO(3)
  ) video (
      .clk_sys_99_287(clk_sys_99_287),
      .clk_vid_33_095(clk_vid_33_095),

      .reset(reset || ioctl_download),

      .cpu_id(cpu_id),

      .mask_data_wr(mask_config_download && ioctl_wr),
      .mask_data(ioctl_dout),

      .divider_1khz(divider_1khz),

      // Segments
      .current_segment_a (current_segment_a),
      .current_segment_b (current_segment_b),
      .current_segment_bs(current_segment_bs),

      .current_w_prime(current_w_prime),
      .current_w_main (current_w_main),

      .output_lcd_h_index(output_lcd_h_index),

      // Settings
      .lcd_off_alpha(lcd_off_alpha),

      // Video
      .hsync (hsync),
      .vsync (vsync),
      .hblank(hblank),
      .vblank(vblank),

      .de (de),
      .rgb(rgb),

      // SDRAM
      .sd_data_available(sd_data_available),
      .sd_out(sd_out),
      .sd_end_burst(sd_end_burst),
      .sd_rd(sd_rd),
      .sd_rd_addr(sd_rd_addr)
  );

  ////////////////////////////////////////////////////////////////////////////////////////
  // SDRAM

  wire sdram_wr = ioctl_wr && image_download;

  sdram_burst #(
      .CLOCK_SPEED_MHZ(99.28704),
      .CAS_LATENCY(2)
  ) sdram (
      .clk  (clk_sys_99_287),
      .reset(~pll_core_locked),

      // Port 0
      .p0_addr(sdram_wr ? base_addr : sd_rd_addr),
      .p0_data(ioctl_dout),
      .p0_byte_en(2'b11),
      .p0_q(sd_out),

      .p0_wr_req(sdram_wr),
      .p0_rd_req(sd_rd),
      .p0_end_burst_req(sd_end_burst),

      .p0_data_available(sd_data_available),

      .SDRAM_DQ(SDRAM_DQ),
      .SDRAM_A(SDRAM_A),
      .SDRAM_DQM(SDRAM_DQM),
      .SDRAM_BA(SDRAM_BA),
      .SDRAM_nCS(SDRAM_nCS),
      .SDRAM_nWE(SDRAM_nWE),
      .SDRAM_nRAS(SDRAM_nRAS),
      .SDRAM_nCAS(SDRAM_nCAS),
      .SDRAM_CLK(SDRAM_CLK),
      .SDRAM_CKE(SDRAM_CKE)
  );

endmodule
