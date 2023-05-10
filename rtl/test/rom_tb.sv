`timescale 1ns / 1ns

module rom_tb;

  reg clk = 0;
  reg [1:0] clk_div = 0;

  wire clk_en = clk_div == 2'h3;

  reg reset = 0;

  wire [11:0] rom_addr;
  reg [7:0] rom_data = 0;

  // Comb
  reg [3:0] input_k;
  wire [7:0] shifter_s;

  sm510 cpu_uut (
      .clk(clk),

      .clk_en(clk_en),

      .reset(reset),

      .rom_data(rom_data),
      .rom_addr(rom_addr),

      .input_k(input_k),

      // MAME defaults to these being wired high
      .input_ba  (1'b1),
      .input_beta(1'b1),

      .output_shifter_s(shifter_s)
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

  reg press_game_a = 0;
  reg press_game_b = 0;
  reg press_dpad_up = 0;

  always_comb begin
    input_k = 0;

    // Donkey Kong II
    // if (shifter_s[1]) begin
    //   input_k |= press_dpad_up ? 4'h2 : 0;
    // end else if (shifter_s[2]) begin
    //   input_k |= press_game_a ? 4'h4 : 0;
    //   input_k |= press_game_b ? 4'h2 : 0;
    // end
    // Cement
    if (shifter_s[1]) begin
      input_k |= press_game_a ? 4'h4 : 0;
    end
  end

  // initial $readmemh("dkii.hex", rom);
  initial $readmemh("cement.hex", rom);

  initial begin
    // Initialize RAM
    integer i;
    for (i = 0; i < 128; i += 1) begin
      cpu_uut.ram.ram[i] = 0;
    end
  end

  reg [11:0] last_pc;
  integer fd;
  integer step_count;

  task log();
    $fwrite(fd, "pc=%h, acc=%h, carry=%d, bm=%h, bl=%h, shifter_w=%h, gamma=%0d, div=%h\n",
            last_pc, cpu_uut.Acc, cpu_uut.carry, cpu_uut.Bm, cpu_uut.Bl, cpu_uut.shifter_w,
            cpu_uut.gamma, cpu_uut.divider);
  endtask

  initial begin
    reg did_write;
    did_write = 0;

    step_count = 0;

    fd = $fopen("log.txt", "w");

    reset = 1;

    #20;

    reset = 0;

    forever begin
      #1;

      if (~did_write && cpu_uut.stage == 1) begin
        // STAGE_DECODE_PERF_1
        did_write = 1;

        log();
        step_count += 1;
      end else if (~did_write && cpu_uut.stage == 7 && cpu_uut.opcode[7:4] == 4'h2 && cpu_uut.last_opcode[7:4] == 4'h2) begin
        // Log skipped LAX in order to match MAME
        did_write = 1;

        log();
        step_count += 1;
      end else if (cpu_uut.stage == 0) begin
        // STAGE_LOAD_PC
        did_write = 0;

        // Store prev PC for use in tracing
        last_pc   = cpu_uut.pc;
      end

      // Donkey Kong II
      // if (step_count == 32'h4E20) begin
      //   // Enable Game A
      //   press_game_a = 1;
      // end else if (step_count == 32'h4E20 + 32'h400) begin
      //   // Disable Game A
      //   press_game_a = 0;
      // end else if (step_count == 32'h4E20 + 32'h400 + 32'h4E20) begin
      //   // Press up
      //   press_dpad_up = 1;
      // end else if (step_count == 32'h4E20 + 32'h400 + 32'h4E20 + 32'h400) begin
      //   // Stop press up
      //   press_dpad_up = 0;
      // end else if (step_count == 32'h4E20 + 32'h400 + 32'h4E20 + 32'h400 + 32'h20000) begin
      //   // Press up
      //   press_dpad_up = 1;
      // end else if (step_count == 32'h4E20 + 32'h400 + 32'h4E20 + 32'h400 + 32'h20000 + 32'h400) begin
      //   // Stop press up
      //   press_dpad_up = 0;
      // end else if (step_count == 32'h4E20 + 32'h400 + 32'h4E20 + 32'h400 + 32'h20000 + 32'h400 + 32'h10000) begin
      //   // Press up
      //   press_dpad_up = 1;
      // end else if (step_count == 32'h4E20 + 32'h400 + 32'h4E20 + 32'h400 + 32'h20000 + 32'h400 + 32'h10000 + 32'h400) begin
      //   // Stop press up
      //   press_dpad_up = 0;
      // end else if (step_count == 32'h4E20 + 32'h400 + 32'h4E20 + 32'h400 + 32'h20000 + 32'h400 + 32'h10000 + 32'h400 + 32'hD000) begin
      //   // Press Game B
      //   press_game_b = 1;
      // end else if (step_count == 32'h4E20 + 32'h400 + 32'h4E20 + 32'h400 + 32'h20000 + 32'h400 + 32'h10000 + 32'h400 + 32'hD000 + 32'h400) begin
      //   // Stop press Game B
      //   press_game_b = 0;
      // end else if (step_count == 32'h4E20 + 32'h400 + 32'h4E20 + 32'h400 + 32'h20000 + 32'h400 + 32'h10000 + 32'h400 + 32'hD000 + 32'h400 + 32'h10000) begin
      //   $display("Done");
      //   $finish();
      // end

      if (step_count == 32'h8000) begin
        // Enable Game A
        press_game_a = 1;
      end else if (step_count == 32'h8000 + 32'h400) begin
        // Disable Game A
        press_game_a = 0;
      end else if (step_count == 32'h8000 + 32'h400 + 32'h4E20) begin
        $finish();
      end
    end
  end

endmodule
