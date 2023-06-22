        //! Dummy Wires for usage with DataStorm DAQ
        wire        FPGA_CLK1_50;
        wire        FPGA_CLK2_50;
        wire        FPGA_CLK3_50;
        //! SDRAM
        wire [12:0] SDRAM_A;
        wire [15:0] SDRAM_DQ;
        wire        SDRAM_DQML;
        wire        SDRAM_DQMH;
        wire        SDRAM_nWE;
        wire        SDRAM_nCAS;
        wire        SDRAM_nRAS;
        wire        SDRAM_nCS;
        wire  [1:0] SDRAM_BA;
        wire        SDRAM_CLK;
        wire        SDRAM_CKE;

`ifdef NSX_ENABLE_2ND_SDRAM
        //! SDRAM #2
        wire [12:0] SDRAM2_A;
        wire [15:0] SDRAM2_DQ;
        wire        SDRAM2_nWE;
        wire        SDRAM2_nCAS;
        wire        SDRAM2_nRAS;
        wire        SDRAM2_nCS;
        wire  [1:0] SDRAM2_BA;
        wire        SDRAM2_CLK;
`else
        //! 8-Bit VGA DAC (DE10-Standard; DE1-SoC and Arrow SoCkit)
        wire  [5:0] VGA_R;
        wire  [5:0] VGA_G;
        wire  [5:0] VGA_B;
        wire        VGA_HS; // VGA_HS is secondary SD card detect when VGA_EN = 1 (inactive)
        wire        VGA_VS;
        wire        VGA_CLK;
        wire        VGA_BLANK_N;
        wire        VGA_SYNC_N;

        //! AUDIO
        wire        AUDIO_L;
        wire        AUDIO_R;
        wire        AUDIO_SPDIF;

        //! SDIO
        wire  [3:0] SDIO_DAT;
        wire        SDIO_CMD;
        wire        SDIO_CLK;

        //! I/O
        wire        LED_USER;
        wire        LED_HDD;
        wire        LED_POWER;
        wire        BTN_USER  = 1;
        wire        BTN_OSD   = 1;
        wire        BTN_RESET = 1;
`endif

        //! I/O ALT (SD SPI on SDIO)
        wire        SDCD_SPDIF;
        wire        IO_SCL;
        wire        IO_SDA;

        //! MB KEY
        wire  [1:0] KEY;

        //! VGA
        wire        VGA_EN;

        //! ADC
        wire        ADC_SCK;
        wire        ADC_SDO;
        wire        ADC_SDI;
        wire        ADC_CONVST;

        //! I/O ALT
        wire        SD_SPI_CS;
        wire        SD_SPI_MISO;
        wire        SD_SPI_CLK;
        wire        SD_SPI_MOSI;

        //! MB SWITCH
        wire  [3:0] SW = 3'b1111;

        //! MB LED
        wire  [7:0] LED;

        //! USER IO
        wire  [6:0] USER_IO;


        wire        CLK_OSC;

        clk_osc cv_osc (.clkout(CLK_OSC),.oscena(1));

        assign FPGA_CLK1_50 = CLK_OSC;
        assign FPGA_CLK2_50 = CLK_OSC;
        assign FPGA_CLK3_50 = CLK_OSC;