Debug string

```
trace output.log,,noloop,{tracelog "pc=%03x, acc=%x, carry=%d, bm=%x, bl=%x, shifter_w=%02x:    ", pc, acc, c, bm, bl, w}
```

MAME can only output flags marked for debugging somehow, seen in the left side of the debugger

Log is cleaned by removing

```regex
:    .*$
```

Note. MAME prints skipped LAX instructions, so those can be ignored

Building (my environment, MSYS2 MinGW Windows)

```
export MINGW64=/mingw64 MINGW32=
make SUBTARGET=gnw SOURCES=src/mame/handheld/hh_sm510.cpp -j8 ARCHOPTS="-fuse-ld=lld"
```