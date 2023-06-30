//------------------------------------------------------------------------------
// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileType: SOURCE
// SPDX-FileCopyrightText: (c) 2023, Open Gateware authors and contributors
//------------------------------------------------------------------------------
//
// OSD (On Screen Display)
// Copyright (c) 2022, Marcus Andrade <marcus@opengateware.org>
// Copyright (c) 2017, Alexey Melnikov <pour.garbage@gmail.com>
// Copyright (c) 2014, Till Harbaum <till@harbaum.org>
//
// This source file is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This source file is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
//------------------------------------------------------------------------------
// A simple OSD that can be hooked up between a core video output and the
// physical VGA pins. This module supports only OSD related commands.
//------------------------------------------------------------------------------

`default_nettype none

module osd
    (
        input         clk_sys,
        input         io_osd,
        input         io_strobe,
        input  [15:0] io_din,

        input         clk_video,
        input  [23:0] din,
        input         de_in,
        input         vs_in,
        input         hs_in,
        output [23:0] dout,
        output reg    de_out,
        output reg    vs_out,
        output reg    hs_out,

        output reg    osd_status
    );

    localparam OSD_HEIGHT   = 12'd64;

`ifdef NSX_ENABLE_OSD_HEADER
    localparam OSD_HDR      = 12'd24;
