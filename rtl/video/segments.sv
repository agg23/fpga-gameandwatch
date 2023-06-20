module segments (
    input wire clk,

    input wire [3:0] cpu_id,

    input wire mask_data_wr,
    input wire [15:0] mask_data,

    // Segments
    input wire [15:0] cache_segment_a [4],
    input wire [15:0] cache_segment_b [4],
    input wire [ 1:0] cache_segment_bs,

    input wire [3:0] cache_w_prime[9],
    input wire [3:0] cache_w_main [9],

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
      case (cpu_id)
        4: begin
          // SM5a
          if (segment_row == 2'h1) begin
            // W'
            segment_en = cache_w_prime[segment_line_select][segment_column];
          end else begin
            // W
            segment_en = cache_w_main[segment_line_select][segment_column];
          end
        end
        default: begin
          // SM510
          case (segment_line_select)
            4'h0: segment_en = cache_segment_a[segment_row][segment_column];
            4'h1: segment_en = cache_segment_b[segment_row][segment_column];
            4'h2: segment_en = cache_segment_bs[segment_row];
            default: begin
              // TODO: What happens in these cases?
            end
          endcase
        end
      endcase
    end
  end
endmodule
