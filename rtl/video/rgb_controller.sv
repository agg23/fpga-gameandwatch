module rgb_controller (
    input wire clk_sys_131_072,
    input wire clk_vid_32_768,

    input wire reset,

    // Video
    input wire hblank_int,
    input wire [9:0] video_x,
    input wire [9:0] video_y,
    input wire de_int,

    // RGB
    output wire [23:0] background_rgb,
    output wire [23:0] mask_rgb,

    // SDRAM
    input wire sd_data_available,
    input wire [15:0] sd_out,
    output reg sd_rd = 0,
    output reg sd_end_burst = 0,
    output reg [24:0] sd_rd_addr
);

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
  reg prev_hblank2 = 0;

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
      prev_hblank2 <= prev_hblank;

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

      // Delay hblank trigger by one cycle so that sd_rd_addr can be set properly
      if (hblank_int && ~prev_hblank) begin
        sd_read_count <= 0;
      end else if (prev_hblank && ~prev_hblank2) begin
        sd_rd <= 1;

        // For easy debugging
        background_buffer <= 0;
        mask_buffer <= 0;
        buffer_count <= 0;
      end
    end
  end

  // Address of the next line of the image
  // Address calculates the number of bytes (not words) so we have full precision
  // Essentually multiply by two, then divide by to for interleaved data, then byte addressing
  always @(posedge clk_sys_131_072) begin
    reg [ 9:0] read_y;
    reg [25:0] read_byte_addr;

    read_y = video_y >= 10'd720 ? 10'b0 : hblank_int ? video_y + 10'h1 : video_y;
    read_byte_addr = {16'b0, read_y} * 26'd720 * 26'h3 * 26'h2;

    sd_rd_addr <= read_byte_addr[25:1] + {9'b0, sd_read_count};
  end

endmodule
