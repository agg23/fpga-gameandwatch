interface instructions (
    input wire [3:0] cpu_id,

    // Data
    input wire [7:0] opcode,
    input wire [7:0] last_opcode,
    input wire [3:0] ram_data,

    // Internal
    input wire gamma,
    input wire [14:0] divider,
    input wire divider_4hz,
    input wire divider_32hz,
    input wire [5:0] last_Pl,

    // IO
    input wire [3:0] input_k,
    input wire input_beta,
    input wire input_ba
);
  ////////////////////////////////////////////////////////////////////////////////////////
  // Instruction controlled registers

  // PC
  reg [1:0] Pu = 0;
  reg [3:0] Pm = 0;
  reg [5:0] Pl = 0;

  wire [11:0] pc = {Pu, Pm, Pl};
  wire [11:0] rom_addr = pc;

  // Reused as entire stack in SM5a
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

  // TODO: Remove and replace with just buzzer_r
  // reg [1:0] cached_buzzer_r = 0;

  // Control
  reg skip_next_instr = 0;
  // Skip next instruction only if next is LAX
  reg skip_next_if_lax = 0;

  reg temp_sbm = 0;

  reg [5:0] next_ram_addr = 0;
  reg wr_next_ram_addr = 0;

  reg reset_divider = 0;
  reg reset_divider_keep_6 = 0;
  reg reset_gamma = 0;

  reg halt = 0;

  reg [3:0] stored_output_r = 0;
  reg [3:0] output_r = 0;
  // Direct passthrough of R0 on 0x7, otherwise use the divider bit indicated by this value
  reg [2:0] output_r_mask = 4'h7;

  ////////////////////////////////////////////////////////////////////////////////////////
  // RAM

  // RAM Address
  reg [2:0] Bm = 0;
  reg [3:0] Bl = 0;

  wire [6:0] ram_addr = {Bm, Bl};

  reg ram_wr = 0;
  reg [3:0] ram_wr_data = 0;

  ////////////////////////////////////////////////////////////////////////////////////////
  // SM5a Registers

  // Bank select used by some jumps
  reg cb_bank = 0;

  // MAME calls this `m_rsub`
  reg within_subroutine = 0;

  reg [3:0] w_prime[9];
  reg [3:0] w_main[9];

  // LCD CN flag. MAME uses bit 3 of `m_bp` for this
  reg lcd_cn = 0;

  reg m_prime = 0;

  ////////////////////////////////////////////////////////////////////////////////////////
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
    // INCB. Increment Bl. If Bl was 0xF, skip next
    next_ram_addr[3:0] <= Bl + 4'h1;
    wr_next_ram_addr <= 1;

    skip_next_instr <= Bl == 4'hF;
  endtask

  task incb_sm500();
    // INCB. Increment Bl. If Bl was 0x7, skip next
    next_ram_addr[3:0] <= Bl + 4'h1;
    wr_next_ram_addr <= 1;

    skip_next_instr <= Bl == 4'h7;
  endtask

  task decb();
    // DECB. Decrement Bl. If Bl was 0x0, skip next
    next_ram_addr[3:0] <= Bl - 4'h1;
    wr_next_ram_addr <= 1;

    skip_next_instr <= Bl == 4'h0;
  endtask

  task pop_stack(reg update_s);
    {Pu, Pm, Pl} <= stack_s;

    if (update_s) begin
      stack_s <= stack_r;
    end
  endtask

  task push_stack(reg [11:0] next_pc);
    stack_r <= stack_s;
    stack_s <= next_pc;
  endtask

  ////////////////////////////////////////////////////////////////////////////////////////
  // Melody/Output

  task clock_melody();
    case (cpu_id)
      4: begin
        // SM5a
        reg r0_mask;
        r0_mask = output_r_mask == 4'h7 ? 1 : divider[output_r_mask];

        output_r <= {~stored_output_r[3:1], r0_mask && ~stored_output_r[0]};
      end
      default: begin
        // SM510
        // TODO: Populate
      end
    endcase
  endtask

  ////////////////////////////////////////////////////////////////////////////////////////
  // Instructions

  task atbp();
    // ATBP. Set LCD BP to Acc
    lcd_bp <= Acc[0];
  endtask

  task sbm();
    // SBM. Set high bit of Bm high for next instruction only. Returns to previous value after
    // This is masked directly into the RAM input
    temp_sbm <= 1;
  endtask

  task sbm_sm500();
    // SBM. Set high bit of Bm high
    Bm[2] <= 1;
  endtask

  task atpl();
    // ATPL. Load Pl with Acc
    // Since Pl was already incremented, we need to make sure the upper two bits
    // haven't changed, so we restore the old value
    Pl <= {last_Pl[5:4], Acc};
  endtask

  task rm();
    // 0x04-07: RM x. Zero RAM at bit indexed by immediate
    reg [3:0] temp;

    temp = ram_data;
    // Zero bit at index
    temp[opcode[1:0]] = 0;

    ram_wr_data <= temp;
    ram_wr <= 1;
  endtask

  task add();
    // ADD. Add RAM to Acc
    Acc <= Acc + ram_data;
  endtask

  task add11();
    // ADD11. Add RAM to Acc with carry. Skip next instruction if carry
    reg [4:0] result;
    result = Acc + ram_data + carry;

    {carry, Acc} <= result;
    skip_next_instr <= result[4];
  endtask

  task coma();
    // COMA. NOT Acc (complement Acc)
    Acc <= ~Acc;
  endtask

  task exbla();
    // EXBLA. Swap Acc and Bl
    Acc <= Bl;
    Bl  <= Acc;
  endtask

  task sm();
    // 0x0C-0F: SM x. Set RAM at bit indexed by immediate
    reg [3:0] temp;

    temp = ram_data;
    // Set bit at index
    temp[opcode[1:0]] = 1;

    ram_wr_data <= temp;
    ram_wr <= 1;
  endtask

  // task exc();
  //   // 0x10-13: EXC x. Swap Acc and RAM. XOR Bm with immed
  //   exc_x(1);
  // endtask

  // task exci();
  //   // 0x14-17: EXCI x. Swap Acc and RAM. XOR Bm with immed. Increment Bl. If Bl was 0xF, skip next
  //   exc_x(1);
  //   incb();
  // endtask

  // task lda();
  //   // 0x18-1B: LDA x. Load Acc with RAM value. XOR Bm with immed
  //   exc_x(0);
  // endtask

  // task excd();
  //   // 0x1C-1F: EXCD x. Swap Acc and RAM. XOR Bm with immed. Decrement Bl. If Bl was 0x0, skip next
  //   exc_x(1);
  //   decb();
  // endtask

  task lax();
    // LAX x. Load Acc with immed. If next instruction is LAX, skip it
    Acc <= opcode[3:0];
    skip_next_if_lax <= 1;
  endtask

  task adx();
    // ADX x. Add immed to Acc. Skip next instruction if carry is set
    // Do not skip if immediate is 0xA due to die bug
    reg [4:0] result;

    result = Acc + opcode[3:0];
    Acc <= result[3:0];

    // Die bug when 0xA. Do nothing
    skip_next_instr <= result[4] && opcode[3:0] != 4'hA;
  endtask

  task lb();
    // LB x. Set lower Bm to immed. Set lower Bl to immed. Set upper Bl to ORed immed
    // OR is questionable here according to docs, but other implementations (MAME) use OR
    reg ored;
    ored = opcode[3] | opcode[2];

    Bl <= {ored, ored, opcode[3:2]};
    Bm[1:0] <= opcode[1:0];
  endtask

  task lb_sm500();
    // LB x. Set Bm to lower 2 bits immed. Set lower Bl to upper 2 bits immed. Set upper Bl to 2 if immed had data
    Bl <= {opcode[3:2] != 0 ? 2'b10 : 2'b0, opcode[3:2]};
    Bm <= {1'b0, opcode[1:0]};
  endtask

  task tb();
    // TB. Skip next instruction if Beta is 1
    skip_next_instr <= input_beta;
  endtask

  task tc();
    // TC. Skip next instruction if C = 0
    skip_next_instr <= ~carry;
  endtask

  task tam();
    // TAM. Skip next instruction if Acc = RAM value
    skip_next_instr <= Acc == ram_data;
  endtask

  task tmi();
    // TMI x. Skip next instruction if indexed memory bit is set
    skip_next_instr <= ram_data[opcode[1:0]];
  endtask

  task tis();
    // TIS. Skip next instruction if one second clock divider signal is low. Zero gamma
    // TODO: All sources seem to consider gamma as the one second signal. We're using it for now
    skip_next_instr <= ~gamma;

    reset_gamma <= 1;
  endtask

  task atl();
    // ATL. Set segment output L to Acc
    segment_l <= Acc;

  endtask

  task tao();
    // TAO. Skip next instruction if Acc = 0
    skip_next_instr <= Acc == 4'h0;
  endtask

  task tabl();
    // TABL. Skp next instruction if Acc = Bl
    skip_next_instr <= Acc == Bl;
  endtask

  task cend();
    // CEND. Stop clock
    halt <= 1;

    reset_divider <= 1;
  endtask

  task tal();
    // TAL. Skip next instruction if BA = 1
    skip_next_instr <= input_ba == 1;
  endtask

  task atfc();
    // ATFC. Set segment output Y to Acc
    segment_y <= Acc;
  endtask

  task atr();
    // ATR. Set R buzzer control value to the bottom two bits of Acc
    stored_output_r <= Acc;
  endtask

  task wr();
    // WR. Shift 0 into W
    shifter_w <= {shifter_w[6:0], 1'b0};
  endtask

  // task wr_sm500(reg [3:0] w_length);
  //   // WR. Shift Acc (0 high bit) into W'
  //   shift_w_prime(w_length, Acc & 4'h7);
  // endtask

  task ws();
    // WS. Shift 1 into W
    shifter_w <= {shifter_w[6:0], 1'b1};
  endtask

  // task ws_sm500(reg [3:0] w_length);
  //   // WS. Shift Acc (1 high bit) into W'
  //   shift_w_prime(w_length, Acc | 4'h8);
  // endtask

  task idiv();
    // IDIV. Reset clock divider
    reset_divider <= 1;
  endtask

  task idiv_sm500();
    // IDIV. Reset clock divider, keeping lower 6 bits
    reset_divider_keep_6 <= 1;
  endtask

  task rc();
    // RC. Clear carry
    carry <= 0;
  endtask

  task sc();
    // SC. Set carry
    carry <= 1;
  endtask

  task tf1();
    // TF1. Skip next instruction if F1 = 1 (clock divider 14th bit)
    skip_next_instr <= divider_4hz;
  endtask

  task tf4();
    // TF4. Skip next instruction if F4 = 1 (clock divider 11th bit)
    skip_next_instr <= divider_32hz;
  endtask

  task kta();
    // KTA. Read K input bits into Acc
    Acc <= input_k;
  endtask

  task rot();
    // ROT. Rotate right
    {Acc, carry} <= {carry, Acc};
  endtask

  task bdc();
    // BDC. Set LCD power. Display is on when low
    lcd_bc <= carry;
  endtask

  // task rtn0();
  //   // RTN0. Pop stack. Move S into PC, and R into S
  //   pop_stack();
  //   within_subroutine <= 0;
  // endtask

  // task rtn1();
  //   // RTN1. Pop stack. Move S into PC, and R into S. Skip next instruction
  //   pop_stack();

  //   skip_next_instr <= 1;
  //   within_subroutine <= 0;
  // endtask

  task t();
    // T xy. Short jump, within page. Set Pl to immediate
    Pl <= opcode[5:0];
  endtask

  // task tm();
  //   // TM x. Jumps to IDX table, and executes that instruction. Push PC + 1 into stack
  //   push_stack(pc);

  //   {Pu, Pm, Pl} <= {2'b0, 4'b0, opcode[5:0]};
  // endtask

  ////////////////////////////////////////////////////////////////////////////////////////
  // SM5a Instructions

  task ptw(reg [3:0] w_length);
    // PTW. Copy last two values from W' to W
    w_main[w_length-1] <= w_prime[w_length-1];
    w_main[w_length-2] <= w_prime[w_length-2];
  endtask

  task tw(reg [3:0] w_length);
    // TW. Copy W' to W
    int i;

    for (i = 0; i < w_length; i += 1) begin
      w_main[i] <= w_prime[i];
    end
  endtask

  reg [3:0] pla_data[32] = '{
      4'he,
      4'h0,
      4'hc,
      4'h8,
      4'h2,
      4'ha,
      4'he,
      4'h2,
      4'he,
      4'ha,
      4'h0,
      4'h0,
      4'h2,
      4'ha,
      4'h2,
      4'h2,
      4'hb,
      4'h9,
      4'h7,
      4'hf,
      4'hd,
      4'he,
      4'he,
      4'hb,
      4'hf,
      4'hf,
      4'h4,
      4'h0,
      4'hd,
      4'he,
      4'h4,
      4'h0
  };

  function [3:0] pla_digit();
    reg [3:0] temp;

    temp = pla_data[{lcd_cn, Acc}];

    return temp | (~lcd_cn && m_prime);
  endfunction

  task shift_w_prime(reg [3:0] w_length, reg [3:0] new_value);
    int i;
    for (i = 0; i < 8; i += 1) begin
      w_prime[i] <= w_prime[i+1];
    end
    // Put new value in correct position
    w_prime[w_length-1] <= new_value;
  endtask

  // task dtw(reg [3:0] w_length);
  //   // DTW. Shift PLA value into W'
  //   reg [3:0] digit;
  //   digit = pla_digit();

  //   shift_w_prime(w_length, digit);
  // endtask

  task comcn();
    // COMCN. XOR (complement) LCD CN flag
    lcd_cn <= lcd_cn ^ 1'b1;
  endtask

  // task pdtw(reg [3:0] w_length);
  //   // PDTW. Shift last two nibbles of W', moving one PLA value in
  //   reg [3:0] w_prime_temp[9];
  //   reg [3:0] digit;

  //   digit = pla_digit();

  //   w_prime_temp[w_length-2] = w_prime_temp[w_length-1];
  //   w_prime_temp[w_length-1] = digit;

  //   w_prime <= w_prime_temp;
  // endtask

  task rmf();
    // RMF. Clear m' and Acc
    m_prime <= 0;
    Acc <= 0;
  endtask

  task smf();
    // SMF. Set m'
    m_prime <= 1;
  endtask

  task rbm();
    // RBM. Clear Bm high bit
    Bm[2] <= 0;
  endtask

  task comcb();
    // COMCB. XOR (complement) CB
    cb_bank <= cb_bank ^ 1'b1;
  endtask

  task ssr();
    // SSR. Set stack higher bits bits to immed. Set E for next inst
    stack_s[9:6] <= opcode[3:0];
  endtask

  task tr();
    // TR. Long/short jump. Uses stack page value for distance
    // Short jump is set regardless
    Pl <= opcode[5:0];

    if (~within_subroutine) begin
      // Do long jump. Pl was already set above
      {Pu, Pm} <= {1'b0, cb_bank, stack_s[9:6]};
    end
  endtask

  // task trs(reg field);
  //   // TRS. Call subroutine
  //   if (within_subroutine) begin
  //     Pl <= {2'b0, opcode[3:0]};
  //     Pm[1:0] <= opcode[5:4];
  //   end else begin
  //     // Enter subroutine
  //     reg [3:0] temp_su;

  //     within_subroutine <= 1;

  //     temp_su = stack_s[9:6];

  //     push_stack(pc);

  //     if (last_opcode[7:4] == 4'h7) begin
  //       // Last instruction was SSR, and E flag would be set
  //       {Pu, Pm, Pl} <= {1'b0, cb_bank, temp_su, opcode[5:0]};
  //     end else begin
  //       {Pu, Pm, Pl} <= {1'b0, field, 4'b0, opcode[5:0]};
  //     end
  //   end
  // endtask

  task dta();
    // DTA. Copy high bits of clock divider to Acc
    Acc <= divider[14:11];
  endtask
endinterface
