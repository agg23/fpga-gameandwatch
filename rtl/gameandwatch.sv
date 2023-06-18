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

    // Settings
    input wire accurate_lcd_timing, // Use precise timing to update the cached LCD segments based on H timing. This doesn't look good, hence the setting

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

  wire [31:0] input_s0_config;
  wire [31:0] input_s1_config;
  wire [31:0] input_s2_config;
  wire [31:0] input_s3_config;
  wire [31:0] input_s4_config;
  wire [31:0] input_s5_config;
  wire [31:0] input_s6_config;
  wire [31:0] input_s7_config;

  wire [7:0] input_b_config;
  wire [7:0] input_ba_config;
  wire [7:0] input_acl_config;

  wire [24:0] base_addr;
  wire image_download;
  wire mask_config_download;
  // TODO: Use
  wire rom_download;

  wire wr_8bit;
  wire [25:0] addr_8bit;
  wire [7:0] data_8bit;

  wire [7:0] mpu;
  wire [3:0] cpu_id = mpu[3:0];

  rom_loader rom_loader (
      .clk(clk_sys_131_072),

      .ioctl_wr  (ioctl_wr),
      .ioctl_addr(ioctl_addr),
      .ioctl_dout(ioctl_dout),

      // Main config
      .mpu(mpu),

      // Input config
      .input_s0_config(input_s0_config),
      .input_s1_config(input_s1_config),
      .input_s2_config(input_s2_config),
      .input_s3_config(input_s3_config),
      .input_s4_config(input_s4_config),
      .input_s5_config(input_s5_config),
      .input_s6_config(input_s6_config),
      .input_s7_config(input_s7_config),

      .input_b_config  (input_b_config),
      .input_ba_config (input_ba_config),
      .input_acl_config(input_acl_config),

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

  always @(posedge clk_sys_131_072) begin
    if (clk_en) begin
      rom_data <= rom[rom_addr];
    end
  end

  always @(posedge clk_sys_131_072) begin
    if (wr_8bit && rom_download) begin
      // ioctl_dout has flipped bytes, flip back by modifying address
      rom[{addr_8bit[25:1], ~addr_8bit[0]}] <= data_8bit;
    end
  end

  ////////////////////////////////////////////////////////////////////////////////////////
  // Input

  wire [ 7:0] output_shifter_s;
  wire [ 3:0] output_r;

  // Comb
  reg  [31:0] active_input_config;

  always_comb begin
    active_input_config = input_s0_config;

    case (cpu_id)
      4: begin
        // SM5a
        if (output_r[1]) active_input_config = input_s0_config;
        else if (output_r[2]) active_input_config = input_s1_config;
        else if (output_r[3]) active_input_config = input_s2_config;
      end
      default: begin
        // SM510
        if (output_shifter_s[0]) active_input_config = input_s0_config;
        else if (output_shifter_s[1]) active_input_config = input_s1_config;
        else if (output_shifter_s[2]) active_input_config = input_s2_config;
        else if (output_shifter_s[3]) active_input_config = input_s3_config;
        else if (output_shifter_s[4]) active_input_config = input_s4_config;
        else if (output_shifter_s[5]) active_input_config = input_s5_config;
        else if (output_shifter_s[6]) active_input_config = input_s6_config;
        else if (output_shifter_s[7]) active_input_config = input_s7_config;
      end
    endcase
  end

  reg [3:0] input_k = 0;

  reg input_beta = 0;
  reg input_ba = 0;

  // TODO: Unused
  reg input_acl = 0;

  // Map from config value to control
  function input_mux([7:0] config_value);
    reg out;

    // High bit is active low flag
    case (config_value[6:0])
      0: out = dpad_up;
      1: out = dpad_down;
      2: out = dpad_left;
      3: out = dpad_right;

      // Buttons
      4: out = button_b;
      5: out = button_a;
      6: out = button_y;
      7: out = button_x;

      // Buttons 5-8 unhandled
      // Select is Time
      12: out = button_trig_l;
      13: out = button_select;
      14: out = button_start;

      // Service1 unhandled
      // Service 2 is Alarm
      16: out = button_trig_r;

      // This input is unused
      7'h7F: out = 0;
      // Other values unhandled

      default: out = 0;
    endcase

    return config_value[7] ? ~out : out;
  endfunction

  always @(posedge clk_sys_131_072) begin
    input_k <= {
      input_mux(active_input_config[31:24]),
      input_mux(active_input_config[23:16]),
      input_mux(active_input_config[15:8]),
      input_mux(active_input_config[7:0])
    };

    input_beta <= input_mux(input_b_config);
    input_ba <= input_mux(input_ba_config);
    input_acl <= input_mux(input_acl_config);
  end

  ////////////////////////////////////////////////////////////////////////////////////////
  // Device/CPU

  localparam DIVIDER_RESET_VALUE = 12'hFA0 - 12'h1;
  reg [11:0] clock_divider = DIVIDER_RESET_VALUE;

  wire clk_en = clock_divider == 0;

  always @(posedge clk_sys_131_072) begin
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

  sm510 sm510 (
      .clk(clk_sys_131_072),

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
  // Mask

  // Segments, over all H's, as last seen
  reg [15:0] segment_a[4];
  reg [15:0] segment_b[4];
  reg [1:0] segment_bs;

  reg [15:0] cache_segment_a[4];
  reg [15:0] cache_segment_b[4];
  reg [1:0] cache_segment_bs;

  reg [3:0] w_prime[9];
  reg [3:0] w_main[9];

  reg [3:0] cache_w_prime[9];
  reg [3:0] cache_w_main[9];

  reg [4:0] decay_w_prime[9][4];
  reg [4:0] decay_w_main[9][4];

  wire divider_1khz;
  reg prev_divider_1khz = 0;

  // Comb
  reg [1:0] current_h_index;
  reg prev_vblank = 0;

  localparam DECAY_MAX = 5'h1F;
  localparam DECAY_MIN_DISPLAY = 5'h10;

  always @(posedge clk_sys_131_072) begin
    int i;
    int j;

    prev_vblank <= vblank_int;
    prev_divider_1khz <= divider_1khz;

    // TODO: This is very similar to the logic already in `ram.sv`
    segment_a[output_lcd_h_index] <= current_segment_a;
    segment_b[output_lcd_h_index] <= current_segment_b;
    segment_bs[output_lcd_h_index] <= current_segment_bs;

    if (output_lcd_h_index[0]) begin
      // W'
      w_prime <= current_w_prime;
    end else begin
      // W
      w_main <= current_w_main;
    end

    if (divider_1khz && ~prev_divider_1khz) begin
      for (i = 0; i < 9; i += 1) begin
        for (j = 0; j < 4; j += 1) begin
          // W'
          // Modify decay
          if (w_prime[i][j] && decay_w_prime[i][j] < DECAY_MAX) begin
            // Segment is on, and decay isn't max
            // Increment decay
            decay_w_prime[i][j] <= decay_w_prime[i][j] + 5'h1;
          end else if (~w_prime[i][j] && decay_w_prime[i][j] > 5'h0) begin
            // Segment is off, and decay isn't min
            // Decrement decay
            decay_w_prime[i][j] <= decay_w_prime[i][j] - 5'h1;
          end

          // Update segment array (an iteration delayed)
          cache_w_prime[i][j] <= decay_w_prime[i][j] > DECAY_MIN_DISPLAY;

          // W
          if (w_main[i][j] && decay_w_main[i][j] < DECAY_MAX) begin
            decay_w_main[i][j] <= decay_w_main[i][j] + 5'h1;
          end else if (~w_main[i][j] && decay_w_main[i][j] > 5'h0) begin
            decay_w_main[i][j] <= decay_w_main[i][j] - 5'h1;
          end

          cache_w_main[i][j] <= decay_w_main[i][j] > DECAY_MIN_DISPLAY;
        end
      end
    end

    if (vblank_int && ~prev_vblank) begin
      cache_segment_a[0] <= segment_a[0];
      cache_segment_a[1] <= segment_a[1];
      cache_segment_a[2] <= segment_a[2];
      cache_segment_a[3] <= segment_a[3];

      cache_segment_b[0] <= segment_b[0];
      cache_segment_b[1] <= segment_b[1];
      cache_segment_b[2] <= segment_b[2];
      cache_segment_b[3] <= segment_b[3];

      cache_segment_bs   <= segment_bs;
    end
  end

  // The line select of the segment, choosing which seg_a/b/bs is used
  wire [3:0] segment_line_select  /* synthesis keep */;

  // The column of the segment, corresponding to bit in the seg_a/b/bs line
  wire [3:0] segment_column  /* synthesis keep */;

  // The row of the segment, corresponding to which H bit is high
  wire [1:0] segment_row  /* synthesis keep */;

  // Comb
  reg display_segment;
  wire has_segment;

  always_comb begin
    display_segment = 0;

    if (has_segment) begin
      case (cpu_id)
        4: begin
          // SM5a
          if (segment_row == 2'h1) begin
            // W'
            display_segment = cache_w_prime[segment_line_select][segment_column];
          end else begin
            // W
            display_segment = cache_w_main[segment_line_select][segment_column];
          end
        end
        default: begin
          // SM510
          case (segment_line_select)
            4'h0: display_segment = cache_segment_a[segment_row][segment_column];
            4'h1: display_segment = cache_segment_b[segment_row][segment_column];
            4'h2: display_segment = cache_segment_bs[segment_row];
            default: begin
              // TODO: What happens in these cases?
            end
          endcase
        end
      endcase
    end
  end

  mask mask (
      .clk(clk_sys_131_072),

      .ioctl_wr  (mask_config_download && ioctl_wr),
      .ioctl_dout(ioctl_dout),

      .vblank (vblank_int),
      .hblank (hblank_int),
      .video_x(video_x),
      .video_y(video_y),

      .segment_id ({segment_line_select, segment_column, segment_row}),
      .has_segment(has_segment)
  );

  ////////////////////////////////////////////////////////////////////////////////////////
  // SDRAM

  reg sd_rd = 0;
  reg sd_end_burst = 0;

  wire sd_data_available;
  wire [15:0] sd_out;

  wire [23:0] background_rgb;
  wire [23:0] mask_rgb;

  assign rgb = display_segment ? mask_rgb : background_rgb;

  wire fifo_clear = hblank_int && ~prev_hblank;

  image_fifo background_image_fifo (
      .wrclk(clk_sys_131_072),
      .rdclk(clk_vid_32_768),

      .wrreq(buffer_count == 3'h3),
      .data (background_buffer),

      .rdreq(de_int),
      // TODO: Can this be fixed somewhere?
      // .q({rgb[7:0], rgb[15:8], rgb[23:16]}),
      .q({background_rgb[7:0], background_rgb[15:8], background_rgb[23:16]}),

      .aclr(fifo_clear)
  );

  image_fifo mask_image_fifo (
      .wrclk(clk_sys_131_072),
      .rdclk(clk_vid_32_768),

      .wrreq(buffer_count == 3'h3),
      .data (mask_buffer),

      .rdreq(de_int),
      .q({mask_rgb[7:0], mask_rgb[15:8], mask_rgb[23:16]}),

      .aclr(fifo_clear)
  );

  // 1/3rd of each pixel per 16 bit word (one byte to each FIFO)
  localparam WORDS_PER_LINE = 16'd720 * 16'h3;

  reg prev_sd_data_available;
  reg prev_hblank = 0;

  reg [23:0] background_buffer = 0;
  reg [23:0] mask_buffer = 0;

  reg [2:0] buffer_count = 0;
  reg [15:0] sd_read_count = 0;

  always @(posedge clk_sys_131_072) begin
    if (reset) begin
      background_buffer <= 0;
      mask_buffer <= 0;

      buffer_count <= 0;
    end else begin
      reg [2:0] new_buffer_count;

      prev_sd_data_available <= sd_data_available;
      prev_hblank <= hblank_int;

      new_buffer_count = buffer_count;

      sd_rd <= 0;
      sd_end_burst <= 0;

      if (buffer_count == 3'h3) begin
        // Writting buffer, we've now "cleared" it
        new_buffer_count = 0;
      end

      buffer_count <= new_buffer_count;

      if (sd_data_available) begin
        // Background is low byte
        background_buffer <= {sd_out[7:0], background_buffer[23:8]};
        mask_buffer <= {sd_out[15:8], mask_buffer[23:8]};

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

      if (hblank_int && ~prev_hblank) begin
        sd_rd <= 1;

        // For easy debugging
        background_buffer <= 0;
        mask_buffer <= 0;
        buffer_count <= 0;

        sd_read_count <= 0;
      end
    end
  end

  wire [9:0] video_x;
  wire [9:0] video_y;

  // Address of the next line of the image
  // Address calculates the number of bytes (not words) so we have full precision
  // Essentually multiply by two, then divide by to for interleaved data, then byte addressing
  wire [9:0] read_y = video_y >= 10'd720 ? 10'b0 : hblank_int ? video_y + 10'h1 : video_y;
  wire [25:0] read_byte_addr = {16'b0, read_y} * 26'd720 * 26'h3 * 26'h2  /* synthesis keep */;
  wire [24:0] read_addr = read_byte_addr[25:1] + {9'b0, sd_read_count};

  wire sdram_wr = ioctl_wr && image_download;

  sdram_burst #(
      .CLOCK_SPEED_MHZ(131.072),
      .CAS_LATENCY(3)
  ) sdram (
      .clk  (clk_sys_131_072),
      .reset(~pll_core_locked),

      // Port 0
      .p0_addr(sdram_wr ? base_addr : read_addr),
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

      .x(video_x),
      .y(video_y),

      .hsync (hsync_int),
      .vsync (vsync_int),
      .hblank(hblank_int),
      .vblank(vblank_int),

      .de(de_int)
  );

endmodule
