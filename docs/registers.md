# Registers

Note: This document has not been edited and may contain inaccuracies. More information can be found in [Instructions](instructions.md).

## ROM

Pages are arranged as 4 columns (`Pu`) with 10 values each (`Pm`). Pages contain 63 values indexed by `Pl`

## RAM

512 bits, in the form of 8 files (`Bm`) with 16 words (`Bl`) of 4 bits

The last two files are reserved for display RAM (referred to as `R, S`)

# Registers

## PC

* `Pu` - 2 bits - Part of page
* `Pm` - 4 bits - Part of page
* `Pl` - 6 bits - Polynomial counter - TODO: How does this work?

Appears to increment like: `{ Pl[0] == Pl[1], Pl[5:1] }`, but [MAME has more](https://github.com/mamedev/mame/blob/master/src/devices/cpu/sm510/sm510base.cpp#L260)

Initializes to `Pu` = 3, `Pm` = 7, `Pl` = 0 (`3_7_0`)

Restoring from clock halt, starts at `1_0_0`

## SP

Hardware registers for maintaining stack depth and values. `S` is the first level, and `R` is the second

* `Su` - 2 bits
* `Sm` - 4 bits
* `Sl` - 6 bits
* `Ru` - 2 bits
* `Rm` - 4 bits
* `Rl` - 6 bits

## General

* `Acc` - 4 bits - Accumulator
* `W` - 8 bits - Shift register - TODO: Is this necessary?
* `Bm` - 3 bits - Upper 3 bits of RAM address
* `Bl` - 4 bits - Lower 4 bits of RAM address
* `L`, `Y` - 4 bits - Flip flop - TODO: Is this necessary

# IO

## Inputs

* `K` - 4 bits. Arbitrary 4 bits
* `BA` - 1 bit. Arbitrary 1 bit - Has a pull-up resistor by default, so if unused/unspecified, should be high
* `BETA` - 1 bit. Arbitrary 1 bit - Has a pull-up resistor by default, so if unused/unspecified, should be high

## Outputs

* `H` - 4 bits - Controls which bit (out of 4) for each word in display memory is being used to drive the segments. Docs say it has a 1/4 duty cycle, so each bit is high 1/4th of the time, so it's driven by a counter up to 4. An aside lists the frame frequency as 64Hz
* `S` - 8 bits - Directly driven by the `W` register (the SM510 docs talk about the `W'` register and `PTW` instruction, but those don't exist on this hardware)
* `BS` - 1 bit - Somehow driven by "the contents of the `L` or `Y` register", but it doesn't describe how. It uses the same 1/4 duty cycle, so assumedly it changes along with `H`. MAME ANDs the two registers, but only sometime. TODO: This is implemented with only `L` at the moment