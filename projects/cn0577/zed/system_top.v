// ***************************************************************************
// ***************************************************************************
// Copyright 2022 (c) Analog Devices, Inc. All rights reserved.
//
// In this HDL repository, there are many different and unique modules, consisting
// of various HDL (Verilog or VHDL) components. The individual modules are
// developed independently, and may be accompanied by separate and unique license
// terms.
//
// The user should read each of these license terms, and understand the
// freedoms and responsibilities that he or she has by using this source/core.
//
// This core is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE.
//
// Redistribution and use of source or resulting binaries, with or without modification
// of this file, are permitted under one of the following two license terms:
//
//   1. The GNU General Public License version 2 as published by the
//      Free Software Foundation, which can be found in the top level directory
//      of this repository (LICENSE_GPL2), and also online at:
//      <https://www.gnu.org/licenses/old-licenses/gpl-2.0.html>
//
// OR
//
//   2. An ADI specific BSD license, which can be found in the top level directory
//      of this repository (LICENSE_ADIBSD), and also on-line at:
//      https://github.com/analogdevicesinc/hdl/blob/master/LICENSE_ADIBSD
//      This will allow to generate bit files and not release the source code,
//      as long as it attaches to an ADI device.
//
// ***************************************************************************
// ***************************************************************************

`timescale 1ns/100ps

module system_top (

  inout       [14:0]      ddr_addr,
  inout       [ 2:0]      ddr_ba,
  inout                   ddr_cas_n,
  inout                   ddr_ck_n,
  inout                   ddr_ck_p,
  inout                   ddr_cke,
  inout                   ddr_cs_n,
  inout       [ 3:0]      ddr_dm,
  inout       [31:0]      ddr_dq,
  inout       [ 3:0]      ddr_dqs_n,
  inout       [ 3:0]      ddr_dqs_p,
  inout                   ddr_odt,
  inout                   ddr_ras_n,
  inout                   ddr_reset_n,
  inout                   ddr_we_n,

  inout                   fixed_io_ddr_vrn,
  inout                   fixed_io_ddr_vrp,
  inout       [53:0]      fixed_io_mio,
  inout                   fixed_io_ps_clk,
  inout                   fixed_io_ps_porb,
  inout                   fixed_io_ps_srstb,

  inout       [31:0]      gpio_bd,

  output                  hdmi_out_clk,
  output                  hdmi_vsync,
  output                  hdmi_hsync,
  output                  hdmi_data_e,
  output      [15:0]      hdmi_data,

  output                  i2s_mclk,
  output                  i2s_bclk,
  output                  i2s_lrclk,
  output                  i2s_sdata_out,
  input                   i2s_sdata_in,

  output                  spdif,

  inout                   iic_scl,
  inout                   iic_sda,
  inout       [ 1:0]      iic_mux_scl,
  inout       [ 1:0]      iic_mux_sda,

  input                   otg_vbusoc,

  input                   ref_clk_p,
  input                   ref_clk_n,
  output                  clk_p,
  output                  clk_n,
  input                   dco_p,
  input                   dco_n,
  input                   da_n,
  input                   da_p,
  input                   db_n,
  input                   db_p,
  output                  cnv_p,
  output                  cnv_n,
  output                  cnv_en,
  input                  pd_cntrl,
  input                  testpat_cntrl,
  input                  twolanes_cntrl
);

// internal signals

  wire    [63:0]  gpio_i;
  wire    [63:0]  gpio_o;
  wire    [63:0]  gpio_t;

  wire    [ 1:0]  iic_mux_scl_i_s;
  wire    [ 1:0]  iic_mux_scl_o_s;
  wire            iic_mux_scl_t_s;
  wire    [ 1:0]  iic_mux_sda_i_s;
  wire    [ 1:0]  iic_mux_sda_o_s;
  wire            iic_mux_sda_t_s;

  wire            clk_s;
  wire            cnv_s;
  wire            cnv;
  wire            clk_gate;
  wire            sampling_clk_s;
  wire            ltc_clk;

  assign gpio_i[63:34] = gpio_o[63:34];
//  assign twolanes_cntrl = 1'b1;
  assign cnv_en = cnv;
// instantiations

ad_data_clk #(
  .SINGLE_ENDED (0))
  i_ref_clk (
    .rst (1'b0),
    .locked (),
    .clk_in_p (ref_clk_p),
    .clk_in_n (ref_clk_n),
    .clk (clk_s));

ODDR #(.DDR_CLK_EDGE ("SAME_EDGE")) i_tx_clk_oddr (
    .CE (1'b1),
    .R (1'b0),
    .S (1'b0),
    .C (sampling_clk_s),
    .D1 (clk_gate),
    .D2 (1'b0),
    .Q (ltc_clk));

ODDR #(.DDR_CLK_EDGE ("SAME_EDGE")) i_cnv_oddr (
    .CE (1'b1),
    .R (1'b0),
    .S (1'b0),
    .C (sampling_clk_s),
    .D1 (cnv),
    .D2 (cnv),
    .Q (cnv_s));

OBUFDS i_tx_data_obuf (
    .I (ltc_clk),
    .O (clk_p),
    .OB (clk_n));

OBUFDS OBUFDS_cnv (
    .O(cnv_p),
    .OB(cnv_n),
    .I(cnv_s));

//ad_iobuf #(.DATA_WIDTH(2)) iobuf_gpio_cn0577 (
//    .dio_i (gpio_o[33:32]),
//    .dio_o (gpio_i[33:32]),
//    .dio_t (gpio_t[33:32]),
//    .dio_p ({pd_cntrl,testpat_cntrl}));

ad_iobuf #(.DATA_WIDTH(32)) iobuf_gpio_bd (
    .dio_i (gpio_o[31:0]),
    .dio_o (gpio_i[31:0]),
    .dio_t (gpio_t[31:0]),
    .dio_p (gpio_bd));

ad_iobuf #(
  .DATA_WIDTH(2)
  ) i_iic_mux_scl (
    .dio_t({iic_mux_scl_t_s, iic_mux_scl_t_s}),
    .dio_i(iic_mux_scl_o_s),
    .dio_o(iic_mux_scl_i_s),
    .dio_p(iic_mux_scl));

ad_iobuf #(
  .DATA_WIDTH(2)
  ) i_iic_mux_sda (
    .dio_t({iic_mux_sda_t_s, iic_mux_sda_t_s}),
    .dio_i(iic_mux_sda_o_s),
    .dio_o(iic_mux_sda_i_s),
    .dio_p(iic_mux_sda));

system_wrapper i_system_wrapper (
    .ddr_addr(ddr_addr),
    .ddr_ba(ddr_ba),
    .ddr_cas_n(ddr_cas_n),
    .ddr_ck_n(ddr_ck_n),
    .ddr_ck_p(ddr_ck_p),
    .ddr_cke(ddr_cke),
    .ddr_cs_n(ddr_cs_n),
    .ddr_dm(ddr_dm),
    .ddr_dq(ddr_dq),
    .ddr_dqs_n(ddr_dqs_n),
    .ddr_dqs_p(ddr_dqs_p),
    .ddr_odt(ddr_odt),
    .ddr_ras_n(ddr_ras_n),
    .ddr_reset_n(ddr_reset_n),
    .ddr_we_n(ddr_we_n),
    .fixed_io_ddr_vrn (fixed_io_ddr_vrn),
    .fixed_io_ddr_vrp (fixed_io_ddr_vrp),
    .fixed_io_mio (fixed_io_mio),
    .fixed_io_ps_clk (fixed_io_ps_clk),
    .fixed_io_ps_porb (fixed_io_ps_porb),
    .fixed_io_ps_srstb (fixed_io_ps_srstb),
    .gpio_i (gpio_i),
    .gpio_o (gpio_o),
    .gpio_t (gpio_t),
    .hdmi_data (hdmi_data),
    .hdmi_data_e (hdmi_data_e),
    .hdmi_hsync (hdmi_hsync),
    .hdmi_out_clk (hdmi_out_clk),
    .hdmi_vsync (hdmi_vsync),
    .i2s_bclk (i2s_bclk),
    .i2s_lrclk (i2s_lrclk),
    .i2s_mclk (i2s_mclk),
    .i2s_sdata_in (i2s_sdata_in),
    .i2s_sdata_out (i2s_sdata_out),
    .iic_fmc_scl_io (iic_scl),
    .iic_fmc_sda_io (iic_sda),
    .iic_mux_scl_i (iic_mux_scl_i_s),
    .iic_mux_scl_o (iic_mux_scl_o_s),
    .iic_mux_scl_t (iic_mux_scl_t_s),
    .iic_mux_sda_i (iic_mux_sda_i_s),
    .iic_mux_sda_o (iic_mux_sda_o_s),
    .iic_mux_sda_t (iic_mux_sda_t_s),
    .otg_vbusoc (otg_vbusoc),
    .spdif (spdif),
    .ref_clk (clk_s),
    .sampling_clk (sampling_clk_s),
    .dco_p (dco_p),
    .dco_n (dco_n),
    .da_n (da_n),
    .da_p (da_p),
    .db_n (db_n),
    .db_p (db_p),
    .cnv (cnv),
    .clk_gate (clk_gate),
    .spi0_clk_i (1'b0),
    .spi0_clk_o (),
    .spi0_csn_0_o (),
    .spi0_csn_1_o (),
    .spi0_csn_2_o (),
    .spi0_csn_i (1'b0),
    .spi0_sdi_i (1'b0),
    .spi0_sdo_i (1'b0),
    .spi0_sdo_o (),
    .spi1_clk_i (1'b0),
    .spi1_clk_o (),
    .spi1_csn_0_o (),
    .spi1_csn_1_o (),
    .spi1_csn_2_o (),
    .spi1_csn_i (1'b0),
    .spi1_sdi_i (1'b0),
    .spi1_sdo_i (1'b0),
    .spi1_sdo_o ());

endmodule

// ***************************************************************************
// ***************************************************************************
