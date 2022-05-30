

`ifndef MPRJ_IO_PADS
    `define MPRJ_IO_PADS 38
`endif
// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
/*
 *-------------------------------------------------------------
 *
 * user_proj_example
 *
 * This is an example of a (trivially simple) user project,
 * showing how the user project can connect to the logic
 * analyzer, the wishbone bus, and the I/O pads.
 *
 * This project generates an integer count, which is output
 * on the user area GPIO pads (digital output only).  The
 * wishbone connection allows the project to be controlled
 * (start and stop) from the management SoC program.
 *
 * See the testbenches in directory "mprj_counter" for the
 * example programs that drive this user project.  The three
 * testbenches are "io_ports", "la_test1", and "la_test2".
 *
 *-------------------------------------------------------------
 */

module user_proj_example #(
    parameter BITS = 32
)(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // IRQ
    output [2:0] irq,

    //user clock
    input user_clock2
);

//     wire [`MPRJ_IO_PADS-1:0] io_in;
//     wire [`MPRJ_IO_PADS-1:0] io_out;
//     wire [`MPRJ_IO_PADS-1:0] io_oeb;

    wire                                                    clkmux_usrclk;
    wire                                                    io_clk;
    wire                                                    io_rst_n;
    wire                                                    clkmux_clk;
    wire                                                    rstmux_rst_n;
    wire                                                    usr_rst_n_sync;
    wire                                                    wb_rst_n_sync;
    wire                                                    wbs_usrclk_sel;
    wire                                                    wbs_mode;
    wire                                                    wbs_debug;
    wire                                                    wbs_done;
    wire                                                    wbs_cfg_done;
    wire                                                    wbs_fsm_start;
    wire                                                    wbs_qp_mem_csb0;
    wire                                                    wbs_qp_mem_web0;
    wire [8:0]                                              wbs_qp_mem_addr0;
    wire [54:0]                                             wbs_qp_mem_wpatch0;
    wire [54:0]                                             wbs_qp_mem_rpatch0;
    wire [7:0]                                              wbs_leaf_mem_csb0;
    wire [7:0]                                              wbs_leaf_mem_web0;
    wire [5:0]                                              wbs_leaf_mem_addr0;
    wire [63:0]                                             wbs_leaf_mem_wleaf0;
    wire [64*8-1:0]                                         wbs_leaf_mem_rleaf0;
    wire                                                    wbs_best_arr_csb1;
    wire [7:0]                                              wbs_best_arr_addr1;
    wire [63:0]                                             wbs_best_arr_rdata1;
    wire                                                    wbs_node_mem_we;
    wire                                                    wbs_node_mem_rd;
    wire [5:0]                                              wbs_node_mem_addr;
    wire [21:0]                                             wbs_node_mem_wdata;
    wire [21:0]                                             wbs_node_mem_rdata;

    wire                                                    wbs_fsm_start_synced;
    wire                                                    fsm_done_synced;
    wire                                                    load_done_synced;
    wire                                                    send_done_synced;
    wire                                                    wbs_busy_synced;
    wire                                                    wbs_done_synced;
    wire                                                    wbs_cfg_done_synced;
    wire                                                    fsm_start;
    wire                                                    fsm_done;
    wire                                                    send_best_arr;
    wire                                                    send_done;
    wire                                                    load_kdtree;
    wire                                                    load_done;
    wire                                                    in_fifo_wenq;
    wire [10:0]                                             in_fifo_wdata;
    wire                                                    in_fifo_wfull_n;
    wire                                                    out_fifo_deq;
    wire [10:0]                                             out_fifo_rdata;
    wire                                                    out_fifo_rempty_n;


    // IRQ
    assign irq = 3'b000;	// Unused
    assign la_data_out = 128'd0;  // Unused
    // assign io_oeb = la_data_in[37:0];  // TODO
    // assign io_oeb[17:0] = 18'd0;
    // assign io_oeb[37:18] = {20{1'b1}};
    assign io_oeb[17:0] = {18{1'b1}};
    assign io_oeb[37:18] = {20{1'b0}};

    // define all IO pin locations
    assign io_clk = io_in[0];
    assign io_rst_n = io_in[1];
    assign in_fifo_wenq = io_in[2];
    assign in_fifo_wdata = io_in[13:3];
    assign out_fifo_deq = io_in[14];
    assign fsm_start = io_in[15];
    assign send_best_arr = io_in[16];
    assign load_kdtree = io_in[17];
    assign io_out[18] = in_fifo_wfull_n;
    assign io_out[29:19] = out_fifo_rdata;
    assign io_out[30] = out_fifo_rempty_n;
    assign io_out[31] = fsm_done;
    assign io_out[32] = wbs_done_synced;
    assign io_out[33] = wbs_busy_synced;
    assign io_out[34] = wbs_cfg_done_synced;
    assign io_out[17:0] = 18'd0;
    assign io_out[37:35] = 3'd0;


    ClockMux usrclockmux_inst (
        .select  ( wbs_usrclk_sel ),
        .clk0    ( io_clk         ),
        .clk1    ( user_clock2    ),
        .out_clk ( clkmux_usrclk  )
    );

    ClockMux clockmux_inst (
        .select  ( wbs_mode      ),
        .clk0    ( clkmux_usrclk ),
        .clk1    ( wb_clk_i      ),
        .out_clk ( clkmux_clk    )
    );

    ResetMux resetmux_inst (
        .select  ( wbs_mode     ),
        .rst0    ( io_rst_n     ),
        .rst1    ( ~wb_rst_i    ),
        .out_rst ( rstmux_rst_n )
    );

    SyncResetA usr_rst_synca_inst (
        .CLK     (clkmux_clk),
        .IN_RST  (rstmux_rst_n),
        .OUT_RST (usr_rst_n_sync)
    );

    SyncResetA wb_rst_synca_inst (
        .CLK     (wb_clk_i),
        .IN_RST  (~wb_rst_i),
        .OUT_RST (wb_rst_n_sync)
    );

    wbsCtrl 
    // #(
    //     .DATA_WIDTH                             (DATA_WIDTH),
    //     .LEAF_SIZE                              (LEAF_SIZE),
    //     .PATCH_SIZE                             (PATCH_SIZE),
    //     .ROW_SIZE                               (ROW_SIZE),
    //     .COL_SIZE                               (COL_SIZE),
    //     .K                                      (K),
    //     .NUM_LEAVES                             (NUM_LEAVES)
    // ) 
    wbsctrl_inst (
        .wb_clk_i                               (wb_clk_i),
        .wb_rst_n_i                             (wb_rst_n_sync),
        .wbs_stb_i                              (wbs_stb_i),
        .wbs_cyc_i                              (wbs_cyc_i),
        .wbs_we_i                               (wbs_we_i),
        .wbs_sel_i                              (wbs_sel_i),
        .wbs_dat_i                              (wbs_dat_i),
        .wbs_adr_i                              (wbs_adr_i),
        .wbs_ack_o                              (wbs_ack_o),
        .wbs_dat_o                              (wbs_dat_o),
        .wbs_mode                               (wbs_mode),
        .wbs_debug                              (wbs_debug),
        .wbs_usrclk_sel                         (wbs_usrclk_sel),
        .wbs_done                               (wbs_done),
        .wbs_cfg_done                           (wbs_cfg_done),
        .wbs_fsm_start                          (wbs_fsm_start),
        .acc_fsm_done                           (fsm_done_synced),
        .acc_load_done                          (load_done_synced),
        .acc_send_done                          (send_done_synced),
        .wbs_qp_mem_csb0                        (wbs_qp_mem_csb0),
        .wbs_qp_mem_web0                        (wbs_qp_mem_web0),
        .wbs_qp_mem_addr0                       (wbs_qp_mem_addr0),
        .wbs_qp_mem_wpatch0                     (wbs_qp_mem_wpatch0),
        .wbs_qp_mem_rpatch0                     (wbs_qp_mem_rpatch0),
        .wbs_leaf_mem_csb0                      (wbs_leaf_mem_csb0),
        .wbs_leaf_mem_web0                      (wbs_leaf_mem_web0),
        .wbs_leaf_mem_addr0                     (wbs_leaf_mem_addr0),
        .wbs_leaf_mem_wleaf0                    (wbs_leaf_mem_wleaf0),
        .wbs_leaf_mem_rleaf0                    (wbs_leaf_mem_rleaf0),
        .wbs_node_mem_we                        (wbs_node_mem_we),
        .wbs_node_mem_rd                        (wbs_node_mem_rd),
        .wbs_node_mem_addr                      (wbs_node_mem_addr),
        .wbs_node_mem_wdata                     (wbs_node_mem_wdata),
        .wbs_node_mem_rdata                     (wbs_node_mem_rdata),
        .wbs_best_arr_csb1                      (wbs_best_arr_csb1),
        .wbs_best_arr_addr1                     (wbs_best_arr_addr1),
        .wbs_best_arr_rdata1                    (wbs_best_arr_rdata1)
    );

    top 
    // #(
    //     .DATA_WIDTH(DATA_WIDTH),
    //     .DIST_WIDTH(DIST_WIDTH),
    //     .IDX_WIDTH(IDX_WIDTH),
    //     .LEAF_SIZE(LEAF_SIZE),
    //     .PATCH_SIZE(PATCH_SIZE),
    //     .ROW_SIZE(ROW_SIZE),
    //     .COL_SIZE(COL_SIZE),
    //     .NUM_QUERYS(NUM_QUERYS),
    //     .K(K),
    //     .NUM_LEAVES(NUM_LEAVES),
    //     .BLOCKING(BLOCKING),
    //     .LEAF_ADDRW(LEAF_ADDRW)
    // ) 
    acc_inst (
        .clk(clkmux_clk),
        .rst_n(usr_rst_n_sync),

        .load_kdtree(load_kdtree),
        .load_done(load_done),
        .fsm_start(fsm_start | wbs_fsm_start_synced),
        .fsm_done(fsm_done),
        .send_best_arr(send_best_arr),
        .send_done(send_done),

        .io_clk(io_clk),
        .io_rst_n(io_rst_n),
        .in_fifo_wenq(in_fifo_wenq),
        .in_fifo_wdata(in_fifo_wdata),
        .in_fifo_wfull_n(in_fifo_wfull_n),
        .out_fifo_deq(out_fifo_deq),
        .out_fifo_rdata(out_fifo_rdata),
        .out_fifo_rempty_n(out_fifo_rempty_n),

        .wbs_debug                              (wbs_debug),
        .wbs_qp_mem_csb0                        (wbs_qp_mem_csb0),
        .wbs_qp_mem_web0                        (wbs_qp_mem_web0),
        .wbs_qp_mem_addr0                       (wbs_qp_mem_addr0),
        .wbs_qp_mem_wpatch0                     (wbs_qp_mem_wpatch0),
        .wbs_qp_mem_rpatch0                     (wbs_qp_mem_rpatch0),
        .wbs_leaf_mem_csb0                      (wbs_leaf_mem_csb0),
        .wbs_leaf_mem_web0                      (wbs_leaf_mem_web0),
        .wbs_leaf_mem_addr0                     (wbs_leaf_mem_addr0),
        .wbs_leaf_mem_wleaf0                    (wbs_leaf_mem_wleaf0),
        .wbs_leaf_mem_rleaf0                    (wbs_leaf_mem_rleaf0),
        .wbs_node_mem_we                        (wbs_node_mem_we),
        .wbs_node_mem_rd                        (wbs_node_mem_rd),
        .wbs_node_mem_addr                      (wbs_node_mem_addr),
        .wbs_node_mem_wdata                     (wbs_node_mem_wdata),
        .wbs_node_mem_rdata                     (wbs_node_mem_rdata),
        .wbs_best_arr_csb1                      (wbs_best_arr_csb1),
        .wbs_best_arr_addr1                     (wbs_best_arr_addr1),
        .wbs_best_arr_rdata1                    (wbs_best_arr_rdata1)
    );

    SyncPulse fsm_start_sync (
        .sCLK(wb_clk_i),
        .sRST(),  // not needed
        .sEN(wbs_fsm_start),
        .dCLK(clkmux_clk),
        .dPulse(wbs_fsm_start_synced)
    );

    SyncPulse fsm_done_sync (
        .sCLK(clkmux_clk),
        .sRST(),  // not needed
        .sEN(fsm_done),
        .dCLK(wb_clk_i),
        .dPulse(fsm_done_synced)
    );

    SyncPulse load_done_sync (
        .sCLK(clkmux_clk),
        .sRST(),  // not needed
        .sEN(load_done),
        .dCLK(wb_clk_i),
        .dPulse(load_done_synced)
    );

    SyncPulse send_done_sync (
        .sCLK(clkmux_clk),
        .sRST(),  // not needed
        .sEN(send_done),
        .dCLK(wb_clk_i),
        .dPulse(send_done_synced)
    );

    SyncBit wbs_mode_sync (
        .sCLK(wb_clk_i),
        .sRST(wb_rst_n_sync),
        .sEN(1'b1),
        .sD_IN(wbs_mode),
        .dCLK(io_clk),
        .dD_OUT(wbs_busy_synced)
    );

    SyncBit wbs_done_sync (
        .sCLK(wb_clk_i),
        .sRST(wb_rst_n_sync),
        .sEN(1'b1),
        .sD_IN(wbs_done),
        .dCLK(io_clk),
        .dD_OUT(wbs_done_synced)
    );

    SyncBit wbs_cfg_done_sync (
        .sCLK(wb_clk_i),
        .sRST(wb_rst_n_sync),
        .sEN(1'b1),
        .sD_IN(wbs_cfg_done),
        .dCLK(io_clk),
        .dD_OUT(wbs_cfg_done_synced)
    );


endmodule

`default_nettype wire
