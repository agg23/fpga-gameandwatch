module mask #(
    parameter START_ADDRESS = 25'h17BB00,
    parameter CLOCK_RATIO   = 4
) (
    input wire clk,

    input wire        ioctl_wr,
    input wire [24:0] ioctl_addr,
    input wire [15:0] ioctl_dout,

    input wire vblank,
    input wire hblank,
    input wire [9:0] video_x,
    input wire [9:0] video_y,

    output reg segment_enabled = 0
);
  ////////////////////////////////////////////////////////////////////////////////////////
  // ROM management

  reg [14:0] read_addr = 0;
  reg [14:0] write_addr = 0;

  reg [39:0] mask_rom[18720];
  reg [39:0] mask_output = 0;

  reg wren = 0;

  always @(posedge clk) begin
    if (wren) begin
      mask_rom[write_addr] <= buffer_40;
    end
    mask_output <= mask_rom[read_addr];
  end

  wire [9:0] segment_id  /* synthesis keep */;
  wire [9:0] segment_start_x  /* synthesis keep */;
  wire [9:0] segment_y  /* synthesis keep */;
  wire [9:0] segment_length  /* synthesis keep */;

  assign {segment_length, segment_y, segment_start_x, segment_id} = mask_output;

  reg [15:0] buffer_16 = 0;
  reg [ 1:0] buffer_16_bytes = 0;

  always @(posedge clk) begin
    if (ioctl_wr && ioctl_addr >= START_ADDRESS) begin
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

  always @(posedge clk) begin
    prev_wren <= wren;
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
  localparam VID_COUNTER_DEPTH = $clog2(CLOCK_RATIO_START_VALUE);

  reg in_segment = 0;
  reg [9:0] length = 0;
  reg [VID_COUNTER_DEPTH -1 : 0] vid_counter = 0;

  always @(posedge clk) begin
    segment_enabled <= in_segment;

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
      if (in_segment) begin
        // Existing segment
        length <= length - 10'h1;

        in_segment <= length > 10'h0;

        if (length == 10'h1) begin
          read_addr <= read_addr + 15'h1;
        end
      end else if (video_x == segment_start_x && video_y == segment_y) begin
        // Beginning of segment
        in_segment <= 1;
        // TODO: Change to actual segment status by using ID
        segment_enabled <= 1;

        length <= segment_length - 10'h1;

        if (segment_length == 10'h1) begin
          read_addr <= read_addr + 15'h1;
        end
      end else begin
        segment_enabled <= 0;
      end
    end
  end

endmodule
