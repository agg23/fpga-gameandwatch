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