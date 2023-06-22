# ==============================================================================
# Clock Circuitry
# ==============================================================================
set_location_assignment PIN_Y26  -to FPGA_CLK1_50 ;#OSC_50_B5B
set_location_assignment PIN_AA16 -to FPGA_CLK2_50 ;#OSC_50_B4A
set_location_assignment PIN_AF14 -to FPGA_CLK3_50 ;#OSC_50_B3B
set_location_assignment PIN_K14  -to FPGA_CLK4_50 ;#OSC_50_B8A

set_instance_assignment -name IO_STANDARD "2.5 V" -to FPGA_CLK1_50
set_instance_assignment -name IO_STANDARD "1.5 V" -to FPGA_CLK2_50
set_instance_assignment -name IO_STANDARD "1.5 V" -to FPGA_CLK3_50
set_instance_assignment -name IO_STANDARD "2.5 V" -to FPGA_CLK4_50

#============================================================
# Push Buttons
#============================================================
set_location_assignment PIN_AE9  -to KEY[0] ;#BTN_OSD
set_location_assignment PIN_AE12 -to KEY[1] ;#BTN_USER
# set_location_assignment PIN_AD9  -to KEY[2] ;#Reserved
# set_location_assignment PIN_AD11 -to KEY[3] ;#Reserved

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to KEY[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to KEY[1]
# set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to KEY[2]
# set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to KEY[3]

#============================================================
# LED
#============================================================
set_location_assignment PIN_AF10 -to LED_0_USER
set_location_assignment PIN_AD10 -to LED_1_HDD
set_location_assignment PIN_AE11 -to LED_2_POWER
set_location_assignment PIN_AD7  -to LED_3_LOCKED

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LED_0_USER
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LED_1_HDD
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LED_2_POWER
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LED_3_LOCKED

#============================================================
# SW
#============================================================
set_location_assignment PIN_W25  -to SW[0]
set_location_assignment PIN_V25  -to SW[1]
set_location_assignment PIN_AC28 -to SW[2]
set_location_assignment PIN_AC29 -to SW[3]

set_instance_assignment -name IO_STANDARD "2.5 V" -to SW[0]
set_instance_assignment -name IO_STANDARD "2.5 V" -to SW[1]
set_instance_assignment -name IO_STANDARD "2.5 V" -to SW[2]
set_instance_assignment -name IO_STANDARD "2.5 V" -to SW[3]

#============================================================
# VGA
#============================================================
set_location_assignment PIN_AG5  -to VGA_R[0]
set_location_assignment PIN_AA12 -to VGA_R[1]
set_location_assignment PIN_AB12 -to VGA_R[2]
set_location_assignment PIN_AF6  -to VGA_R[3]
set_location_assignment PIN_AG6  -to VGA_R[4]
set_location_assignment PIN_AJ2  -to VGA_R[5]
set_location_assignment PIN_AH5  -to VGA_R[6]
set_location_assignment PIN_AJ1  -to VGA_R[7]

set_location_assignment PIN_Y21  -to VGA_G[0]
set_location_assignment PIN_AA25 -to VGA_G[1]
set_location_assignment PIN_AB26 -to VGA_G[2]
set_location_assignment PIN_AB22 -to VGA_G[3]
set_location_assignment PIN_AB23 -to VGA_G[4]
set_location_assignment PIN_AA24 -to VGA_G[5]
set_location_assignment PIN_AB25 -to VGA_G[6]
set_location_assignment PIN_AE27 -to VGA_G[7]

set_location_assignment PIN_AE28 -to VGA_B[0]
set_location_assignment PIN_Y23  -to VGA_B[1]
set_location_assignment PIN_Y24  -to VGA_B[2]
set_location_assignment PIN_AG28 -to VGA_B[3]
set_location_assignment PIN_AF28 -to VGA_B[4]
set_location_assignment PIN_V23  -to VGA_B[5]
set_location_assignment PIN_W24  -to VGA_B[6]
set_location_assignment PIN_AF29 -to VGA_B[7]

set_location_assignment PIN_AD12 -to VGA_HS
set_location_assignment PIN_AC12 -to VGA_VS

set_location_assignment PIN_AG2  -to VGA_SYNC_N
set_location_assignment PIN_AH3  -to VGA_BLANK_N
set_location_assignment PIN_W20  -to VGA_CLK

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_R[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_R[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_R[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_R[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_R[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_R[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_R[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_R[7]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_G[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_G[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_G[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_G[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_G[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_G[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_G[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_G[7]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_B[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_B[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_B[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_B[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_B[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_B[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_B[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_B[7]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_HS
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_VS
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_SYNC_N
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_BLANK_N
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_CLK

set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to VGA_R[0]
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to VGA_R[1]
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to VGA_R[2]
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to VGA_R[3]
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to VGA_R[4]
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to VGA_R[5]
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to VGA_R[6]
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to VGA_R[7]
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to VGA_G[0]
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to VGA_G[1]
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to VGA_G[2]
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to VGA_G[3]
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to VGA_G[4]
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to VGA_G[5]
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to VGA_G[6]
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to VGA_G[7]
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to VGA_B[0]
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to VGA_B[1]
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to VGA_B[2]
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to VGA_B[3]
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to VGA_B[4]
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to VGA_B[5]
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to VGA_B[6]
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to VGA_B[7]
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to VGA_HS
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to VGA_VS
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to VGA_SYNC_N
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to VGA_BLANK_N
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to VGA_CLK

#============================================================
# Audio
#============================================================
set_location_assignment PIN_AC27 -to AUD_ADCDAT
set_location_assignment PIN_AG30 -to AUD_ADCLRCK
set_location_assignment PIN_AE7  -to AUD_BCLK
set_location_assignment PIN_AG3  -to AUD_DACDAT
set_location_assignment PIN_AH4  -to AUD_DACLRCK
set_location_assignment PIN_AD26 -to AUD_MUTE
set_location_assignment PIN_AC9  -to AUD_XCK
set_location_assignment PIN_AH30 -to AUD_I2C_SCLK
set_location_assignment PIN_AF30 -to AUD_I2C_SDAT

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to AUD_ADCDAT
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to AUD_ADCLRCK
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to AUD_BCLK
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to AUD_DACDAT
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to AUD_DACLRCK
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to AUD_MUTE
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to AUD_XCK
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to AUD_I2C_SCLK
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to AUD_I2C_SDAT

# ==============================================================================
# HPS Peripherals
# ==============================================================================
set_instance_assignment -name HPS_LOCATION HPSINTERFACEPERIPHERALSPIMASTER_X52_Y72_N111 -entity sys_top -to spi
set_instance_assignment -name HPS_LOCATION HPSINTERFACEPERIPHERALUART_X52_Y67_N111 -entity sys_top -to uart

# ==============================================================================
# FPGA DDR3
# ==============================================================================
set_location_assignment PIN_AA14 -to DDR3_CK_p
set_location_assignment PIN_AA15 -to DDR3_CK_n
set_location_assignment PIN_V16  -to DDR3_DQS_p[0]
set_location_assignment PIN_W16  -to DDR3_DQS_n[0]
set_location_assignment PIN_V17  -to DDR3_DQS_p[1]
set_location_assignment PIN_W17  -to DDR3_DQS_n[1]
set_location_assignment PIN_Y17  -to DDR3_DQS_p[2]
set_location_assignment PIN_AA18 -to DDR3_DQS_n[2]
set_location_assignment PIN_AC20 -to DDR3_DQS_p[3]
set_location_assignment PIN_AD19 -to DDR3_DQS_n[3]
set_location_assignment PIN_AJ21 -to DDR3_CKE
set_location_assignment PIN_AB15 -to DDR3_CS_n
set_location_assignment PIN_AK21 -to DDR3_RESET_n
set_location_assignment PIN_AJ6  -to DDR3_WE_n
set_location_assignment PIN_AH8  -to DDR3_RAS_n
set_location_assignment PIN_AH7  -to DDR3_CAS_n
set_location_assignment PIN_AH10 -to DDR3_BA[0]
set_location_assignment PIN_AJ11 -to DDR3_BA[1]
set_location_assignment PIN_AK11 -to DDR3_BA[2]
set_location_assignment PIN_AH17 -to DDR3_DM[0]
set_location_assignment PIN_AG23 -to DDR3_DM[1]
set_location_assignment PIN_AK23 -to DDR3_DM[2]
set_location_assignment PIN_AJ27 -to DDR3_DM[3]
set_location_assignment PIN_AE16 -to DDR3_ODT
set_location_assignment PIN_AG17 -to DDR3_RZQ
set_location_assignment PIN_AF18 -to DDR3_DQ[0]
set_location_assignment PIN_AE17 -to DDR3_DQ[1]
set_location_assignment PIN_AG16 -to DDR3_DQ[2]
set_location_assignment PIN_AF16 -to DDR3_DQ[3]
set_location_assignment PIN_AH20 -to DDR3_DQ[4]
set_location_assignment PIN_AG21 -to DDR3_DQ[5]
set_location_assignment PIN_AJ16 -to DDR3_DQ[6]
set_location_assignment PIN_AH18 -to DDR3_DQ[7]
set_location_assignment PIN_AK18 -to DDR3_DQ[8]
set_location_assignment PIN_AJ17 -to DDR3_DQ[9]
set_location_assignment PIN_AG18 -to DDR3_DQ[10]
set_location_assignment PIN_AK19 -to DDR3_DQ[11]
set_location_assignment PIN_AG20 -to DDR3_DQ[12]
set_location_assignment PIN_AF19 -to DDR3_DQ[13]
set_location_assignment PIN_AJ20 -to DDR3_DQ[14]
set_location_assignment PIN_AH24 -to DDR3_DQ[15]
set_location_assignment PIN_AE19 -to DDR3_DQ[16]
set_location_assignment PIN_AE18 -to DDR3_DQ[17]
set_location_assignment PIN_AG22 -to DDR3_DQ[18]
set_location_assignment PIN_AK22 -to DDR3_DQ[19]
set_location_assignment PIN_AF21 -to DDR3_DQ[20]
set_location_assignment PIN_AF20 -to DDR3_DQ[21]
set_location_assignment PIN_AH23 -to DDR3_DQ[22]
set_location_assignment PIN_AK24 -to DDR3_DQ[23]
set_location_assignment PIN_AF24 -to DDR3_DQ[24]
set_location_assignment PIN_AF23 -to DDR3_DQ[25]
set_location_assignment PIN_AJ24 -to DDR3_DQ[26]
set_location_assignment PIN_AK26 -to DDR3_DQ[27]
set_location_assignment PIN_AE23 -to DDR3_DQ[28]
set_location_assignment PIN_AE22 -to DDR3_DQ[29]
set_location_assignment PIN_AG25 -to DDR3_DQ[30]
set_location_assignment PIN_AK27 -to DDR3_DQ[31]
set_location_assignment PIN_AJ14 -to DDR3_A[0]
set_location_assignment PIN_AK14 -to DDR3_A[1]
set_location_assignment PIN_AH12 -to DDR3_A[2]
set_location_assignment PIN_AJ12 -to DDR3_A[3]
set_location_assignment PIN_AG15 -to DDR3_A[4]
set_location_assignment PIN_AH15 -to DDR3_A[5]
set_location_assignment PIN_AK12 -to DDR3_A[6]
set_location_assignment PIN_AK13 -to DDR3_A[7]
set_location_assignment PIN_AH13 -to DDR3_A[8]
set_location_assignment PIN_AH14 -to DDR3_A[9]
set_location_assignment PIN_AJ9  -to DDR3_A[10]
set_location_assignment PIN_AK9  -to DDR3_A[11]
set_location_assignment PIN_AK7  -to DDR3_A[12]
set_location_assignment PIN_AK8  -to DDR3_A[13]
set_location_assignment PIN_AG12 -to DDR3_A[14]

set_instance_assignment -name IO_STANDARD "Differential 1.5-V SSTL Class I" -to DDR3_CK_p
set_instance_assignment -name IO_STANDARD "Differential 1.5-V SSTL Class I" -to DDR3_CK_n
set_instance_assignment -name IO_STANDARD "Differential 1.5-V SSTL Class I" -to DDR3_DQS_p[0]
set_instance_assignment -name IO_STANDARD "Differential 1.5-V SSTL Class I" -to DDR3_DQS_n[0]
set_instance_assignment -name IO_STANDARD "Differential 1.5-V SSTL Class I" -to DDR3_DQS_p[1]
set_instance_assignment -name IO_STANDARD "Differential 1.5-V SSTL Class I" -to DDR3_DQS_n[1]
set_instance_assignment -name IO_STANDARD "Differential 1.5-V SSTL Class I" -to DDR3_DQS_p[2]
set_instance_assignment -name IO_STANDARD "Differential 1.5-V SSTL Class I" -to DDR3_DQS_n[2]
set_instance_assignment -name IO_STANDARD "Differential 1.5-V SSTL Class I" -to DDR3_DQS_p[3]
set_instance_assignment -name IO_STANDARD "Differential 1.5-V SSTL Class I" -to DDR3_DQS_n[3]
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_CKE
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_CS_n
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_RESET_n
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_WE_n
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_RAS_n
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_CAS_n
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_BA[0]
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_BA[1]
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_BA[2]
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_DM[0]
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_DM[1]
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_DM[2]
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_DM[3]
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_ODT
set_instance_assignment -name IO_STANDARD "1.5 V" -to DDR3_RZQ
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_DQ[0]
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_DQ[1]
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_DQ[2]
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_DQ[3]
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_DQ[4]
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_DQ[5]
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_DQ[6]
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_DQ[7]
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_DQ[8]
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_DQ[9]
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_DQ[10]
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_DQ[11]
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_DQ[12]
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_DQ[13]
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_DQ[14]
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_DQ[15]
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_DQ[16]
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_DQ[17]
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_DQ[18]
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_DQ[19]
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_DQ[20]
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_DQ[21]
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_DQ[22]
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_DQ[23]
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_DQ[24]
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_DQ[25]
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_DQ[26]
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_DQ[27]
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_DQ[28]
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_DQ[29]
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_DQ[30]
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_DQ[31]
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_A[0]
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_A[1]
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_A[2]
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_A[3]
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_A[4]
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_A[5]
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_A[6]
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_A[7]
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_A[8]
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_A[9]
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_A[10]
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_A[11]
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_A[12]
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_A[13]
set_instance_assignment -name IO_STANDARD "SSTL-15 Class I" -to DDR3_A[14]
