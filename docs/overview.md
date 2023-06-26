# Overview

* [Format](format.md) - The ROM data format and construction
* [Graphics](graphics.md) - The rendering of MAME ROMs and different CPU's LCD handling
* [Instructions](instructions.md) - A collection of all instructions used by the supported CPUs, and the differences against the base SM510
* [Registers](registers.md) - Registers across the CPU and what they do
* [ROM Generator](rom_generator.md) - Tool to create the ROMs

## Implementation

The implementation for the SM510 is strongly based on the [official, error prone docs](1990_Sharp_Microcomputers_Data_Book.pdf), and leans on MAME's implemenation slightly to clear up confusion. The Tiger variant and SM5a are entirely based on MAME, other than some minor references in the [older official documentation](1986_Sharp_MOS_Semiconductor_Data_Book.pdf).

See the rest of these docs, but [Instructions](instructions.md) in particular for my rewritten (hopefully without error) documentation.

The overall layout of the CPU went through several iterations, with me trying to plan the best for the multiple CPU functionality that I knew was coming. I settled on using a SystemVerilog `interface` for abstracting the main registers and all instructions into `task`s in a separate file, but I ran into several issues with this. Turns out Quartus doesn't like when you call a task in an interface that calls another task. I found out the hard way that Quartus just silently drops these inner tasks, which is why you see replicated code in `sm510.sv` (in the decode segments).

For the overal ROM format, see [Format](format.md). There are a lot of steps to reading MAME ROMs and converting them into something useful for the FPGA, so you may also be interested in the [ROM Generator](rom_generator.md).

Note that as of the initial release, the MiSTer design just barely does not pass timing due to SDRAM address registering issues.