module video (
    input wire clk_sys_131_072,
    input wire clk_vid_32_768,

    input wire reset,

    input wire [3:0] cpu_id,

    // Data in
    input wire mask_data_wr,
    input wire [15:0] mask_data,

    input wire divider_1khz,

    // Segments
    input wire [15:0] current_segment_a,
    input wire [15:0] current_segment_b,
    input wire current_segment_bs,

    input wire [3:0] current_w_prime[9],
    input wire [3:0] current_w_main [9],

    input wire [1:0] output_lcd_h_index,

    // Video
    output reg hsync,
    output reg vsync,
    output reg hblank,
    output reg vblank,

    output reg de,
    output wire [23:0] rgb,

    // SDRAM
    input wire sd_data_available,
    input wire [15:0] sd_out,
    output wire sd_end_burst,
    output wire sd_rd,
    output wire [24:0] sd_rd_addr
);
  wire [9:0] video_x;
  wire [9:0] video_y;

  wire hsync_int;
  wire vsync_int;
  wire hblank_int;
  wire vblank_int;

  wire de_int;

  ////////////////////////////////////////////////////////////////////////////////////////
  // LCD

  wire segment_en;

  lcd lcd (
      .clk(clk_sys_131_072),

      .cpu_id(cpu_id),

      .mask_data_wr(mask_data_wr),
      .mask_data(mask_data),

      // Segments
      .current_segment_a (current_segment_a),
      .current_segment_b (current_segment_b),
      .current_segment_bs(current_segment_bs),

      .current_w_prime(current_w_prime),
      .current_w_main (current_w_main),

      .output_lcd_h_index(output_lcd_h_index),

      .divider_1khz(divider_1khz),

      // Video counters
      .vblank_int(vblank_int),
      .hblank_int(hblank_int),
      .video_x(video_x),
      .video_y(video_y),

      .segment_en(segment_en)
  );

  ////////////////////////////////////////////////////////////////////////////////////////
  // SDRAM and RGB

  wire [23:0] background_rgb;
  wire [23:0] mask_rgb;

  assign rgb = segment_en ? mask_rgb : background_rgb;

  rgb_controller rgb_controller (
      .clk_sys_131_072(clk_sys_131_072),
      .clk_vid_32_768 (clk_vid_32_768),

      .reset(reset),

      // Video
      .hblank_int(hblank_int),
      .video_x(video_x),
      .video_y(video_y),
      .de_int(de_int),

      // RGB
      .background_rgb(background_rgb),
      .mask_rgb(mask_rgb),

      // SDRAM
      .sd_data_available(sd_data_available),
      .sd_out(sd_out),
      .sd_end_burst(sd_end_burst),
      .sd_rd(sd_rd),
      .sd_rd_addr(sd_rd_addr)
  );

  ////////////////////////////////////////////////////////////////////////////////////////
  // Sync counts

  // Delay all signals by 1 cycle so that RGB is caught up
  always @(posedge clk_vid_32_768) begin
    hsync <= hsync_int;
    vsync <= vsync_int;
    hblank <= hblank_int;
    vblank <= vblank_int;

    de <= de_int;
  end

  counts counts (
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
