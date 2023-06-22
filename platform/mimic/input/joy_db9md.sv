//------------------------------------------------------------------------------
// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileType: SOURCE
// SPDX-FileCopyrightText: (c) 2023, OpenGateware authors and contributors
//------------------------------------------------------------------------------
//
// Control module for Antonio Villena's DB9 Splitter
// Copyright (c) 2020, Aitor Pelaez (NeuroRulez)
// Copyright (c) 2020, Fernando Mosquera
// Copyright (c) 2020, Victor Trucco
//
// This source file is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.
//
//------------------------------------------------------------------------------

module joy_db9md
    (
        input         clk,
        input   [5:0] joy_in,
        output        joy_mdsel,
        output        joy_split,
        output [11:0] joystick1,
        output [11:0] joystick2
    );

    reg  [7:0] state = 8'd0;
    reg  [5:0] joy1_in;
    reg  [5:0] joy2_in;
    reg [11:0] joyMDdat1 = 12'hFFF;
    reg [11:0] joyMDdat2 = 12'hFFF;
    reg        joy1_6btn = 1'b0;
    reg        joy2_6btn = 1'b0;
    reg        joyMDsel  = 1'b0;
    reg        joySEL    = 1'b0;
    reg        joySplit  = 1'b1;

    reg [7:0] delay;
    always @(negedge clk) begin
        delay <= delay + 1;
    end

    always @(posedge delay[5]) begin
        joySplit <= ~joySplit;
    end

    always @(negedge delay[5]) begin
        if (joySplit) begin joy2_in <= joy_in; end
        else          begin joy1_in <= joy_in; end
    end

    //Gestion de Joystick
    always @(negedge delay[7]) begin
        state <= state + 1;
        case (state) //-- joy_s format MXYZ SACB UDLR
            8'd0: begin
                joyMDsel <= 1'b0;
            end
            8'd1: begin
                joyMDsel <= 1'b1;
            end
            8'd2: begin
                joyMDdat1[5:0] <= joy1_in[5:0]; //-- CBUDLR
                joyMDdat2[5:0] <= joy2_in[5:0]; //-- CBUDLR
                joyMDsel  <= 1'b0;
                joy1_6btn <= 1'b0; //-- Assume it's not a six-button controller
                joy2_6btn <= 1'b0; //-- Assume it's not a six-button controller
            end
            8'd3: begin // Si derecha e Izda es 0 es un mando de megadrive
                if (joy1_in[1:0] == 2'b00) begin joyMDdat1[7:6] <=              joy1_in[5:4];  end //-- Start, A
                else                       begin joyMDdat1[7:4] <= {1'b1, 1'b1, joy1_in[5:4]}; end //-- read A/B as master System
                if (joy2_in[1:0] == 2'b00) begin joyMDdat2[7:6] <=              joy2_in[5:4];  end //-- Start, A
                else                       begin joyMDdat2[7:4] <= {1'b1, 1'b1, joy2_in[5:4]}; end //-- read A/B as master System
                joyMDsel <= 1'b1;
            end
            8'd4: begin
                joyMDsel <= 1'b0;
            end
            8'd5: begin
                if (joy1_in[3:0] == 4'b000) begin joy1_6btn <= 1'b1; end // --it's a six button
                if (joy2_in[3:0] == 4'b000) begin joy2_6btn <= 1'b1; end // --it's a six button
                joyMDsel <= 1'b1;
            end
            8'd6: begin
                if (joy1_6btn == 1'b1) begin joyMDdat1[11:8] <= joy1_in[4:0]; end //-- Mode, X, Y e Z
                if (joy2_6btn == 1'b1) begin joyMDdat2[11:8] <= joy2_in[4:0]; end //-- Mode, X, Y e Z
                joyMDsel <= 1'b0;
            end
            default: begin
                joyMDsel <= 1'b1;
            end
        endcase

    end

    //joyMDdat1 y joyMDdat2
    //   11 1098 7654 3210
    //----Z  YXM SACB UDLR
    //SALIDA joystick[11:0]:
    //BA9876543210
    //MSZYXCBAUDLR
    assign joystick1 = ~{joyMDdat1[8],joyMDdat1[7],joyMDdat1[11:9],joyMDdat1[5:4],joyMDdat1[6],joyMDdat1[3:0]};
    assign joystick2 = ~{joyMDdat2[8],joyMDdat2[7],joyMDdat2[11:9],joyMDdat2[5:4],joyMDdat2[6],joyMDdat2[3:0]};
    assign joy_mdsel = joyMDsel;
    assign joy_split = joySplit;

endmodule
