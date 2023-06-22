# ==============================================================================
# SPDX-License-Identifier: CC0-1.0
# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (c) 2022, OpenGateware authors and contributors
# ==============================================================================
# GPIO 0 [GPIO-HSTC Card - P0033]
# ==============================================================================

# ==============================================================================
# SDRAM
# ==============================================================================
set_location_assignment PIN_B1  -to SDRAM_A[0]   ;#GPIO_0[32]
set_location_assignment PIN_C2  -to SDRAM_A[1]   ;#GPIO_0[33]
set_location_assignment PIN_B2  -to SDRAM_A[2]   ;#GPIO_0[34]
set_location_assignment PIN_D2  -to SDRAM_A[3]   ;#GPIO_0[35]
set_location_assignment PIN_D9  -to SDRAM_A[4]   ;#GPIO_0[25]
set_location_assignment PIN_C7  -to SDRAM_A[5]   ;#GPIO_0[22]
set_location_assignment PIN_E12 -to SDRAM_A[6]   ;#GPIO_0[23]
set_location_assignment PIN_B7  -to SDRAM_A[7]   ;#GPIO_0[20]
set_location_assignment PIN_D12 -to SDRAM_A[8]   ;#GPIO_0[21]
set_location_assignment PIN_A11 -to SDRAM_A[9]   ;#GPIO_0[18]
set_location_assignment PIN_B6  -to SDRAM_A[10]  ;#GPIO_0[31]
set_location_assignment PIN_D11 -to SDRAM_A[11]  ;#GPIO_0[19]
set_location_assignment PIN_A10 -to SDRAM_A[12]  ;#GPIO_0[16]
set_location_assignment PIN_B5  -to SDRAM_BA[0]  ;#GPIO_0[29]
set_location_assignment PIN_A4  -to SDRAM_BA[1]  ;#GPIO_0[30]
set_location_assignment PIN_F14 -to SDRAM_DQ[0]  ;#GPIO_0[1]
set_location_assignment PIN_G15 -to SDRAM_DQ[1]  ;#GPIO_0[0]
set_location_assignment PIN_F15 -to SDRAM_DQ[2]  ;#GPIO_0[3]
set_location_assignment PIN_H15 -to SDRAM_DQ[3]  ;#GPIO_0[2]
set_location_assignment PIN_G13 -to SDRAM_DQ[4]  ;#GPIO_0[5]
set_location_assignment PIN_A13 -to SDRAM_DQ[5]  ;#GPIO_0[4]
set_location_assignment PIN_H14 -to SDRAM_DQ[6]  ;#GPIO_0[7]
set_location_assignment PIN_B13 -to SDRAM_DQ[7]  ;#GPIO_0[6]
set_location_assignment PIN_C13 -to SDRAM_DQ[8]  ;#GPIO_0[15]
set_location_assignment PIN_C8  -to SDRAM_DQ[9]  ;#GPIO_0[14]
set_location_assignment PIN_B12 -to SDRAM_DQ[10] ;#GPIO_0[13]
set_location_assignment PIN_B8  -to SDRAM_DQ[11] ;#GPIO_0[12]
set_location_assignment PIN_F13 -to SDRAM_DQ[12] ;#GPIO_0[11]
set_location_assignment PIN_C12 -to SDRAM_DQ[13] ;#GPIO_0[10]
set_location_assignment PIN_B11 -to SDRAM_DQ[14] ;#GPIO_0[8]
set_location_assignment PIN_E13 -to SDRAM_DQ[15] ;#GPIO_0[9]
set_location_assignment PIN_D10 -to SDRAM_CLK    ;#GPIO_0[17]
set_location_assignment PIN_A5  -to SDRAM_nWE    ;#GPIO_0[24]
set_location_assignment PIN_A6  -to SDRAM_nCAS   ;#GPIO_0[26]
set_location_assignment PIN_A3  -to SDRAM_nCS    ;#GPIO_0[28]
set_location_assignment PIN_E9  -to SDRAM_nRAS   ;#GPIO_0[27]

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_*
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM_*
set_instance_assignment -name FAST_OUTPUT_REGISTER ON -to SDRAM_*
set_instance_assignment -name FAST_OUTPUT_ENABLE_REGISTER ON -to SDRAM_DQ[*]
set_instance_assignment -name FAST_INPUT_REGISTER ON -to SDRAM_DQ[*]
set_instance_assignment -name ALLOW_SYNCH_CTRL_USAGE OFF -to *|SDRAM_*

# HSMC J2 connector prototype area
# DQMH/L and CKE are not connected on newer SDRAM modules
set_location_assignment PIN_D1  -to SDRAM_CKE  ;#HSMC_TX_n[8]
set_location_assignment PIN_E1  -to SDRAM_DQMH ;#HSMC_TX_p[8]
set_location_assignment PIN_E11 -to SDRAM_DQML ;#HSMC_RX_n[8]
