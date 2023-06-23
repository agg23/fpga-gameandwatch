//------------------------------------------------------------------------------
// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileType: SOURCE
// SPDX-FileCopyrightText: (c) 2022, OpenGateware authors and contributors
//------------------------------------------------------------------------------
//
// Copyright (c) 2022, OpenGateware authors and contributors
// Copyright (c) 2017, Alexey Melnikov <pour.garbage@gmail.com>
// Copyright (c) 2015, Till Harbaum <till@harbaum.org>
//
// This source file is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.
//
//------------------------------------------------------------------------------
// Platform Specific top-level
// Instantiated by the real top-level: sys_top
//------------------------------------------------------------------------------

module core_top (
    //Master input clock
    input CLK_50M,

    //Async reset from top-level module.
    //Can be used as initial reset.
    input RESET,

    //Must be passed to hps_io module
    inout [48:0] HPS_BUS,

    //Base video clock. Usually equals to CLK_SYS.
    output CLK_VIDEO,

    //Multiple resolutions are supported using different CE_PIXEL rates.
    //Must be based on CLK_VIDEO
    output CE_PIXEL,

    //Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
    //if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
    output [12:0] VIDEO_ARX,
    output [12:0] VIDEO_ARY,

    output [7:0] VGA_R,
    output [7:0] VGA_G,
    output [7:0] VGA_B,
    output       VGA_HS,
    output       VGA_VS,
    output       VGA_DE,      // = ~(vblank | hblank)
    output       VGA_F1,
    output [1:0] VGA_SL,
    output       VGA_SCALER,  // Force VGA scaler
    output       VGA_DISABLE, // analog out is off

    input  [11:0] HDMI_WIDTH,
    input  [11:0] HDMI_HEIGHT,
    output        HDMI_FREEZE,

`ifdef NSX_ENABLE_FB
    // Use framebuffer in DDRAM
    // FB_FORMAT:
    //    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
    //    [3]   : 0=16bits 565 1=16bits 1555
    //    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
    //
    // FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
    output        FB_EN,
    output [ 4:0] FB_FORMAT,
    output [11:0] FB_WIDTH,
    output [11:0] FB_HEIGHT,
    output [31:0] FB_BASE,
    output [13:0] FB_STRIDE,
    input         FB_VBL,
    input         FB_LL,
    output        FB_FORCE_BLANK,

`ifdef NSX_ENABLE_FB_PAL
    // Palette control for 8bit modes.
    // Ignored for other video modes.
    output        FB_PAL_CLK,
    output [ 7:0] FB_PAL_ADDR,
    output [23:0] FB_PAL_DOUT,
    input  [23:0] FB_PAL_DIN,
    output        FB_PAL_WR,
`endif
`endif

    output LED_USER,  // 1 - ON, 0 - OFF.

    // b[1]: 0 - LED status is system status OR'd with b[0]
    //       1 - LED status is controled solely by b[0]
    // hint: supply 2'b00 to let the system control the LED.
    output [1:0] LED_POWER,
    output [1:0] LED_DISK,

    // I/O board button press simulation (active high)
    // b[1]: user button
    // b[0]: osd button
    output [1:0] BUTTONS,

    input         CLK_AUDIO,  // 24.576 MHz
    output [15:0] AUDIO_L,
    output [15:0] AUDIO_R,
    output        AUDIO_S,    // 1 - signed audio samples, 0 - unsigned
    output [ 1:0] AUDIO_MIX,  // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

    //ADC
    inout [3:0] ADC_BUS,

    //SD-SPI
    output SD_SCK,
    output SD_MOSI,
    input  SD_MISO,
    output SD_CS,
    input  SD_CD,

    //HPS DDR3 RAM interface (High latency)
    //Use for non-critical time purposes
    output        DDRAM_CLK,
    input         DDRAM_BUSY,
    output [ 7:0] DDRAM_BURSTCNT,
    output [28:0] DDRAM_ADDR,
    input  [63:0] DDRAM_DOUT,
    input         DDRAM_DOUT_READY,
    output        DDRAM_RD,
    output [63:0] DDRAM_DIN,
    output [ 7:0] DDRAM_BE,
    output        DDRAM_WE,

    //SDRAM interface (Lower latency)
    output        SDRAM_CLK,
    output        SDRAM_CKE,
    output [12:0] SDRAM_A,
    output [ 1:0] SDRAM_BA,
    inout  [15:0] SDRAM_DQ,
    output        SDRAM_DQML,
    output        SDRAM_DQMH,
    output        SDRAM_nCS,
    output        SDRAM_nCAS,
    output        SDRAM_nRAS,
    output        SDRAM_nWE,

`ifdef NSX_ENABLE_2ND_SDRAM
    //Secondary SDRAM
    //Set all output SDRAM_* signals to Z ASAP if SDRAM2_EN is 0
    input         SDRAM2_EN,
    output        SDRAM2_CLK,
    output [12:0] SDRAM2_A,
    output [ 1:0] SDRAM2_BA,
    inout  [15:0] SDRAM2_DQ,
    output        SDRAM2_nCS,
    output        SDRAM2_nCAS,
    output        SDRAM2_nRAS,
    output        SDRAM2_nWE,
`endif

    input  UART_CTS,
    output UART_RTS,
    input  UART_RXD,
    output UART_TXD,
    output UART_DTR,
    input  UART_DSR,

    // Open-drain User port.
    // 0 - D+/RX
    // 1 - D-/TX
    // 2..6 - USR2..USR6
    // Set USER_OUT to 1 to read from USER_IN.
    input  [6:0] USER_IN,
    output [6:0] USER_OUT,

    input OSD_STATUS
);

  // Tie pins not being used
  assign ADC_BUS = 'Z;
  assign USER_OUT = '1;
  assign {UART_RTS, UART_TXD, UART_DTR} = 0;
  assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
  assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = '0;

  // Default values for ports not used in this core
  assign VGA_SL = 0;
  assign VGA_F1 = 0;
  assign VGA_SCALER = 0;
  assign VGA_DISABLE = 0;
  assign HDMI_FREEZE = 0;

  assign AUDIO_MIX = 0;

  assign LED_DISK = 0;
  assign LED_POWER = 0;
  assign LED_USER = 0;
  assign BUTTONS = 0;

  ////////////////////////////////////////////////////////////////////////////////////////
  // Config string

  assign VIDEO_ARX = 13'd1;
  assign VIDEO_ARY = 13'd1;

  `include "build_id.vh"

  localparam CONF_STR = {
    "Game and Watch;;",
    "FS0,gnw,Load ROM;",
    "-;",
    "O[1],Accurate LCD Timing,Off,On;",
    "-;",
    "-;",
    // Close OSD after reset
    "R[0],Reset;",

    "J1,Btn 1/R Joy Down,Btn 2/R Joy Right,Btn 3/R Joy Left,Btn 4/R Joy Up,Time,Alarm,Game A,Game B;",
    // As much as I hate this, buttons are flipped due to wanting J1 to be in the correct order when reconfiguring inputs
    "jn,B,A,Y,X,L,R,Select,Start;",

    "v,0;", // Config version should be used to reset options to default values on first start if CONF_STR has changed in an incompatible way [Values: 0-99].
    "V,v",
    `BUILD_DATE
  };

  ////////////////////////////////////////////////////////////////////////////////////////
  // PLL

  wire clk_sys_131_072;
  wire clk_vid_32_768;

  wire pll_core_locked;

  pll pll_core (
      .refclk  (CLK_50M),
      .rst     (0),
      .outclk_0(clk_sys_131_072),
      .outclk_1(clk_vid_32_768),
      .locked  (pll_core_locked)
  );

  ////////////////////////////////////////////////////////////////////////////////////////
  // HPS (Hard Processor System)

  wire [127:0] status;
  wire [  1:0] buttons;

  // HPS <=> FPGA - Downloads/Upload
  wire         ioctl_download;
  wire         ioctl_upload;
  wire         ioctl_upload_req;
  wire [  7:0] ioctl_index;
  wire         ioctl_wr;
  wire [ 24:0] ioctl_addr;
  wire [ 15:0] ioctl_dout;
  wire [ 15:0] ioctl_din;

  // Inputs
  wire [ 10:0] ps2_key;
  wire [ 15:0] joystick_0;

  hps_io #(
      .CONF_STR(CONF_STR),
      // Use 16 bit ioctl
      .WIDE(1)
  ) hps_io (
      .clk_sys(clk_sys_131_072),
      .HPS_BUS(HPS_BUS),

      .buttons(buttons),
      .status (status),

      .ioctl_upload    (ioctl_upload),
      .ioctl_upload_req(ioctl_upload_req),
      .ioctl_download  (ioctl_download),
      .ioctl_wr        (ioctl_wr),
      .ioctl_addr      (ioctl_addr),
      .ioctl_dout      (ioctl_dout),
      .ioctl_din       (ioctl_din),
      .ioctl_index     (ioctl_index),

      .ps2_key(ps2_key),

      .joystick_0(joystick_0)
  );

  ////////////////////////////////////////////////////////////////////////////////////////
  // Settings
  wire external_reset = status[0];
  wire accurate_lcd_timing = status[1];

  ////////////////////////////////////////////////////////////////////////////////////////
  // Core

  reg has_rom = 0;

  reg prev_ioctl_download = 0;

  // Hold core in reset (to blank video) when there is no ROM
  always @(posedge clk_sys_131_072) begin
    prev_ioctl_download <= ioctl_download;

    if (~ioctl_download && prev_ioctl_download) begin
      has_rom <= 1;
    end
  end

  wire sound;

  gameandwatch gameandwatch (
      .clk_sys_131_072(clk_sys_131_072),
      .clk_vid_32_768 (clk_vid_32_768),

      .reset(RESET || ~has_rom || external_reset || buttons[1]),
      .pll_core_locked(pll_core_locked),

      // Input
      .button_a(joystick_0[5]),
      .button_b(joystick_0[4]),
      .button_x(joystick_0[7]),
      .button_y(joystick_0[6]),
      .button_trig_l(joystick_0[8]),
      .button_trig_r(joystick_0[9]),
      .button_start(joystick_0[11]),
      .button_select(joystick_0[10]),
      .dpad_up(joystick_0[3]),
      .dpad_down(joystick_0[2]),
      .dpad_left(joystick_0[1]),
      .dpad_right(joystick_0[0]),

      // Data in
      .ioctl_download(ioctl_download),
      .ioctl_wr(ioctl_wr),
      // Convert to word addresses
      .ioctl_addr({1'b0, ioctl_addr[24:1]}),
      .ioctl_dout(ioctl_dout),

      // Video
      .hsync(hsync),
      .vsync(vsync),

      .de (de),
      .rgb(rgb),

      .sound(sound),

      // Settings
      .accurate_lcd_timing(accurate_lcd_timing),

      // SDRAM
      .SDRAM_A(SDRAM_A),
      .SDRAM_BA(SDRAM_BA),
      .SDRAM_DQ(SDRAM_DQ),
      .SDRAM_DQM({SDRAM_DQMH, SDRAM_DQML}),
      .SDRAM_CLK(SDRAM_CLK),
      .SDRAM_CKE(SDRAM_CKE),
      //   .SDRAM_nCS(),
      .SDRAM_nRAS(SDRAM_nRAS),
      .SDRAM_nCAS(SDRAM_nCAS),
      .SDRAM_nWE(SDRAM_nWE)
  );

  assign SDRAM_nCS = 0;

  ////////////////////////////////////////////////////////////////////////////////////////
  // Video

  wire vsync;
  wire hsync;
  wire de;
  wire [23:0] rgb;

  assign CLK_VIDEO = clk_vid_32_768;
  assign VGA_DE = de;
  assign CE_PIXEL = 1;
  assign VGA_HS = hsync;
  assign VGA_VS = vsync;
  assign VGA_R = rgb[23:16];
  assign VGA_G = rgb[15:8];
  assign VGA_B = rgb[7:0];

  ////////////////////////////////////////////////////////////////////////////////////////
  // Audio

  assign AUDIO_S = 0;
  assign AUDIO_L = {2'b0, {14{sound}}};
  assign AUDIO_R = AUDIO_L;

endmodule
