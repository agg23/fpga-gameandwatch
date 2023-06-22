        //! Port substitutions for DE10-Standard, DE1-SoC and Arrow SoCkit
        //! CLOCK
        input  wire        FPGA_CLK1_50,
        input  wire        FPGA_CLK2_50,
        input  wire        FPGA_CLK3_50,

        //! SDRAM
        output wire [12:0] SDRAM_A,
        inout  wire [15:0] SDRAM_DQ,
        output wire        SDRAM_DQML,
        output wire        SDRAM_DQMH,
        output wire        SDRAM_nWE,
        output wire        SDRAM_nCAS,
        output wire        SDRAM_nRAS,
        output wire        SDRAM_nCS,
        output wire  [1:0] SDRAM_BA,
        output wire        SDRAM_CLK,
        output wire        SDRAM_CKE,

`ifdef NSX_ENABLE_FPGA_DDR3
        //! FPGA DDR3
        output wire [14:0] DDR3_A,
        output wire  [2:0] DDR3_BA,
        output wire        DDR3_CAS_n,
        output wire        DDR3_CKE,
        output wire        DDR3_CK_n,
        output wire        DDR3_CK_p,
        output wire        DDR3_CS_n,
        output wire  [3:0] DDR3_DM,
        inout  wire [31:0] DDR3_DQ,
        inout  wire  [3:0] DDR3_DQS_n,
        inout  wire  [3:0] DDR3_DQS_p,
        output wire        DDR3_ODT,
        output wire        DDR3_RAS_n,
        output wire        DDR3_RESET_n,
        input  wire        DDR3_RZQ,
        output wire        DDR3_WE_n,
`endif

`ifdef NSX_ENABLE_2ND_SDRAM
        //! SDRAM #2
        output wire [12:0] SDRAM2_A,
        inout  wire [15:0] SDRAM2_DQ,
        output wire        SDRAM2_nWE,
        output wire        SDRAM2_nCAS,
        output wire        SDRAM2_nRAS,
        output wire        SDRAM2_nCS,
        output wire  [1:0] SDRAM2_BA,
        output wire        SDRAM2_CLK,
`else
        //! 8-Bit VGA DAC (DE10-Standard, DE1-SoC and Arrow SoCkit)
        output wire  [7:0] VGA_R,
        output wire  [7:0] VGA_G,
        output wire  [7:0] VGA_B,
        inout  wire        VGA_HS, // VGA_HS is secondary SD card detect when VGA_EN = 1 (inactive)
        output wire        VGA_VS,
        output wire        VGA_CLK,
        output wire        VGA_BLANK_N,
        output wire        VGA_SYNC_N,

        //! AUDIO
        output wire        AUDIO_L,
        output wire        AUDIO_R,
        output wire        AUDIO_SPDIF,

        //! AUDIO CODEC (DE10-Standard, DE1-SoC and Arrow SoCkit)
        inout  wire        AUD_ADCLRCK,  // ADC LR Clock
        input  wire        AUD_ADCDAT,   // ADC Data
        inout  wire        AUD_DACLRCK,  // DAC LR Clock
        output wire        AUD_DACDAT,   // DAC Data
        inout  wire        AUD_BCLK,     // Bit-Stream Clock
        output wire        AUD_XCK,      // Chip Clock
        output wire        AUD_MUTE,     // Mute (active low)
        inout  wire        AUD_I2C_SDAT, // I2C Audio Data
        output wire        AUD_I2C_SCLK, // I2C Audio Clock

        //! SDIO
        inout  wire  [3:0] SDIO_DAT,
        inout  wire        SDIO_CMD,
        output wire        SDIO_CLK,

        //! I/O
        output wire        LED_USER,
        output wire        LED_HDD,
        output wire        LED_POWER,
        input  wire        BTN_USER,
        input  wire        BTN_OSD,
        input  wire        BTN_RESET,
`endif

        //! I/O ALT (SD SPI on SDIO)
        inout  wire        SDCD_SPDIF,
        output wire        IO_SCL,
        inout  wire        IO_SDA,

        //! MB KEY
        input  wire  [1:0] KEY,

        //! MB SWITCH
        inout  wire  [3:0] SW,

        //! MB LED (DE10-Standard, DE1-SoC and Arrow SoCkit)
        output wire        LED_0_USER,
        output wire        LED_1_HDD,
        output wire        LED_2_POWER,
        output wire        LED_3_LOCKED,

        //! USER IO
        inout  wire  [6:0] USER_IO