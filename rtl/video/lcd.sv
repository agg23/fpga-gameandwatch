module lcd (
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

  reg prev_divider_1khz = 0;

  // Comb
  reg [1:0] current_h_index;
  reg prev_vblank = 0;

  localparam DECAY_MAX = 5'h1F;
  localparam DECAY_MIN_DISPLAY = 5'h10;

  segments segments (
      .clk(clk),

      .cpu_id(cpu_id),

      .mask_data_wr(mask_data_wr),
      .mask_data(mask_data),

      // Segments
      .cache_segment_a (cache_segment_a),
      .cache_segment_b (cache_segment_b),
      .cache_segment_bs(cache_segment_bs),

      .cache_w_prime(cache_w_prime),
      .cache_w_main (cache_w_main),

      .vblank_int(vblank_int),
      .hblank_int(hblank_int),
      .video_x(video_x),
      .video_y(video_y),

      .segment_en(segment_en)
  );

  always @(posedge clk) begin
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
endmodule
