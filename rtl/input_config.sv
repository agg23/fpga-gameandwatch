import types::*;

module input_config (
    input wire clk,

    input system_config sys_config,

    input wire [3:0] cpu_id,

    // Input selection
    input wire [7:0] output_shifter_s,
    input wire [3:0] output_r,

    // Input
    input wire button_a,
    input wire button_b,
    input wire button_x,
    input wire button_y,
    input wire button_trig_l,
    input wire button_trig_r,
    input wire button_start,
    input wire button_select,
    input wire dpad_up,
    input wire dpad_down,
    input wire dpad_left,
    input wire dpad_right,

    // MPU Input
    output reg [3:0] input_k = 0,

    output reg input_beta = 0,
    output reg input_ba = 0,
    output reg input_acl = 0
);
  localparam INACTIVE_CONFIG_ROW = 32'h7F7F_7F7F;

  function [31:0] s_config_by_index(reg [2:0] index);
    case (index)
      0: return sys_config.input_s0_config;
      1: return sys_config.input_s1_config;
      2: return sys_config.input_s2_config;
      3: return sys_config.input_s3_config;
      4: return sys_config.input_s4_config;
      5: return sys_config.input_s5_config;
      6: return sys_config.input_s6_config;
      7: return sys_config.input_s7_config;
    endcase
  endfunction

  // Map from config value to control
  function input_mux([7:0] config_value);
    reg out;

    case (config_value[6:0])
      0: out = dpad_up;
      1: out = dpad_down;
      2: out = dpad_left;
      3: out = dpad_right;

      // Buttons 1-4
      4: out = button_b;
      5: out = button_a;
      6: out = button_y;
      7: out = button_x;

      // Buttons 5-8 unhandled
      // Select is Time
      12: out = button_trig_l;
      13: out = button_select;
      14: out = button_start;

      // Service1 unhandled
      // Service 2 is Alarm
      16: out = button_trig_r;

      // Left joystick
      17: out = dpad_up;
      18: out = dpad_down;
      19: out = dpad_left;
      20: out = dpad_right;

      // Right joystick
      21: out = button_x;
      22: out = button_b;
      23: out = button_y;
      24: out = button_a;

      // This input is unused
      7'h7F: out = 0;
      // Other values unhandled

      default: out = 0;
    endcase

    // High bit is active low flag
    return config_value[7] ? ~out : out;
  endfunction

  function [3:0] build_k([31:0] input_config);
    return {
      input_mux(input_config[31:24]),
      input_mux(input_config[23:16]),
      input_mux(input_config[15:8]),
      input_mux(input_config[7:0])
    };
  endfunction

  // Always active config
  reg [31:0] grounded_input_config = INACTIVE_CONFIG_ROW;

  reg [ 3:0] main_input_k = 0;

  always @(posedge clk) begin
    reg [3:0] temp_k;

    temp_k = 0;
    grounded_input_config <= INACTIVE_CONFIG_ROW;

    if (sys_config.grounded_port_config == 4'h0) begin
      // Disabled
      grounded_input_config <= INACTIVE_CONFIG_ROW;
    end else begin
      reg [3:0] temp;
      temp = sys_config.grounded_port_config - 4'h1;

      grounded_input_config <= s_config_by_index(temp[2:0]);
    end

    case (cpu_id)
      4: begin
        // SM5a
        if (output_r[1]) temp_k = build_k(sys_config.input_s0_config);
        if (output_r[2]) temp_k = temp_k | build_k(sys_config.input_s1_config);
        if (output_r[3]) temp_k = temp_k | build_k(sys_config.input_s2_config);
      end
      default: begin
        // SM510/SM510 Tiger
        if (output_shifter_s[0]) temp_k = build_k(sys_config.input_s0_config);
        if (output_shifter_s[1]) temp_k = temp_k | build_k(sys_config.input_s1_config);
        if (output_shifter_s[2]) temp_k = temp_k | build_k(sys_config.input_s2_config);
        if (output_shifter_s[3]) temp_k = temp_k | build_k(sys_config.input_s3_config);
        if (output_shifter_s[4]) temp_k = temp_k | build_k(sys_config.input_s4_config);
        if (output_shifter_s[5]) temp_k = temp_k | build_k(sys_config.input_s5_config);
        if (output_shifter_s[6]) temp_k = temp_k | build_k(sys_config.input_s6_config);
        if (output_shifter_s[7]) temp_k = temp_k | build_k(sys_config.input_s7_config);
      end
    endcase

    main_input_k <= temp_k;
  end

  always @(posedge clk) begin
    reg [3:0] grounded_input_k;

    grounded_input_k = {
      input_mux(grounded_input_config[31:24]),
      input_mux(grounded_input_config[23:16]),
      input_mux(grounded_input_config[15:8]),
      input_mux(grounded_input_config[7:0])
    };

    input_k <= main_input_k | grounded_input_k;

    input_beta <= input_mux(sys_config.input_b_config);
    input_ba <= input_mux(sys_config.input_ba_config);
    input_acl <= input_mux(sys_config.input_acl_config);
  end

endmodule
