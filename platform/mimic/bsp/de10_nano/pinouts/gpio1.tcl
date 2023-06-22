# ==============================================================================
# SPDX-License-Identifier: CC0-1.0
# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (c) 2022, OpenGateware authors and contributors
# ==============================================================================
# DE10-Nano GPIO 1
# ==============================================================================
post_message "Framework: Loading GPIO 1 pinout"

# ==============================================================================
if {$ENABLE_2ND_SDRAM eq "OFF"} {
    post_message "Framework: Analog I/O enabled"
    # ===========================================================================
    # SDIO
    # ===========================================================================
    set_location_assignment PIN_AF25 -to SDIO_DAT[0] ;#GPIO_1[13]
    set_location_assignment PIN_AF23 -to SDIO_DAT[1] ;#GPIO_1[15]
    set_location_assignment PIN_AD26 -to SDIO_DAT[2] ;#GPIO_1[3]
    set_location_assignment PIN_AF28 -to SDIO_DAT[3] ;#GPIO_1[5]
    set_location_assignment PIN_AF27 -to SDIO_CMD    ;#GPIO_1[7]
    set_location_assignment PIN_AH26 -to SDIO_CLK    ;#GPIO_1[11]

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

    # ===========================================================================
    # VGA
    # ===========================================================================
    set_location_assignment PIN_AE17 -to VGA_R[0] ;#GPIO_1[35]
    set_location_assignment PIN_AE20 -to VGA_R[1] ;#GPIO_1[33]
    set_location_assignment PIN_AF20 -to VGA_R[2] ;#GPIO_1[31]
    set_location_assignment PIN_AH18 -to VGA_R[3] ;#GPIO_1[29]
    set_location_assignment PIN_AH19 -to VGA_R[4] ;#GPIO_1[27]
    set_location_assignment PIN_AF21 -to VGA_R[5] ;#GPIO_1[25]

    set_location_assignment PIN_AE19 -to VGA_G[0] ;#GPIO_1[34]
    set_location_assignment PIN_AG15 -to VGA_G[1] ;#GPIO_1[32]
    set_location_assignment PIN_AF18 -to VGA_G[2] ;#GPIO_1[30]
    set_location_assignment PIN_AG18 -to VGA_G[3] ;#GPIO_1[28]
    set_location_assignment PIN_AG19 -to VGA_G[4] ;#GPIO_1[26]
    set_location_assignment PIN_AG20 -to VGA_G[5] ;#GPIO_1[24]

    set_location_assignment PIN_AG21 -to VGA_B[0] ;#GPIO_1[19]
    set_location_assignment PIN_AA20 -to VGA_B[1] ;#GPIO_1[21]
    set_location_assignment PIN_AE22 -to VGA_B[2] ;#GPIO_1[23]
    set_location_assignment PIN_AF22 -to VGA_B[3] ;#GPIO_1[22]
    set_location_assignment PIN_AH23 -to VGA_B[4] ;#GPIO_1[20]
    set_location_assignment PIN_AH21 -to VGA_B[5] ;#GPIO_1[18]

    set_location_assignment PIN_AH22 -to VGA_HS   ;#GPIO_1[17]
    set_location_assignment PIN_AG24 -to VGA_VS   ;#GPIO_1[16]
    set_location_assignment PIN_AH27 -to VGA_EN   ;#GPIO_1[9]

    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_R[0]
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_R[1]
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_R[2]
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_R[3]
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_R[4]
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_R[5]
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_G[0]
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_G[1]
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_G[2]
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_G[3]
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_G[4]
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_G[5]
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_B[0]
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_B[1]
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_B[2]
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_B[3]
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_B[4]
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_B[5]
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_HS
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_VS
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_EN

    set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to VGA_R[0]
    set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to VGA_R[1]
    set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to VGA_R[2]
    set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to VGA_R[3]
    set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to VGA_R[4]
    set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to VGA_R[5]
    set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to VGA_G[0]
    set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to VGA_G[1]
    set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to VGA_G[2]
    set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to VGA_G[3]
    set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to VGA_G[4]
    set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to VGA_G[5]
    set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to VGA_B[0]
    set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to VGA_B[1]
    set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to VGA_B[2]
    set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to VGA_B[3]
    set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to VGA_B[4]
    set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to VGA_B[5]
    set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to VGA_HS
    set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to VGA_VS
    set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to VGA_EN

    set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to VGA_EN

    # ==========================================================================
    # AUDIO
    # ==========================================================================
    set_location_assignment PIN_AC24 -to AUDIO_L     ;#GPIO_1[1]
    set_location_assignment PIN_AE25 -to AUDIO_R     ;#GPIO_1[6]
    set_location_assignment PIN_AG26 -to AUDIO_SPDIF ;#GPIO_1[8]

    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to AUDIO_L
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to AUDIO_R
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to AUDIO_SPDIF

    set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to AUDIO_L
    set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to AUDIO_R
    set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to AUDIO_SPDIF

    # ==========================================================================
    # LEDs
    # ==========================================================================
    set_location_assignment PIN_Y15  -to LED_USER  ;#GPIO_1[0]
    set_location_assignment PIN_AA15 -to LED_HDD   ;#GPIO_1[2]
    set_location_assignment PIN_AG28 -to LED_POWER ;#GPIO_1[4]

    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LED_USER
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LED_HDD
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LED_POWER

    # ==========================================================================
    # Buttons
    # ==========================================================================
    set_location_assignment PIN_AH24 -to BTN_USER  ;#GPIO_1[12]
    set_location_assignment PIN_AG25 -to BTN_OSD   ;#GPIO_1[10]
    set_location_assignment PIN_AG23 -to BTN_RESET ;#GPIO_1[14]

    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to BTN_USER
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to BTN_OSD
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to BTN_RESET

    set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to BTN_USER
    set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to BTN_OSD
    set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to BTN_RESET

} else {
    post_message "Framework: Second SDRAM enabled, analog output will be disabled"
    # ==============================================================================
    # Secondary SDRAM
    # ==============================================================================
    set_location_assignment PIN_AG15 -to SDRAM2_A[0]   ;#GPIO_1[32]
    set_location_assignment PIN_AE20 -to SDRAM2_A[1]   ;#GPIO_1[33]
    set_location_assignment PIN_AE19 -to SDRAM2_A[2]   ;#GPIO_1[34]
    set_location_assignment PIN_AE17 -to SDRAM2_A[3]   ;#GPIO_1[35]
    set_location_assignment PIN_AF21 -to SDRAM2_A[4]   ;#GPIO_1[25]
    set_location_assignment PIN_AF22 -to SDRAM2_A[5]   ;#GPIO_1[22]
    set_location_assignment PIN_AE22 -to SDRAM2_A[6]   ;#GPIO_1[23]
    set_location_assignment PIN_AH23 -to SDRAM2_A[7]   ;#GPIO_1[20]
    set_location_assignment PIN_AA20 -to SDRAM2_A[8]   ;#GPIO_1[21]
    set_location_assignment PIN_AH21 -to SDRAM2_A[9]   ;#GPIO_1[18]
    set_location_assignment PIN_AF20 -to SDRAM2_A[10]  ;#GPIO_1[31]
    set_location_assignment PIN_AG21 -to SDRAM2_A[11]  ;#GPIO_1[19]
    set_location_assignment PIN_AG24 -to SDRAM2_A[12]  ;#GPIO_1[16]

    set_location_assignment PIN_AH18 -to SDRAM2_BA[0]  ;#GPIO_1[29]
    set_location_assignment PIN_AF18 -to SDRAM2_BA[1]  ;#GPIO_1[30]

    set_location_assignment PIN_Y15  -to SDRAM2_DQ[0]  ;#GPIO_1[0]
    set_location_assignment PIN_AC24 -to SDRAM2_DQ[1]  ;#GPIO_1[1]
    set_location_assignment PIN_AA15 -to SDRAM2_DQ[2]  ;#GPIO_1[2]
    set_location_assignment PIN_AD26 -to SDRAM2_DQ[3]  ;#GPIO_1[3]
    set_location_assignment PIN_AG28 -to SDRAM2_DQ[4]  ;#GPIO_1[4]
    set_location_assignment PIN_AF28 -to SDRAM2_DQ[5]  ;#GPIO_1[5]
    set_location_assignment PIN_AE25 -to SDRAM2_DQ[6]  ;#GPIO_1[6]
    set_location_assignment PIN_AF27 -to SDRAM2_DQ[7]  ;#GPIO_1[7]
    set_location_assignment PIN_AF23 -to SDRAM2_DQ[8]  ;#GPIO_1[15]
    set_location_assignment PIN_AG23 -to SDRAM2_DQ[9]  ;#GPIO_1[14]
    set_location_assignment PIN_AF25 -to SDRAM2_DQ[10] ;#GPIO_1[13]
    set_location_assignment PIN_AH24 -to SDRAM2_DQ[11] ;#GPIO_1[12]
    set_location_assignment PIN_AH26 -to SDRAM2_DQ[12] ;#GPIO_1[11]
    set_location_assignment PIN_AG25 -to SDRAM2_DQ[13] ;#GPIO_1[10]
    set_location_assignment PIN_AG26 -to SDRAM2_DQ[14] ;#GPIO_1[8]
    set_location_assignment PIN_AH27 -to SDRAM2_DQ[15] ;#GPIO_1[9]

    set_location_assignment PIN_AH22 -to SDRAM2_CLK    ;#GPIO_1[17]
    set_location_assignment PIN_AG20 -to SDRAM2_nWE    ;#GPIO_1[24]
    set_location_assignment PIN_AG19 -to SDRAM2_nCAS   ;#GPIO_1[26]
    set_location_assignment PIN_AG18 -to SDRAM2_nCS    ;#GPIO_1[28]
    set_location_assignment PIN_AH19 -to SDRAM2_nRAS   ;#GPIO_1[27]

    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM2_A[0]
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM2_A[1]
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM2_A[2]
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM2_A[3]
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM2_A[4]
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM2_A[5]
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM2_A[6]
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM2_A[7]
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM2_A[8]
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM2_A[9]
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM2_A[10]
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM2_A[11]
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM2_A[12]
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM2_BA[0]
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM2_BA[1]
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM2_DQ[0]
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM2_DQ[1]
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM2_DQ[2]
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM2_DQ[3]
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM2_DQ[4]
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM2_DQ[5]
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM2_DQ[6]
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM2_DQ[7]
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM2_DQ[8]
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM2_DQ[9]
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM2_DQ[10]
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM2_DQ[11]
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM2_DQ[12]
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM2_DQ[13]
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM2_DQ[14]
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM2_DQ[15]
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM2_CLK
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM2_nWE
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM2_nCAS
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM2_nCS
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM2_nRAS

    set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM2_A[0]
    set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM2_A[1]
    set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM2_A[2]
    set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM2_A[3]
    set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM2_A[4]
    set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM2_A[5]
    set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM2_A[6]
    set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM2_A[7]
    set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM2_A[8]
    set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM2_A[9]
    set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM2_A[10]
    set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM2_A[11]
    set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM2_A[12]
    set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM2_BA[0]
    set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM2_BA[1]
    set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM2_DQ[0]
    set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM2_DQ[1]
    set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM2_DQ[2]
    set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM2_DQ[3]
    set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM2_DQ[4]
    set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM2_DQ[5]
    set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM2_DQ[6]
    set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM2_DQ[7]
    set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM2_DQ[8]
    set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM2_DQ[9]
    set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM2_DQ[10]
    set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM2_DQ[11]
    set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM2_DQ[12]
    set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM2_DQ[13]
    set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM2_DQ[14]
    set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM2_DQ[15]
    set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM2_CLK
    set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM2_nWE
    set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM2_nCAS
    set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM2_nCS
    set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM2_nRAS
    set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM2_DQML
    set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM2_DQMH
    set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM2_CKE

    set_instance_assignment -name FAST_OUTPUT_REGISTER ON -to SDRAM2_*
    set_instance_assignment -name FAST_INPUT_REGISTER ON -to SDRAM2_DQ[*]
    set_instance_assignment -name FAST_OUTPUT_ENABLE_REGISTER ON -to SDRAM2_DQ[*]
    set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to SDRAM2_DQ[*]
    set_instance_assignment -name ALLOW_SYNCH_CTRL_USAGE OFF -to *|SDRAM2_*
}
