# ==============================================================================
# SPDX-License-Identifier: CC0-1.0
# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (c) 2022, OpenGateware authors and contributors
# ==============================================================================
# HSMC-GPIO 1 [GPIO-HSTC Card - P0033]
# ==============================================================================

# ==============================================================================
# I2C LEDs/Buttons
# ==============================================================================
set_location_assignment PIN_C5  -to IO_SCL ;#GPIO_1[24]
set_location_assignment PIN_J12 -to IO_SDA ;#GPIO_1[25]

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to IO_SCL
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to IO_SDA

set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to IO_SCL
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to IO_SDA

set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to IO_SCL
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to IO_SDA

# ==============================================================================
# USER PORT
# ==============================================================================
set_location_assignment PIN_H7 -to USER_IO[0] ;#GPIO_1[9]
set_location_assignment PIN_D4 -to USER_IO[1] ;#GPIO_1[8]
set_location_assignment PIN_H8 -to USER_IO[2] ;#GPIO_1[7]
set_location_assignment PIN_J7 -to USER_IO[3] ;#GPIO_1[11]
set_location_assignment PIN_E2 -to USER_IO[4] ;#GPIO_1[12]
set_location_assignment PIN_E4 -to USER_IO[5] ;#GPIO_1[10]
set_location_assignment PIN_C3 -to USER_IO[6] ;#GPIO_1[6]

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to USER_IO[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to USER_IO[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to USER_IO[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to USER_IO[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to USER_IO[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to USER_IO[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to USER_IO[6]

set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to USER_IO[0]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to USER_IO[1]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to USER_IO[2]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to USER_IO[3]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to USER_IO[4]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to USER_IO[5]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to USER_IO[6]

set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to USER_IO[0]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to USER_IO[1]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to USER_IO[2]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to USER_IO[3]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to USER_IO[4]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to USER_IO[5]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to USER_IO[6]

# ==============================================================================
# SDIO      (Secondary SD)                 (DE10-nano GPIO 1)
# ==============================================================================
set_location_assignment PIN_K7 -to SDIO_DAT[0] ;#GPIO_1[15]
set_location_assignment PIN_J9 -to SDIO_DAT[1] ;#GPIO_1[17]
set_location_assignment PIN_E7 -to SDIO_DAT[2] ;#GPIO_1[18]
set_location_assignment PIN_K8 -to SDIO_DAT[3] ;#GPIO_1[13]
set_location_assignment PIN_E3 -to SDIO_CMD    ;#GPIO_1[14]
set_location_assignment PIN_E6 -to SDIO_CLK    ;#GPIO_1[16]

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDIO_DAT[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDIO_DAT[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDIO_DAT[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDIO_DAT[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDIO_CMD
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDIO_CLK

set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDIO_DAT[0]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDIO_DAT[1]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDIO_DAT[2]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDIO_DAT[3]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDIO_CMD
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDIO_CLK

set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to SDIO_DAT[0]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to SDIO_DAT[1]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to SDIO_DAT[2]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to SDIO_DAT[3]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to SDIO_CMD

# ==============================================================================
# SDIO_CD or SPDIF_OUT
# ==============================================================================
set_location_assignment PIN_J10 -to SDCD_SPDIF ;#GPIO_1[19]

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDCD_SPDIF
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDCD_SPDIF
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to SDCD_SPDIF

# ==============================================================================
# AUDIO
# ==============================================================================
set_location_assignment PIN_D5  -to AUDIO_L     ;#HSMC_TX_p[4] | GPIO_1[22]
set_location_assignment PIN_G10 -to AUDIO_R     ;#HSMC_RX_p[2] | GPIO_1[23]
set_location_assignment PIN_F10 -to AUDIO_SPDIF ;#HSMC_RX_n[2] | GPIO_1[21]

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to AUDIO_L
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to AUDIO_R
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to AUDIO_SPDIF

set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to AUDIO_L
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to AUDIO_R
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to AUDIO_SPDIF

# ==============================================================================
# I/O #1                                   (DE10-nano GPIO 1)
# ==============================================================================
set_location_assignment PIN_D6  -to LED_USER  ;#HSMC_TX_p[3] | GPIO_1[26]
set_location_assignment PIN_K12 -to LED_HDD   ;#HSMC_RX_p[1] | GPIO_1[27]
set_location_assignment PIN_F6  -to LED_POWER ;#HSMC_TX_n[2] | GPIO_1[28]

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LED_USER
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LED_HDD
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LED_POWER

set_location_assignment PIN_G11  -to BTN_USER  ;#HSMC_RX_n[0] | GPIO_1[29]
set_location_assignment PIN_G7   -to BTN_OSD   ;#HSMC_TX_p[2] | GPIO_1[30]
set_location_assignment PIN_AD27 -to BTN_RESET ;#RESET_n

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to BTN_USER
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to BTN_OSD
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to BTN_RESET

set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to BTN_USER
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to BTN_OSD
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to BTN_RESET

# ==============================================================================
# SPI SD     (Secondary SD)            (DE10-nano Arduino_IO)    [Sockit uses SDIO for 2nd SD card]
# ==============================================================================
# set_location_assignment PIN_AE15 -to SD_SPI_CS
# set_location_assignment PIN_AH8  -to SD_SPI_MISO
# set_location_assignment PIN_AG8  -to SD_SPI_CLK
# set_location_assignment PIN_U13  -to SD_SPI_MOSI
# set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SD_SPI*
# set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SD_SPI*
# set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to SD_SPI*

# HSMC J3 connector pin 25 |            | HSMC_TX_p[4]     | PIN_D5  | AUDIO_L
# HSMC J3 connector pin 26 |            | HSMC_RX_p[2]     | PIN_G10 | AUDIO_R
# HSMC J3 connector pin 24 |            | HSMC_RX_n[2]     | PIN_F10 | AUDIO_SPDIF
# HSMC J3 connector pin 31 |            | HSMC_TX_p[3]     | PIN_D6  | LED_USER
# HSMC J3 connector pin 32 |            | HSMC_RX_p[1]     | PIN_K12 | LED_HDD
# HSMC J3 connector pin 33 |            | HSMC_TX_n[2]     | PIN_F6  | LED_POWER
# HSMC J3 connector pin 27 |            | HSMC_TX_n[3]     | PIN_C5  | IO_SCL
# HSMC J3 connector pin 28 |            | HSMC_RX_n[1]     | PIN_J12 | IO_SDA
# HSMC J3 connector pin 7  | JOY1_B2_P9 | HSMC_TX_p[7]     | PIN_C3  | USER_IO[6] C
# HSMC J3 connector pin 8  | JOY1_B1_P6 | HSMC_RX_p[6]     | PIN_H8  | USER_IO[2] B
# HSMC J3 connector pin 9  | JOY1_UP    | HSMC_TX_n[6]     | PIN_D4  | USER_IO[1]
# HSMC J3 connector pin 10 | JOY1_DOWN  | HSMC_RX_n[5]     | PIN_H7  | USER_IO[0]
# HSMC J3 connector pin 13 | JOY1_LEFT  | HSMC_TX_p[6]     | PIN_E4  | USER_IO[5]
# HSMC J3 connector pin 14 | JOY1_RIGHT | HSMC_RX_p[5]     | PIN_J7  | USER_IO[3]
# HSMC J3 connector pin 15 | JOYX_SEL_O | HSMC_TX_n[5]     | PIN_E2  | USER_IO[4]
# HSMC J3 connector pin 34 |            | HSMC_RX_n[0]     | PIN_G11 | BTN_USER
# HSMC J3 connector pin 35 |            | HSMC_TX_p[2]     | PIN_G7  | BTN_OSD
# HSMC J3 connector pin 36 |            | HSMC_RX_p[0]     | PIN_G12 | provision for a future external reset button
# HSMC J3 connector pin 18 | PMOD3[2]   | HSMC_RX_p[4]     | PIN_K7  | SDIO_DAT[0]
# HSMC J3 connector pin 20 | PMOD3[4]   | HSMC_RX_n[3]     | PIN_J9  | SDIO_DAT[1]
# HSMC J3 connector pin 21 | PMOD3[5]   | HSMC_CLKOUT_p[1] | PIN_E7  | SDIO_DAT[2]
# HSMC J3 connector pin 16 | PMOD3[0]   | HSMC_RX_n[4]     | PIN_K8  | SDIO_DAT[3]
# HSMC J3 connector pin 17 | PMOD3[1]   | HSMC_TX_p[5]     | PIN_E3  | SDIO_CMD
# HSMC J3 connector pin 19 | PMOD3[3]   | HSMC_CLKOUT_n[1] | PIN_E6  | SDIO_CLK
# HSMC J3 connector pin 22 | PMOD3[6]   | HSMC_RX_p[3]     | PIN_J10 | -->  SDCD_SPDIF  (sys.tcl)
# HSMC J3 connector pin 23 | PMOD3[7]   | HSMC_TX_n[4]     | PIN_C4  | -->  not used
# HSMC J3 connector pin 22 | PMOD3[6]   | HSMC_RX_p[3]     | PIN_J10 | SDCD_SPDIF

# SOCKIT KEY4 button (KEY_RESET_n)        PIN_AD27  BTN_RESET