        //! Port substitutions for Chameleon 96
        //! HDMI
        output wire        HDMI_I2C_SCL,
        inout  wire        HDMI_I2C_SDA,

        output wire        HDMI_MCLK,
        output wire        HDMI_SCLK,
        output wire        HDMI_LRCLK,
        output wire        HDMI_I2S,

        output wire        HDMI_TX_CLK,
        output wire        HDMI_TX_DE,
        output wire [23:0] HDMI_TX_D,
        output wire        HDMI_TX_HS,
        output wire        HDMI_TX_VS,

        input  wire        HDMI_TX_INT
