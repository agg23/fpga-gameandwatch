interface instructions (
    // Data
    input wire [7:0] opcode,
    input wire [3:0] ram_data,

    // Internal
    input wire gamma,
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
  reg [1:0] cached_buzzer_r = 0;

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

  ////////////////////////////////////////////////////////////////////////////////////////
  // RAM

  // RAM Address
  reg [2:0] Bm = 0;
  reg [3:0] Bl = 0;

  wire [6:0] ram_addr = {Bm, Bl};

  reg ram_wr = 0;
  reg [3:0] ram_wr_data = 0;

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

  task decb();
    // DECB. Decrement Bl. If Bl was 0x0, skip next
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

  task exc();
    // 0x10-13: EXC x. Swap Acc and RAM. XOR Bm with immed
    exc_x(1);
  endtask

  task exci();
    // 0x14-17: EXCI x. Swap Acc and RAM. XOR Bm with immed. Increment Bl. If Bl was 0xF, skip next
    exc_x(1);
    incb();
  endtask

  task lda();
    // 0x18-1B: LDA x. Load Acc with RAM value. XOR Bm with immed
    exc_x(0);
  endtask

  task excd();
    // 0x1C-1F: EXCD x. Swap Acc and RAM. XOR Bm with immed. Decrement Bl. If Bl was 0x0, skip next
    exc_x(1);
    decb();
  endtask

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
    cached_buzzer_r <= Acc[1:0];
  endtask

  task wr();
    // WR. Shift 0 into W
    shifter_w <= {shifter_w[6:0], 1'b0};
  endtask

  task ws();
    // WS. Shift 1 into W
    shifter_w <= {shifter_w[6:0], 1'b1};
  endtask

  task idiv();
    // IDIV. Reset clock divider
    reset_divider <= 1;
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

  task rtn0();
    // RTN0. Pop stack. Move S into PC, and R into S
    pop_stack();
  endtask

  task rtn1();
    // RTN1. Pop stack. Move S into PC, and R into S. Skip next instruction
    pop_stack();

    skip_next_instr <= 1;
  endtask

  task t();
    // T xy. Short jump, within page. Set Pl to immediate
    Pl <= opcode[5:0];
  endtask

  task tm();
    // TM x. Jumps to IDX table, and executes that instruction. Push PC + 1 into stack
    push_stack(pc);

    {Pu, Pm, Pl} <= {2'b0, 4'b0, opcode[5:0]};
  endtask
endinterface
