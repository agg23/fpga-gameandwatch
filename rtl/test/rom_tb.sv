`timescale 1ns / 1ns

module rom_tb;

  reg clk = 0;
  reg [1:0] clk_div = 0;

  reg reset = 0;

  wire [11:0] rom_addr;
  reg [7:0] rom_data = 0;

  sm510 cpu_uut (
      .clk(clk),

      .clk_en(clk_div == 2'h3),

      .reset(reset),

      .rom_data(rom_data),
      .rom_addr(rom_addr),

      .input_k(4'b0),

      .input_ba  (1'b0),
      .input_beta(1'b0)
  );

  always begin
    #1 clk <= ~clk;
  end

  always @(posedge clk) begin
    clk_div <= clk_div + 2'h1;
  end

  // 44 pages and 63 steps
  reg [7:0] rom[4096];

  always @(posedge clk) begin
    rom_data <= rom[rom_addr];
  end

  initial $readmemh("dkii.hex", rom);

  initial begin
    // Initialize RAM
    integer i;
    for (i = 0; i < 128; i += 1) begin
      cpu_uut.ram.ram[i] = 0;
    end
  end

  initial begin
    reset = 1;

    #20;

    reset = 0;

    forever begin
      #1;
    end
  end

endmodule
