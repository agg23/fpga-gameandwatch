--------------------------------------------------------------------------------
-- SPDX-License-Identifier: GPL-3.0-or-later
-- SPDX-FileType: SOURCE
-- SPDX-FileCopyrightText: (c) 2023, OpenGateware authors and contributors
--------------------------------------------------------------------------------
--
-- Copyright (c) 2020, Alexey Melnikov <pour.garbage@gmail.com>
--
-- This source file is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published
-- by the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful, but
-- WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
-- General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program. If not, see <http://www.gnu.org/licenses/>.
--
--------------------------------------------------------------------------------
-- HDMI PLL Adjust
-- Changes the HDMI PLL frequency according to the scaler suggestions.
--
-- LLTUNE :
-- 0 : Input Display Enable
-- 1 : Input Vsync
-- 2 : Input Interlaced mode
-- 3 : Input Interlaced field
-- 4 : Output Image frame
-- 5 :
-- 6 : Input clock
-- 7 : Output clock
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity hdmi_pll_adj is
    port (
        -- Scaler
        llena         : in  std_logic;             -- 0=Disabled 1=Enabled
        lltune        : in  unsigned(15 downto 0); -- Outputs from scaler
        locked        : out std_logic;
        -- Signals from reconfig commands
        i_waitrequest : out std_logic;
        i_write       : in  std_logic;
        i_address     : in  unsigned(5 downto 0);
        i_writedata   : in  unsigned(31 downto 0);
        -- Outputs to PLL_HDMI_CFG
        o_waitrequest : in  std_logic;
        o_write       : out std_logic;
        o_address     : out unsigned(5 downto 0);
        o_writedata   : out unsigned(31 downto 0);
        ------------------------------------
        clk           : in  std_logic;
        reset_na      : in  std_logic
    );
    begin
    end entity hdmi_pll_adj;
    --##############################################################################
    architecture rtl of hdmi_pll_adj is
        signal i_clk, i_de, i_de2, i_vss, i_vss2, i_vss_delay, i_ce : std_logic;
        signal i_linecpt, i_line : natural range 0 to 2 ** 12 - 1;
        signal i_delay : natural range 0 to 2 ** 14 - 1;
        signal pwrite : std_logic;
        signal paddress : unsigned(5 downto 0);
        signal pdata : unsigned(31 downto 0);
        type enum_state is (sIDLE, sW1, sW2, sW3, sW4, sW5, sW6);
        signal state : enum_state;
        signal tune_freq, tune_phase : unsigned(5 downto 0);
        signal lltune_sync, lltune_sync2, lltune_sync3 : unsigned(15 downto 0);
        signal mfrac, mfrac_mem, mfrac_ref, diff : unsigned(40 downto 0);
        signal mul : unsigned(15 downto 0);
        signal sign, sign_pre : std_logic;
        signal expand : boolean;
        signal up, modo, phm, dir : std_logic;
        signal cpt : natural range 0 to 3;
        signal col : natural range 0 to 15;
        signal icpt, ocpt, o2cpt, ssh, ofsize, ifsize : natural range 0 to 2 ** 24 - 1;
        signal ivss, ivss2, itog : std_logic;
        signal ovss, ovss2, otog : std_logic;
        signal sync, pulse, los, lop : std_logic;
        signal osize, offset, osizep, offsetp : signed(23 downto 0);
        signal logcpt : natural range 0 to 31;
        signal udiff : integer range - 2 ** 23 to 2 ** 23 - 1 := 0;
    begin
        ----------------------------------------------------------------------------
        -- 4 lines delay to input
        i_vss <= lltune(0);
        i_de <= lltune(1);
        i_ce <= lltune(5);
        i_clk <= lltune(6);
        Delay : process (i_clk) is
        begin
            if rising_edge(i_clk) then
                if i_ce = '1' then
                    -- Measure input line time.
                    i_de2 <= i_de;
                    if i_de = '1' and i_de2 = '0' then
                        i_linecpt <= 0;
                        if i_vss = '1' then
                            i_line <= i_linecpt;
                        end if;
                    else
                        i_linecpt <= i_linecpt + 1;
                    end if;
                    -- Delay 4 lines
                    i_vss2 <= i_vss;
                    if i_vss /= i_vss2 then
                        i_delay <= 0;
                    elsif i_delay = i_line * 4 then
                        i_vss_delay <= i_vss;
                    else
                        i_delay <= i_delay + 1;
                    end if;
                end if;
            end if;
        end process Delay;
        ----------------------------------------------------------------------------
        -- Sample image sizes
        Sampler : process (clk, reset_na) is
        begin
            if reset_na = '0' then
                --pragma synthesis_off
                otog <= '0';
                itog <= '0';
                ivss <= '0';
                ivss2 <= '0';
                ovss <= '0';
                ovss2 <= '0';
                --pragma synthesis_on
            elsif rising_edge(clk) then
                -- Clock domain crossing
                ivss <= i_vss_delay; -- 
                ivss2 <= ivss;
                ovss <= lltune(4); -- 
                ovss2 <= ovss;
                otog <= otog xor (ovss and not ovss2);
                -- Measure output frame time
                if ovss = '1' and ovss2 = '0' and otog = '1' then
                    ocpt <= 0;
                    osizep <= to_signed(ocpt, 24);
                else
                    ocpt <= ocpt + 1;
                end if;
                if ovss = '0' and ovss2 = '1' and otog = '0' then
                    o2cpt <= 0;
                else
                    o2cpt <= o2cpt + 1;
                end if;
                -- Measure output image time
                if ovss = '0' and ovss2 = '1' and otog = '0' then
                    ofsize <= ocpt;
                end if;
                itog <= itog xor (ivss and not ivss2);
                -- Measure input frame time
                if ivss = '1' and ivss2 = '0' and itog = '1' then
                    icpt <= 0;
                    osize <= osizep;
                    udiff <= integer(to_integer(osizep)) - integer(icpt);
                    sync <= '1';
                else
                    icpt <= icpt + 1;
                    sync <= '0';
                end if;
                -- Measure input image time
                if ivss = '0' and ivss2 = '1' and itog = '0' then
                    ifsize <= icpt;
                end if;
                expand <= (ofsize >= ifsize);
                -- IN | ######### | EXPAND = 1
                -- OUT | ############# |
                -- IN | ######### | EXPAND = 0
                -- OUT | ###### |
                if expand then
                    if ivss = '1' and ivss2 = '0' and itog = '1' then
                        offset <= to_signed(ocpt, 24);
                    end if;
                else
                    if ivss = '0' and ivss2 = '1' and itog = '0' then
                        offset <= to_signed(o2cpt, 24);
                    end if;
                end if;
                --------------------------------------------
                pulse <= '0';
                if sync = '1' then
                    logcpt <= 0;
                    ssh <= to_integer(osize);
                    los <= '0';
                    lop <= '0';
                elsif logcpt < 24 then
                    -- Frequency difference
                    if udiff > 0 and ssh < udiff and los = '0' then
                        tune_freq <= '0' & to_unsigned(logcpt, 5);
                        los <= '1';
                    elsif udiff <= 0 and ssh <- udiff and los = '0' then
                        tune_freq <= '1' & to_unsigned(logcpt, 5);
                        los <= '1';
                    end if;
                    -- Phase difference
                    if offset < osize/2 and ssh < offset and lop = '0' then
                        tune_phase <= '0' & to_unsigned(logcpt, 5);
                        lop <= '1';
                    elsif offset >= osize/2 and ssh < (osize - offset) and lop = '0' then
                        tune_phase <= '1' & to_unsigned(logcpt, 5);
                        lop <= '1';
                    end if;
                    ssh <= ssh/2;
                    logcpt <= logcpt + 1;
                elsif logcpt = 24 then
                    pulse <= '1';
                    ssh <= ssh/2;
                    logcpt <= logcpt + 1;
                end if;
            end if;
        end process Sampler;
        ----------------------------------------------------------------------------
        -- 000010 : Start reg "Write either 0 or 1 to start fractional PLL reconf.
        -- 000100 : M counter
        -- 000111 : M counter Fractional Value K
        Comb : process (i_write, i_address,
            i_writedata, pwrite, paddress, pdata) is
        begin
            if i_write = '1' then
                o_write <= i_write;
                o_address <= i_address;
                o_writedata <= i_writedata;
            else
                o_write <= pwrite;
                o_address <= paddress;
                o_writedata <= pdata;
            end if;
        end process Comb;
        i_waitrequest <= o_waitrequest when state = sIDLE else '0';
        ----------------------------------------------------------------------------
        Schmurtz : process (clk, reset_na) is
            variable off_v, ofp_v : natural range 0 to 63;
            variable diff_v : unsigned(40 downto 0);
            variable mulco : unsigned(15 downto 0);
            variable up_v, sign_v : std_logic;
        begin
            if reset_na = '0' then
                modo <= '0';
                state <= sIDLE;
            elsif rising_edge(clk) then
                ------------------------------------------------------
                -- Snoop accesses to PLL reconfiguration
                if i_address = "000100" and i_write = '1' then
                    mfrac (40 downto 32) <= ('0' & i_writedata(15 downto 8)) +
                        ('0' & i_writedata(7 downto 0));
                        mfrac_ref(40 downto 32) <= ('0' & i_writedata(15 downto 8)) +
                            ('0' & i_writedata(7 downto 0));
                            mfrac_mem(40 downto 32) <= ('0' & i_writedata(15 downto 8)) +
                                ('0' & i_writedata(7 downto 0));
                                mul <= i_writedata(15 downto 0);
                                modo <= '1';
                end if;
                if i_address = "000111" and i_write = '1' then
                    mfrac (31 downto 0) <= i_writedata;
                    mfrac_ref(31 downto 0) <= i_writedata;
                    mfrac_mem(31 downto 0) <= i_writedata;
                    modo <= '1';
                end if;
                ------------------------------------------------------
                -- Tuning
                off_v := to_integer('0' & tune_freq(4 downto 0));
                ofp_v := to_integer('0' & tune_phase(4 downto 0));
                --IF off_v<8 THEN off_v:=8; END IF;
                --IF ofp_v<7 THEN ofp_v:=7; END IF;
                if off_v < 4 then
                    off_v := 4;
                end if;
                if ofp_v < 4 then
                    ofp_v := 4;
                end if;
                if off_v >= 18 and ofp_v >= 18 then
                    locked <= llena;
                else
                    locked <= '0';
                end if;
                up_v := '0';
                if pulse = '1' then
                    cpt <= (cpt + 1) mod 4;
                    if llena = '0' then
                        -- Recover original freq when disabling low lag mode
                        cpt <= 0;
                        col <= 0;
                        if modo = '1' then
                            mfrac <= mfrac_mem;
                            mfrac_ref <= mfrac_mem;
                            up <= '1';
                            modo <= '0';
                        end if;
                    elsif phm = '0' and cpt = 0 then
                        -- Frequency adjust
                        sign_v := tune_freq(5);
                        if col < 10 then
                            col <= col + 1;
                        end if;
                        if off_v >= 16 and col >= 10 then
                            phm <= '1';
                            col <= 0;
                        else
                            off_v := off_v + 1;
                            if off_v > 17 then
                                off_v := off_v + 3;
                            end if;
                            up_v := '1';
                            up <= '1';
                        end if;
                    elsif cpt = 0 then
                        -- Phase adjust
                        sign_v := not tune_phase(5);
                        col <= col + 1;
                        if col >= 10 then
                            phm <= '0';
                            up_v := '1';
                            off_v := 31;
                            col <= 0;
                        else
                            off_v := ofp_v + 1;
                            if ofp_v > 7 then
                                off_v := off_v + 1;
                            end if;
                            if ofp_v > 14 then
                                off_v := off_v + 2;
                            end if;
                            if ofp_v > 17 then
                                off_v := off_v + 3;
                            end if;
                            up_v := '1';
                        end if;
                        up <= '1';
                    end if;
                end if;
                diff_v := shift_right(mfrac_ref, off_v);
                if sign_v = '0' then
                    diff_v := mfrac_ref + diff_v;
                else
                    diff_v := mfrac_ref - diff_v;
                end if;
                if up_v = '1' then
                    mfrac <= diff_v;
                end if;
                if up_v = '1' and phm = '0' then
                    mfrac_ref <= diff_v;
                end if;
                ------------------------------------------------------
                -- Update PLL registers
                mulco := mfrac(40 downto 33) & (mfrac(40 downto 33) + ('0' & mfrac(32)));
                case state is
                    when sIDLE =>
                        pwrite <= '0';
                        if up = '1' then
                            up <= '0';
                            if mulco /= mul then
                                state <= sW1;
                            else
                                state <= sW3;
                            end if;
                        end if;
                    when sW1 => -- Change M multiplier
                        mul <= mulco;
                        pdata <= x"0000" & mulco;
                        paddress <= "000100";
                        pwrite <= '1';
                        state <= sW2;
                    when sW2 =>
                        if pwrite = '1' and o_waitrequest = '0' then
                            state <= sW3;
                            pwrite <= '0';
                        end if;
                    when sW3 => -- Change M fractional value
                        pdata <= mfrac(31 downto 0);
                        paddress <= "000111";
                        pwrite <= '1';
                        state <= sW4;
                    when sW4 =>
                        if pwrite = '1' and o_waitrequest = '0' then
                            state <= sW5;
                            pwrite <= '0';
                        end if;
                    when sW5 =>
                        pdata <= x"0000_0001";
                        paddress <= "000010";
                        pwrite <= '1';
                        state <= sW6;
                    when sW6 =>
                        if pwrite = '1' and o_waitrequest = '0' then
                            pwrite <= '0';
                            state <= sIDLE;
                        end if;
                end case;
            end if;
        end process Schmurtz;
        ----------------------------------------------------------------------------
end architecture rtl;