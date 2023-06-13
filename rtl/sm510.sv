module sm510 (
    input wire clk,

    // Clocked at 32.768kHz
    input wire clk_en,

    input wire reset,

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
    output reg [1:0] buzzer_r,

    // Settings
    input wire accurate_lcd_timing
);
  // TODO: Remove
  reg [1:0] cached_buzzer_r = 0;

  reg buzzer = 0;

  reg [1:0] delay_counter = 0;
  always @(posedge clk) begin
    if (clk_en) begin
      delay_counter <= delay_counter + 2'h1;

      if (delay_counter == 0) begin
        buzzer <= ~buzzer;

        buzzer_r[0] <= cached_buzzer_r[0] ? buzzer : 1'b0;
        buzzer_r[1] <= cached_buzzer_r[1] ? ~buzzer : 1'b0;
      end
    end
  end

  // PC
  reg [1:0] Pu = 0;
  reg [3:0] Pm = 0;
  reg [5:0] Pl = 0;

  wire [11:0] pc = {Pu, Pm, Pl};
  assign rom_addr = pc;

  reg [11:0] stack_s = 0;
  reg [11:0] stack_r = 0;

  // Accumulator
  reg [3:0] Acc = 0;
  reg carry = 0;

  // LCD Functions
  // LCD pulse generator circuit
  reg lcd_bp = 0;
  // LCD bleeder circuit (on means no display)
  reg lcd_bc = 0;

  reg [3:0] segment_l = 0;

  // TODO: Currently unused. See LCD pulsing
  reg [3:0] segment_y = 0;

  reg [7:0] shifter_w = 0;
  assign output_shifter_s = shifter_w;

  // Control
  reg skip_next_instr = 0;
  // Skip next instruction only if next is LAX
  reg skip_next_if_lax = 0;

  reg temp_sbm = 0;

  reg [5:0] next_ram_addr = 0;
  reg wr_next_ram_addr = 0;

  reg reset_divider = 0;
  reg reset_gamma = 0;

  reg halt = 0;
  reg reset_halt = 0;

  ////////////////////////////////////////////////////////////////////////////////////////
  // Divider

  reg gamma = 0;

  reg [14:0] divider = 0;
  // Temp value to wake from halt
  reg divider_1s_tick = 0;
  wire divider_64hz = divider[10];
  wire divider_1khz = divider[4];

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
        // divider <= 2;
        divider <= 0;
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
    temp = lcd_h & segment_l;

    // If bit is set, pulse bs
    segment_bs = temp != 0;
  end

  ////////////////////////////////////////////////////////////////////////////////////////
  // RAM

  // RAM Address
  reg [2:0] Bm = 0;
  reg [3:0] Bl = 0;

  wire [6:0] ram_addr = {Bm, Bl};
  wire [3:0] ram_data;

  reg ram_wr = 0;
  reg [3:0] ram_wr_data = 0;

  ram ram (
      .clk(clk),

      // While temp_sbm is set, we operate as if the highest bit is high, rather than its current value
      .addr(temp_sbm ? {1'b1, ram_addr[5:0]} : ram_addr),
      .wren(ram_wr),
      .data(ram_wr_data),
      .q(ram_data),

      .lcd_h(lcd_h_index + 2'h1),
      .segment_a(ram_segment_a),
      .segment_b(ram_segment_b)
  );

  ////////////////////////////////////////////////////////////////////////////////////////
  // Halt

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

  wire [7:0] opcode = rom_data;

  // LBL xy | TL/TML xyz
  wire is_two_bytes = opcode == 8'h5F || opcode[7:4] == 4'h7;
  // TMI x
  wire is_tmi = opcode[7:6] == 2'b11;
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
          if (halt) begin
            stage <= STAGE_HALT;
          end else if (skip_next_instr || skip_next_if_lax && is_lax) begin
            // Skip
            stage <= STAGE_SKIP;
          end else begin
            stage <= STAGE_DECODE_PERF_1;
          end
        end
        STAGE_DECODE_PERF_1: begin
          stage <= STAGE_LOAD_PC;

          if (is_tmi) begin
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
  reg [7:0] last_opcode = 0;
  reg [5:0] last_Pl = 0;

  reg last_temp_sbm = 0;

  // Instruction shortcuts
  task exc_x(reg swap);
    // Swap Acc and RAM
    Acc <= ram_data;

    if (swap) begin
      ram_wr_data <= Acc;
      ram_wr <= 1;
    end

    // XOR Bm with immed
    // Will be written in STAGE_LOAD_PC
    next_ram_addr[5:4] <= Bm[1:0] ^ opcode[1:0];
    wr_next_ram_addr   <= 1;
  endtask

  task incb();
    next_ram_addr[3:0] <= Bl + 4'h1;
    wr_next_ram_addr <= 1;

    skip_next_instr <= Bl == 4'hF;
  endtask

  task decb();
    next_ram_addr[3:0] <= Bl - 4'h1;
    wr_next_ram_addr <= 1;

    skip_next_instr <= Bl == 4'h0;
  endtask

  task pop_stack();
    {Pu, Pm, Pl} <= stack_s;
    stack_s <= stack_r;
  endtask

  task push_stack(reg [11:0] next_pc);
    stack_r <= stack_s;
    stack_s <= next_pc;
  endtask

  // Decoder

  // PC increment only changes Pl
  // TODO: Is this correct, it doesn't match MAME?
  wire [11:0] pc_inc = {Pu, Pm, Pl[0] == Pl[1], Pl[5:1]};

  always @(posedge clk) begin
    if (reset) begin
      // Initial PC to 3_7_0
      {Pu, Pm, Pl} <= {2'h3, 4'h7, 6'b0};

      stack_s <= 0;
      stack_r <= 0;

      Acc <= 0;
      carry <= 0;

      lcd_bp <= 0;
      lcd_bc <= 0;

      segment_l <= 0;
      segment_y <= 0;

      shifter_w <= 0;

      // Control
      skip_next_instr <= 0;
      skip_next_if_lax <= 0;

      temp_sbm <= 0;

      reset_divider <= 0;
      reset_gamma <= 0;

      halt <= 0;

      // RAM
      {Bm, Bl} <= 7'h0;

      ram_wr <= 0;
      ram_wr_data <= 0;

      // Internal
      last_Pl <= 0;

      last_opcode <= 0;
      last_temp_sbm <= 0;
    end else if (clk_en) begin
      reset_divider <= 0;
      reset_gamma <= 0;

      ram_wr <= 0;

      if (stage == STAGE_LOAD_PC || stage == STAGE_PERF_3) begin
        // Increment PC
        // For two byte instr (STAGE_PERF_3), PC needs to be incremented for the next instruction,
        // as we already consumed the incremented version, so we need to do it again
        Pl <= pc_inc[5:0];

        // Backup Pl, so operations that change parts of it (ATPL) don't use the incremented version
        last_Pl <= Pl;
      end

      case (stage)
        STAGE_LOAD_PC: begin
          skip_next_instr  <= 0;
          // Continue skipping if previously skipped LAX, and still LAX
          skip_next_if_lax <= skip_next_if_lax && is_lax;
          wr_next_ram_addr <= 0;

          if (last_temp_sbm) begin
            // SBM flag has been set and used for one instruction. Lower it
            temp_sbm <= 0;
          end

          if (wr_next_ram_addr) begin
            {Bm[1:0], Bl} <= next_ram_addr;
          end else begin
            // Update address for next time we write
            next_ram_addr <= {Bm[1:0], Bl};
          end
        end
        STAGE_HALT: begin
          // Load PC at 1_0_00
          {Pu, Pm, Pl} <= {2'b1, 4'b0, 6'b0};

          if (reset_halt) begin
            halt <= 0;
          end
        end
        STAGE_DECODE_PERF_1: begin
          last_opcode   <= opcode;
          last_temp_sbm <= temp_sbm;

          casex (opcode)
            8'h00: begin
              // SKIP. NOP
            end
            8'h01: begin
              // ATBP. Set LCD BP to Acc
              lcd_bp <= Acc[0];
            end
            8'h02: begin
              // SBM. Set high bit of Bm high for next instruction only. Returns to previous value after
              // This is masked directly into the RAM input
              temp_sbm <= 1;
            end
            8'h03: begin
              // ATPL. Load Pl with Acc
              // Since Pl was already incremented, we need to make sure the upper two bits
              // haven't changed, so we restore the old value
              Pl <= {last_Pl[5:4], Acc};
            end
            8'b0000_01XX: begin
              // 0x04-07: RM x. Zero RAM at bit indexed by immediate
              reg [3:0] temp;

              temp = ram_data;
              // Zero bit at index
              temp[opcode[1:0]] = 0;

              ram_wr_data <= temp;
              ram_wr <= 1;
            end
            8'h08: begin
              // ADD. Add RAM to Acc
              Acc <= Acc + ram_data;
            end
            8'h09: begin
              // ADD11. Add RAM to Acc with carry. Skip next instruction if carry
              reg [4:0] result;
              result = Acc + ram_data + carry;

              {carry, Acc} <= result;
              skip_next_instr <= result[4];
            end
            8'h0A: begin
              // COMA. NOT Acc
              Acc <= ~Acc;
            end
            8'h0B: begin
              // EXBLA. Swap Acc and Bl
              Acc <= Bl;
              Bl  <= Acc;
            end
            8'b0000_11XX: begin
              // 0x0C-0F: SM x. Set RAM at bit indexed by immediate
              reg [3:0] temp;

              temp = ram_data;
              // Set bit at index
              temp[opcode[1:0]] = 1;

              ram_wr_data <= temp;
              ram_wr <= 1;
            end
            8'b0001_00XX: begin
              // 0x10-13: EXC x. Swap Acc and RAM. XOR Bm with immed
              exc_x(1);
            end
            8'b0001_01XX: begin
              // 0x14-17: EXCI x. Swap Acc and RAM. XOR Bm with immed. Increment Bl. If Bl was 0xF, skip next
              exc_x(1);
              incb();
            end
            8'b0001_10XX: begin
              // 0x18-1B: LDA x. Load Acc with RAM value. XOR Bm with immed
              exc_x(0);
            end
            8'b0001_11XX: begin
              // 0x1C-1F: EXCD x. Swap Acc and RAM. XOR Bm with immed. Decrement Bl. If Bl was 0x0, skip next
              exc_x(1);
              decb();
            end
            8'h2X: begin
              // LAX x. Load Acc with immed. If next instruction is LAX, skip it
              Acc <= opcode[3:0];
              skip_next_if_lax <= 1;
            end
            8'h3X: begin
              // ADX x. Add immed to Acc. Skip next instruction if carry is set
              // Do not skip if immediate is 0xA due to die bug
              reg [4:0] result;

              result = Acc + opcode[3:0];
              Acc <= result[3:0];

              // Die bug when 0xA. Do nothing
              skip_next_instr <= result[4] && opcode[3:0] != 4'hA;
            end
            8'h4X: begin
              // LB x. Set lower Bm to immed. Set lower Bl to immed. Set upper Bl to ORed immed
              // OR is questionable here according to docs, but other implementations (MAME) use OR
              reg ored;
              ored = opcode[3] | opcode[2];

              Bl <= {ored, ored, opcode[3:2]};
              Bm[1:0] <= opcode[1:0];
            end
            // 0x50 unused
            8'h51: begin
              // TB. Skip next instruction if Beta is 1
              skip_next_instr <= input_beta;
            end
            8'h52: begin
              // TC. Skip next instruction if C = 0
              skip_next_instr <= ~carry;
            end
            8'h53: begin
              // TAM. Skip next instruction if Acc = RAM value
              skip_next_instr <= Acc == ram_data;
            end
            8'b0101_01XX: begin
              // TMI x. Skip next instruction if indexed memory bit is set
              skip_next_instr <= ram_data[opcode[1:0]];
            end
            8'h58: begin
              // TIS. Skip next instruction if one second clock divider signal is low. Zero gamma
              // TODO: All sources seem to consider gamma as the one second signal. We're using it for now
              skip_next_instr <= ~gamma;

              reset_gamma <= 1;
            end
            8'h59: begin
              // ATL. Set segment output L to Acc
              segment_l <= Acc;
            end
            8'h5A: begin
              // TAO. Skip next instruction if Acc = 0
              skip_next_instr <= Acc == 4'h0;
            end
            8'h5B: begin
              // TABL. Skp next instruction if Acc = Bl
              skip_next_instr <= Acc == Bl;
            end
            // 0x5C unused
            8'h5D: begin
              // CEND. Stop clock
              halt <= 1;

              reset_divider <= 1;
            end
            8'h5E: begin
              // TAL. Skip next instruction if BA = 1
              skip_next_instr <= input_ba == 1;
            end
            8'h5F: begin
              // LBL xy (2 byte)
              // Do nothing here. Entirely done in second stage
            end
            8'h60: begin
              // ATFC. Set segment output Y to Acc
              segment_y <= Acc;
            end
            8'h61: begin
              // ATR. Set R buzzer control value to the bottom two bits of Acc
              cached_buzzer_r <= Acc[1:0];
            end
            8'h62: begin
              // WR. Shift 0 into W
              shifter_w <= {shifter_w[6:0], 1'b0};
            end
            8'h63: begin
              // WS. Shift 1 into W
              shifter_w <= {shifter_w[6:0], 1'b1};
            end
            8'h64: begin
              // INCB. Increment Bl. If Bl was 0xF, skip next
              incb();
            end
            8'h65: begin
              // IDIV. Reset clock divider
              reset_divider <= 1;
            end
            8'h66: begin
              // RC. Clear carry
              carry <= 0;
            end
            8'h67: begin
              // SC. Set carry
              carry <= 1;
            end
            8'h68: begin
              // TF1. Skip next instruction if F1 = 1 (clock divider 14th bit)
              skip_next_instr <= divider[14];
            end
            8'h69: begin
              // TF4. Skip next instruction if F4 = 1 (clock divider 11th bit)
              skip_next_instr <= divider[11];
            end
            8'h6A: begin
              // KTA. Read K input bits into Acc
              Acc <= input_k;
            end
            8'h6B: begin
              // ROT. Rotate right
              {Acc, carry} <= {carry, Acc};
            end
            8'h6C: begin
              // DECB. Decrement Bl. If Bl was 0x0, skip next
              decb();
            end
            8'h6D: begin
              // BDC. Set LCD power. Display is on when low
              lcd_bc <= carry;
            end
            8'h6E: begin
              // RTN0. Pop stack. Move S into PC, and R into S
              pop_stack();
            end
            8'h6F: begin
              // RTN1. Pop stack. Move S into PC, and R into S. Skip next instruction
              pop_stack();

              skip_next_instr <= 1;
            end
            8'h7X: begin
              // TL/TML xyz
              // Do nothing here. Entirely done in second stage
            end
            8'b10XX_XXXX: begin
              // T xy. Short jump, within page. Set Pl to immediate
              Pl <= opcode[5:0];
            end
            8'b11XX_XXXX: begin
              // TM x. Jumps to IDX table, and executes that instruction. Push PC + 1 into stack
              push_stack(pc);

              {Pu, Pm, Pl} <= {2'b0, 4'b0, opcode[5:0]};
            end
          endcase
        end
        STAGE_PERF_3: begin
          casex (last_opcode)
            8'h5F: begin
              // LBL xy (2 byte). Immed is only second byte. Set Bm to high 3 bits of immed, and Bl to low 4 immed. Highest bit is unused
              Bm <= opcode[6:4];
              Bl <= opcode[3:0];
            end
            8'h7X: begin
              // This is weird and goes up to 0xA for some reason, so we need the nested checks
              // Notice there is a gap where 0xB is not handled (in the actual CPU)
              if (last_opcode[3:0] < 4'hB) begin
                // TL xyz (2 byte). Long jump. Load PC with immediates
                {Pu, Pm, Pl} <= {opcode[7:6], last_opcode[3:0], opcode[5:0]};
              end else if (last_opcode[3:0] >= 4'hC) begin
                // TML xyz (2 byte). Long call. Push PC + 1 into stack registers. Load PC with immediates
                // Need to push instruction after this one, so increment again
                push_stack(pc_inc);

                {Pu, Pm, Pl} <= {opcode[7:6], {2'b0, last_opcode[1:0]}, opcode[5:0]};
              end else begin
                $display("Unexpected immediate in TL %h at %h", opcode, pc);
              end
            end
            default: begin
              $display("Unknown instruction in second stage %h_%h", last_opcode, opcode);
            end
          endcase
        end
        STAGE_IDX_PERF: begin
          // Prev cycle fetched IDX data. Now set PC
          {Pu, Pm, Pl} <= {opcode[7:6], 4'h4, opcode[5:0]};
        end
      endcase
    end
  end

endmodule
