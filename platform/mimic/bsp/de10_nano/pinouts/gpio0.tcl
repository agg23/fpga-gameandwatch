# ==============================================================================
# SPDX-License-Identifier: CC0-1.0
# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (c) 2022, OpenGateware authors and contributors
# ==============================================================================
# DE10-Nano GPIO 0
# ==============================================================================
post_message "Framework: Loading GPIO 0 pinout"

# ==============================================================================
# SDRAM
# ==============================================================================
set_location_assignment PIN_Y11  -to SDRAM_A[0]   ;#GPIO_0[32]
set_location_assignment PIN_AA26 -to SDRAM_A[1]   ;#GPIO_0[33]
set_location_assignment PIN_AA13 -to SDRAM_A[2]   ;#GPIO_0[34]
set_location_assignment PIN_AA11 -to SDRAM_A[3]   ;#GPIO_0[35]
set_location_assignment PIN_W11  -to SDRAM_A[4]   ;#GPIO_0[25]
set_location_assignment PIN_Y19  -to SDRAM_A[5]   ;#GPIO_0[22]
set_location_assignment PIN_AB23 -to SDRAM_A[6]   ;#GPIO_0[23]
set_location_assignment PIN_AC23 -to SDRAM_A[7]   ;#GPIO_0[20]
set_location_assignment PIN_AC22 -to SDRAM_A[8]   ;#GPIO_0[21]
set_location_assignment PIN_C12  -to SDRAM_A[9]   ;#GPIO_0[18]
set_location_assignment PIN_AB26 -to SDRAM_A[10]  ;#GPIO_0[31]
set_location_assignment PIN_AD17 -to SDRAM_A[11]  ;#GPIO_0[19]
set_location_assignment PIN_D12  -to SDRAM_A[12]  ;#GPIO_0[16]

set_location_assignment PIN_Y17  -to SDRAM_BA[0]  ;#GPIO_0[29]
set_location_assignment PIN_AB25 -to SDRAM_BA[1]  ;#GPIO_0[30]

set_location_assignment PIN_E8   -to SDRAM_DQ[0]  ;#GPIO_0[1]
set_location_assignment PIN_V12  -to SDRAM_DQ[1]  ;#GPIO_0[0]
set_location_assignment PIN_D11  -to SDRAM_DQ[2]  ;#GPIO_0[3]
set_location_assignment PIN_W12  -to SDRAM_DQ[3]  ;#GPIO_0[2]
set_location_assignment PIN_AH13 -to SDRAM_DQ[4]  ;#GPIO_0[5]
set_location_assignment PIN_D8   -to SDRAM_DQ[5]  ;#GPIO_0[4]
set_location_assignment PIN_AH14 -to SDRAM_DQ[6]  ;#GPIO_0[7]
set_location_assignment PIN_AF7  -to SDRAM_DQ[7]  ;#GPIO_0[6]
set_location_assignment PIN_AE24 -to SDRAM_DQ[8]  ;#GPIO_0[15]
set_location_assignment PIN_AD23 -to SDRAM_DQ[9]  ;#GPIO_0[14]
set_location_assignment PIN_AE6  -to SDRAM_DQ[10] ;#GPIO_0[13]
set_location_assignment PIN_AE23 -to SDRAM_DQ[11] ;#GPIO_0[12]
set_location_assignment PIN_AG14 -to SDRAM_DQ[12] ;#GPIO_0[11]
set_location_assignment PIN_AD5  -to SDRAM_DQ[13] ;#GPIO_0[10]
set_location_assignment PIN_AF4  -to SDRAM_DQ[14] ;#GPIO_0[8]
set_location_assignment PIN_AH3  -to SDRAM_DQ[15] ;#GPIO_0[9]

set_location_assignment PIN_AD20 -to SDRAM_CLK    ;#GPIO_0[17]
set_location_assignment PIN_AA19 -to SDRAM_nWE    ;#GPIO_0[24]
set_location_assignment PIN_AA18 -to SDRAM_nCAS   ;#GPIO_0[26]
set_location_assignment PIN_Y18  -to SDRAM_nCS    ;#GPIO_0[28]
set_location_assignment PIN_W14  -to SDRAM_nRAS   ;#GPIO_0[27]

# Pins not used on newer SDRAM Modules
set_location_assignment PIN_AG13 -to SDRAM_DQML   ;#ARDUINO_IO[0]
set_location_assignment PIN_AF13 -to SDRAM_DQMH   ;#ARDUINO_IO[5]
set_location_assignment PIN_AG10 -to SDRAM_CKE    ;#ARDUINO_IO[2]

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_A[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_A[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_A[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_A[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_A[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_A[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_A[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_A[7]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_A[8]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_A[9]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_A[10]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_A[11]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_A[12]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_BA[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_BA[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_DQ[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_DQ[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_DQ[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_DQ[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_DQ[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_DQ[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_DQ[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_DQ[7]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_DQ[8]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_DQ[9]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_DQ[10]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_DQ[11]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_DQ[12]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_DQ[13]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_DQ[14]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_DQ[15]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_CLK
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_nWE
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_nCAS
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_nCS
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_nRAS
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_DQML
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_DQMH
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_CKE

set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM_A[0]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM_A[1]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM_A[2]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM_A[3]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM_A[4]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM_A[5]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM_A[6]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM_A[7]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM_A[8]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM_A[9]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM_A[10]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM_A[11]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM_A[12]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM_BA[0]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM_BA[1]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM_DQ[0]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM_DQ[1]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM_DQ[2]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM_DQ[3]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM_DQ[4]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM_DQ[5]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM_DQ[6]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM_DQ[7]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM_DQ[8]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM_DQ[9]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM_DQ[10]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM_DQ[11]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM_DQ[12]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM_DQ[13]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM_DQ[14]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM_DQ[15]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM_CLK
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM_nWE
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM_nCAS
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM_nCS
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM_nRAS
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM_DQML
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM_DQMH
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM_CKE

set_instance_assignment -name FAST_INPUT_REGISTER ON -to SDRAM_DQ[*]
set_instance_assignment -name FAST_OUTPUT_REGISTER ON -to SDRAM_*
set_instance_assignment -name FAST_OUTPUT_ENABLE_REGISTER ON -to SDRAM_DQ[*]
set_instance_assignment -name ALLOW_SYNCH_CTRL_USAGE OFF -to *|SDRAM_*
