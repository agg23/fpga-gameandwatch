module lcd #(
    parameter CLOCK_RATIO = 3
) (
    input wire clk,

    input wire [3:0] cpu_id,

    input wire mask_data_wr,
    input wire [15:0] mask_data,

    // Segments
    input wire [15:0] current_segment_a,
    input wire [15:0] current_segment_b,
    input wire current_segment_bs,

    input wire [3:0] current_w_prime[9],
    input wire [3:0] current_w_main [9],

    input wire [1:0] output_lcd_h_index,

    input wire divider_1khz,

    // Video counters
    input wire vblank_int,
    input wire hblank_int,
    input wire [9:0] video_x,
    input wire [9:0] video_y,

    output wire segment_en
);
  localparam DECAY_MAX = 5'h1F;
  localparam DECAY_MIN_DISPLAY = 5'h10;

  localparam MAX_X_SEGMENT = 9;
  localparam MAX_Y_SEGMENT = 16;
  localparam MAX_Z_SEGMENT = 4;

  wire [MAX_Z_SEGMENT-1:0] raw_segments[MAX_X_SEGMENT][MAX_Y_SEGMENT];
  reg [MAX_Z_SEGMENT-1:0] decayed_segments[MAX_X_SEGMENT][MAX_Y_SEGMENT];
  reg [MAX_Z_SEGMENT-1:0] vsync_segments[MAX_X_SEGMENT][MAX_Y_SEGMENT];

  reg [4:0] segment_current_decays[MAX_X_SEGMENT][MAX_Y_SEGMENT][MAX_Z_SEGMENT-1:0];

  reg prev_divider_1khz = 0;
  reg prev_vblank = 0;

  normalize #(
      .MAX_X_SEGMENT(MAX_X_SEGMENT),
      .MAX_Y_SEGMENT(MAX_Y_SEGMENT),
      .MAX_Z_SEGMENT(MAX_Z_SEGMENT)
  ) normalize (
      .clk(clk),

      .cpu_id(cpu_id),

      .current_segment_a (current_segment_a),
      .current_segment_b (current_segment_b),
      .current_segment_bs(current_segment_bs),

      .current_w_prime(current_w_prime),
      .current_w_main (current_w_main),

      .output_lcd_h_index(output_lcd_h_index),

      .segments(raw_segments)
  );

  segments #(
      .CLOCK_RATIO  (CLOCK_RATIO),
      .MAX_X_SEGMENT(MAX_X_SEGMENT),
      .MAX_Y_SEGMENT(MAX_Y_SEGMENT),
      .MAX_Z_SEGMENT(MAX_Z_SEGMENT)
  ) lcd_segments (
      .clk(clk),

      .cpu_id(cpu_id),

      .mask_data_wr(mask_data_wr),
      .mask_data(mask_data),

      .segments(vsync_segments),

      .vblank_int(vblank_int),
      .hblank_int(hblank_int),
      .video_x(video_x),
      .video_y(video_y),

      .segment_en(segment_en)
  );

  always @(posedge clk) begin
    int x, y, z;

    prev_vblank <= vblank_int;
    prev_divider_1khz <= divider_1khz;

    // Pass raw segments through deflicker stage
    if (divider_1khz && ~prev_divider_1khz) begin
      for (x = 0; x < MAX_X_SEGMENT; x += 1) begin
        for (y = 0; y < MAX_Y_SEGMENT; y += 1) begin
          for (z = 0; z < MAX_Z_SEGMENT; z += 1) begin
            reg [4:0] current_decay;
            current_decay = segment_current_decays[x][y][z];

            if (raw_segments[x][y][z] && current_decay < DECAY_MAX) begin
              // Segment is on, and decay isn't max
              // Increment decay
              segment_current_decays[x][y][z] <= current_decay + 5'h1;
            end else if (~raw_segments[x][y][z] && current_decay > 5'h0) begin
              // Segment is off, and decay isn't min
              // Decrement decay
              segment_current_decays[x][y][z] <= current_decay - 5'h1;
            end

            // Update segment array (an iteration delayed)
            decayed_segments[x][y][z] <= current_decay > DECAY_MIN_DISPLAY;
          end
        end
      end
    end

    // Pass deflickered segment through vblank buffer stage
    if (vblank_int && ~prev_vblank) begin
      vsync_segments <= decayed_segments;
    end
  end
endmodule
