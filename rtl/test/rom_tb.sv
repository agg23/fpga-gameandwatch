`timescale 1ns / 1ns

module rom_tb;

  reg clk = 0;
  reg [1:0] clk_div = 0;

  wire clk_en = clk_div == 2'h3;

  reg reset = 0;

  wire [11:0] rom_addr;
  reg [7:0] rom_data = 0;

  sm510 cpu_uut (
      .clk(clk),

      .clk_en(clk_en),

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
    if (clk_en) begin
      rom_data <= rom[rom_addr];
    end
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
    integer fd;
    reg did_write;
    reg [11:0] last_pc;
    did_write = 0;

    fd = $fopen("log.txt", "w");

    reset = 1;

    #20;

    reset = 0;

    forever begin
      #1;

      if (~did_write && cpu_uut.stage == 1) begin
        // STAGE_DECODE_PERF_1
        did_write = 1;

        $fwrite(fd, "pc=%h, acc=%h, carry=%d, bm=%h, bl=%h, shifter_w=%h\n", last_pc, cpu_uut.Acc,
                cpu_uut.carry, cpu_uut.Bm, cpu_uut.Bl, cpu_uut.shifter_w);
      end else if (cpu_uut.stage == 0) begin
        // STAGE_LOAD_PC
        did_write = 0;

        // Store prev PC for use in tracing
        last_pc   = cpu_uut.pc;
      end
    end
  end

endmodule
