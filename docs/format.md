RAM controller can fetch 16 bytes in 15 cycles at 118MHz. Add 3 cycles for processing, to make 18 cycles per 16 bytes. 18 * 8.5ns = 153ns per 16 bytes or 9.56ns per byte

Our video clock is 32MHz. We need a full pixel (3 bytes) every clock (31ns, so 10ns per byte)

```
line 10: [id 8bit][color 4bit][x 10bit][length 10bit]...next
```