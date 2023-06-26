# Format

The MAME ROM format is not conducive to FPGA use, so we have to package up all of the assets into a new format. This format is designed with space for growth, but it should cover most usecases (i.e. games) already.

First is a config section of `0x80` bytes, followed by two byte interleaved 720x720 images, `0x2DB40` bytes of mask config, and finally the ROM data.

## Config

First bit is version. Spec V1 is as follows:

```
0x0: [version 8 bits (01)][mpu 8 bits][screen configuration 8 bits][screen width|screen height 24 bits][reserved 16 bits]
0x8: input mapping 40 bytes - [s0 config 4 bytes][s1 config 4 bytes] ... [s7 config 4 bytes][b config 1 byte][ba config 1 byte][acl config 1 byte][grounded port index 1 byte][reserved 4 bytes]
0x30: Start of reserved space - This is reserved for future functionality
0x80: Start of byte interleaved images
0x17BB80: [mask config 0x2DB40 bytes] End of images, start of mask config
0x1A96C0: ROM data
```

0000_1101_11 -> 00_0011_0111

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

Each button can be ~32 items. For alignment, assign a full 8 bits to each. There can be a maximum of 8 `S` ports (of 4 values), and 1 for `B`, `BA`, and `ACL` (in that order). We also add a "grounded input port index", which indicates which index of `S` port, if any, is grounded and thus is always active, ORed with the other input bits. Thus there are `8 * 4 + 4 = 36` bytes required for full config.

Each entry byte takes the form:
```
[active low 1 bit][reserved 2 bits][input 5 bits]
```

The `unused`/unset controller byte is assigned `0x7F` for clarity.

NOTE: These won't all be addressable given a normal input scheme, given the limited number of buttons on controllers.

The grounded input port is `0xFF` when unset, and the 0-based index otherwise.

| Input Name              | Config Value |
| ----------------------- | ------------ |
| JoyUp                   | 0            |
| JoyDown                 | 1            |
| JoyLeft                 | 2            |
| JoyRight                | 3            |
| Button1                 | 4            |
| Button2                 | 5            |
| Button3                 | 6            |
| Button4                 | 7            |
| Button5                 | 8            |
| Button6                 | 9            |
| Button7                 | 10           |
| Button8                 | 11           |
| Select (typically Time) | 12           |
| Start1 (Game A)         | 13           |
| Start2 (Game B)         | 14           |
| Service1                | 15           |
| Service2                | 16           |
| LeftJoyUp               | 17           |
| LeftJoyDown             | 18           |
| LeftJoyLeft             | 19           |
| LeftJoyRight            | 20           |
| RightJoyUp              | 21           |
| RightJoyDown            | 22           |
| RightJoyLeft            | 23           |
| RightJoyRight           | 24           |
| VolumeDown              | 25           |
| PowerOn                 | 26           |
| PowerOff                | 27           |
| Keypad                  | 28           |
| Custom                  | 29           |
| Mark Unused             | `0x7F`       |

### Images

Images are byte interleaved values of background and mask images. The background is the first byte, and is the lowest byte in each word.

### Mask

The mask data correlates the mask pixel data with the [LCD segment as defined in the MAME file](graphics.md). The 10 bit `id` provides the `x`, `y`, and `z` coordinate values for each segment, which allows the CPU to address them via the `S` shifter or `W` shift registers.

The `x`, `y` coordinates of the start of a run of mask pixels is recorded, along with the length of the run. Thus we can minimize the number of bytes required for a contiguous strip of pixels.

```
40 bits: [id 10 bits][x 10 bits][y 10 bits][length 10 bits]...next
id: [row/z 2 bits][column/y 4 bits][line/x 4 bits]
0x2DB40 bytes total - 720 rows, average of 52 entries, 5 bytes each
```
