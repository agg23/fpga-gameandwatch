module ram (
    input wire clk,

    input wire [6:0] addr,
    input wire wren,
    input wire [3:0] data,

    output reg [3:0] q = 0,

    input wire [1:0] lcd_h,

    // Comb
    output reg [15:0] segment_a = 0,
    output reg [15:0] segment_b = 0
);

  // Entire RAM is represented here. We write through to registers for display RAM (segments)
  reg [3:0] ram[128];

  // Cached versions of all segments, with 4 H values
  reg [1:0] cached_segment_a[16];
  reg [1:0] cached_segment_b[16];

  always_comb begin
    integer i;

    for (i = 0; i < 16; i += 1) begin
      segment_a[i] = cached_segment_a[i][lcd_h];
      segment_b[i] = cached_segment_b[i][lcd_h];
    end
  end

  always @(posedge clk) begin
    // TODO: Does this need to be comb?
    q <= ram[addr];

    if (wren) begin
      ram[addr] <= data;

      if (addr >= 7'h60) begin
        // Display RAM segment
        reg [15:0] temp;

        if (addr[4]) begin
          // Segment B
          cached_segment_b[addr[3:0]] <= data;
        end else begin
          // Segment A
          cached_segment_a[addr[3:0]] <= data;
        end
      end
    end
  end

endmodule
