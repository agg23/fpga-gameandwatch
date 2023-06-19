## Annotations

* `M` - RAM value
* `BP` - LCD control register BP
* `BC` - LCD Power. On when low
* `BA` - Input pin
* `Beta` - Input pin
* `1S` - One second signal output by divider. `Gamma` is set on the rising edge of that function
* `F1` - 14th bit of the clock divider, 0 indexed
* `F4` - 11th bit of the clock divider, 0 indexed - TODO: MAME uses the 10th bit

## Timing

Docs list oscillator at 32.768kHz and typical 61us instruction timing, which implies two cycles. Assuming two byte instructions, and particularly `TM` to `IDX` is multiple cycles. Skipping an instruction takes two cycles \[1]

1. MAME uses 2 cycle and 4 cycle instructions only. We've followed their lead, even though the non-`TM` two byte instructions can be done in 3

## 1. RAM Address Instructions

| Mnemonic          | Opcode        | Operation                                                            | Description                                                                                                                                                 |
| ----------------- | ------------- | -------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `LB x`            | `0x4X`        | `Bl[3:2] <- {2{x[3] \| x[2]}}, Bl[1:0] <- x[3:2], Bm[1:0] <- x[1:0]` | Set lower 2 bits of `Bm` to the lower 2 of immed. Set lower 2 bits of `Bl` to upper 2 of immed. Set upper 2 bits of `Bl` to the upper 2 of immed ORed. \[1] |
| `LBL xy` (2 byte) | `0x5F` `0xXX` | `Bm <- x[6:4], Bl <- x[3:0]`                                         | Set `Bm` to high 3 bits of immed. Set `Bl` to low 4 bits of immed                                                                                           |
| `SBM`             | `0x02`        | `Bm[2] <- 1` for only the next step                                  | Sets the high bit of `Bm` high for the next cycle only. It will return to its previous value after that cycle                                               |
| `EXBLA`           | `0x0B`        | `Acc <-> Bl`                                                         | Swap Acc and `Bl`                                                                                                                                           |
| `INCB`            | `0x64`        | Skip next if `Bl == 0xF`. `Bl <- Bl + 1`                             | Increment `Bl`. If original `Bl` was `0xF`, skip next instruction                                                                                           |
| `DECB`            | `0x6C`        | Skip next if `Bl == 0`. `Bl <- Bl - 1`                               | Decrement `Bl`. If original `Bl` was `0x0`, skip next instruction                                                                                           |

Notes:
1. Docs use a plus in a circle symbol for the OR, but elsewhere uses it to indicate XOR. MAME and other implementations use OR, so this is probably a docs bug

## 2. ROM Address Instructions

| Mnemonic               | Opcode                  | Operation                                                            | Description                                                                                               |
| ---------------------- | ----------------------- | -------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| `ATPL`                 | `0x03`                  | `Pl[3:0] <- Acc`                                                     | Load PC low bits with Acc                                                                                 |
| `RTN0`                 | `0x6E`                  | `{Pu, Pm, Pl} <- {Su, Sm, Sl} <- {Ru, Rm, Rl}`                       | Pop stack. Move `S` into `PC`, and `R` into `S`                                                           |
| `RTN1`                 | `0x6F`                  | `{Pu, Pm, Pl} <- {Su, Sm, Sl} <- {Ru, Rm, Rl}`                       | Pop stack. Move `S` into `PC`, and `R` into `S`. Skip next instruction                                    |
| `TL xyz` (2 byte)      | `0x70-7A` X `0x00-FE` Y | `{Pu, Pm, Pl} <- {y[7:6], x[3:0], y[5:0]}`                           | Long jump. Load `PC` with immediates as shown                                                             |
| `TML xyz` (2 byte)     | `0x7C-7F` X `0x00-FE` Y | `R <- S <- PC + 1, Pu <- y[7:6], Pm <- {2'b0, x[1:0]}, Pl <- y[5:0]` | Long call. Push `PC + 2` into stack registers. Load PC with immediates as shown \[1]                      |
| `TM x` (psuedo 2 byte) | `0xC0-FE`               | `R <- S <- PC + 1, {Pu, Pm, Pl} <- {2'b0, 4'b0, x[5:0]}`             | Jumps to IDX table, and executes (see `IDX` below). Push `PC + 1` into stack registers. Jump to zero page |
| `IDX yz`               | `0x00-FE`               | `{Pu, Pm, Pl} <- {y[7:6], 4'h4, x[5:0]}, `                           | Not a real opcode. Always preceeded by `TM`. Loads immediate into PC                                     |
| `T xy`                 | `0x80-BF`               | `Pl <- x[5:0]`                                                       | Short jump, within page. Set `Pl` to immediate                                                            |

