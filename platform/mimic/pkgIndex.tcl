# ==============================================================================
# SPDX-License-Identifier: CC0-1.0
# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (c) 2022, OpenGateware authors and contributors
# ==============================================================================
# @file: functions.tcl
# @brief: Collection of TCL Functions for the Framework
# ==============================================================================

source $PLATFORM_ROOT/scripts/functions.tcl

set ignore_list {}
set nsx_proms {}
set nsx_modules [list \
    "audio"       \
    "video"       \
    "memory"      \
    "peripherals" \
    "helpers"
]

switch $DEVICE_FAMILY {
    "Cyclone V" {
        lappend nsx_modules "pll/c5"
    }
    "Cyclone 10 LP" {
        puts "This is a Cyclone 10 LP"
    }
    "MAX 10" {
        puts "This is a MAX 10"
    }
    "Cyclone IV GX" {
        puts "This is a Cyclone IV GX"
    }
    "Cyclone IV E" {
        puts "This is a Cyclone IV E"
    }
    default {
        puts "Unknown Device Family"
    }
}

switch $DEVICE_ID {
    "de10_standard" -
    "de1_soc" -
    "sockit" {
        lappend nsx_proms "$PLATFORM_ROOT/proms/adv7123_config.sv"
    }
    "de10_nano" {
        puts "This is a DE10-Nano"
    }
    default {
        puts "Unknown Device"
    }
}

foreach folder $nsx_modules {
    set platform_files [getHDLFiles "$PLATFORM_ROOT/$folder"]
    foreach file $platform_files {
        if {$file in $ignore_list} {
            continue
        } else {
            set ext [file extension $file]
            set is_pll [string match "pll*"  $file]
            if {$is_pll && $ext eq ".v"} {
                continue
            }
            switch $ext {
                ".sv"  { set_global_assignment -name SYSTEMVERILOG_FILE \"$file\" }
                ".v"   { set_global_assignment -name VERILOG_FILE       \"$file\" }
                ".vhd" { set_global_assignment -name VHDL_FILE          \"$file\" }
                ".qip" { set_global_assignment -name QIP_FILE           \"$file\" }
            }
        }
    }
    foreach prom $nsx_proms {
        set_global_assignment -name SYSTEMVERILOG_FILE "$prom"
    }
}
