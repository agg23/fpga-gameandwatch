    //! Dummy Wires for usage with DataStorm DAQ
    //! Clock
    wire        FPGA_CLK3_50;

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

    //! I/O
    wire        BTN_USER  = 1;
    wire        BTN_OSD   = 1;
    wire        BTN_RESET = 1;

    //! MB SWITCH
    wire  [3:0] SW = 3'b111;

    //! MB LED
    wire  [7:0] LED;

    //! Clock
    assign FPGA_CLK3_50 = FPGA_CLK1_50;

    //! VGA DAC
    assign VGA_EN = 1'b0; // enable VGA mode when VGA_EN is low
    assign SW[3]  = 1'b0; // necessary for VGA mode