module segments #(
    parameter MAX_X_SEGMENT = 9,
    parameter MAX_Y_SEGMENT = 16,
    parameter MAX_Z_SEGMENT = 4
) (
    input wire clk,

    input wire [3:0] cpu_id,

    input wire mask_data_wr,
    input wire [15:0] mask_data,

    input wire [MAX_Z_SEGMENT-1:0] segments[MAX_X_SEGMENT][MAX_Y_SEGMENT],

    // Video counters
    input wire vblank_int,
    input wire hblank_int,
    input wire [9:0] video_x,
    input wire [9:0] video_y,

    // Comb
    output reg segment_en
);
  // The line select of the segment, choosing which seg_a/b/bs is used. First value x in x.y.z
  wire [3:0] segment_line_select  /* synthesis keep */;

  // The column of the segment, corresponding to bit in the seg_a/b/bs line. Second value y in x.y.z
  wire [3:0] segment_column  /* synthesis keep */;

  // The row of the segment, corresponding to which H bit is high. Third value z in x.y.z
  wire [1:0] segment_row  /* synthesis keep */;

  wire has_segment;

  mask mask (
      .clk(clk),

      .ioctl_wr  (mask_data_wr),
      .ioctl_dout(mask_data),

      .vblank (vblank_int),
      .hblank (hblank_int),
      .video_x(video_x),
      .video_y(video_y),

      .segment_id ({segment_line_select, segment_column, segment_row}),
      .has_segment(has_segment)
  );

  always_comb begin
    segment_en = 0;

    if (has_segment) begin
      segment_en = segments[segment_line_select][segment_column][segment_row];
    end
  end
endmodule
