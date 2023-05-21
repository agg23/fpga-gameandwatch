32RAM controller can fetch 16 bytes in 15 cycles at 118MHz. Add 3 cycles for processing, to make 18 cycles per 16 bytes. 18 * 8.5ns = 153ns per 16 bytes or 9.56ns per byte

At dest 131.072MHz, we take 18 * 7.63ns = 140ns per 16 bytes, or 8.75ns per byte

Our video clock is 32.768MHz. We need a full pixel (3 bytes) every clock (30.5ns, so 10ns per byte)

```
line 10: [id 10bit][x 10bit][y 10bit][length 10bit]...next
```

## Config

First bit is version. Spec V1 is as follows:

```
0x0: [version 8 bits (01)][mpu 8 bits][screen configuration 8 bits][screen width|screen height 24 bits][reserved 16 bits]
0x8: [input mapping 40 bytes]
0x30: Start of reserved space
0x100: Start of byte interleaved images
0x17BC00: If dual screen, start of image 2, otherwise middle of image
0x2F7700: [mask config 0x16DA0 bytes] End of images, start of mask config
0x30E4A0: ROM data
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
| SM511 + Tiger 2 bit | `0x7`       |
| KB1013VK12          | `0x8`       |

### Screen Configuration

| Screen Config   | Conf. Value |
| --------------- | ----------- |
| Single screen   | `0x0`       |
| Dual Horizontal | `0x1`       |
| Dual Vertical   | `0x2`       |

12 bits each for screen width/height

### Input Mapping

Each button can be ~32 items. For alignment, assign a full 8 bits to each. There can be a maximum of 8 `S` ports (of 4 values), and 1 for `B`, `BA`, and `ACL` (in that order). Thus there are `8 * 4 + 3 = 35` bytes required for full config.

```
[active low 1 bit][reserved 2 bits][input 5 bits]
```

The `unused`/unset controller byte is assigned `0x7F` for clarity.

NOTE: These won't all be addressable given a normal input scheme, given the limited number of buttons on controllers.

### Images

Images are byte interleaved values of background and mask images. The background is the first byte, and is the lowest byte in each word.