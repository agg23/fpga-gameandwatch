# ==============================================================================
# SPDX-License-Identifier: CC0-1.0
# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (c) 2022, OpenGateware authors and contributors
# ==============================================================================
# DE10-Nano System
# ==============================================================================
post_message "Framework: Loading System pinout"

# ==============================================================================
# Clock Circuitry
# ==============================================================================
set_location_assignment PIN_V11 -to FPGA_CLK1_50
set_location_assignment PIN_Y13 -to FPGA_CLK2_50
set_location_assignment PIN_E11 -to FPGA_CLK3_50

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to FPGA_CLK1_50
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to FPGA_CLK2_50
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to FPGA_CLK3_50

# ==============================================================================
# HPS Peripherals
# ==============================================================================
set_instance_assignment -name HPS_LOCATION HPSINTERFACEPERIPHERALSPIMASTER_X52_Y72_N111 -entity sys_top -to spi
set_instance_assignment -name HPS_LOCATION HPSINTERFACEPERIPHERALUART_X52_Y67_N111 -entity sys_top -to uart
set_instance_assignment -name HPS_LOCATION HPSINTERFACEPERIPHERALI2C_X52_Y60_N111 -entity sys_top -to hdmi_i2c

# ==============================================================================
# HDMI
# ==============================================================================
set_location_assignment PIN_U10  -to HDMI_I2C_SCL
set_location_assignment PIN_AA4  -to HDMI_I2C_SDA

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HDMI_I2C_SCL
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HDMI_I2C_SDA
# ------------------------------------------------------------------------------
set_location_assignment PIN_T13  -to HDMI_I2S
set_location_assignment PIN_T11  -to HDMI_LRCLK
set_location_assignment PIN_U11  -to HDMI_MCLK
set_location_assignment PIN_T12  -to HDMI_SCLK

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HDMI_I2S
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HDMI_LRCLK
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HDMI_MCLK
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HDMI_SCLK
# ------------------------------------------------------------------------------
set_location_assignment PIN_AD12 -to HDMI_TX_D[0]
set_location_assignment PIN_AE12 -to HDMI_TX_D[1]
set_location_assignment PIN_W8   -to HDMI_TX_D[2]
set_location_assignment PIN_Y8   -to HDMI_TX_D[3]
set_location_assignment PIN_AD11 -to HDMI_TX_D[4]
set_location_assignment PIN_AD10 -to HDMI_TX_D[5]
set_location_assignment PIN_AE11 -to HDMI_TX_D[6]
set_location_assignment PIN_Y5   -to HDMI_TX_D[7]
set_location_assignment PIN_AF10 -to HDMI_TX_D[8]
set_location_assignment PIN_Y4   -to HDMI_TX_D[9]
set_location_assignment PIN_AE9  -to HDMI_TX_D[10]
set_location_assignment PIN_AB4  -to HDMI_TX_D[11]
set_location_assignment PIN_AE7  -to HDMI_TX_D[12]
set_location_assignment PIN_AF6  -to HDMI_TX_D[13]
set_location_assignment PIN_AF8  -to HDMI_TX_D[14]
set_location_assignment PIN_AF5  -to HDMI_TX_D[15]
set_location_assignment PIN_AE4  -to HDMI_TX_D[16]
set_location_assignment PIN_AH2  -to HDMI_TX_D[17]
set_location_assignment PIN_AH4  -to HDMI_TX_D[18]
set_location_assignment PIN_AH5  -to HDMI_TX_D[19]
set_location_assignment PIN_AH6  -to HDMI_TX_D[20]
set_location_assignment PIN_AG6  -to HDMI_TX_D[21]
set_location_assignment PIN_AF9  -to HDMI_TX_D[22]
set_location_assignment PIN_AE8  -to HDMI_TX_D[23]
set_location_assignment PIN_AG5  -to HDMI_TX_CLK
set_location_assignment PIN_T8   -to HDMI_TX_HS
set_location_assignment PIN_V13  -to HDMI_TX_VS
set_location_assignment PIN_AD19 -to HDMI_TX_DE
set_location_assignment PIN_AF11 -to HDMI_TX_INT

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HDMI_TX_D[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HDMI_TX_D[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HDMI_TX_D[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HDMI_TX_D[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HDMI_TX_D[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HDMI_TX_D[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HDMI_TX_D[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HDMI_TX_D[7]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HDMI_TX_D[8]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HDMI_TX_D[9]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HDMI_TX_D[10]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HDMI_TX_D[11]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HDMI_TX_D[12]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HDMI_TX_D[13]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HDMI_TX_D[14]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HDMI_TX_D[15]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HDMI_TX_D[16]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HDMI_TX_D[17]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HDMI_TX_D[18]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HDMI_TX_D[19]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HDMI_TX_D[20]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HDMI_TX_D[21]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HDMI_TX_D[22]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HDMI_TX_D[23]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HDMI_TX_CLK
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HDMI_TX_HS
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HDMI_TX_VS
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HDMI_TX_DE
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HDMI_TX_INT

set_instance_assignment -name FAST_OUTPUT_REGISTER ON -to HDMI_TX_D[*]
set_instance_assignment -name FAST_OUTPUT_REGISTER ON -to HDMI_TX_CLK
set_instance_assignment -name FAST_OUTPUT_REGISTER ON -to HDMI_TX_HS
set_instance_assignment -name FAST_OUTPUT_REGISTER ON -to HDMI_TX_VS
set_instance_assignment -name FAST_OUTPUT_REGISTER ON -to HDMI_TX_DE

# ==============================================================================
# KEY
# ==============================================================================
set_location_assignment PIN_AH17 -to KEY[0]
set_location_assignment PIN_AH16 -to KEY[1]

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to KEY[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to KEY[1]

# ==============================================================================
# LED
# ==============================================================================
set_location_assignment PIN_W15  -to LED[0]
set_location_assignment PIN_AA24 -to LED[1]
set_location_assignment PIN_V16  -to LED[2]
set_location_assignment PIN_V15  -to LED[3]
set_location_assignment PIN_AF26 -to LED[4]
set_location_assignment PIN_AE26 -to LED[5]
set_location_assignment PIN_Y16  -to LED[6]
set_location_assignment PIN_AA23 -to LED[7]

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LED[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LED[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LED[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LED[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LED[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LED[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LED[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LED[7]

# ==============================================================================
# SW
# ==============================================================================
set_location_assignment PIN_Y24 -to SW[0]
set_location_assignment PIN_W24 -to SW[1]
set_location_assignment PIN_W21 -to SW[2]
set_location_assignment PIN_W20 -to SW[3]

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SW[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SW[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SW[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SW[3]

# ==============================================================================
# ADC
# ==============================================================================
set_location_assignment PIN_U9  -to ADC_CONVST
set_location_assignment PIN_V10 -to ADC_SCK
set_location_assignment PIN_AC4 -to ADC_SDI
set_location_assignment PIN_AD4 -to ADC_SDO

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to ADC_CONVST
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to ADC_SCK
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to ADC_SDI
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to ADC_SDO