Note
1. This pushes PC + 2, because PC + 1 is part of the contents of the instruction

## 3. Data Transfer Instructions

| Mnemonic | Opcode    | Operation                                                                               | Description                                                                                                                               |
| -------- | --------- | --------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| `EXC x`  | `0x10-13` | `Acc <-> M, Bm[1:0] <- Bm[1:0] ^ x[1:0]`                                                | Swap Acc and RAM value. XOR `Bm` with immed                                                                                               |
| `BDC`    | `0x6D`    | `BC <- C`                                                                               | Set LCD power. Display is on if `C` is low                                                                                                |
| `EXCI x` | `0x14-17` | `Acc <-> M, Bm[1:0] <- Bm[1:0] ^ x[1:0]`. Skip next instr if `Bl = 0xF`. `Bl <- Bl + 1` | Swap Acc and RAM value. XOR `Bm` with immed. Increment `Bl`. If original `Bl` was `0xF`, skip next instruction. Combines `EXC` and `INCB` |
| `EXCD x` | `0x1C-1F` | `Acc <-> M, Bm[1:0] <- Bm[1:0] ^ x[1:0]`. Skip next instr if `Bl = 0x0`. `Bl <- Bl - 1` | Swap Acc and RAM value. XOR `Bm` with immed. Decrement `Bl`. If original `Bl` was `0x0`, skip next instruction. Combines `EXC` and `DECB` |
| `LDA x`  | `0x18-1B` | `Acc <- M, Bm[1:0] <- Bm[1:0] ^ x[1:0]`                                                 | Load Acc with RAM value. XOR `Bm` with immed                                                                                              |
| `LAX x`  | `0x20-2F` | `Acc <- x[3:0]`. Skip next instr if also LAX                                            | Load Acc with immed. If following instruction is `LAX`, skip it. Continue skipping instruction until all of the `LAX` are passed          |
| `WR`     | `0x62`    | `W[7] <- W[6] <- ... <- W[0] <- 0`                                                      | Shift 0 into `W`                                                                                                                          |
| `WS`     | `0x63`    | `W[7] <- W[6] <- ... <- W[0] <- 1`                                                      | Shift 1 into `W`                                                                                                                          |

## 4. I/O Instructions

| Mnemonic | Opcode | Operation       | Description                                                |
| -------- | ------ | --------------- | ---------------------------------------------------------- |
| `KTA`    | `0x6A` | `Acc <- K`      | Reads `K` input bits into Acc                              |
| `ATBP`   | `0x01` | `BP <- Acc[0]`  | Set LCD BP reg to Acc                                      |
| `ATL`    | `0x59` | `L <- Acc`      | Set Segment output `L` to Acc                              |
| `ATFC`   | `0x60` | `Y <- Acc`      | Set Segment output `Y` to Acc                              |
| `ATR`    | `0x61` | `R <- Acc[1:0]` | Set `R` buzzer control value to the bottom two bits of Acc |

## 5. Arithmetic Instructions