`else
    localparam OSD_HDR      = 12'd0;
`endif

    (* ramstyle="no_rw_check" *)
    reg  [7:0] osd_buffer[OSD_HDR ? (8192+1024) : 8192];
    reg        osd_enable;

    reg        info = 0;
    reg  [8:0] infoh;
    reg  [8:0] infow;
    reg [21:0] infox;
    reg [21:0] infoy;
    reg [21:0] osd_h;
    reg [21:0] osd_t;
    reg [21:0] osd_w;

    reg  [1:0] rot = 0;
    reg  [5:0] osd_rgb = 6'h0;
    reg [11:0] osd_width = 12'd256;

    always@(posedge clk_sys) begin
        reg [13:0] bcnt;
        reg  [7:0] cmd;
        reg        has_cmd;
        reg        old_strobe;
        reg        highres = 0;

        osd_t <= rot[0] ? osd_width : (OSD_HEIGHT<<1);
        osd_h <= rot[0] ? (info ? infow : osd_width) : info ? infoh : (OSD_HEIGHT<<highres);
        osd_w <= rot[0] ? (info ? infoh : (OSD_HEIGHT<<highres)) : (info ? infow : osd_width);

        old_strobe <= io_strobe;

        if(~io_osd) begin
            bcnt <= 0;
            has_cmd <= 0;
            cmd <= 0;
            if(cmd[7:4] == 4) begin
                osd_enable <= cmd[0];
            end
        end
        else begin
            if(~old_strobe & io_strobe) begin
                if(!has_cmd) begin
                    has_cmd <= 1;
                    cmd <= io_din[7:0];
                    // command 0x80: OSD_CMD_COLOR
                    if(io_din[7:6] == 'b10) begin
                        osd_rgb <= io_din[5:0];
                        bcnt  <= 0;
                    end
                    // command 0x60: OSD_CMD_SIZE
                    if(io_din[7:6] == 'b11) begin
                        if(io_din[5:0] == 'b000000) osd_width <= 12'd256;
                        if(io_din[5:0] == 'b000001) osd_width <= 12'd320;
                        if(io_din[5:0] == 'b000010) osd_width <= 12'd384;
                        if(io_din[5:0] == 'b000011) osd_width <= 12'd448;
                        if(io_din[5:0] == 'b000100) osd_width <= 12'd512;
                        bcnt  <= 0;
                    end
                    // command 0x40: OSDCMDENABLE, OSDCMDDISABLE
                    if(io_din[7:4] == 'b0100) begin
                        if(!io_din[0]) begin
                            {osd_status,highres} <= 0;
                        end
                        else begin
                            {osd_status,info} <= {~io_din[2] & ~io_din[3],io_din[2]};
                        end
                        bcnt  <= 0;
                    end
                    // command 0x20: OSDCMDWRITE
                    if(io_din[7:5] == 'b001) begin
                        if(io_din[3]) begin
                            highres <= 1;
                        end
                        bcnt <= {io_din[4:0], 9'h00};
                    end
                end
                else begin
                    // command 0x80: OSD_CMD_COLOR
                    if(cmd[7:6] == 'b10) begin
                        osd_rgb <= io_din[5:0];
                    end
                    // command 0x60: OSD_CMD_SIZE
                    if(cmd[7:6] == 'b11) begin
                        if(io_din[5:0] == 'b000000) osd_width <= 12'd256;
                        if(io_din[5:0] == 'b000001) osd_width <= 12'd320;
                        if(io_din[5:0] == 'b000010) osd_width <= 12'd384;
                        if(io_din[5:0] == 'b000011) osd_width <= 12'd448;
                        if(io_din[5:0] == 'b000100) osd_width <= 12'd512;
                    end
                    // command 0x40: OSDCMDENABLE, OSDCMDDISABLE
                    if(cmd[7:4] == 'b0100) begin
                        if(bcnt == 0) infox <= io_din[11:0];
                        if(bcnt == 1) infoy <= io_din[11:0];
                        if(bcnt == 2) infow <= {io_din[5:0], 3'b000};
                        if(bcnt == 3) infoh <= {io_din[5:0], 3'b000};
                        if(bcnt == 4) rot   <= io_din[1:0];
                    end
                    // command 0x20: OSDCMDWRITE
                    if(cmd[7:5] == 'b001) begin
                        osd_buffer[bcnt] <= io_din[7:0];
                    end

                    bcnt <= bcnt + 1'd1;
                end
            end
        end
    end

    (* direct_enable *) reg ce_pix;
    always @(posedge clk_video) begin
        reg [21:0] cnt = 0;
        reg [21:0] pixsz, pixcnt;
        reg        deD;

        cnt <= cnt + 1'd1;
        deD <= de_in;

        pixcnt <= pixcnt + 1'd1;
        if(pixcnt == pixsz) begin
            pixcnt <= 0;
        end
        ce_pix <= !pixcnt;

        if(~deD && de_in) begin
            cnt <= 0;
        end

        if(deD && ~de_in) begin
            pixsz  <= (((cnt+1'b1) >> (9-rot[0])) > 1) ? (((cnt+1'b1) >> (9-rot[0])) - 1'd1) : 22'd0;
            pixcnt <= 0;
        end
    end

    reg  [2:0] osd_de;
    reg        osd_pixel;
    reg [21:0] v_cnt;
    reg        v_cnt_h, v_cnt_1, v_cnt_2, v_cnt_3, v_cnt_4;
    reg [21:0] v_osd_start_h, v_osd_start_1, v_osd_start_2, v_osd_start_3, v_osd_start_4, v_osd_start_5;
    reg [21:0] v_info_start_h, v_info_start_1, v_info_start_2, v_info_start_3, v_info_start_4, v_info_start_5;

    wire [21:0] osd_h_hdr = (info || rot) ? osd_h : (osd_h + OSD_HDR);

    // pipeline the comparisons a bit
    always @(posedge clk_video) if(ce_pix) begin
            v_cnt_h <= v_cnt <= osd_t;
            v_cnt_1 <= v_cnt < 320;
            v_cnt_2 <= v_cnt < 640;
            v_cnt_3 <= v_cnt < 960;
            v_cnt_4 <= v_cnt < 1280;

            v_osd_start_h <= (v_cnt-(osd_h_hdr>>1))>>1;
            v_osd_start_1 <= (v_cnt-osd_h_hdr)>>1;
            v_osd_start_2 <= (v_cnt-(osd_h_hdr<<1))>>1;
            v_osd_start_3 <= (v_cnt-(osd_h_hdr + (osd_h_hdr<<1)))>>1;
            v_osd_start_4 <= (v_cnt-(osd_h_hdr<<2))>>1;
            v_osd_start_5 <= (v_cnt-(osd_h_hdr + (osd_h_hdr<<2)))>>1;

            v_info_start_h <= rot[0] ? infox : infoy;
            v_info_start_1 <= rot[0] ? infox : infoy;
            v_info_start_2 <= rot[0] ? (infox<<1) : (infoy<<1);
            v_info_start_3 <= rot[0] ? (infox + (infox << 1)) : (infoy + (infoy << 1));
            v_info_start_4 <= rot[0] ? (infox << 2) : (infoy << 2);
            v_info_start_5 <= rot[0] ? (infox + (infox << 2)) : (infoy + (infoy << 2));
        end

    always @(posedge clk_video) begin
        reg        deD;
        reg  [2:0] osd_div;
        reg  [2:0] multiscan;
        reg  [7:0] osd_byte;
        reg [23:0] h_cnt;
        reg [21:0] dsp_width;
        reg [21:0] osd_vcnt;
        reg [21:0] h_osd_start;
        reg [21:0] v_osd_start;
        reg [21:0] osd_hcnt;
        reg [21:0] osd_hcnt2;
        reg        osd_de1,osd_de2;
        reg  [1:0] osd_en;
        reg        f1;
        reg        half;

        if(ce_pix) begin

            deD <= de_in;
            if(~&h_cnt)     begin h_cnt     <= h_cnt     + 1'd1; end
            if(~&osd_hcnt)  begin osd_hcnt  <= osd_hcnt  + 1'd1; end
            if(~&osd_hcnt2) begin osd_hcnt2 <= osd_hcnt2 + 1'd1; end

            if (h_cnt == h_osd_start) begin
                osd_de[0] <= osd_en[1] && osd_h && (
                          osd_vcnt[11] ? (osd_vcnt[7] && (osd_vcnt[6:0] >= 4) && (osd_vcnt[6:0] < 19)) :
                          (info && (rot == 3)) ? !osd_vcnt[21:8] :
                          (osd_vcnt < osd_h));
                osd_hcnt <= 0;
                osd_hcnt2 <= 0;
                if(info && rot == 1) begin
                    osd_hcnt2 <= 22'd128-infoh;
                end
            end
            if (osd_hcnt+1 == osd_w) begin
                osd_de[0] <= 0;
            end

            // falling edge of de
            if(!de_in && deD) begin
                dsp_width <= h_cnt[21:0];
            end

            // rising edge of de
            if(de_in && !deD) begin
                h_cnt <= 0;
                v_cnt <= v_cnt + 1'd1;
                h_osd_start <= info ? (rot[0] ? infoy : infox) : (((dsp_width - osd_w)>>1) - 2'd2);

                if(h_cnt > {dsp_width, 2'b00}) begin
                    v_cnt <= 1;
                    f1 <= ~f1; // skip every other frame for interlace compatibility.
                    if(~f1) begin

                        osd_en <= (osd_en << 1) | osd_enable;
                        if(~osd_enable) begin
                            osd_en <= 0;
                        end

                        half <= 0;
                        if(v_cnt_h) begin
                            multiscan <= 0;
                            v_osd_start <= info ? v_info_start_h : v_osd_start_h;
                            half <= 1;
                        end
                        else if(v_cnt_1 | (rot[0] & v_cnt_2)) begin
                            multiscan <= 0;
                            v_osd_start <= info ? v_info_start_1 : v_osd_start_1;
                        end
                        else if(rot[0] ? v_cnt_3 : v_cnt_2) begin
                            multiscan <= 1;
                            v_osd_start <= info ? v_info_start_2 : v_osd_start_2;
                        end
                        else if(rot[0] ? v_cnt_4 : v_cnt_3) begin
                            multiscan <= 2;
                            v_osd_start <= info ? v_info_start_3 : v_osd_start_3;
                        end
                        else if(rot[0] | v_cnt_4) begin
                            multiscan <= 3;
                            v_osd_start <= info ? v_info_start_4 : v_osd_start_4;
                        end
                        else begin
                            multiscan <= 4;
                            v_osd_start <= info ? v_info_start_5 : v_osd_start_5;
                        end
                    end
                end

                osd_div <= osd_div + 1'd1;
                if(osd_div == multiscan) begin
                    osd_div <= 0;
                    if(~osd_vcnt[10]) begin
                        osd_vcnt <= osd_vcnt + 1'd1 + half;
                    end
                    if(osd_vcnt == 'b100010011111 && ~info) begin
                        osd_vcnt <= 0;
                    end
                end
                if(v_osd_start == v_cnt) begin
                    {osd_div,osd_vcnt} <= 0;
                    if(info && rot == 3) begin
                        osd_vcnt <= 22'd256-infow;
                    end
                    else if(OSD_HDR && !rot) begin
                        osd_vcnt <= {~info, 3'b000, ~info, 7'b0000000};
                    end
                end
            end

            osd_byte    <= osd_buffer[rot[0] ? ({osd_hcnt2[6:3], osd_vcnt[7:0]} ^ { {4{~rot[1]}}, {8{rot[1]}} }) : {osd_vcnt[7:3], osd_hcnt[8:0]}];
            osd_pixel   <= osd_byte[rot[0] ? ((osd_hcnt2[2:0]-1'd1) ^ {3{~rot[1]}}) : osd_vcnt[2:0]];
            osd_de[2:1] <= osd_de[1:0];
        end
    end

    reg [23:0] rdout;
    assign dout = rdout;

    always @(posedge clk_video) begin
        reg [23:0] ordout1, nrdout1, rdout2, rdout3;
        reg        de1, de2, de3;
        reg        vs1, vs2, vs3;
        reg        hs1, hs2, hs3;
        reg        osd_mux;

        nrdout1 <= din;
        ordout1 <= {
                    {osd_pixel, osd_pixel, osd_rgb[5:4], din[23:20]},  // 23:16 - R
                    {osd_pixel, osd_pixel, osd_rgb[3:2], din[15:12]},  // 15:8  - G
                    {osd_pixel, osd_pixel, osd_rgb[1:0], din[7:4]  }   //  7:0  - B
                };

        osd_mux <= ~osd_de[2];
        rdout2  <= osd_mux ? nrdout1 : ordout1;
        rdout3  <= rdout2;

        de1 <= de_in; de2 <= de1; de3 <= de2;
        hs1 <= hs_in; hs2 <= hs1; hs3 <= hs2;
        vs1 <= vs_in; vs2 <= vs1; vs3 <= vs2;

        rdout   <= rdout3;
        de_out  <= de3;
        hs_out  <= hs3;
        vs_out  <= vs3;
    end

endmodule
