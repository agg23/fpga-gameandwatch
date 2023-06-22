# ==============================================================================
# SPDX-License-Identifier: CC0-1.0
# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (c) 2022, OpenGateware authors and contributors
# ==============================================================================

# ==============================================================================
# Parameters Assignments
# ==============================================================================
set FRAMEWORK_ID      "mimic"
set FRAMEWORK_NAME    "MiMiC NSX"
set DEVICE_FAMILY     [get_global_assignment -name FAMILY]
set DEVICE_ID         [get_parameter -name NSX_DEVICE_ID]
set ENABLE_FB         [get_parameter -name NSX_ENABLE_FB]
set ENABLE_FB_PAL     [get_parameter -name NSX_ENABLE_FB_PAL]
set ENABLE_SMALL_VBUF [get_parameter -name NSX_ENABLE_SMALL_VBUF]
set ENABLE_OSD_HEADER [get_parameter -name NSX_ENABLE_OSD_HEADER]
set DISABLE_HDMI      [get_parameter -name NSX_DISABLE_HDMI]
set DISABLE_BILINEAR  [get_parameter -name NSX_DISABLE_BILINEAR]
set DISABLE_ADAPTIVE  [get_parameter -name NSX_DISABLE_ADAPTIVE]
set DISABLE_YC        [get_parameter -name NSX_DISABLE_YC]
set DISABLE_ALSA      [get_parameter -name NSX_DISABLE_ALSA]
set ENABLE_2ND_SDRAM  [get_parameter -name NSX_ENABLE_2ND_SDRAM]
set ENABLE_FPGA_DDR3  [get_parameter -name NSX_ENABLE_FPGA_DDR3]
set RTL_ROOT          "../rtl"
set PLATFORM_ROOT     "../platform/$FRAMEWORK_ID"
set TARGET_ROOT       "../target/$FRAMEWORK_ID"
set BSP_ROOT          "$PLATFORM_ROOT/bsp/$DEVICE_ID"

# ==============================================================================
# System and Core Top Level, Pinout and Constrains
# ==============================================================================
set_global_assignment -name SYSTEMVERILOG_FILE      "$BSP_ROOT/sys_top.sv"
set_global_assignment -name SDC_FILE                "$BSP_ROOT/sys_constr.sdc"
set_global_assignment -name SOURCE_TCL_SCRIPT_FILE  "$PLATFORM_ROOT/pkgIndex.tcl"
set_global_assignment -name QIP_FILE                "$TARGET_ROOT/core.qip"
set BOARD_PINS [glob -nocomplain -types f [file join $BSP_ROOT/pinouts *.tcl]]
foreach pinout $BOARD_PINS {
    set_global_assignment -name SOURCE_TCL_SCRIPT_FILE \"$pinout\"
}

# Check if build_id.vh exists
checkBuildID

# ==============================================================================
# Framework Assignments
# ==============================================================================
if {$ENABLE_2ND_SDRAM eq "ON" && $DEVICE_ID eq "de10_nano"} {
    post_message "Framework: Second SDRAM enabled, analog output will be disabled"
    set_global_assignment -name VERILOG_MACRO "NSX_ENABLE_2ND_SDRAM=1"
}
if {$ENABLE_FPGA_DDR3 eq "ON" && $DEVICE_ID eq "sockit"} {
    post_message "Framework: FPGA DDR3 enabled"
    set_global_assignment -name VERILOG_MACRO "NSX_ENABLE_FPGA_DDR3=1"
}
if {$ENABLE_FB eq "ON"} {
    post_message "Framework: Core framebuffer has been enabled"
    set_global_assignment -name VERILOG_MACRO "NSX_ENABLE_FB=1"
}
if {$ENABLE_FB_PAL eq "ON"} {
    post_message "Framework: FB palette has been enabled. Use only if you're using 8bit indexed mode in the core"
    set_global_assignment -name VERILOG_MACRO "NSX_ENABLE_FB_PAL=1"
}
if {$ENABLE_SMALL_VBUF eq "ON"} {
    post_message "Framework: Small video buffer (1MB/Frame) has been enabled"
    set_global_assignment -name VERILOG_MACRO "NSX_ENABLE_SMALL_VBUF=1"
}
if {$ENABLE_OSD_HEADER eq "ON"} {
    post_message "Framework: Header on the Menu has been enabled"
    set_global_assignment -name VERILOG_MACRO "NSX_ENABLE_OSD_HEADER=1"
}
if {$DISABLE_HDMI eq "ON"} {
    post_message "Framework: HDMI modules has been disabled. (Use for Debug only, don't use for releases)"
    set_global_assignment -name VERILOG_MACRO "NSX_DISABLE_HDMI=1"
}
if {$DISABLE_BILINEAR eq "ON"} {
    post_message "Framework: Bilinear filtering when downscaling has been disabled"
    set_global_assignment -name VERILOG_MACRO "NSX_DISABLE_BILINEAR=1"
}
if {$DISABLE_ADAPTIVE eq "ON"} {
    post_message "Framework: Adaptive scanline filtering has been disabled"
    set_global_assignment -name VERILOG_MACRO "NSX_DISABLE_ADAPTIVE=1"
}
if {$DISABLE_YC eq "ON"} {
    post_message "Framework: YC/Composite output has been disabled"
    set_global_assignment -name VERILOG_MACRO "NSX_DISABLE_YC=1"
}
if {$DISABLE_ALSA eq "ON"} {
    post_message "Framework: ALSA audio output has been disabled"
    set_global_assignment -name VERILOG_MACRO "NSX_DISABLE_ALSA=1"
}

# ==============================================================================
# Classic Timing Assignments
# ==============================================================================
set QUARTUS_VERSION    [lindex $quartus(version) 1]
set VERSION_COMPONENTS [split $QUARTUS_VERSION "."]
set VERSION_MAJOR      [lindex $VERSION_COMPONENTS 0]

if {$VERSION_MAJOR > 17} {
    set_global_assignment -name TIMING_ANALYZER_MULTICORNER_ANALYSIS OFF
    set_global_assignment -name TIMING_ANALYZER_REPORT_WORST_CASE_TIMING_PATHS [expr {$DEVICE_FAMILY eq "MAX 10" || $DEVICE_FAMILY eq "Cyclone V" ? "OFF" : "ON"}]
    set_global_assignment -name DISABLE_LEGACY_TIMING_ANALYZER [expr {$DEVICE_FAMILY eq "Cyclone 10 LP" ? "ON" : "OFF"}]
} else {
    set_global_assignment -name TIMEQUEST_MULTICORNER_ANALYSIS OFF
    set_global_assignment -name TIMEQUEST_REPORT_WORST_CASE_TIMING_PATHS [expr {$DEVICE_FAMILY eq "MAX 10" || $DEVICE_FAMILY eq "Cyclone V" ? "OFF" : "ON"}]
}

# ==============================================================================
# User Options Assignments
# ==============================================================================
# set_user_option -name GENERATE_JSON_REPORT_FILES OFF
# set_user_option -name GENERATE_HTML_REPORT_FILES OFF
# set_user_option -name GENERATE_SINGLE_REPORT_FILE ON
# set_user_option -name COMPACT_REPORT_TABLE_FORMAT ON