| Mnemonic | Opcode     | Operation                                                       | Description                                                                                                           |
| -------- | ---------- | --------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| `ADD`    | `0x08`     | `Acc <- Acc + RAM`                                              | Add RAM to Acc                                                                                                        |
| `ADD11`  | `0x09`     | `Acc <- Acc + RAM + C`, Set carry, skip next instr if new carry | Add RAM to Acc with carry. Skip next instr if carry                                                                   |
| `ADX x`  | `0x3X`     | `Acc <- Acc + x`. Skip next instr if new carry                  | Add 4 bit immediate to Acc, saving carry. Skip next instr if carry except if immediate is `'d10` (exception is a bug) |
| `COMA`   | `0x0A`     | `Acc <- ~Acc`                                                   | NOT Acc                                                                                                               |
| ~~`DC`~~ | ~~`0x3A`~~ | ~~`Acc <- Acc + (1010)^2`~~                                     | ~~This command doesn't seem to exist anywhere. No idea what it's for~~ \[1]                                           |
| `ROT`    | `0x6B`     | `C <- Acc[0] <- Acc[1] <- ... <- C`                             | Rotates right                                                                                                         |
| `RC`     | `0x66`     | `C <- 0`                                                        | Clears carry                                                                                                          |
| `SC`     | `0x67`     | `C <- 1`                                                        | Sets carry                                                                                                            |

Notes:
1. I don't know why this is listed in the docs. This is what `ADX x` does. However it has a bug at 0xA, which is what this exception shows

## 6. Test Instructions

| Mnemonic | Opcode    | Operation                                 | Description                                                 |
| -------- | --------- | ----------------------------------------- | ----------------------------------------------------------- |
| `TB`     | `0x51`    | Skip next instr if `Beta = 1`             |                                                             |
| `TC`     | `0x52`    | Skip next instr if `C = 0`                |                                                             |
| `TAM`    | `0x53`    | Skip next instr if `Acc = M`              |                                                             |
| `TMI x`  | `0x54-57` | Skip next instr if `M[x[1:0]] = 1`        |                                                             |
| `TAO`    | `0x5A`    | Skip next instr if `Acc = 0`              |                                                             |
| `TABL`   | `0x5B`    | Skip next instr if `Acc = Bl`             |                                                             |
| `TIS`    | `0x58`    | Skip next instr if `1S = 0`, `Gamma <- 0` | Check one second clock divider signal and zero `Gamma` \[1] |
| `TAL`    | `0x5E`    | Skip next instr if `BA = 1`               |                                                             |
| `TF1`    | `0x68`    | Skip next instr if `F1 = 1`               | Clock divider value (14th bit)                              |
| `TF4`    | `0x69`    | Skip next instr if `F4 = 1`               | Clock divider value (11th bit) \[2]                         |

Note:
1. MAME does not check the clock divider value, but the current state of `Gamma`. TODO: Is this correct?
2. MAME says this should be the 10th bit, but if F1 is 14, then F4 should be 11

## 7. Bit Manipulation Instructions

| Mnemonic | Opcode    | Operation        | Description                          |
| -------- | --------- | ---------------- | ------------------------------------ |
| `RM x`   | `0x04-07` | `M[x[1:0]] <- 0` | Zero bit of RAM indexed by immediate |
| `SM x`   | `0x0C-0F` | `M[x[1:0]] <- 1` | Set bit of RAM indexed by immediate  |

## 8. Special Instructions

| Mnemonic | Opcode | Operation                       |
| -------- | ------ | ------------------------------- |
| `SKIP`   | `0x00` | Do nothing                      |
| `CEND`   | `0x5D` | Stop clock                      |
| `IDIV`   | `0x65` | `DIV <- 0`. Reset clock divider |

# Variant: SM5a

## Hardware

* Adds `W'` shift registers, which drive output
* Adds `m'` flag register to accompany `W'`
* Adds page setting functionality with the `Cs`, `Su`, `Sl` stack registers - Stack is initialized to initial PC
* Adds `CB` bank select for certain branches (`TR` and `TRS`)
* Adds 4 bit `R` output
* Removes stack `S` and `R`
* Removes LCD `H` and segments `A` and `B`. Uses `O` output pins based on `W` and `W'`
* Removes 2 bit buzzer `R` output

### Data Bus Layout

Memory is arranged as 5 sets of 13 nibbles (5 x 13 x 4bits). This is exposed as:
```
0x00 - 0x0C: Chunk 0
0x10 - 0x1C: Chunk 1
0x20 - 0x2C: Chunk 2
0x30 - 0x3C: Chunk 3
0x40 - 0x4C: Chunk 4
```

