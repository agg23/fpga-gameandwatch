module sm510 (
    input wire clk,

    // Clocked at 32.768kHz
    input wire clk_en,

    input wire reset,

    // Data for external ROM
    input  wire [ 7:0] opcode,
    output wire [11:0] rom_addr,

    // The K1-4 input pins
    input wire [3:0] input_k,

    // The BA and Beta input pins
    input wire input_ba,
    input wire input_beta,

    // The H1-4 output pins
    output wire [3:0] output_h,

    // The S1-8 strobe output pins
    output wire [7:0] output_s,

    // LCD Segments
    output wire [15:0] segment_a,
    output wire [15:0] segment_b,
    // TODO: What is this?
    output wire segment_bs,

    // Audio
    output wire [1:0] buzzer_r
);
  // PC
  reg [1:0] Pu = 0;
  reg [3:0] Pm = 0;
  reg [5:0] Pl = 0;

  wire [11:0] pc = {Pu, Pm, Pl};

  reg [11:0] stack_s = 0;
  reg [11:0] stack_r = 0;

  // RAM Address
  reg [2:0] Bm = 0;
  reg [3:0] Bl = 0;

  wire [6:0] ram_addr = {Bm, Bl};

  // Accumulator
  reg [3:0] Acc = 0;
  reg carry = 0;

  // LCD Functions
  reg [3:0] BP = 0;
  reg lcd_bp = 0;

  reg [3:0] segment_l = 0;
  reg [3:0] segment_y = 0;

  reg [7:0] shifter_w = 0;

  ///////////

  wire divider_one_second = 0;
  reg gamma = 0;

  reg [14:0] divider = 0;

  ///////////

  localparam STAGE_LOAD_PC = 0;
  localparam STAGE_DECODE_PERF_1 = 1;
  localparam STAGE_PERF_2 = 2;
  localparam STAGE_IDX_FETCH = 3;
  localparam STAGE_IDX_PERF = 4;

  reg [2:0] stage = STAGE_LOAD_PC;

  always @(posedge clk) begin
    if (reset) begin
      stage <= STAGE_LOAD_PC;
    end else if (clk_en) begin
      case (stage)
        STAGE_LOAD_PC: stage <= STAGE_DECODE_PERF_1;
        STAGE_DECODE_PERF_1: begin
          state <= STAGE_LOAD_PC;

          if (is_tmi) begin
            // TMI x. Load IDX data
            stage <= STAGE_IDX_FETCH;
          end else if (is_two_bytes) begin
            // Instruction takes two bytes
            stage <= STAGE_PERF_2;
          end
        end
        STAGE_PERF_2: stage <= STAGE_LOAD_PC;
        STAGE_IDX_FETCH: stage <= STAGE_IDX_PERF;
        STAGE_IDX_PERF: stage <= STAGE_LOAD_PC;
      endcase
    end
  end

  // Control
  reg skip_next_instr = 0;
  // Skip next instruction only if next is LAX
  reg skip_next_if_lax = 0;

  reg temp_sbm = 0;

  reg halt = 0;

  // Internal
  reg [7:0] last_opcode = 0;

  // RAM
  // TODO: Handle
  wire [3:0] ram_data;

  reg ram_wr = 0;
  reg [3:0] ram_wr_data = 0;

  // Instruction shortcuts
  task exc_x(reg swap);
    // Swap Acc and RAM
    Acc <= ram_data;

    if (swap) begin
      ram_wr_data <= ram_data;
      ram_wr <= 1;
    end

    // XOR Bm with immed
    Bm[1:0] <= Bm[1:0] ^ opcode[1:0];
  endtask

  task incb();
    Bl <= Bl + 4'h1;
    skip_next_instr <= Bl == 4'hF;
  endtask

  task decb();
    Bl <= Bl - 4'h1;
    skip_next_instr <= Bl == 4'h0;
  endtask

  task pop_stack();
    {Pu, Pm, Pl} <= stack_s;
    stack_s <= stack_r;
  endtask

  task push_stack();
    stack_r <= stack_s;
    stack_s <= pc;
  endtask

  // Decoder
  // LBL xy | TL/TML xyz
  wire is_two_bytes = opcode == 8'h5F || opcode[7:4] == 4'h7;
  // TMI x
  wire is_tmi = opcode[7:6] == 2'b11;

  always @(posedge clk) begin
    if (clk_en) begin
      case (stage)
        STAGE_DECODE_PERF_1: begin
          last_opcode <= opcode;

          casex (opcode)
            8'h00: begin
              // SKIP. NOP
            end
            8'h01: begin
              // ATBP. Set LCD BP to Acc
              BP <= Acc;
            end
            8'h02: begin
              // SBM. Set high bit of Bm high for next instruction only. Returns to 0 after
              temp_sbm <= 1;
              Bm[1] <= 1;
            end
            8'h03: begin
              // ATPL. Load Pl with Acc
              Pl <= Acc;
            end
            8'b0000_01XX: begin
              // 0x04-07: RM x. Zero RAM at bit indexed by immediate
              reg [3:0] temp;

              temp = ram_data;
              // Zero bit at index
              temp[opcode[1:0]] <= 0;

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
              skip_next_instr <= carry;
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
              temp[opcode[1:0]] <= 1;

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
              // LB x. Set lower Bm to immed. Set lower Bl to immed. Set upper Bl to XORed immed
              reg xored;
              xored = opcode[3] ^ opcode[2];

              Bl <= {xored, xored, opcode[3:2]};
              Bm[1:0] <= opcode[1:0];
            end
            // 0x50 unused
            8'h51: begin
              // TB. Skip next instruction if Beta is 1
              skip_next_instr <= input_beta == 1;
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
              skip_next_instr <= ~divider_one_second;

              gamma <= 0;
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

              divider <= 0;
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
              buzzer_r <= Acc[1:0];
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
              divider <= 0;
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
              lcd_bp <= carry;
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
              // TMI x. Jumps to IDX table, and executes that instruction. Push PC + 1 into stack
              push_stack();

              {Pu, Pm, Pl} <= {2'b0, 4'b0, opcode[5:0]};
            end
          endcase
        end
        STAGE_PERF_2: begin
          casex (last_opcode)
            8'h5F: begin
              // LBL xy (2 byte). Immed is only second byte. Set Bm to high 3 bits of immed, and Bl to low 4 immed. Highest bit is unused
              Bm <= opcode[6:4];
              Bl <= opcode[3:0];
            end
            8'h7X: begin
              // This is weird and goes up to 0xA for some reason, so we need the nested checks
              if (opcode[3:0] < 4'hB) begin
                // TL xyz (2 byte). Long jump. Load PC with immediates
                {Pu, Pm, Pl} <= {opcode[7:6], last_opcode[3:0], opcode[5:0]};
              end else if (opcode[3:0] >= 4'hC) begin
                // TML xyz (2 byte). Long call. Push PC + 1 into stack registers. Load PC with immediates
                push_stack();

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
