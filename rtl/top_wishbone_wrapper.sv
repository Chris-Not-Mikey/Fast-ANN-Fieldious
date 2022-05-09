module top_wishbone_wrapper
#(
    parameter DATA_WIDTH = 11,
    parameter DIST_WIDTH = 25, // maximum 25
    parameter IDX_WIDTH = 9, // index of patch in the original image
    parameter LEAF_SIZE = 8,
    parameter PATCH_SIZE = 5, //excluding the index
    parameter ROW_SIZE = 26,
    parameter COL_SIZE = 19,
    parameter NUM_QUERYS = ROW_SIZE * COL_SIZE,
    parameter K = 4,
    parameter NUM_LEAVES = 64,
    parameter BLOCKING = 4,
    parameter LEAF_ADDRW = $clog2(NUM_LEAVES)
)
(
    input  logic wb_clk_i,
    input  logic wb_rst_i,
    input  logic wbs_stb_i,
    input  logic wbs_cyc_i,
    input  logic wbs_we_i,
    input  logic [3:0] wbs_sel_i,
    input  logic [31:0] wbs_dat_i,
    input  logic [31:0] wbs_adr_i,
    output logic wbs_ack_o,
    output logic [31:0] wbs_dat_o,

    // testbench use
    // might need to add clock domain crossing modules for these controls
    input logic                                 load_kdtree,
    input logic                                 fsm_start,
    output logic                                fsm_done,
    input logic                                 send_best_arr,

    // FIFO
    input logic                                 io_clk,
    input logic                                 io_rst_n,
    input logic                                 in_fifo_wenq,
    input logic [DATA_WIDTH-1:0]                in_fifo_wdata,
    output logic                                in_fifo_wfull_n,
    input logic                                 out_fifo_deq,
    output logic [DATA_WIDTH-1:0]               out_fifo_rdata,
    output logic                                out_fifo_rempty_n
);

    logic                                                   clkmux_clk;
    logic                                                   rstmux_rstn;
    logic                                                   wbs_mode;
    logic                                                   wbs_debug;
    logic                                                   wbs_qp_mem_csb0;
    logic                                                   wbs_qp_mem_web0;
    logic [$clog2(NUM_QUERYS)-1:0]                          wbs_qp_mem_addr0;
    logic [PATCH_SIZE*DATA_WIDTH-1:0]                       wbs_qp_mem_wpatch0;
    logic [PATCH_SIZE*DATA_WIDTH-1:0]                       wbs_qp_mem_rpatch0;
    logic [LEAF_SIZE-1:0]                                   wbs_leaf_mem_csb0;
    logic [LEAF_SIZE-1:0]                                   wbs_leaf_mem_web0;
    logic [LEAF_ADDRW-1:0]                                  wbs_leaf_mem_addr0;
    logic [63:0]                                            wbs_leaf_mem_wleaf0;
    logic [63:0]                                            wbs_leaf_mem_rleaf0 [LEAF_SIZE-1:0];

    ClockMux clockmux_inst (
        .select  ( wbs_mode  ),
        .clk0    ( wb_clk_i  ),
        .clk1    ( io_clk    ),
        .out_clk ( clkmux_clk)
    );

    ClockMux rstmux_inst (
        .select  ( wbs_mode     ),
        .clk0    ( ~wb_rst_i    ),
        .clk1    ( io_rst_n     ),
        .out_clk ( rstmux_rstn  )
    );

    wbsCtrl #(
        .DATA_WIDTH                             (DATA_WIDTH),
        .LEAF_SIZE                              (LEAF_SIZE),
        .PATCH_SIZE                             (PATCH_SIZE),
        .ROW_SIZE                               (ROW_SIZE),
        .COL_SIZE                               (COL_SIZE),
        .K                                      (K),
        .NUM_LEAVES                             (NUM_LEAVES)
    ) wbsctrl_inst (
        .wb_clk_i                               (wb_clk_i),
        .wb_rst_i                               (wb_rst_i),
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
        .wbs_qp_mem_csb0                        (wbs_qp_mem_csb0),
        .wbs_qp_mem_web0                        (wbs_qp_mem_web0),
        .wbs_qp_mem_addr0                       (wbs_qp_mem_addr0),
        .wbs_qp_mem_wpatch0                     (wbs_qp_mem_wpatch0),
        .wbs_qp_mem_rpatch0                     (wbs_qp_mem_rpatch0),
        .wbs_leaf_mem_csb0                      (wbs_leaf_mem_csb0),
        .wbs_leaf_mem_web0                      (wbs_leaf_mem_web0),
        .wbs_leaf_mem_addr0                     (wbs_leaf_mem_addr0),
        .wbs_leaf_mem_wleaf0                    (wbs_leaf_mem_wleaf0),
        .wbs_leaf_mem_rleaf0                    (wbs_leaf_mem_rleaf0)
    );

    top #(
        .DATA_WIDTH(DATA_WIDTH),
        .DIST_WIDTH(DIST_WIDTH),
        .IDX_WIDTH(IDX_WIDTH),
        .LEAF_SIZE(LEAF_SIZE),
        .PATCH_SIZE(PATCH_SIZE),
        .ROW_SIZE(ROW_SIZE),
        .COL_SIZE(COL_SIZE),
        .NUM_QUERYS(NUM_QUERYS),
        .K(K),
        .NUM_LEAVES(NUM_LEAVES),
        .BLOCKING(BLOCKING),
        .LEAF_ADDRW(LEAF_ADDRW)
      ) dut(
        .clk(clkmux_clk),
        .rst_n(rstmux_rstn),

        .load_kdtree(load_kdtree),
        .fsm_start(fsm_start),
        .fsm_done(fsm_done),
        .send_best_arr(send_best_arr),

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
        .wbs_leaf_mem_rleaf0                    (wbs_leaf_mem_rleaf0)   
    );

endmodule