Values outside of this range (in the form `0xXD-F` where `X` <= 4) are wrapped back to `0xXC`. Values >= `0x50` are wrapped into the `0x40` block, such that `0x67` maps to `0x47`

## Instructions

| Mnemonic | Opcode      | Operation                                                                                                               | Replaces                                |
| -------- | ----------- | ----------------------------------------------------------------------------------------------------------------------- | --------------------------------------- |
| `SBM`    | `0x02`      | Set high bit of `Bm` high                                                                                               | `SBM`, just different definition        |
| `LB`     | `0x4X`      | Set `Bm` to low 2 immed. Set `Bl` to high two immed ORed with 8                                                         | `LB`, just different definition         |
| `SSR`    | `0x7X`      | Set stack `S` `Pm` (page) to immed. Sets `E` flag for next opcode                                                       | `TL` and `TML`, long jump and long call |
| `TR`     | `0x80-0xBF` | Long or short jump. Uses set page value to determine whether long/short \[1]                                            | `T` short jump                          |
| `TRS`    | `0xC0-0xFF` | Call subroutine. Sets `Pl` to immed, pushes stack. Uses stored page/bank if `E` flag is set from `SSR` prev instruction | `TM` jump to IDX table                  |
| `ATR`    | `0x01`      | Same as normal: Set `R` buzzer control value to the bottom two bits of Acc                                              | `ATBP` set BP                           |
| `ATBP`   | `0x03`      | Same as normal: Set LCD BP reg to Acc                                                                                   | `ATPL` set PC low bits                  |
| `TAL`    | `0x50`      | Skip next instr if `BA` is set                                                                                          | None                                    |
| `PTW`    | `0x59`      | Copy last two values from `W'` to `W`                                                                                   | `ATL` set `L` segment output            |
| `TW`     | `0x5C`      | Copy `W'` to `W`                                                                                                        | None                                    |
| `DTW`    | `0x5D`      | Shift PLA value into `W'`. See \[2]                                                                                     | `CEND` stop clock                       |
| `COMCN`  | `0x60`      | XOR (complement) LCD `CN` flag                                                                                          | `ATFC` set `Y` segment output           |
| `PDTW`   | `0x61`      | Shift last two nibbles only, moving one PLA value into `W'` \[2]                                                        | `ATR` set buzzer                        |
| `WR`     | `0x62`      | Shift Acc (with 0 high bit) into `W'`                                                                                   | `WR`, just different definition         |
| `WS`     | `0x63`      | Shift Acc (with 1 high bit) into `W'`                                                                                   | `WS`, just different definition         |
| `INCB`   | `0x64`      | Increment `Bl`. If `Bl` was 8, skip next inst                                                                           | `INCB`, just different definition       |
| `IDIV`   | `0x65`      | Reset clock divider, keeping the low 6 bits bits                                                                        | `IDIV`, just different definition       |
| `RMF`    | `0x68`      | Clear `m'` and Acc                                                                                                      | `TF1` skip if divider                   |
| `SMF`    | `0x69`      | Set `m'`                                                                                                                | `TF4` skip if divider                   |
| `RBM`    | `0x6B`      | Clear `Bm` high bit                                                                                                     | `ROT` rotate right                      |
| `COMCB`  | `0x6D`      | XOR (complement) `CB`                                                                                                   | `BCD` set LCD power                     |
| `CEND`   | `0x5E 0x00` | Stop clock                                                                                                              | `TAL`                                   |
| `DTA`    | `0x5E 0x04` | Copy high 4 bits of clock divider to Acc                                                                                | `TAL`                                   |

Note:
1. MAME has some strange logic for the `m_rsub` flag which indicates whether a call has occurred (`TRS`), and changes all of the branching behavior of `TR` and `TRS` until `RTN0` is executed
2. PLA values from MAME: `0xe, 0x0, 0xc, 0x8, 0x2, 0xa, 0xe, 0x2, 0xe, 0xa, 0x0, 0x0, 0x2, 0xa, 0x2, 0x2, 0xb, 0x9, 0x7, 0xf, 0xd, 0xe, 0xe, 0xb, 0xf, 0xf, 0x4, 0x0, 0xd, 0xe, 0x4, 0x0`