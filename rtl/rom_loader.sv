import types::*;

module rom_loader (
    input wire clk,

    input wire        ioctl_download,
    input wire        ioctl_wr,
    input wire [24:0] ioctl_addr,
    input wire [15:0] ioctl_dout,

    output system_config sys_config,

    // Data signals
    // Comb
    output reg [25:0] base_addr,
    output wire image_download,
    output wire mask_config_download,
    output wire rom_download,

    // 8 bit bus
    output reg wr_8bit,
    output wire [25:0] addr_8bit,
    output wire [7:0] data_8bit
);
  // Word addresses
  localparam IMAGE_START_ADDR = 25'h80;
  localparam MASK_CONFIG_ADDR = 25'h17BB80;
  localparam ROM_DATA_ADDR = 25'h187250;

  // wire config_data = ioctl_addr < IMAGE_START_ADDR;
  assign image_download = ioctl_addr >= IMAGE_START_ADDR && ioctl_addr < MASK_CONFIG_ADDR;
  assign mask_config_download = ioctl_addr >= MASK_CONFIG_ADDR && ioctl_addr < ROM_DATA_ADDR;
  assign rom_download = ioctl_addr >= ROM_DATA_ADDR;

  always_comb begin
    base_addr = ioctl_addr;

    if (image_download) begin
      base_addr = ioctl_addr - IMAGE_START_ADDR;
    end else if (mask_config_download) begin
      base_addr = ioctl_addr - MASK_CONFIG_ADDR;
    end else if (rom_download) begin
      base_addr = ioctl_addr - ROM_DATA_ADDR;
    end
  end

  reg [23:0] screen_size = 0;

  reg [15:0] buffer = 0;
  reg [ 1:0] read_count = 0;

  assign data_8bit = buffer[7:0];
  // Byte address
  assign addr_8bit = {base_addr[24:0], read_count == 2'h1};

  always @(posedge clk) begin
    wr_8bit <= 0;

    if (ioctl_wr) begin
      buffer <= ioctl_dout;
      read_count <= 2'h2;
    end

    if (wr_8bit) begin
      buffer <= {8'h0, buffer[15:8]};
    end

    if (read_count > 0) begin
      wr_8bit <= 1;
      read_count <= read_count - 2'h1;
    end
  end

  ////////////////////////////////////////////////////////////////////////////////////////
  // State machine

  localparam VERSION = 0;
  localparam MPU = 1;
  localparam SCREEN_CONFIG = 2;
  localparam SCREEN_SIZE = 3;
  localparam SCREEN_RESERVED = 4;
  localparam INPUT_MAP = 5;
  localparam DONE = 6;

  reg [7:0] state = VERSION;
  reg [5:0] byte_count = 0;

  always @(posedge clk) begin
    if (state == DONE && ~ioctl_download) begin
      // Reset to load another ROM
      state <= VERSION;
      byte_count <= 6'h0;
    end

    if (wr_8bit) begin
      case (state)
        VERSION: begin
          // Check for version number 1, though we can't do anything about it now
          state <= MPU;
        end
        MPU: begin
          state <= SCREEN_CONFIG;
          sys_config.mpu <= data_8bit;
        end
        SCREEN_CONFIG: begin
          state <= SCREEN_SIZE;
          sys_config.screen_config <= data_8bit;
        end
        SCREEN_SIZE: begin
          byte_count  <= byte_count + 6'h1;
          screen_size <= {data_8bit, screen_size[23:8]};

          if (byte_count == 4'h2) begin
            state <= SCREEN_RESERVED;
            {sys_config.screen_height, sys_config.screen_width} <= {data_8bit, screen_size[23:8]};
            byte_count <= 0;
          end
        end
        SCREEN_RESERVED: begin
          // Reserved two bytes after screen size
          byte_count <= byte_count + 6'h1;

          if (byte_count == 6'h1) begin
            state <= INPUT_MAP;
            byte_count <= 0;
          end
        end
        INPUT_MAP: begin
          byte_count <= byte_count + 6'h1;

          if (byte_count >= 0 && byte_count < 4) begin
            // S0
            sys_config.input_s0_config <= {data_8bit, sys_config.input_s0_config[31:8]};
          end else if (byte_count >= 4 && byte_count < 8) begin
            // S1
            sys_config.input_s1_config <= {data_8bit, sys_config.input_s1_config[31:8]};
          end else if (byte_count >= 8 && byte_count < 12) begin
            // S2
            sys_config.input_s2_config <= {data_8bit, sys_config.input_s2_config[31:8]};
          end else if (byte_count >= 12 && byte_count < 16) begin
            // S3
            sys_config.input_s3_config <= {data_8bit, sys_config.input_s3_config[31:8]};
          end else if (byte_count >= 16 && byte_count < 20) begin
            // S4
            sys_config.input_s4_config <= {data_8bit, sys_config.input_s4_config[31:8]};
          end else if (byte_count >= 20 && byte_count < 24) begin
            // S5
            sys_config.input_s5_config <= {data_8bit, sys_config.input_s5_config[31:8]};
          end else if (byte_count >= 24 && byte_count < 28) begin
            // S6
            sys_config.input_s6_config <= {data_8bit, sys_config.input_s6_config[31:8]};
          end else if (byte_count >= 28 && byte_count < 32) begin
            // S7
            sys_config.input_s7_config <= {data_8bit, sys_config.input_s7_config[31:8]};
          end else if (byte_count == 32) begin
            // B
            sys_config.input_b_config <= data_8bit;
          end else if (byte_count == 33) begin
            // BA
            sys_config.input_ba_config <= data_8bit;
          end else if (byte_count == 34) begin
            // ACL
            sys_config.input_acl_config <= data_8bit;
          end

          // Extra gap for reserved bytes
          if (byte_count == 6'h27) begin
            state <= DONE;
          end
        end
      endcase
    end
  end

endmodule
