module divider (
    input wire clk,
    input wire clk_en,

    input wire reset,

    input wire reset_gamma,
    input wire reset_divider,

    output reg gamma = 0,
    output reg divider_1s_tick = 0, // Temp value to wake from halt

    output wire divider_4hz,
    output wire divider_32hz,
    output wire divider_64hz,
    output wire divider_1khz
);
  reg [14:0] divider = 0;

  assign divider_4hz  = divider[14];
  assign divider_32hz = divider[11];
  assign divider_64hz = divider[10];
  assign divider_1khz = divider[4];

  always @(posedge clk) begin
    if (reset) begin
      gamma <= 0;

      divider <= 0;
      divider_1s_tick <= 0;
    end else if (clk_en) begin
      divider_1s_tick <= 0;

      if (reset_gamma) begin
        gamma <= 0;
      end

      if (reset_divider) begin
        // TODO: Remove. This is to match MAME testing
        divider <= 2;
        // divider <= 0;
      end else begin
        // Increment
        divider <= divider + 15'h1;

        if (divider == 15'h7FFF) begin
          // Will wrap to 0 next cycle. 1 second has elapsed
          gamma <= 1;
          divider_1s_tick <= 1;
        end
      end
    end
  end

endmodule
