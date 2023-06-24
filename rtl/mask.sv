module mask #(
    parameter CLOCK_RATIO = 3
) (
    input wire clk,

    input wire reset,

    input wire        ioctl_wr,
    input wire [15:0] ioctl_dout,

    input wire vblank,
    input wire hblank,
    input wire [9:0] video_x,
    input wire [9:0] video_y,

    output reg [9:0] segment_id = 0,  // Cycle delayed to only update on video_clock cycles
    output reg has_segment = 0 // Cycle delayed in_segment to properly track the cycles we should render segments
);
  ////////////////////////////////////////////////////////////////////////////////////////
  // ROM management

  reg [14:0] read_addr = 0;
  reg [14:0] write_addr = 0;

  reg wren = 0;

  wire [9:0] next_segment_id;

  mask_rom mask_rom (
      .clock(clk),

      .address(wren ? write_addr : read_addr),
      .wren(wren),
      .data(buffer_40),
      .q({segment_length, segment_y, segment_start_x, next_segment_id})
  );

  wire [ 9:0] segment_start_x  /* synthesis keep */;
  wire [ 9:0] segment_y  /* synthesis keep */;
  wire [ 9:0] segment_length  /* synthesis keep */;

  reg  [15:0] buffer_16 = 0;
  reg  [ 1:0] buffer_16_bytes = 0;

  always @(posedge clk) begin
    if (ioctl_wr) begin
      buffer_16 <= ioctl_dout;
      buffer_16_bytes <= 2;
    end

    if (buffer_16_bytes > 0) begin
      buffer_16 <= {8'h0, buffer_16[15:8]};
      buffer_16_bytes <= buffer_16_bytes - 2'h1;
    end
  end

  reg [39:0] buffer_40 = 0;
  reg [2:0] buffer_40_bytes = 0;
  reg prev_wren = 0;

  reg prev_reset = 0;

  always @(posedge clk) begin
    prev_reset <= reset;
    prev_wren  <= wren;

    if (reset && ~prev_reset) begin
      write_addr <= 0;
    end

    wren <= 0;

    if (buffer_16_bytes > 0) begin
      // Write. Load next byte into buffer
      buffer_40 <= {buffer_16[7:0], buffer_40[39:8]};
      buffer_40_bytes <= buffer_40_bytes + 3'h1;

      if (buffer_40_bytes + 3'h1 == 3'h5) begin
        // This was last byte, write
        wren <= 1;
        buffer_40_bytes <= 3'h0;
      end
    end

    if (~wren && prev_wren) begin
      // Finished write, increment addr
      write_addr <= write_addr + 15'h1;
    end
  end

  ////////////////////////////////////////////////////////////////////////////////////////
  // Mask pixel selection

  localparam CLOCK_RATIO_START_VALUE = CLOCK_RATIO - 1;
  localparam VID_COUNTER_DEPTH = $clog2(CLOCK_RATIO_START_VALUE + 1);

  // Currently in segment
  reg in_segment = 0;
  reg [9:0] length = 0;
  reg [VID_COUNTER_DEPTH -1 : 0] vid_counter = 0;

  always @(posedge clk) begin
    has_segment <= in_segment;

    if (vid_counter > 0) begin
      vid_counter <= vid_counter - 'h1;
    end else begin
      vid_counter <= CLOCK_RATIO_START_VALUE[VID_COUNTER_DEPTH-1:0];
    end

    if (vblank) begin
      read_addr  <= 0;
      in_segment <= 0;
    end else if (hblank) begin
      in_segment <= 0;
    end else if (vid_counter == 0) begin
      segment_id <= next_segment_id;

      if (video_x == segment_start_x && video_y == segment_y) begin
        // Beginning of segment
        // This takes priority over existing segment, as the segments may come one right after another
        in_segment <= 1;
        // TODO: Change to actual segment status by using ID
        has_segment <= 1;

        length <= segment_length - 10'h1;

        if (segment_length == 10'h1) begin
          read_addr <= read_addr + 15'h1;
        end
      end else if (in_segment) begin
        // Existing segment
        length <= length - 10'h1;

        in_segment <= length > 10'h0;

        if (length == 10'h1) begin
          read_addr <= read_addr + 15'h1;
        end
      end else begin
        has_segment <= 0;
      end
    end
  end

endmodule
