# ==============================================================================
# SPDX-License-Identifier: CC0-1.0
# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (c) 2022, OpenGateware authors and contributors
# ==============================================================================
#
# Platform Global/Location/Instance Assignments
#
# ==============================================================================
# Hardware Information
# ==============================================================================
set_global_assignment -name FAMILY "Cyclone V"
set_global_assignment -name DEVICE 5CSXFC6D6F31C6
set_global_assignment -name DEVICE_FILTER_PACKAGE FBGA
set_global_assignment -name DEVICE_FILTER_PIN_COUNT 896
set_global_assignment -name DEVICE_FILTER_SPEED_GRADE 6

# ==============================================================================
# Hardware Parameters
# ==============================================================================
set_parameter -name NSX_DEVICE_ID "de10_standard"
set_parameter -name NSX_DEVICE_NAME "DE10-Standard"
set_parameter -name NSX_DEVICE_PLATFORM "Intel"
set_parameter -name NSX_DEVICE_MAKER "Terasic"
set_parameter -name NSX_DEVICE_USE_HPS ON

# ==============================================================================
# Setup BSP
# ==============================================================================
set_global_assignment -name SOURCE_TCL_SCRIPT_FILE "../platform/mimic/bsp/setup.tcl"

# ==============================================================================
# Classic Timing Assignments
# ==============================================================================
set_global_assignment -name MIN_CORE_JUNCTION_TEMP 0
set_global_assignment -name MAX_CORE_JUNCTION_TEMP 85
set_global_assignment -name POWER_BOARD_THERMAL_MODEL "NONE (CONSERVATIVE)"

# ==============================================================================
# Assembler Assignments
# ==============================================================================
set_global_assignment -name GENERATE_RBF_FILE ON

# ==============================================================================
# Power Estimation Assignments
# ==============================================================================
set_global_assignment -name POWER_PRESET_COOLING_SOLUTION "23 MM HEAT SINK WITH 200 LFPM AIRFLOW"
set_global_assignment -name POWER_BOARD_THERMAL_MODEL "NONE (CONSERVATIVE)"

# ==============================================================================
# Scripts
# ==============================================================================
set_global_assignment -name PRE_FLOW_SCRIPT_FILE  "quartus_sh:$PLATFORM_ROOT/scripts/pre-flow.tcl"
set_global_assignment -name POST_FLOW_SCRIPT_FILE "quartus_sh:$PLATFORM_ROOT/scripts/post-flow.tcl"
