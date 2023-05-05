# Example Instruction Exectutions

## `TMI x`

1. Read PC. Increment PC
2. Decode. Push PC + 1 into stack registers. Set PC to immediate

Now `IDX yz`
3. Read PC. Increment PC (doesn't matter)
4. Set PC to immediate

## `TML xyz`

1. Read PC. Increment PC
2. Decode. Push PC + 1 into stack registers. Set PC to immediate part one
3. Set PC to immediate part 2

## `EXC x`

1. Read PC. Increment PC
2. Decord. Set Acc to RAM value. Write old Acc to RAM. Set Bm to some pattern. Skip if Bl is 0xF
Next cycle, Acc is being written to RAM, but it doesn't matter because we're reading the next PC