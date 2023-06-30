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
  wire [3:0] output_r;

  sm510 cpu_uut (
      .clk(clk),

      .clk_en(clk_en),

      .reset(reset),

      .cpu_id(0),

      .rom_data(rom_data),
      .rom_addr(rom_addr),

      .input_k(input_k),

      // MAME defaults to these being wired high
      // .input_ba  (1'b1),
      // .input_beta(1'b1),
      .input_ba  (1'b1),
      .input_beta(1'b1),

      .output_shifter_s(shifter_s),

      .output_r(output_r),

      .accurate_lcd_timing(1'b1)
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
  reg press_dpad_right = 0;

  always_comb begin
    input_k = 0;

    // Donkey Kong II
    if (shifter_s[1]) begin
      input_k |= press_dpad_right ? 4'h1 : 0;
      input_k |= press_dpad_up ? 4'h2 : 0;
    end
    if (shifter_s[2]) begin
      input_k |= press_game_a ? 4'h4 : 0;
      input_k |= press_game_b ? 4'h2 : 0;
    end
    // Cement
    // if (shifter_s[1]) begin
    //   input_k |= press_game_a ? 4'h4 : 0;
    // end

    // DKJr
    // if (shifter_s[2]) begin
    //   input_k |= press_game_a ? 4'h4 : 0;
    // end

    // Octopus/Egg
    // if (output_r[3]) begin
    //   input_k |= press_game_a ? 4'h4 : 0;
    // end

    // if (shifter_s[1]) begin
    //   input_k |= press_game_a ? 4'h2 : 0;
    // end

    // Double Dragon
    // if (shifter_s[5]) begin
    //   input_k |= press_game_a ? 4'h8 : 0;
    // end

    // TFish
    // if (shifter_s[0]) begin
    //   input_k |= press_dpad_right ? 4'h2 : 0;
    // end
    // if (shifter_s[1]) begin
    //   input_k |= press_game_a ? 4'h2 : 0;
    // end
  end

  // initial $readmemh("dkii.hex", rom);
  // initial $readmemh("cement.hex", rom);
  // initial $readmemh("dkjr.hex", rom);
  // initial $readmemh("octopus.hex", rom);
  // initial $readmemh("egg.hex", rom);
  // initial $readmemh("tfish.hex", rom);
  // initial $readmemh("tsfight2.hex", rom);
  // initial $readmemh("tddragon.hex", rom);
  initial $readmemh("bride.hex", rom);

  initial begin
    // Initialize RAM
    integer i;
    for (i = 0; i < 128; i += 1) begin
      cpu_uut.ram.ram[i] = 0;
    end
  end

  reg [11:0] last_pc;
  reg in_instruction;
  reg did_skip;
  reg last_did_skip;
  integer fd = 0;
  integer step_count;

  task log();
    // ram=%h, cpu_uut.ram.ram[cpu_uut.ram.computed_addr()],
    if (fd != 0) begin
      $fwrite(
          fd,
          "pc=%h, acc=%h, carry=%d, bm=%h, bl=%h, ram=%h, shifter_w=%h, k=%h, gamma=%0d, div=%h\n",
          last_pc, cpu_uut.inst.Acc, cpu_uut.inst.carry, cpu_uut.inst.Bm, cpu_uut.inst.Bl,
          cpu_uut.ram.ram[cpu_uut.ram.computed_addr()], cpu_uut.inst.shifter_w, cpu_uut.input_k,
          cpu_uut.inst.gamma, cpu_uut.div.divider);
    end
  endtask

  wire is_skip = cpu_uut.stage == 7 || cpu_uut.stage == 8 || cpu_uut.stage == 9;

  initial begin
    reg did_write;
    did_write = 0;

    in_instruction = 0;

    did_skip = 0;
    last_did_skip = 0;

    step_count = 0;

    fd = $fopen("log.txt", "w");

    reset = 1;

    #20;

    reset = 0;

    forever begin
      #1;

      if (cpu_uut.stage != 0) begin
        in_instruction = 1;
      end

      if (is_skip) begin
        did_skip = 1;
      end

      if (~did_write && cpu_uut.stage == 1) begin
        // STAGE_DECODE_PERF_1
        if (last_did_skip && cpu_uut.opcode == 8'h0) begin
          // SKIP after previous skip. To match MAME, don't log, and don't count as a step
        end else begin
          did_write = 1;

          log();
          step_count += 1;
        end
      end else if (~did_write && is_skip && cpu_uut.opcode[7:4] == 4'h2 && cpu_uut.last_opcode[7:4] == 4'h2) begin
        // Log skipped LAX in order to match MAME
        did_write = 1;

        log();
        step_count += 1;
      end else if (cpu_uut.stage == 0) begin
        // STAGE_LOAD_PC
        did_write = 0;

        if (in_instruction) begin
          // This is the first cycle of this stage
          last_did_skip = did_skip;
          did_skip = 0;
        end

        in_instruction = 0;

        // Store prev PC for use in tracing
        last_pc = cpu_uut.inst.pc;
      end

      // if (step_count == 32'h8000) begin
      //   // Enable Game A
      //   press_game_a = 1;
      //   $fwrite(fd, "Pressing A\n");
      // end else if (step_count == 32'h8000 + 32'h800) begin
      //   // Disable Game A
      //   press_game_a = 0;
      //   $fwrite(fd, "Releasing A\n");
      // end else if (step_count == 32'h8000 + 32'h800 + 32'h4E20) begin
      //   $stop();
      // end

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

      // Bride
      if (step_count == 32'h8000) begin
        // Enable Game A
        press_game_a = 1;
        $fwrite(fd, "Pressing A\n");
      end else if (step_count == 32'h8000 + 32'h800) begin
        // Disable Game A
        press_game_a = 0;
        $fwrite(fd, "Releasing A\n");
      end else if (step_count == 32'h8000 + 32'h800 + 32'h8000) begin
        press_dpad_right = 1;
        $fwrite(fd, "Pressing right\n");
      end else if (step_count == 32'h8000 + 32'h800 + 32'h8000 + 32'h1000) begin
        press_dpad_right = 0;
        $fwrite(fd, "Releasing right\n");
      end else if (step_count == 32'h8000 + 32'h800 + 32'h8000 + 32'h1000 + 32'h1000) begin
        press_dpad_right = 1;
        $fwrite(fd, "Pressing right\n");
      end  else if (step_count == 32'h8000 + 32'h800 + 32'h8000 + 32'h1000 + 32'h1000 + 32'h1000) begin
        press_dpad_right = 0;
        $fwrite(fd, "Releasing right\n");
      end else if (step_count == 32'h8000 + 32'h800 + 32'h8000 + 32'h1000 + 32'h1000 + 32'h1000 + 32'h1000) begin
        press_dpad_right = 1;
        $fwrite(fd, "Pressing right\n");
      end else if (step_count == 32'h8000 + 32'h800 + 32'h8000 + 32'h1000 + 32'h1000 + 32'h1000 + 32'h1000 + 32'h1000) begin
        press_dpad_right = 0;
        $fwrite(fd, "Releasing right\n");
      end else if (step_count == 32'h8000 + 32'h800 + 32'h8000 + 32'h1000 + 32'h1000 + 32'h1000 + 32'h1000 + 32'h1000 + 32'h1000) begin
        $stop();
      end

      // TFish
      // if (step_count == 32'h8000) begin
      //   press_game_a = 1;
      // end else if (step_count == 32'h8000 + 32'h800) begin
      //   press_game_a = 0;
      // end else if (step_count == 32'h8000 + 32'h800 + 32'h80000 + 32'h1000) begin
      //   fd = $fopen("log.txt", "w");
      //   press_dpad_right = 1;
      //   $fwrite(fd, "Pressing right\n");
      // end else if (step_count == 32'h8000 + 32'h800 + 32'h80000 + 32'h1000 + 32'h8000) begin
      //   press_dpad_right = 0;
      //   $fwrite(fd, "Releasing right\n");
      // end else if (step_count == 32'h8000 + 32'h800 + 32'h80000 + 32'h1000 + 32'h8000 + 32'h8000) begin
      //   press_game_a = 1;
      //   $fwrite(fd, "Pressing A\n");
      // end else if (step_count == 32'h8000 + 32'h800 + 32'h80000 + 32'h1000 + 32'h8000 + 32'h8000 + 32'h8000) begin
      //   press_game_a = 0;
      //   $fwrite(fd, "Releasing A\n");
      // end else if (step_count == 32'h8000 + 32'h800 + 32'h80000 + 32'h1000 + 32'h8000 + 32'h8000 + 32'h8000 + 32'h8000) begin
      //   $stop();
      // end
      // if (step_count == 32'h8000) begin
      //   press_dpad_right = 1;
      //   $fwrite(fd, "Pressing right\n");
      // end else if (step_count == 32'h8000 + 32'h800) begin
      //   press_game_a = 1;
      //   $fwrite(fd, "Pressing A\n");
      // end else if (step_count == 32'h8000 + 32'h800 + 32'h800) begin
      //   press_game_a = 0;
      //   $fwrite(fd, "Releasing A\n");
      // end else if (step_count == 32'h8000 + 32'h800 + 32'h800 + 32'h800) begin
      //   press_dpad_right = 0;
      //   $fwrite(fd, "Releasing right\n");
      // end else if (step_count == 32'h8000 + 32'h800 + 32'h800 + 32'h800 + 32'h4E20) begin
      //   $stop();
      // end
    end
  end

endmodule
