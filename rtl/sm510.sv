module sm510 (
    input wire clk,

    // Clocked at 32.768kHz
    input wire clk_en,

    input wire reset,

    // The type of CPU being implemented
    input wire [3:0] cpu_id,

    // Data for external ROM
    // NOTE: rom_data is expected to be updated with clk_en, and not run at a higher clock
    // Doing so will break this CPU's operation
    input  wire [ 7:0] rom_data,
    output wire [11:0] rom_addr,

    // The K1-4 input pins
    input wire [3:0] input_k,

    // The BA and Beta input pins
    input wire input_ba,
    input wire input_beta,

    // The H1-4 output pins, as an index
    output wire [1:0] output_lcd_h_index,

    // The S1-8 strobe output pins
    output wire [7:0] output_shifter_s,

    // LCD Segments
    output reg [15:0] segment_a,
    output reg [15:0] segment_b,
    // Comb
    output reg segment_bs,

    // Audio
    // output reg [1:0] buzzer_r,
    output wire [3:0] output_r,

    // Settings
    input wire accurate_lcd_timing
);
  ////////////////////////////////////////////////////////////////////////////////////////

  wire [7:0] opcode = rom_data;
  reg [7:0] last_opcode = 0;

  wire [3:0] ram_data;

  reg [5:0] last_Pl = 0;

  wire gamma;
  wire divider_1s_tick;

  wire divider_4hz;
  wire divider_32hz;
  wire divider_64hz;
  wire divider_1khz;

  wire [14:0] divider;

  instructions inst (
      .cpu_id(cpu_id),

      // Data
      .opcode(opcode),
      .last_opcode(last_opcode),
      .ram_data(ram_data),

      // Internal
      .gamma(gamma),
      .divider(divider),
      .divider_4hz(divider_4hz),
      .divider_32hz(divider_32hz),
      .last_Pl(last_Pl),

      // IO
      .input_k(input_k),
      .input_beta(input_beta),
      .input_ba(input_ba)
  );

  assign rom_addr = inst.rom_addr;
  assign output_shifter_s = inst.shifter_w;
  assign output_r = inst.output_r;

  reg buzzer = 0;

  reg [1:0] delay_counter = 0;
  // always @(posedge clk) begin
  //   if (clk_en) begin
  //     delay_counter <= delay_counter + 2'h1;

  //     if (delay_counter == 0) begin
  //       buzzer <= ~buzzer;

  //       buzzer_r[0] <= inst.cached_buzzer_r[0] ? buzzer : 1'b0;
  //       buzzer_r[1] <= inst.cached_buzzer_r[1] ? ~buzzer : 1'b0;
  //     end
  //   end
  // end

  ////////////////////////////////////////////////////////////////////////////////////////
  // Divider

  // TODO: Refactor - Move these registers
  // reg reset_gamma = 0;
  // reg reset_divider = 0;

  divider div (
      .clk(clk),
      .clk_en(clk_en),

      .reset(reset),

      .cpu_id(cpu_id),

      .reset_gamma(inst.reset_gamma),
      .reset_divider(inst.reset_divider),
      .reset_divider_keep_6(inst.reset_divider_keep_6),

      .gamma(gamma),
      .divider_1s_tick(divider_1s_tick),

      .divider_4hz(divider_4hz),
      .divider_32hz(divider_32hz),
      .divider_64hz(divider_64hz),
      .divider_1khz(divider_1khz),
      .divider(divider)
  );

  ////////////////////////////////////////////////////////////////////////////////////////
  // LCD Strobe

  wire [15:0] ram_segment_a;
  wire [15:0] ram_segment_b;

  // Select the active bit of display memory words in use
  // Comb
  reg  [ 3:0] lcd_h;
  reg  [ 1:0] lcd_h_index = 0;

  assign output_lcd_h_index = lcd_h_index;

  reg prev_strobe_divider = 0;

  always @(posedge clk) begin
    if (reset) begin
      lcd_h_index <= 0;
    end else if (clk_en) begin
      reg temp;
      temp = accurate_lcd_timing ? divider_64hz : divider_1khz;

      prev_strobe_divider <= temp;

      if (temp && ~prev_strobe_divider) begin
        // Strobe LCD
        lcd_h_index <= lcd_h_index + 2'b1;

        // Copy over segments
        segment_a   <= ram_segment_a;
        segment_b   <= ram_segment_b;
      end
    end
  end

  always_comb begin
    integer i;
    reg [3:0] temp;
    // TODO: This should also use Y somehow
    for (i = 0; i < 4; i += 1) begin
      lcd_h[i] = lcd_h_index == i;
    end

    // Use same timing and position as H
    temp = lcd_h & inst.segment_l;

    // If bit is set, pulse bs
    segment_bs = temp != 0;
  end

  ////////////////////////////////////////////////////////////////////////////////////////
  // RAM

  ram ram (
      .clk(clk),

      // While temp_sbm is set, we operate as if the highest bit is high, rather than its current value
      .addr(inst.temp_sbm ? {1'b1, inst.ram_addr[5:0]} : inst.ram_addr),
      .wren(inst.ram_wr),
      .data(inst.ram_wr_data),
      .q(ram_data),

      .lcd_h(lcd_h_index + 2'h1),
      .segment_a(ram_segment_a),
      .segment_b(ram_segment_b)
  );

  ////////////////////////////////////////////////////////////////////////////////////////
  // Halt

  reg reset_halt = 0;

  always @(posedge clk) begin
    if (reset) begin
      reset_halt <= 0;
    end else if (clk_en) begin
      reset_halt <= 0;

      if (divider_1s_tick || input_k != 0) begin
        // Wake from halt
        reset_halt <= 1;
      end
    end
  end

  ////////////////////////////////////////////////////////////////////////////////////////
  // Stages

  // LBL xy | TL/TML xyz
  wire is_two_bytes_sm510 = opcode == 8'h5F || opcode[7:4] == 4'h7;

  // LBL xy | CEND/DTA
  wire is_two_bytes_sm5a = opcode == 8'h5F || opcode == 8'h5E;

  wire is_two_bytes = cpu_id == 4 ? is_two_bytes_sm5a : is_two_bytes_sm510;
  // TM x
  wire is_tm = cpu_id == 0 && opcode[7:6] == 2'b11;
  // LAX x
  wire is_lax = opcode[7:4] == 4'h2;

  localparam STAGE_LOAD_PC = 0;
  localparam STAGE_DECODE_PERF_1 = 1;
  localparam STAGE_LOAD_2 = 2;
  localparam STAGE_PERF_3 = 3;
  // TODO: Combine both sets of stages
  localparam STAGE_IDX_FETCH = 4;
  localparam STAGE_IDX_PERF = 5;
  localparam STAGE_HALT = 6;
  localparam STAGE_SKIP = 7;

  reg [2:0] stage = STAGE_LOAD_PC;

  always @(posedge clk) begin
    if (reset) begin
      // rom_data <= 0;

      stage <= STAGE_LOAD_PC;
    end else if (clk_en) begin
      case (stage)
        STAGE_LOAD_PC: begin
          if (inst.halt) begin
            stage <= STAGE_HALT;
          end else if (inst.skip_next_instr || inst.skip_next_if_lax && is_lax) begin
            // Skip
            stage <= STAGE_SKIP;
          end else begin
            stage <= STAGE_DECODE_PERF_1;
          end
        end
        STAGE_DECODE_PERF_1: begin
          stage <= STAGE_LOAD_PC;

          if (is_tm) begin
            // TMI x. Load IDX data
            stage <= STAGE_IDX_FETCH;
          end else if (is_two_bytes) begin
            // Instruction takes two bytes
            stage <= STAGE_LOAD_2;
          end
        end
        STAGE_LOAD_2: stage <= STAGE_PERF_3;
        STAGE_PERF_3: stage <= STAGE_LOAD_PC;
        STAGE_IDX_FETCH: stage <= STAGE_IDX_PERF;
        STAGE_IDX_PERF: stage <= STAGE_LOAD_PC;
        STAGE_HALT: begin
          if (reset_halt) begin
            stage <= STAGE_LOAD_PC;
          end
        end
        STAGE_SKIP: stage <= STAGE_LOAD_PC;
      endcase
    end
  end

  // Internal
  reg last_temp_sbm = 0;

  // Decoder

  task sm510_decode();
    casex (opcode)
      8'h00: begin
        // SKIP. NOP
      end
      8'h01: inst.atbp();  // ATBP. Set LCD BP to Acc
      8'h02: inst.sbm();  // SBM. Set high bit of Bm high for next instruction only
      8'h03: inst.atpl();  // ATPL. Load Pl with Acc
      8'b0000_01XX: inst.rm();  // 0x04-07: RM x. Zero RAM at bit indexed by immediate
      8'h08: inst.add();  // ADD. Add RAM to Acc
      8'h09: inst.add11();  // ADD11. Add RAM to Acc with carry. Skip next inst if carry
      8'h0A: inst.coma();  // COMA. NOT Acc (complement Acc)
      8'h0B: inst.exbla();  // EXBLA. Swap Acc and Bl
      8'b0000_11XX: inst.sm();  // 0x0C-0F: SM x. Set RAM at bit indexed by immediate
      8'b0001_00XX: begin
        // All opcodes that call a task must be replicated inline due to a Quartus bug that just silently drops
        // nested tasks inside of interfaces

        // inst.exc();  // 0x10-13: EXC x. Swap Acc and RAM. XOR Bm with immed
        inst.exc_x(1);
      end
      8'b0001_01XX: begin
        // inst.exci();  // 0x14-17: EXCI x. Swap Acc/RAM. XOR Bm with immed. Inc Bl
        inst.exc_x(1);
        inst.incb();
      end
      8'b0001_10XX: begin
        // inst.lda();  // 0x18-1B: LDA x. Load Acc with RAM value. XOR Bm with immed
        inst.exc_x(0);
      end
      8'b0001_11XX: begin
        // inst.excd();  // 0x1C-1F: EXCD x. Swap Acc/RAM. XOR Bm with immed. Dec Bl
        inst.exc_x(1);
        inst.decb();
      end
      8'h2X: inst.lax();  // LAX x. Load Acc with immed. If next instruction is LAX, skip it
      8'h3X: inst.adx();  // ADX x. Add immed to Acc. Skip next instruction if carry is set
      8'h4X: inst.lb();  // LB x. Low Bm to immed. Low Bl to immed. High Bl to OR immed
      // 0x50 unused
      8'h51: inst.tb();  // TB. Skip next instruction if Beta is 1
      8'h52: inst.tc();  // TC. Skip next instruction if C = 0
      8'h53: inst.tam();  // TAM. Skip next instruction if Acc = RAM value
      8'b0101_01XX: inst.tmi();  // TMI x. Skip next instruction if indexed memory bit is set
      8'h58: inst.tis();  // TIS. Skip next inst if 1sec divider signal is low. Zero gamma
      8'h59: inst.atl();  // ATL. Set segment output L to Acc
      8'h5A: inst.tao();  // TAO. Skip next instruction if Acc = 0
      8'h5B: inst.tabl();  // TABL. Skp next instruction if Acc = Bl
      // 0x5C unused
      8'h5D: inst.cend();  // CEND. Stop clock
      8'h5E: inst.tal();  // TAL. Skip next instruction if BA = 1
      8'h5F: begin
        // LBL xy (2 byte)
        // Do nothing here. Entirely done in second stage
      end
      8'h60: inst.atfc();  // ATFC. Set segment output Y to Acc
      8'h61: inst.atr();  // ATR. Set R buzzer control value to the bottom two bits of Acc
      8'h62: inst.wr();  // WR. Shift 0 into W
      8'h63: inst.ws();  // WS. Shift 1 into W
      8'h64: inst.incb();  // INCB. Increment Bl. If Bl was 0xF, skip next
      8'h65: inst.idiv();  // IDIV. Reset clock divider
      8'h66: inst.rc();  // RC. Clear carry
      8'h67: inst.sc();  // SC. Set carry
      8'h68: inst.tf1();  // TF1. Skip next instruction if F1 = 1 (clock divider 14th bit)
      8'h69: inst.tf4();  // TF4. Skip next instruction if F4 = 1 (clock divider 11th bit)
      8'h6A: inst.kta();  // KTA. Read K input bits into Acc
      8'h6B: inst.rot();  // ROT. Rotate right
      8'h6C: inst.decb();  // DECB. Decrement Bl. If Bl was 0x0, skip next
      8'h6D: inst.bdc();  // BDC. Set LCD power. Display is on when low
      8'h6E: begin
        // inst.rtn0();  // RTN0. Pop stack. Move S into PC, and R into S
        inst.pop_stack(1);
      end
      8'h6F: begin
        // inst.rtn1();  // RTN1. Pop stack. Move S into PC, and R into S. Skip next inst
        inst.pop_stack(1);

        inst.skip_next_instr <= 1;
      end
      8'h7X: begin
        // TL/TML xyz
        // Do nothing here. Entirely done in second stage
      end
      8'b10XX_XXXX: inst.t();  // T xy. Short jump, within page. Set Pl to immediate
      8'b11XX_XXXX: begin
        // inst.tm();  // TM x. JP to IDX table, and executes that inst. Push PC + 1
        inst.push_stack(inst.pc);

        {inst.Pu, inst.Pm, inst.Pl} <= {2'b0, 4'b0, opcode[5:0]};
      end
    endcase
  endtask

  task sm5a_decode();
    reg [3:0] w_length;
    reg trs_field;

    w_length  = 4'h9;
    trs_field = 1;

    casex (opcode)
      8'h00: begin
        // SKIP. NOP
      end
      8'h01: inst.atr();  // ATR. Set R buzzer control value to the bottom two bits of Acc
      8'h02: inst.sbm_sm500();  // SBM. Set high bit of Bm high
      8'h03: inst.atbp();  // ATBP. Set LCD BP to Acc
      8'b0000_01XX: inst.rm();  // 0x04-07: RM x. Zero RAM at bit indexed by immediate
      8'h08: inst.add();  // ADD. Add RAM to Acc
      8'h09: inst.add11();  // ADD11. Add RAM to Acc with carry. Skip next inst if carry
      8'h0A: inst.coma();  // COMA. NOT Acc (complement Acc)
      8'h0B: inst.exbla();  // EXBLA. Swap Acc and Bl
      8'b0000_11XX: inst.sm();  // 0x0C-0F: SM x. Set RAM at bit indexed by immediate
      8'b0001_00XX: begin
        // 0x10-13: EXC x. Swap Acc and RAM. XOR Bm with immed
        inst.exc_x(1);
      end
      8'b0001_01XX: begin
        // 0x14-17: EXCI x. Swap Acc/RAM. XOR Bm with immed. Inc Bl
        inst.exc_x(1);
        inst.incb_sm500();
      end
      8'b0001_10XX: begin
        // 0x18-1B: LDA x. Load Acc with RAM value. XOR Bm with immed
        inst.exc_x(0);
      end
      8'b0001_11XX: begin
        // 0x1C-1F: EXCD x. Swap Acc/RAM. XOR Bm with immed. Dec Bl
        inst.exc_x(1);
        inst.decb();
      end
      8'h2X: inst.lax();  // LAX x. Load Acc with immed. If next instruction is LAX, skip it
      8'h3X: inst.adx();  // ADX x. Add immed to Acc. Skip next instruction if carry is set
      8'h4X: inst.lb_sm500();  // LB x. Low Bm to immed. Low Bl to immed. High Bl to 2 if data
      8'h50: inst.tal();  // TAL. Skip next instruction if BA set
      8'h51: inst.tb();  // TB. Skip next instruction if Beta is 1
      8'h52: inst.tc();  // TC. Skip next instruction if C = 0
      8'h53: inst.tam();  // TAM. Skip next instruction if Acc = RAM value
      8'b0101_01XX: inst.tmi();  // TMI x. Skip next instruction if indexed memory bit is set
      8'h58: inst.tis();  // TIS. Skip next inst if 1sec divider signal is low. Zero gamma
      8'h59: inst.ptw(w_length);  // PTW. Copy last two values from W' to W
      8'h5A: inst.tao();  // TAO. Skip next instruction if Acc = 0
      8'h5B: inst.tabl();  // TABL. Skp next instruction if Acc = Bl
      8'h5C: inst.tw(w_length);  // TW. Copy W' to W
      8'h5D: begin
        // DTW. Shift PLA value into W'
        reg [3:0] digit;
        digit = inst.pla_digit();

        inst.shift_w_prime(w_length, digit);
      end
      // TODO: 0x5E
      8'h5F: begin
        // LBL xy (2 byte)
        // Do nothing here. Entirely done in second stage
      end
      8'h60: inst.comcn();  // COMCN. XOR (complement) LCD CN flag
      8'h61: begin
        // PDTW. Shift last two nibbles of W', moving one PLA value in
        reg [3:0] w_prime_temp[9];
        reg [3:0] digit;

        digit = inst.pla_digit();

        w_prime_temp[w_length-2] = w_prime_temp[w_length-1];
        w_prime_temp[w_length-1] = digit;

        inst.w_prime <= w_prime_temp;
      end
      8'h62: begin
        // WR. Shift Acc (0 high bit) into W'
        inst.shift_w_prime(w_length, inst.Acc & 4'h7);
      end
      8'h63: begin
        // WS. Shift Acc (1 high bit) into W'
        inst.shift_w_prime(w_length, inst.Acc | 4'h8);
      end
      8'h64: inst.incb_sm500();  // INCB. Increment Bl. If Bl was 0x7, skip next
      8'h65: inst.idiv_sm500();  // IDIV. Reset clock divider, keeping lower 6 bits
      8'h66: inst.rc();  // RC. Clear carry
      8'h67: inst.sc();  // SC. Set carry
      8'h68: inst.rmf();  // RMF. Clear m' and Acc
      8'h69: inst.smf();  // SMF. Set m'
      8'h6A: inst.kta();  // KTA. Read K input bits into Acc
      8'h6B: inst.rbm();  // RBM. Clear Bm high bit
      8'h6C: inst.decb();  // DECB. Decrement Bl. If Bl was 0x0, skip next
      8'h6D: inst.comcb();  // COMCB. XOR (complement) CB
      8'h6E: begin
        // inst.rtn0();  // RTN0. Pop stack. Move S into PC, and R into S
        inst.pop_stack(0);

        inst.within_subroutine <= 0;
      end
      8'h6F: begin
        // inst.rtn1();  // RTN1. Pop stack. Move S into PC, and R into S. Skip next inst
        inst.pop_stack(0);

        inst.skip_next_instr   <= 1;
        inst.within_subroutine <= 0;
      end
      8'h7X: inst.ssr();  // SSR. Set stack higher bits to immed. Set E for next inst
      8'b10XX_XXXX: inst.tr();  // TR. Long/short jump. Uses stack page value for distance
      8'b11XX_XXXX: begin
        // TRS. Call subroutine
        if (inst.within_subroutine) begin
          inst.Pl <= {2'b0, opcode[3:0]};
          inst.Pm[1:0] <= opcode[5:4];
          // pc[11:8] <= pc[11:8];
          // pc[7:6] <= opcode[5:4];
          // pc[5:4] <= 0;
          // pc[3:0] <= opcode[3:0];
        end else begin
          // Enter subroutine
          reg [3:0] temp_su;

          inst.within_subroutine <= 1;

          temp_su = inst.stack_s[9:6];

          inst.push_stack(inst.pc);

          if (last_opcode[7:4] == 4'h7) begin
            // Last instruction was SSR, and E flag would be set
            {inst.Pu, inst.Pm, inst.Pl} <= {1'b0, inst.cb_bank, temp_su, opcode[5:0]};
          end else begin
            {inst.Pu, inst.Pm, inst.Pl} <= {1'b0, trs_field, 4'b0, opcode[5:0]};
          end
        end
      end
    endcase
  endtask

  // PC increment only changes Pl
  // TODO: Is this correct, it doesn't match MAME?
  wire [11:0] pc_inc = {inst.Pu, inst.Pm, inst.Pl[0] == inst.Pl[1], inst.Pl[5:1]};

  always @(posedge clk) begin
    if (reset) begin
      // Initial PC to 3_7_0
      case (cpu_id)
        4:       {inst.Pu, inst.Pm, inst.Pl} <= {2'h0, 4'hF, 6'b0};  // SM5a
        default: {inst.Pu, inst.Pm, inst.Pl} <= {2'h3, 4'h7, 6'b0};  // SM510
      endcase

      inst.stack_s <= 0;
      inst.stack_r <= 0;

      inst.Acc <= 0;
      inst.carry <= 0;

      inst.lcd_bp <= 0;
      inst.lcd_bc <= 0;

      inst.segment_l <= 0;
      inst.segment_y <= 0;

      inst.shifter_w <= 0;

      // Control
      inst.skip_next_instr <= 0;
      inst.skip_next_if_lax <= 0;

      inst.temp_sbm <= 0;

      inst.reset_divider <= 0;
      inst.reset_divider_keep_6 <= 0;
      inst.reset_gamma <= 0;

      inst.halt <= 0;

      // RAM
      {inst.Bm, inst.Bl} <= 7'h0;

      inst.ram_wr <= 0;
      inst.ram_wr_data <= 0;

      // Internal
      last_Pl <= 0;

      last_opcode <= 0;
      last_temp_sbm <= 0;

      case (cpu_id)
        4: begin
          // SM5a
          inst.stored_output_r <= 4'hF;
        end
        default: begin
          // SM510
          inst.stored_output_r <= 0;

          // Use divider bit 3 for mask
          inst.output_r_mask   <= 2;
        end
      endcase

      inst.output_r <= 0;

      // SM5a
      inst.cb_bank <= 0;

      inst.within_subroutine <= 0;

      inst.lcd_cn <= 0;
      inst.m_prime <= 0;
    end else if (clk_en) begin
      inst.reset_divider <= 0;
      inst.reset_divider_keep_6 <= 0;
      inst.reset_gamma <= 0;

      inst.ram_wr <= 0;

      inst.clock_melody();

      if (stage == STAGE_LOAD_PC || stage == STAGE_PERF_3) begin
        // Increment PC
        // For two byte instr (STAGE_PERF_3), PC needs to be incremented for the next instruction,
        // as we already consumed the incremented version, so we need to do it again
        inst.Pl <= pc_inc[5:0];

        // Backup Pl, so operations that change parts of it (ATPL) don't use the incremented version
        last_Pl <= inst.Pl;
      end

      case (stage)
        STAGE_LOAD_PC: begin
          inst.skip_next_instr  <= 0;
          // Continue skipping if previously skipped LAX, and still LAX
          inst.skip_next_if_lax <= inst.skip_next_if_lax && is_lax;
          inst.wr_next_ram_addr <= 0;

          if (last_temp_sbm) begin
            // SBM flag has been set and used for one instruction. Lower it
            inst.temp_sbm <= 0;
          end

          if (inst.wr_next_ram_addr) begin
            {inst.Bm[1:0], inst.Bl} <= inst.next_ram_addr;
          end else begin
            // Update address for next time we write
            inst.next_ram_addr <= {inst.Bm[1:0], inst.Bl};
          end
        end
        STAGE_HALT: begin
          // Load PC at 1_0_00
          case (cpu_id)
            4:       {inst.Pu, inst.Pm, inst.Pl} <= {2'b0, 4'b0, 6'b0};  // SM5a
            default: {inst.Pu, inst.Pm, inst.Pl} <= {2'b1, 4'b0, 6'b0};  // SM510
          endcase

          inst.cb_bank <= 0;

          if (reset_halt) begin
            inst.halt <= 0;
          end
        end
        STAGE_DECODE_PERF_1: begin
          last_opcode   <= opcode;
          last_temp_sbm <= inst.temp_sbm;

          case (cpu_id)
            4: sm5a_decode();
            default: sm510_decode();
          endcase
        end
        STAGE_PERF_3: begin
          casex (last_opcode)
            8'h5E: begin
              // SM5a: Extended opcodes
              casex (opcode)
                8'h00: inst.cend();  // CEND. Stop clock
                8'h04: inst.dta();  // DTA. Copy high bits of clock divider to Acc
              endcase
            end
            8'h5F: begin
              // LBL xy (2 byte). Immed is only second byte. Set Bm to high 3 bits of immed, and Bl to low 4 immed. Highest bit is unused
              inst.Bm <= opcode[6:4];
              inst.Bl <= opcode[3:0];
            end
            8'h7X: begin
              // Only is TL/TML if SM510
              if (cpu_id == 0) begin
                // This is weird and goes up to 0xA for some reason, so we need the nested checks
                // Notice there is a gap where 0xB is not handled (in the actual CPU)
                if (last_opcode[3:0] < 4'hB) begin
                  // TL xyz (2 byte). Long jump. Load PC with immediates
                  {inst.Pu, inst.Pm, inst.Pl} <= {opcode[7:6], last_opcode[3:0], opcode[5:0]};
                end else if (last_opcode[3:0] >= 4'hC) begin
                  // TML xyz (2 byte). Long call. Push PC + 1 into stack registers. Load PC with immediates
                  // Need to push instruction after this one, so increment again
                  inst.push_stack(pc_inc);

                  {inst.Pu, inst.Pm, inst.Pl} <= {
                    opcode[7:6], {2'b0, last_opcode[1:0]}, opcode[5:0]
                  };
                end else begin
                  $display("Unexpected immediate in TL %h at %h", opcode, inst.pc);
                end
              end
            end
            default: begin
              $display("Unknown instruction in second stage %h_%h", last_opcode, opcode);
            end
          endcase
        end
        STAGE_IDX_PERF: begin
          // Prev cycle fetched IDX data. Now set PC
          {inst.Pu, inst.Pm, inst.Pl} <= {opcode[7:6], 4'h4, opcode[5:0]};
        end
      endcase
    end
  end

endmodule
