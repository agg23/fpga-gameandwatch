# MAME

This is largely for my own use while debugging and comparing against MAME instructions

Debug string

```
trace output.log,,noloop,{tracelog "pc=%03x, acc=%x, carry=%d, bm=%x, bl=%x, shifter_w=%02x, gamma=%x, div=%04x:    ", pc, acc, c, bm, bl, w, gamma, main_div}
```

Step 20000 instructions before halting for input. Values are in hex
```
step 4E20
inputs 2, 4
step 400
inputs 2, 0
step 4E20
inputs 1, 2
step 400
inputs 1, 0
step 20000
inputs 1, 2
step 400
inputs 1, 0
step 10000
inputs 1, 2
step 400
inputs 1, 0
step C400
inputs 2, 2
step 400
inputs 2, 0
step 10000
```

MAME can only output flags marked for debugging somehow, seen in the left side of the debugger

Log is cleaned by removing

```regex
replace with nothing
:    .*$
```

and

```regex
replace with newline
\n   \(interrupted at [a-f0-9]+:[a-f0-9]+:[a-f0-9]+, IRQ 0\)\n\n
```

Note. MAME prints skipped LAX instructions, so those can be ignored

Building (my environment, MSYS2 MinGW Windows)

```
export MINGW64=/mingw64 MINGW32=
make SUBTARGET=gnw SOURCES=src/mame/handheld/hh_sm510.cpp -j8 ARCHOPTS="-fuse-ld=lld"
```

----

Not actually MAME, but for building similar to MAME output logs from Signal Tap, I used the following expressions:

```
0        = core_top:ic|gameandwatch:gameandwatch|sm510:sm510|reset
1        = core_top:ic|gameandwatch:gameandwatch|sm510:sm510|last_pc[11..0]
2        = core_top:ic|gameandwatch:gameandwatch|sm510:sm510|instructions:inst|instructions.Acc[3..0]
3        = core_top:ic|gameandwatch:gameandwatch|sm510:sm510|instructions:inst|instructions.carry
4        = core_top:ic|gameandwatch:gameandwatch|sm510:sm510|instructions:inst|instructions.Bm[2..0]
5        = core_top:ic|gameandwatch:gameandwatch|sm510:sm510|instructions:inst|instructions.Bl[3..0]
6        = core_top:ic|gameandwatch:gameandwatch|sm510:sm510|instructions:inst|instructions.shifter_w[7..0]
7        = core_top:ic|gameandwatch:gameandwatch|sm510:sm510|divider:div|gamma
8        = core_top:ic|gameandwatch:gameandwatch|sm510:sm510|divider:div|divider[14..0]
9        = core_top:ic|gameandwatch:gameandwatch|input_config:input_config|input_k[3..0]
10       = core_top:ic|gameandwatch:gameandwatch|sm510:sm510|stage.STAGE_LOAD_PC
```

Replace with empty string:

```
^([0-9]+\s* 0 )
(.*[0-9]  0\s*)$\n
h
( [0-9]  [0-9]\s*)$
```

Replacement listed:

```
^(.*?)\s(.*?)\s(.*?)\s(.*?)\s(.*?)\s(.*?)\s(.*?)\s(.*?)\s(.*?)\s(.*) to pc=$1, acc=$3, carry=$4, bm=$5, bl=$6, ram=$7, shifter_w=$8, gamma=$9, div=$10

^(.*?)\s(.*?)\s(.*?)\s(.*?)\s(.*?)\s(.*?)\s(.*?)\s(.*?)\s(.*) to pc=$1, acc=$2, carry=$3, bm=$4, bl=$5, shifter_w=$6, k=$9, gamma=$7, div=$8
```