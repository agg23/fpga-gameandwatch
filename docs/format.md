32RAM controller can fetch 16 bytes in 15 cycles at 118MHz. Add 3 cycles for processing, to make 18 cycles per 16 bytes. 18 * 8.5ns = 153ns per 16 bytes or 9.56ns per byte

At dest 131.072MHz, we take 18 * 7.63ns = 140ns per 16 bytes, or 8.75ns per byte

Our video clock is 32.768MHz. We need a full pixel (3 bytes) every clock (30.5ns, so 10ns per byte)

```
line 10: [id 8bit][color 4bit][x 10bit][length 10bit]...next
```

## Config

First bit is version. Spec V1 is as follows:

```
0: [version 8bits (01)][mpu 8bits][screen configuration 8 bits][screen width|screen height 24bits][other input mapping 8 bits]
8: [s input mapping 32 bytes]
40: Start of reserved space
0x100: Start of image 1
0xBDE80: If dual screen, start of image 2, otherwise middle of image 1
0x17BC00: End of image 1, start of mask
```

### MPU

| MPU                 | Conf. Value |
| ------------------- | ----------- |
| SM510               | `0x0`       |
| SM511               | `0x1`       |
| SM512               | `0x2`       |
| SM530               | `0x3`       |
| SM5a                | `0x4`       |
| SM510 + Tiger       | `0x5`       |
| SM511 + Tiger 1 bit | `0x6`       |
| SM511 + Tiger 2 bit | `0x7`        |
|                     |             |