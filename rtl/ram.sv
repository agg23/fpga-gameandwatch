module ram (
    input wire clk,

    input wire [3:0] cpu_id,

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
  reg [3:0] cached_segment_a[16];
  reg [3:0] cached_segment_b[16];

  always_comb begin
    integer i;

    for (i = 0; i < 16; i += 1) begin
      segment_a[i] = cached_segment_a[i][lcd_h];
      segment_b[i] = cached_segment_b[i][lcd_h];
    end
  end

  // Comb
  reg [6:0] final_addr;

  // Function separated out so it can be used for testing
  function [6:0] computed_addr();
    case (cpu_id)
      4: begin
        // SM5a
        reg [2:0] upper_addr;
        upper_addr = addr[6:4];

        if (upper_addr > 3'h4) begin
          // Wrap 0x50 and above to 0x40
          upper_addr = 3'h4;
        end

        computed_addr = {upper_addr, addr[3:0]};

        if (addr[3:0] > 4'hC) begin
          // Wrap 0xD-F to 0xC
          computed_addr[3:0] = 4'hC;
        end
      end
      default: begin
        // SM510/SM510 Tiger
        computed_addr = addr;
      end
    endcase
  endfunction

  always_comb begin
    final_addr = computed_addr();
  end

  always @(posedge clk) begin
    // TODO: Does this need to be comb?
    q <= ram[final_addr];

    if (wren) begin
      ram[final_addr] <= data;

      if (final_addr >= 7'h60) begin
        // Display RAM segment
        if (final_addr[4]) begin
          // Segment B
          cached_segment_b[final_addr[3:0]] <= data;
        end else begin
          // Segment A
          cached_segment_a[final_addr[3:0]] <= data;
        end
      end
    end
  end

endmodule
