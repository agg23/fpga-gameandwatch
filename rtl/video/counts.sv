module counts (
    input wire clk,

    output reg [9:0] x = 0,
    output reg [9:0] y = 0,

    output reg hsync = 0,
    output reg vsync = 0,
    output reg hblank = 0,
    output reg vblank = 0,

    output wire de
);
  localparam WIDTH = 10'd720;
  localparam HEIGHT = 10'd720;

  localparam VBLANK_LEN = 10'd19;
  localparam HBLANK_LEN = 10'd19;

  localparam VBLANK_OFFSET = 10'd5;
  localparam HBLANK_OFFSET = 10'd5;

  ////////////////////////////////////////////////////////////////////////////////////////
  // Generated

  localparam VBLANK_TIME = HEIGHT + VBLANK_OFFSET;
  localparam HBLANK_TIME = WIDTH + HBLANK_OFFSET;

  localparam MAX_X = WIDTH + HBLANK_LEN;
  localparam MAX_Y = HEIGHT + VBLANK_LEN;

  initial begin
    $display("VBLANK at: %d, HBLANK at: %d", VBLANK_TIME, HBLANK_TIME);
    $display("Max x, y: %d, %d", MAX_X, MAX_Y);
  end

  assign de = x < WIDTH && y < HEIGHT;

  assign vblank = y >= HEIGHT;
  assign hblank = x >= WIDTH;

  always @(posedge clk) begin
    reg [9:0] next_x;
    reg [9:0] next_y;

    hsync <= 0;
    vsync <= 0;

    next_x = x + 10'b1;
    next_y = y;

    if (next_y == VBLANK_TIME && next_x == WIDTH + 10'b1) begin
      // VSync
      vsync <= 1;
    end else if (next_x == HBLANK_TIME) begin
      // HSync
      hsync <= 1;
    end else if (next_x == MAX_X) begin
      next_x = 10'h0;
      next_y = y + 10'b1;

      if (next_y == MAX_Y) begin
        next_y = 10'h0;
      end
    end

    x <= next_x;
    y <= next_y;
  end

endmodule
