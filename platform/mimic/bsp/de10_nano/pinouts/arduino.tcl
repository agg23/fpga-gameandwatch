# ==============================================================================
# SPDX-License-Identifier: CC0-1.0
# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (c) 2022, OpenGateware authors and contributors
# ==============================================================================
# DE10-Nano Arduino I/O
# ==============================================================================
post_message "Framework: Loading Arduino I/O pinout"

# ==============================================================================
# I2C LEDS/BUTTONS
# ==============================================================================
set_location_assignment PIN_U14 -to IO_SCL ;#ARDUINO_IO[4]
set_location_assignment PIN_AG9 -to IO_SDA ;#ARDUINO_IO[3]

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to IO_SCL
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to IO_SDA

set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to IO_SCL
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to IO_SDA

set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to IO_SCL
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to IO_SDA

# ==============================================================================
# USER PORT
# ==============================================================================
set_location_assignment PIN_AG11 -to USER_IO[0] ;#ARDUINO_IO[15]
set_location_assignment PIN_AH9  -to USER_IO[1] ;#ARDUINO_IO[14]
set_location_assignment PIN_AH12 -to USER_IO[2] ;#ARDUINO_IO[13]
set_location_assignment PIN_AH11 -to USER_IO[3] ;#ARDUINO_IO[12]
set_location_assignment PIN_AG16 -to USER_IO[4] ;#ARDUINO_IO[11]
set_location_assignment PIN_AF15 -to USER_IO[5] ;#ARDUINO_IO[10]
set_location_assignment PIN_AF17 -to USER_IO[6] ;#ARDUINO_IO[8]

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to USER_IO[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to USER_IO[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to USER_IO[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to USER_IO[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to USER_IO[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to USER_IO[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to USER_IO[6]

set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to USER_IO[0]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to USER_IO[1]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to USER_IO[2]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to USER_IO[3]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to USER_IO[4]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to USER_IO[5]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to USER_IO[6]

set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to USER_IO[0]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to USER_IO[1]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to USER_IO[2]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to USER_IO[3]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to USER_IO[4]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to USER_IO[5]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to USER_IO[6]

# ==============================================================================
# SDIO_CD or SPDIF_OUT
# ==============================================================================
set_location_assignment PIN_AH7 -to SDCD_SPDIF ;#ARDUINO_RESET_N

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDCD_SPDIF
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to SDCD_SPDIF
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDCD_SPDIF

# ==============================================================================
# SPI SD
# ==============================================================================
set_location_assignment PIN_AE15 -to SD_SPI_CS   ;#ARDUINO_IO[9]
set_location_assignment PIN_AH8  -to SD_SPI_MISO ;#ARDUINO_IO[7]
set_location_assignment PIN_AG8  -to SD_SPI_CLK  ;#ARDUINO_IO[6]
set_location_assignment PIN_U13  -to SD_SPI_MOSI ;#ARDUINO_IO[5]

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SD_SPI_CS
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SD_SPI_MISO
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SD_SPI_CLK
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SD_SPI_MOSI

set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to SD_SPI_CS
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to SD_SPI_MISO
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to SD_SPI_CLK
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to SD_SPI_MOSI

set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SD_SPI_CS
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SD_SPI_MISO
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SD_SPI_CLK
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SD_SPI_MOSI
