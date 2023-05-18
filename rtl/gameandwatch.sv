module gameandwatch (
    input wire clk_sys_131_072,
    input wire clk_vid_32_768,

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
    output reg hsync,
    output reg vsync,
    output reg hblank,
    output reg vblank,

    output reg de,
    output wire [23:0] rgb,

    // Sound
    output wire sound,

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
  reg sd_rd = 0;
  reg sd_end_burst = 0;

  wire sd_data_available;
  wire [15:0] sd_out;

  image_fifo image_fifo (
      .wrclk(clk_sys_131_072),
      .rdclk(clk_vid_32_768),

      .wrreq(buffer_count == 3'h3),
      .data (buffer),

      .rdreq(de_int),
      // TODO: Can this be fixed somewhere?
      .q({rgb[7:0], rgb[15:8], rgb[23:16]}),

      .aclr(hblank && ~prev_hblank)
  );

  localparam WORDS_PER_LINE = 16'd720 * 16'h3 / 16'h2;

  reg prev_sd_data_available;
  reg prev_hblank = 0;

  // Two pixel buffer
  reg [47:0] buffer = 0;
  reg [2:0] buffer_count = 0;
  reg [15:0] sd_read_count = 0;

  always @(posedge clk_sys_131_072) begin
    if (reset) begin
      buffer <= 0;
      buffer_count <= 0;
    end else begin
      reg [2:0] new_buffer_count;

      prev_sd_data_available <= sd_data_available;
      prev_hblank <= hblank;

      new_buffer_count = buffer_count;

      sd_rd <= 0;
      sd_end_burst <= 0;

      if (buffer_count == 3'h3) begin
        // Writting buffer, we've now "cleared" it
        new_buffer_count = 0;
      end

      buffer_count <= new_buffer_count;

      if (sd_data_available) begin
        buffer <= {sd_out, buffer[47:16]};
        buffer_count <= new_buffer_count + 3'h1;

        sd_read_count <= sd_read_count + 16'h1;

        if (sd_read_count >= WORDS_PER_LINE - 16'h2) begin
          // Don't need to read any more. Halt burst
          sd_end_burst <= 1;
        end
      end else if (~sd_data_available && prev_sd_data_available) begin
        // We stopped reading, check if we need to read more
        if (sd_read_count < WORDS_PER_LINE) begin
          // We haven't read enough, queue another read
          sd_rd <= 1;
        end
      end

      if (hblank && ~prev_hblank) begin
        sd_rd <= 1;

        // For easy debugging
        buffer <= 0;
        buffer_count <= 0;

        sd_read_count <= 0;
      end
    end
  end

  wire [9:0] video_y;

  // Address of the next line of the image
  // Address calculates the number of bytes (not words) so we have full precision
  // Will never set the lowest bit, so we are fine to drop it to go to word addressing
  // wire [9:0] read_y = video_y >= 10'd720 ? 10'b0 : video_y + 10'h1;
  wire [9:0] read_y = video_y >= 10'd720 ? 10'b0 : video_y;
  wire [25:0] read_byte_addr = {16'b0, read_y} * 26'd720 * 26'h3;
  wire [24:0] read_addr = read_byte_addr[25:1] + {9'b0, sd_read_count};

  sdram_burst #(
      .CLOCK_SPEED_MHZ(131.072),
      .CAS_LATENCY(3)
  ) sdram (
      .clk  (clk_sys_131_072),
      .reset(~pll_core_locked),

      // Port 0
      .p0_addr(ioctl_wr ? ioctl_addr : read_addr),
      .p0_data(ioctl_dout),
      .p0_byte_en(2'b11),
      .p0_q(sd_out),

      .p0_wr_req(ioctl_wr),
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

  wire hsync_int;
  wire vsync_int;
  wire hblank_int;
  wire vblank_int;

  wire de_int;

  // Delay all signals by 1 cycle so that RGB is caught up
  always @(posedge clk_vid_32_768) begin
    hsync <= hsync_int;
    vsync <= vsync_int;
    hblank <= hblank_int;
    vblank <= vblank_int;

    de <= de_int;
  end

  video video (
      .clk(clk_vid_32_768),

      .y(video_y),

      .hsync (hsync_int),
      .vsync (vsync_int),
      .hblank(hblank_int),
      .vblank(vblank_int),

      .de(de_int)
  );

endmodule
