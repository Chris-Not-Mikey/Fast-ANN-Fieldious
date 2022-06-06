module top
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
    parameter BEST_ARRAY_K = 1,
    parameter NUM_LEAVES = 64,
    parameter BLOCKING = 4,
    parameter LEAF_ADDRW = $clog2(NUM_LEAVES)
)
(
    input logic clk,
    input logic rst_n,

    // testbench use
    // might need to add clock domain crossing modules for these controls
    input logic                                             io_load_kdtree,
    input logic                                             io_fsm_start,
    input logic                                             io_send_best_arr,
    output logic                                            io_load_done,
    output logic                                            io_fsm_done,
    output logic                                            io_send_done,

    input logic                                             wb_clk_i,
    input logic                                             wb_rst_n_i,
    input logic                                             wbs_fsm_start,
    output logic                                            wbs_load_done,
    output logic                                            wbs_fsm_done,
    output logic                                            wbs_send_done,

    // FIFO
    input logic                                             io_clk,
    input logic                                             io_rst_n,
    input logic                                             in_fifo_wenq,
    input logic [DATA_WIDTH-1:0]                            in_fifo_wdata,
    output logic                                            in_fifo_wfull_n,
    input logic                                             out_fifo_deq,
    output logic [DATA_WIDTH-1:0]                           out_fifo_rdata,
    output logic                                            out_fifo_rempty_n,

    // Wishbone
    input logic                                             wbs_debug,
    input logic                                             wbs_qp_mem_csb0,
    input logic                                             wbs_qp_mem_web0,
    input logic [$clog2(NUM_QUERYS)-1:0]                    wbs_qp_mem_addr0,
    input logic [PATCH_SIZE*DATA_WIDTH-1:0]                 wbs_qp_mem_wpatch0,
    output logic [PATCH_SIZE*DATA_WIDTH-1:0]                wbs_qp_mem_rpatch0,
    input logic [LEAF_SIZE-1:0]                             wbs_leaf_mem_csb0,
    input logic [LEAF_SIZE-1:0]                             wbs_leaf_mem_web0,
    input logic [LEAF_ADDRW-1:0]                            wbs_leaf_mem_addr0,
    input logic [63:0]                                      wbs_leaf_mem_wleaf0,
	output logic [(64*8)-1:0]                               wbs_leaf_mem_rleaf0,
    input logic                                             wbs_best_arr_csb1,
    input logic [7:0]                                       wbs_best_arr_addr1,
    output logic [63:0]                                     wbs_best_arr_rdata1,

    input logic                                             wbs_node_mem_we,
    input logic                                             wbs_node_mem_rd,
    input logic [5:0]                                       wbs_node_mem_addr,
    input logic [2*DATA_WIDTH-1:0]                          wbs_node_mem_wdata,
    output logic [2*DATA_WIDTH-1:0]                         wbs_node_mem_rdata 

);

    logic                                                   in_fifo_wenq_r;
    logic [DATA_WIDTH-1:0]                                  in_fifo_wdata_r;
    logic                                                   in_fifo_wfull_n_w;
    logic                                                   out_fifo_deq_r;
    logic [DATA_WIDTH-1:0]                                  out_fifo_rdata_w;
    logic                                                   out_fifo_rempty_n_w;
    
    logic                                                   load_done_w;
    logic                                                   fsm_done_w;
    logic                                                   send_done_w;
    logic                                                   io_load_kdtree_r;
    logic                                                   io_fsm_start_r;
    logic                                                   io_send_best_arr_r;
    logic                                                   io_load_kdtree_synced;
    logic                                                   io_load_done_synced;
    logic                                                   io_fsm_start_synced;
    logic                                                   io_fsm_done_synced;
    logic                                                   io_send_best_arr_synced;
    logic                                                   io_send_done_synced;
    logic                                                   wbs_fsm_start_r;
    logic                                                   wbs_fsm_start_synced;
    logic                                                   wbs_load_done_synced;
    logic                                                   wbs_fsm_done_synced;
    logic                                                   wbs_send_done_synced;

    logic                                                   in_fifo_deq;
    logic [DATA_WIDTH-1:0]                                  in_fifo_rdata;
    logic                                                   in_fifo_rempty_n;
    logic [2:0]                                             out_fifo_wdata_sel;
    logic [DATA_WIDTH-1:0]                                  out_fifo_wdata_n11;
    logic                                                   out_fifo_wenq;
    logic [DATA_WIDTH-1:0]                                  out_fifo_wdata;
    logic                                                   out_fifo_wfull_n;

    logic [DATA_WIDTH-1:0]                                  agg_sender_data;
    logic                                                   agg_sender_empty_n;
    logic                                                   agg_sender_deq;
    logic [6*DATA_WIDTH-1:0]                                agg_receiver_data;
    logic                                                   agg_receiver_full_n;
    logic                                                   agg_receiver_enq;
    logic                                                   agg_change_fetch_width;
    logic [2:0]                                             agg_input_fetch_width;

    // logic                                                   int_node_fsm_enable;
    logic                                                   int_node_sender_enable;
    logic [2*DATA_WIDTH-1:0]                                int_node_sender_data;
    logic [5:0]                                             int_node_sender_addr;
    logic                                                   int_node_patch_en;
    logic [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]                 int_node_patch_in;
    logic [LEAF_ADDRW-1:0]                                  int_node_leaf_index;
    logic                                                   int_node_leaf_valid;
    logic                                                   int_node_patch_en2;
    logic [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]                 int_node_patch_in2;
    logic [LEAF_ADDRW-1:0]                                  int_node_leaf_index2;
    logic                                                   int_node_leaf_valid2;

    logic [LEAF_SIZE-1:0]                                   leaf_mem_csb0;
    logic [LEAF_SIZE-1:0]                                   leaf_mem_web0;
    logic [LEAF_ADDRW-1:0]                                  leaf_mem_addr0;
    logic [PATCH_SIZE*DATA_WIDTH+IDX_WIDTH-1:0]             leaf_mem_wleaf0;
    logic [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]                 leaf_mem_rpatch_data0 [LEAF_SIZE-1:0];
    logic [IDX_WIDTH-1:0]                                   leaf_mem_rpatch_idx0 [LEAF_SIZE-1:0];
    logic                                                   leaf_mem_csb1;
    logic [LEAF_ADDRW-1:0]                                  leaf_mem_addr1;
    logic [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]                 leaf_mem_rpatch_data1 [LEAF_SIZE-1:0];
    logic [IDX_WIDTH-1:0]                                   leaf_mem_rpatch_idx1 [LEAF_SIZE-1:0];

    logic                                                   qp_mem_csb0;
    logic                                                   qp_mem_web0;
    logic [$clog2(NUM_QUERYS)-1:0]                          qp_mem_addr0;
    logic [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]                 qp_mem_wpatch0;
    logic [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]                 qp_mem_rpatch0;
    logic                                                   qp_mem_csb1;
    logic [$clog2(NUM_QUERYS)-1:0]                          qp_mem_addr1;
    logic [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]                 qp_mem_rpatch1;

    logic                                                   best_arr_csb0;
    logic                                                   best_arr_web0;
    logic [7:0]                                             best_arr_addr0;
    logic [63:0]                                            best_arr_wdata0 [BEST_ARRAY_K-1:0];
    logic [63:0]                                            best_arr_rdata0 [BEST_ARRAY_K-1:0];
    logic [BEST_ARRAY_K-1:0]                                best_arr_csb1;
    logic [7:0]                                             best_arr_addr1;
    logic [63:0]                                            best_arr_rdata1 [BEST_ARRAY_K-1:0];

    logic                                                   k0_query_first_in;
    logic                                                   k0_query_first_out;
    logic                                                   k0_query_last_in;
    logic                                                   k0_query_last_out;
    logic                                                   k0_query_valid;
    logic signed [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]          k0_query_patch;
    logic                                                   k0_dist_valid;
    logic [LEAF_ADDRW-1:0]                                  k0_leaf_idx_in;
    logic [LEAF_ADDRW-1:0]                                  k0_leaf_idx_out;
    logic signed [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]          k0_p0_data;
    logic signed [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]          k0_p1_data;
    logic signed [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]          k0_p2_data;
    logic signed [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]          k0_p3_data;
    logic signed [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]          k0_p4_data;
    logic signed [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]          k0_p5_data;
    logic signed [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]          k0_p6_data;
    logic signed [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]          k0_p7_data;
    logic [IDX_WIDTH-1:0]                                   k0_p0_idx_in;
    logic [IDX_WIDTH-1:0]                                   k0_p1_idx_in;
    logic [IDX_WIDTH-1:0]                                   k0_p2_idx_in;
    logic [IDX_WIDTH-1:0]                                   k0_p3_idx_in;
    logic [IDX_WIDTH-1:0]                                   k0_p4_idx_in;
    logic [IDX_WIDTH-1:0]                                   k0_p5_idx_in;
    logic [IDX_WIDTH-1:0]                                   k0_p6_idx_in;
    logic [IDX_WIDTH-1:0]                                   k0_p7_idx_in;
    logic [DIST_WIDTH-1:0]                                  k0_p0_l2_dist;
    logic [DIST_WIDTH-1:0]                                  k0_p1_l2_dist;
    logic [DIST_WIDTH-1:0]                                  k0_p2_l2_dist;
    logic [DIST_WIDTH-1:0]                                  k0_p3_l2_dist;
    logic [DIST_WIDTH-1:0]                                  k0_p4_l2_dist;
    logic [DIST_WIDTH-1:0]                                  k0_p5_l2_dist;
    logic [DIST_WIDTH-1:0]                                  k0_p6_l2_dist;
    logic [DIST_WIDTH-1:0]                                  k0_p7_l2_dist;
    logic [IDX_WIDTH-1:0]                                   k0_p0_idx_out;
    logic [IDX_WIDTH-1:0]                                   k0_p1_idx_out;
    logic [IDX_WIDTH-1:0]                                   k0_p2_idx_out;
    logic [IDX_WIDTH-1:0]                                   k0_p3_idx_out;
    logic [IDX_WIDTH-1:0]                                   k0_p4_idx_out;
    logic [IDX_WIDTH-1:0]                                   k0_p5_idx_out;
    logic [IDX_WIDTH-1:0]                                   k0_p6_idx_out;
    logic [IDX_WIDTH-1:0]                                   k0_p7_idx_out;
    logic                                                   s0_query_first_in;
    logic                                                   s0_query_first_out;
    logic                                                   s0_query_last_in;
    logic                                                   s0_query_last_out;
    logic                                                   s0_valid_in;
    logic                                                   s0_valid_out;
    logic [DIST_WIDTH-1:0]                                  s0_data_in_0;
    logic [DIST_WIDTH-1:0]                                  s0_data_in_1;
    logic [DIST_WIDTH-1:0]                                  s0_data_in_2;
    logic [DIST_WIDTH-1:0]                                  s0_data_in_3;
    logic [DIST_WIDTH-1:0]                                  s0_data_in_4;
    logic [DIST_WIDTH-1:0]                                  s0_data_in_5;
    logic [DIST_WIDTH-1:0]                                  s0_data_in_6;
    logic [DIST_WIDTH-1:0]                                  s0_data_in_7;
    logic [IDX_WIDTH-1:0]                                   s0_idx_in_0;
    logic [IDX_WIDTH-1:0]                                   s0_idx_in_1;
    logic [IDX_WIDTH-1:0]                                   s0_idx_in_2;
    logic [IDX_WIDTH-1:0]                                   s0_idx_in_3;
    logic [IDX_WIDTH-1:0]                                   s0_idx_in_4;
    logic [IDX_WIDTH-1:0]                                   s0_idx_in_5;
    logic [IDX_WIDTH-1:0]                                   s0_idx_in_6;
    logic [IDX_WIDTH-1:0]                                   s0_idx_in_7;
    logic [LEAF_ADDRW-1:0]                                  s0_leaf_idx_in;
    logic [LEAF_ADDRW-1:0]                                  s0_leaf_idx_out;
    logic [DIST_WIDTH-1:0]                                  s0_data_out_0;
    logic [DIST_WIDTH-1:0]                                  s0_data_out_1;
    logic [DIST_WIDTH-1:0]                                  s0_data_out_2;
    logic [DIST_WIDTH-1:0]                                  s0_data_out_3;
    logic [IDX_WIDTH-1:0]                                   s0_idx_out_0;
    logic [IDX_WIDTH-1:0]                                   s0_idx_out_1;
    logic [IDX_WIDTH-1:0]                                   s0_idx_out_2;
    logic [IDX_WIDTH-1:0]                                   s0_idx_out_3;
    logic                                                   sl0_restart;
    logic                                                   sl0_insert;
    logic                                                   sl0_last_in;
    logic [DIST_WIDTH-1:0]                                  sl0_l2_dist_in;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0]                        sl0_merged_idx_in;
    logic                                                   sl0_valid_out;
    logic [DIST_WIDTH-1:0]                                  sl0_l2_dist_0;
    logic [DIST_WIDTH-1:0]                                  sl0_l2_dist_1;
    logic [DIST_WIDTH-1:0]                                  sl0_l2_dist_2;
    logic [DIST_WIDTH-1:0]                                  sl0_l2_dist_3;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0]                        sl0_merged_idx_0;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0]                        sl0_merged_idx_1;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0]                        sl0_merged_idx_2;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0]                        sl0_merged_idx_3;
    logic [LEAF_ADDRW-1:0]                                  computes0_leaf_idx [K-1:0];

    logic                                                   k1_exactfstrow;
    logic                                                   k1_query_first_in;
    logic                                                   k1_query_first_out;
    logic                                                   k1_query_last_in;
    logic                                                   k1_query_last_out;
    logic                                                   k1_query_valid;
    logic signed [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]          k1_query_patch;
    logic                                                   k1_dist_valid;
    logic [LEAF_ADDRW-1:0]                                  k1_leaf_idx_in;
    logic [LEAF_ADDRW-1:0]                                  k1_leaf_idx_out;
    logic signed [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]          k1_p0_data;
    logic signed [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]          k1_p1_data;
    logic signed [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]          k1_p2_data;
    logic signed [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]          k1_p3_data;
    logic signed [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]          k1_p4_data;
    logic signed [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]          k1_p5_data;
    logic signed [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]          k1_p6_data;
    logic signed [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]          k1_p7_data;
    logic [IDX_WIDTH-1:0]                                   k1_p0_idx_in;
    logic [IDX_WIDTH-1:0]                                   k1_p1_idx_in;
    logic [IDX_WIDTH-1:0]                                   k1_p2_idx_in;
    logic [IDX_WIDTH-1:0]                                   k1_p3_idx_in;
    logic [IDX_WIDTH-1:0]                                   k1_p4_idx_in;
    logic [IDX_WIDTH-1:0]                                   k1_p5_idx_in;
    logic [IDX_WIDTH-1:0]                                   k1_p6_idx_in;
    logic [IDX_WIDTH-1:0]                                   k1_p7_idx_in;
    logic [DIST_WIDTH-1:0]                                  k1_p0_l2_dist;
    logic [DIST_WIDTH-1:0]                                  k1_p1_l2_dist;
    logic [DIST_WIDTH-1:0]                                  k1_p2_l2_dist;
    logic [DIST_WIDTH-1:0]                                  k1_p3_l2_dist;
    logic [DIST_WIDTH-1:0]                                  k1_p4_l2_dist;
    logic [DIST_WIDTH-1:0]                                  k1_p5_l2_dist;
    logic [DIST_WIDTH-1:0]                                  k1_p6_l2_dist;
    logic [DIST_WIDTH-1:0]                                  k1_p7_l2_dist;
    logic [IDX_WIDTH-1:0]                                   k1_p0_idx_out;
    logic [IDX_WIDTH-1:0]                                   k1_p1_idx_out;
    logic [IDX_WIDTH-1:0]                                   k1_p2_idx_out;
    logic [IDX_WIDTH-1:0]                                   k1_p3_idx_out;
    logic [IDX_WIDTH-1:0]                                   k1_p4_idx_out;
    logic [IDX_WIDTH-1:0]                                   k1_p5_idx_out;
    logic [IDX_WIDTH-1:0]                                   k1_p6_idx_out;
    logic [IDX_WIDTH-1:0]                                   k1_p7_idx_out;
    logic                                                   s1_query_first_in;
    logic                                                   s1_query_first_out;
    logic                                                   s1_query_last_in;
    logic                                                   s1_query_last_out;
    logic                                                   s1_valid_in;
    logic                                                   s1_valid_out;
    logic [DIST_WIDTH-1:0]                                  s1_data_in_0;
    logic [DIST_WIDTH-1:0]                                  s1_data_in_1;
    logic [DIST_WIDTH-1:0]                                  s1_data_in_2;
    logic [DIST_WIDTH-1:0]                                  s1_data_in_3;
    logic [DIST_WIDTH-1:0]                                  s1_data_in_4;
    logic [DIST_WIDTH-1:0]                                  s1_data_in_5;
    logic [DIST_WIDTH-1:0]                                  s1_data_in_6;
    logic [DIST_WIDTH-1:0]                                  s1_data_in_7;
    logic [IDX_WIDTH-1:0]                                   s1_idx_in_0;
    logic [IDX_WIDTH-1:0]                                   s1_idx_in_1;
    logic [IDX_WIDTH-1:0]                                   s1_idx_in_2;
    logic [IDX_WIDTH-1:0]                                   s1_idx_in_3;
    logic [IDX_WIDTH-1:0]                                   s1_idx_in_4;
    logic [IDX_WIDTH-1:0]                                   s1_idx_in_5;
    logic [IDX_WIDTH-1:0]                                   s1_idx_in_6;
    logic [IDX_WIDTH-1:0]                                   s1_idx_in_7;
    logic [LEAF_ADDRW-1:0]                                  s1_leaf_idx_in;
    logic [LEAF_ADDRW-1:0]                                  s1_leaf_idx_out;
    logic [DIST_WIDTH-1:0]                                  s1_data_out_0;
    logic [DIST_WIDTH-1:0]                                  s1_data_out_1;
    logic [DIST_WIDTH-1:0]                                  s1_data_out_2;
    logic [DIST_WIDTH-1:0]                                  s1_data_out_3;
    logic [IDX_WIDTH-1:0]                                   s1_idx_out_0;
    logic [IDX_WIDTH-1:0]                                   s1_idx_out_1;
    logic [IDX_WIDTH-1:0]                                   s1_idx_out_2;
    logic [IDX_WIDTH-1:0]                                   s1_idx_out_3;
    logic                                                   sl1_restart;
    logic                                                   sl1_insert;
    logic                                                   sl1_last_in;
    logic [DIST_WIDTH-1:0]                                  sl1_l2_dist_in;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0]                        sl1_merged_idx_in;
    logic                                                   sl1_valid_out;
    logic [DIST_WIDTH-1:0]                                  sl1_l2_dist_0;
    logic [DIST_WIDTH-1:0]                                  sl1_l2_dist_1;
    logic [DIST_WIDTH-1:0]                                  sl1_l2_dist_2;
    logic [DIST_WIDTH-1:0]                                  sl1_l2_dist_3;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0]                        sl1_merged_idx_0;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0]                        sl1_merged_idx_1;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0]                        sl1_merged_idx_2;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0]                        sl1_merged_idx_3;
    logic [LEAF_ADDRW-1:0]                                  computes1_leaf_idx [K-1:0];


    // input and output port registers
    always_ff @(posedge io_clk, negedge io_rst_n) begin
        if (~io_rst_n) begin
            io_load_kdtree_r <= '0;
            io_fsm_start_r <= '0;
            io_send_best_arr_r <= '0;
            io_load_done <= '0;
            io_fsm_done <= '0;
            io_send_done <= '0;
            in_fifo_wenq_r <= '0;
            in_fifo_wdata_r <= '0;
            in_fifo_wfull_n <= '0;
            out_fifo_deq_r <= '0;
            out_fifo_rdata <= '0;
            out_fifo_rempty_n <= '0;
        end else begin
            io_load_kdtree_r <= io_load_kdtree;
            io_fsm_start_r <= io_fsm_start;
            io_send_best_arr_r <= io_send_best_arr;
            io_load_done <= io_load_done_synced;
            io_fsm_done <= io_fsm_done_synced;
            io_send_done <= io_send_done_synced;
            in_fifo_wenq_r <= in_fifo_wenq;
            in_fifo_wdata_r <= in_fifo_wdata;
            in_fifo_wfull_n <= in_fifo_wfull_n_w;
            out_fifo_deq_r <= out_fifo_deq;
            out_fifo_rdata <= out_fifo_rdata_w;
            out_fifo_rempty_n <= out_fifo_rempty_n_w;
        end
    end
    
    always_ff @(posedge wb_clk_i, negedge wb_rst_n_i) begin
        if (~wb_rst_n_i) begin
            wbs_fsm_start_r <= '0;
            wbs_load_done <= '0;
            wbs_fsm_done <= '0;
            wbs_send_done <= '0;
        end else begin
            wbs_fsm_start_r <= wbs_fsm_start;
            wbs_load_done <= wbs_load_done_synced;
            wbs_fsm_done <= wbs_fsm_done_synced;
            wbs_send_done <= wbs_send_done_synced;
        end
    end

    // FSM pulses CDC for io_clk <=> clk
    SyncPulse io_fsm_start_sync (
        .sCLK(io_clk),
        .sRST(io_rst_n),  // not needed
        .sEN(io_fsm_start_r),
        .dCLK(clk),
        .dPulse(io_fsm_start_synced)
    );

    SyncPulse io_load_kdtree_sync (
        .sCLK(io_clk),
        .sRST(io_rst_n),  // not needed
        .sEN(io_load_kdtree_r),
        .dCLK(clk),
        .dPulse(io_load_kdtree_synced)
    );

    SyncPulse io_send_best_arr_sync (
        .sCLK(io_clk),
        .sRST(io_rst_n),  // not needed
        .sEN(io_send_best_arr_r),
        .dCLK(clk),
        .dPulse(io_send_best_arr_synced)
    );

    SyncPulse io_fsm_done_sync (
        .sCLK(clk),
        .sRST(rst_n),  // not needed
        .sEN(fsm_done_w),
        .dCLK(io_clk),
        .dPulse(io_fsm_done_synced)
    );

    SyncPulse io_load_done_sync (
        .sCLK(clk),
        .sRST(rst_n),  // not needed
        .sEN(load_done_w),
        .dCLK(io_clk),
        .dPulse(io_load_done_synced)
    );

    SyncPulse io_send_done_sync (
        .sCLK(clk),
        .sRST(rst_n),  // not needed
        .sEN(send_done_w),
        .dCLK(io_clk),
        .dPulse(io_send_done_synced)
    );


    // FSM pulses CDC for wb_clk <=> clk
    SyncPulse wbs_fsm_start_sync (
        .sCLK(wb_clk_i),
        .sRST(wb_rst_n_i),  // not needed
        .sEN(wbs_fsm_start_r),
        .dCLK(clk),
        .dPulse(wbs_fsm_start_synced)
    );

    SyncPulse wbs_fsm_done_sync (
        .sCLK(clk),
        .sRST(rst_n),  // not needed
        .sEN(fsm_done_w),
        .dCLK(wb_clk_i),
        .dPulse(wbs_fsm_done_synced)
    );

    SyncPulse wbs_load_done_sync (
        .sCLK(clk),
        .sRST(rst_n),  // not needed
        .sEN(load_done_w),
        .dCLK(wb_clk_i),
        .dPulse(wbs_load_done_synced)
    );

    SyncPulse wbs_send_done_sync (
        .sCLK(clk),
        .sRST(rst_n),  // not needed
        .sEN(send_done_w),
        .dCLK(wb_clk_i),
        .dPulse(wbs_send_done_synced)
    );


    // main controller
    MainFSM #(
        .DATA_WIDTH                             (DATA_WIDTH),
        .LEAF_SIZE                              (LEAF_SIZE),
        .PATCH_SIZE                             (PATCH_SIZE),
        .ROW_SIZE                               (ROW_SIZE),
        .COL_SIZE                               (COL_SIZE),
        .K                                      (K),
        .NUM_LEAVES                             (NUM_LEAVES),
        .BLOCKING                               (BLOCKING)
    ) main_fsm_inst (
        .clk                                    (clk),
        .rst_n                                  (rst_n),
        .load_kdtree                            (io_load_kdtree_synced),
        .load_done                              (load_done_w),
        .fsm_start                              (io_fsm_start_synced | wbs_fsm_start_synced),
        .fsm_done                               (fsm_done_w),
        .send_done                              (send_done_w),
        .send_best_arr                          (io_send_best_arr_synced),
        .agg_receiver_enq                       (agg_receiver_enq),
        .agg_receiver_full_n                    (agg_receiver_full_n),
        .agg_change_fetch_width                 (agg_change_fetch_width),
        .agg_input_fetch_width                  (agg_input_fetch_width),
        .int_node_sender_enable                 (int_node_sender_enable),
        .int_node_sender_addr                   (int_node_sender_addr),
        .int_node_patch_en                      (int_node_patch_en),
        .int_node_leaf_index                    (int_node_leaf_index),
        .int_node_patch_en2                     (int_node_patch_en2),
        .int_node_leaf_index2                   (int_node_leaf_index2),
        .qp_mem_csb0                            (qp_mem_csb0),
        .qp_mem_web0                            (qp_mem_web0),
        .qp_mem_addr0                           (qp_mem_addr0),
        .qp_mem_rpatch0                         (qp_mem_rpatch0),
        .qp_mem_csb1                            (qp_mem_csb1),
        .qp_mem_addr1                           (qp_mem_addr1),
        .qp_mem_rpatch1                         (qp_mem_rpatch1),
        .leaf_mem_csb0                          (leaf_mem_csb0),
        .leaf_mem_web0                          (leaf_mem_web0),
        .leaf_mem_addr0                         (leaf_mem_addr0),
        .leaf_mem_csb1                          (leaf_mem_csb1),
        .leaf_mem_addr1                         (leaf_mem_addr1),
        .best_arr_addr0                         (best_arr_addr0),
        .best_arr_csb1                          (best_arr_csb1),
        .best_arr_addr1                         (best_arr_addr1),
        .out_fifo_wdata_sel                     (out_fifo_wdata_sel),
        .out_fifo_wenq                          (out_fifo_wenq),
        .out_fifo_wfull_n                       (out_fifo_wfull_n),
        .k0_query_valid                         (k0_query_valid),
        .k0_query_first_in                      (k0_query_first_in),
        .k0_query_last_in                       (k0_query_last_in),
        .k0_query_patch                         (k0_query_patch),
        .sl0_valid_out                          (sl0_valid_out),
        .computes0_leaf_idx                     (computes0_leaf_idx),
        .k1_exactfstrow                         (k1_exactfstrow),
        .k1_query_valid                         (k1_query_valid),
        .k1_query_first_in                      (k1_query_first_in),
        .k1_query_last_in                       (k1_query_last_in),
        .k1_query_patch                         (k1_query_patch),
        .sl1_valid_out                          (sl1_valid_out),
        .computes1_leaf_idx                     (computes1_leaf_idx)
    );

    // the propagated leaf idx are store in registers in the main fsm
    // so we do not need to store in best arrays
    assign computes0_leaf_idx   = { sl0_merged_idx_3[LEAF_ADDRW+IDX_WIDTH-1:IDX_WIDTH],
                                    sl0_merged_idx_2[LEAF_ADDRW+IDX_WIDTH-1:IDX_WIDTH],
                                    sl0_merged_idx_1[LEAF_ADDRW+IDX_WIDTH-1:IDX_WIDTH],
                                    sl0_merged_idx_0[LEAF_ADDRW+IDX_WIDTH-1:IDX_WIDTH] };
    assign computes1_leaf_idx   = { sl1_merged_idx_3[LEAF_ADDRW+IDX_WIDTH-1:IDX_WIDTH],
                                    sl1_merged_idx_2[LEAF_ADDRW+IDX_WIDTH-1:IDX_WIDTH],
                                    sl1_merged_idx_1[LEAF_ADDRW+IDX_WIDTH-1:IDX_WIDTH],
                                    sl1_merged_idx_0[LEAF_ADDRW+IDX_WIDTH-1:IDX_WIDTH] };



    // I/O FIFO and Aggregator
    SyncFIFO #(
        .dataWidth          (DATA_WIDTH),
        .depth              (16),
        .indxWidth          (4)
    ) input_fifo_inst (
        .sCLK               (io_clk),
        .sRST               (io_rst_n),
        .sENQ               (in_fifo_wenq_r),
        .sD_IN              (in_fifo_wdata_r),
        .sFULL_N            (in_fifo_wfull_n_w),
        .dCLK               (clk),
        .dDEQ               (in_fifo_deq),
        .dD_OUT             (in_fifo_rdata),
        .dEMPTY_N           (in_fifo_rempty_n)
    );

    assign in_fifo_deq = agg_sender_deq;
	
    aggregator
    #(
        .DATA_WIDTH         (DATA_WIDTH),
        .FETCH_WIDTH        (6)
    ) in_fifo_aggregator_inst
    (
        .clk                (clk),
        .rst_n              (rst_n),
        .sender_data        (agg_sender_data),
        .sender_empty_n     (agg_sender_empty_n),
        .sender_deq         (agg_sender_deq),
        .receiver_data      (agg_receiver_data),
        .receiver_full_n    (agg_receiver_full_n),
        .receiver_enq       (agg_receiver_enq),
        .change_fetch_width (agg_change_fetch_width),
        .input_fetch_width  (agg_input_fetch_width)
    );

    assign agg_sender_data = in_fifo_rdata;
    assign agg_sender_empty_n = in_fifo_rempty_n;


    // out fifo de-aggregator
    // registers 11 bits to be sent to fifo later
    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n) out_fifo_wdata_n11 <= '0;
        else if (out_fifo_wdata_sel[1]) begin
            // the acutal dist stored is 23 bits
            // but we are just sending the lower 22 bits
            out_fifo_wdata_n11 <= out_fifo_wdata_sel[0]
                                    ? best_arr_rdata1[0][62:52]
                                    : best_arr_rdata1[0][30:20];
        end
    end


    SyncFIFO #(
        .dataWidth          (DATA_WIDTH),
        .depth              (16),
        .indxWidth          (4)
    ) output_fifo_inst (
        .sCLK               (clk),
        .sRST               (rst_n),
        .sENQ               (out_fifo_wenq),
        .sD_IN              (out_fifo_wdata),
        .sFULL_N            (out_fifo_wfull_n),
        .dCLK               (io_clk),
        .dDEQ               (out_fifo_deq_r),
        .dD_OUT             (out_fifo_rdata_w),
        .dEMPTY_N           (out_fifo_rempty_n_w)
    );

    always_comb begin
        case (out_fifo_wdata_sel)
            3'd0: out_fifo_wdata = {2'b0, best_arr_rdata1[0][IDX_WIDTH-1:0]};
            3'd1: out_fifo_wdata = {2'b0, best_arr_rdata1[0][32+IDX_WIDTH-1:32]};
            3'd2: out_fifo_wdata = best_arr_rdata1[0][19:9];
            3'd3: out_fifo_wdata = best_arr_rdata1[0][51:41];
            3'd4: out_fifo_wdata = out_fifo_wdata_n11;
            default: begin
                out_fifo_wdata = {2'b0, best_arr_rdata1[0][IDX_WIDTH-1:0]};
            end
        endcase
    end


    // Memories
    internal_node_tree
    #(
        .INTERNAL_WIDTH     (2*DATA_WIDTH),
        .PATCH_WIDTH        (PATCH_SIZE*DATA_WIDTH),
        .ADDRESS_WIDTH      (LEAF_ADDRW)
    ) internal_node_inst (
        .clk                (clk),
        .rst_n              (rst_n),
        .sender_enable      (wbs_debug ? wbs_node_mem_we : int_node_sender_enable),
        .sender_data        (wbs_debug ? wbs_node_mem_wdata : int_node_sender_data),
        .sender_addr        (wbs_debug ? wbs_node_mem_addr : int_node_sender_addr),
        .patch_en           (int_node_patch_en),
        .patch_in           (int_node_patch_in),
        .leaf_index         (int_node_leaf_index),
        .receiver_en        (int_node_leaf_valid),
        .patch_two_en       (int_node_patch_en2),
        .patch_in_two       (int_node_patch_in2),
        .leaf_index_two     (int_node_leaf_index2),
        .receiver_two_en    (int_node_leaf_valid2),
        .wbs_rd_en_i        (wbs_debug ? wbs_node_mem_rd : 1'b0), 
        .wbs_dat_o          (wbs_node_mem_rdata)
    );

    assign int_node_sender_data = agg_receiver_data[2*DATA_WIDTH-1:0];
    assign int_node_patch_in = qp_mem_rpatch0;
    assign int_node_patch_in2 = qp_mem_rpatch1;

    LeavesMem #(
        .DATA_WIDTH         (DATA_WIDTH),
        .IDX_WIDTH          (IDX_WIDTH),
        .LEAF_SIZE          (LEAF_SIZE),
        .PATCH_SIZE         (PATCH_SIZE),
        .NUM_LEAVES         (NUM_LEAVES)
    ) leaf_mem_inst (
        .clk                (clk),
        .csb0               (wbs_debug ?wbs_leaf_mem_csb0 :leaf_mem_csb0),
        .web0               (wbs_debug ?wbs_leaf_mem_web0 :leaf_mem_web0),
        .addr0              (wbs_debug ?wbs_leaf_mem_addr0 :leaf_mem_addr0),
        .wleaf0             (wbs_debug ?wbs_leaf_mem_wleaf0 :leaf_mem_wleaf0),
        .rleaf0             (wbs_leaf_mem_rleaf0),
        .rpatch_data0       (leaf_mem_rpatch_data0),
        .rpatch_idx0        (leaf_mem_rpatch_idx0),
        .csb1               (leaf_mem_csb1),
        .addr1              (leaf_mem_addr1),
        .rpatch_data1       (leaf_mem_rpatch_data1),
        .rpatch_idx1        (leaf_mem_rpatch_idx1)
    );

    assign leaf_mem_wleaf0 = agg_receiver_data[PATCH_SIZE*DATA_WIDTH+IDX_WIDTH-1:0]; // index will be capped due to the macro width

    QueryPatchMem2 #(
        .DATA_WIDTH         (DATA_WIDTH),
        .PATCH_SIZE         (PATCH_SIZE),
        .ADDR_WIDTH         (9),
        .DEPTH              (512)
    ) qp_mem_inst (
        .clk                (clk),
        .csb0               (wbs_debug ?wbs_qp_mem_csb0 :qp_mem_csb0),
        .web0               (wbs_debug ?wbs_qp_mem_web0 :qp_mem_web0),
        .addr0              (wbs_debug ?wbs_qp_mem_addr0 :qp_mem_addr0),
        .wpatch0            (wbs_debug ?wbs_qp_mem_wpatch0 :qp_mem_wpatch0),
        .rpatch0            (qp_mem_rpatch0),
        .csb1               (qp_mem_csb1),
        .addr1              (qp_mem_addr1),
        .rpatch1            (qp_mem_rpatch1)
    );

    assign wbs_qp_mem_rpatch0 = qp_mem_rpatch0;
    assign qp_mem_wpatch0 = agg_receiver_data;

    kBestArrays #(
        .DATA_WIDTH         (64),  // each compute has 32b
        .IDX_WIDTH          (IDX_WIDTH),
        .K                  (BEST_ARRAY_K),
        .NUM_LEAVES         (NUM_LEAVES)
    ) k_best_array_inst (
        .clk                (clk),
        .csb0               (best_arr_csb0),
        .web0               (best_arr_web0),
        .addr0              (best_arr_addr0),
        .wdata0             (best_arr_wdata0),
        .rdata0             (best_arr_rdata0),
        .csb1               (wbs_debug ?wbs_best_arr_csb1 :best_arr_csb1),
        .addr1              (wbs_debug ?wbs_best_arr_addr1 :best_arr_addr1),
        .rdata1             (best_arr_rdata1)
    );

    assign wbs_best_arr_rdata1 = best_arr_rdata1[0];
    assign best_arr_csb0 = ~sl0_valid_out;
    assign best_arr_web0 = 1'b0;

    logic [22:0] sl0_l2_dist_capped;
    logic [22:0] sl1_l2_dist_capped;
    assign sl0_l2_dist_capped = (|sl0_l2_dist_0[DIST_WIDTH-1:23]) ?23'h7FFFFF :sl0_l2_dist_0[22:0];
    assign sl1_l2_dist_capped = (|sl1_l2_dist_0[DIST_WIDTH-1:23]) ?23'h7FFFFF :sl1_l2_dist_0[22:0];
    assign best_arr_wdata0[0][31:0]    = {sl0_l2_dist_capped, sl0_merged_idx_0[IDX_WIDTH-1:0]};
    assign best_arr_wdata0[0][63:32]   = {sl1_l2_dist_capped, sl1_merged_idx_0[IDX_WIDTH-1:0]};


    // Computes 0
    L2Kernel l2_k0_inst (
        .clk                (clk),
        .rst_n              (rst_n),
        .query_first_in     (k0_query_first_in),
        .query_first_out    (k0_query_first_out),
        .query_last_in      (k0_query_last_in),
        .query_last_out     (k0_query_last_out),
        .query_valid        (k0_query_valid),
        .query_patch        (k0_query_patch),
        .dist_valid         (k0_dist_valid),
        .leaf_idx_in        (k0_leaf_idx_in),
        .leaf_idx_out       (k0_leaf_idx_out),
        .p0_data            (k0_p0_data),
        .p1_data            (k0_p1_data),
        .p2_data            (k0_p2_data),
        .p3_data            (k0_p3_data),
        .p4_data            (k0_p4_data),
        .p5_data            (k0_p5_data),
        .p6_data            (k0_p6_data),
        .p7_data            (k0_p7_data),
        .p0_idx_in          (k0_p0_idx_in),
        .p1_idx_in          (k0_p1_idx_in),
        .p2_idx_in          (k0_p2_idx_in),
        .p3_idx_in          (k0_p3_idx_in),
        .p4_idx_in          (k0_p4_idx_in),
        .p5_idx_in          (k0_p5_idx_in),
        .p6_idx_in          (k0_p6_idx_in),
        .p7_idx_in          (k0_p7_idx_in),
        .p0_l2_dist         (k0_p0_l2_dist),
        .p1_l2_dist         (k0_p1_l2_dist),
        .p2_l2_dist         (k0_p2_l2_dist),
        .p3_l2_dist         (k0_p3_l2_dist),
        .p4_l2_dist         (k0_p4_l2_dist),
        .p5_l2_dist         (k0_p5_l2_dist),
        .p6_l2_dist         (k0_p6_l2_dist),
        .p7_l2_dist         (k0_p7_l2_dist),
        .p0_idx_out         (k0_p0_idx_out),
        .p1_idx_out         (k0_p1_idx_out),
        .p2_idx_out         (k0_p2_idx_out),
        .p3_idx_out         (k0_p3_idx_out),
        .p4_idx_out         (k0_p4_idx_out),
        .p5_idx_out         (k0_p5_idx_out),
        .p6_idx_out         (k0_p6_idx_out),
        .p7_idx_out         (k0_p7_idx_out)
    );

    assign k0_p0_data = leaf_mem_rpatch_data0[0];
    assign k0_p1_data = leaf_mem_rpatch_data0[1];
    assign k0_p2_data = leaf_mem_rpatch_data0[2];
    assign k0_p3_data = leaf_mem_rpatch_data0[3];
    assign k0_p4_data = leaf_mem_rpatch_data0[4];
    assign k0_p5_data = leaf_mem_rpatch_data0[5];
    assign k0_p6_data = leaf_mem_rpatch_data0[6];
    assign k0_p7_data = leaf_mem_rpatch_data0[7];
    assign k0_p0_idx_in = leaf_mem_rpatch_idx0[0];
    assign k0_p1_idx_in = leaf_mem_rpatch_idx0[1];
    assign k0_p2_idx_in = leaf_mem_rpatch_idx0[2];
    assign k0_p3_idx_in = leaf_mem_rpatch_idx0[3];
    assign k0_p4_idx_in = leaf_mem_rpatch_idx0[4];
    assign k0_p5_idx_in = leaf_mem_rpatch_idx0[5];
    assign k0_p6_idx_in = leaf_mem_rpatch_idx0[6];
    assign k0_p7_idx_in = leaf_mem_rpatch_idx0[7];

    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n) k0_leaf_idx_in <= '0;
        else if ((~leaf_mem_csb0) & leaf_mem_web0) begin
            k0_leaf_idx_in <= leaf_mem_addr0;
        end
    end


    BitonicSorter sorter0_inst(
        .clk                (clk),
        .rst_n              (rst_n),
        .query_first_in     (s0_query_first_in),
        .query_first_out    (s0_query_first_out),
        .query_last_in      (s0_query_last_in),
        .query_last_out     (s0_query_last_out),
        .valid_in           (s0_valid_in),
        .valid_out          (s0_valid_out),
        .data_in_0          (s0_data_in_0),
        .data_in_1          (s0_data_in_1),
        .data_in_2          (s0_data_in_2),
        .data_in_3          (s0_data_in_3),
        .data_in_4          (s0_data_in_4),
        .data_in_5          (s0_data_in_5),
        .data_in_6          (s0_data_in_6),
        .data_in_7          (s0_data_in_7),
        .idx_in_0           (s0_idx_in_0),
        .idx_in_1           (s0_idx_in_1),
        .idx_in_2           (s0_idx_in_2),
        .idx_in_3           (s0_idx_in_3),
        .idx_in_4           (s0_idx_in_4),
        .idx_in_5           (s0_idx_in_5),
        .idx_in_6           (s0_idx_in_6),
        .idx_in_7           (s0_idx_in_7),
        .leaf_idx_in        (s0_leaf_idx_in),
        .leaf_idx_out       (s0_leaf_idx_out),
        .data_out_0         (s0_data_out_0),
        .data_out_1         (s0_data_out_1),
        .data_out_2         (s0_data_out_2),
        .data_out_3         (s0_data_out_3),
        .idx_out_0          (s0_idx_out_0),
        .idx_out_1          (s0_idx_out_1),
        .idx_out_2          (s0_idx_out_2),
        .idx_out_3          (s0_idx_out_3)
    );

    assign s0_query_first_in    =   k0_query_first_out;
    assign s0_query_last_in     =   k0_query_last_out;
    assign s0_valid_in          =   k0_dist_valid;
    assign s0_data_in_0         =   k0_p0_l2_dist;
    assign s0_data_in_1         =   k0_p1_l2_dist;
    assign s0_data_in_2         =   k0_p2_l2_dist;
    assign s0_data_in_3         =   k0_p3_l2_dist;
    assign s0_data_in_4         =   k0_p4_l2_dist;
    assign s0_data_in_5         =   k0_p5_l2_dist;
    assign s0_data_in_6         =   k0_p6_l2_dist;
    assign s0_data_in_7         =   k0_p7_l2_dist;
    assign s0_idx_in_0          =   k0_p0_idx_out;
    assign s0_idx_in_1          =   k0_p1_idx_out;
    assign s0_idx_in_2          =   k0_p2_idx_out;
    assign s0_idx_in_3          =   k0_p3_idx_out;
    assign s0_idx_in_4          =   k0_p4_idx_out;
    assign s0_idx_in_5          =   k0_p5_idx_out;
    assign s0_idx_in_6          =   k0_p6_idx_out;
    assign s0_idx_in_7          =   k0_p7_idx_out;
    assign s0_leaf_idx_in       =   k0_leaf_idx_out;

    SortedList sl0(
        .clk                    (clk),
        .rst_n                  (rst_n),
        .restart                (sl0_restart),
        .insert                 (sl0_insert),
        .last_in                (sl0_last_in),
        .l2_dist_in             (sl0_l2_dist_in),
        .merged_idx_in          (sl0_merged_idx_in),
        .valid_out              (sl0_valid_out),
        .l2_dist_0              (sl0_l2_dist_0),
        .l2_dist_1              (sl0_l2_dist_1),
        .l2_dist_2              (sl0_l2_dist_2),
        .l2_dist_3              (sl0_l2_dist_3),
        .merged_idx_0           (sl0_merged_idx_0),
        .merged_idx_1           (sl0_merged_idx_1),
        .merged_idx_2           (sl0_merged_idx_2),
        .merged_idx_3           (sl0_merged_idx_3)
    );

    assign sl0_restart          =   s0_query_first_out;
    assign sl0_insert           =   s0_valid_out;
    assign sl0_last_in          =   s0_query_last_out;
    assign sl0_l2_dist_in       =   s0_data_out_0;
    assign sl0_merged_idx_in    =   {s0_leaf_idx_out, s0_idx_out_0};
    
    
    // Computes 1
    L2Kernel l2_k1_inst (
        .clk                (clk),
        .rst_n              (rst_n),
        .query_first_in     (k1_query_first_in),
        .query_first_out    (k1_query_first_out),
        .query_last_in      (k1_query_last_in),
        .query_last_out     (k1_query_last_out),
        .query_valid        (k1_query_valid),
        .query_patch        (k1_query_patch),
        .dist_valid         (k1_dist_valid),
        .leaf_idx_in        (k1_exactfstrow ?k0_leaf_idx_in :k1_leaf_idx_in), // a special case to reduce the number of SRAM reads
        .leaf_idx_out       (k1_leaf_idx_out),
        .p0_data            (k1_p0_data),
        .p1_data            (k1_p1_data),
        .p2_data            (k1_p2_data),
        .p3_data            (k1_p3_data),
        .p4_data            (k1_p4_data),
        .p5_data            (k1_p5_data),
        .p6_data            (k1_p6_data),
        .p7_data            (k1_p7_data),
        .p0_idx_in          (k1_p0_idx_in),
        .p1_idx_in          (k1_p1_idx_in),
        .p2_idx_in          (k1_p2_idx_in),
        .p3_idx_in          (k1_p3_idx_in),
        .p4_idx_in          (k1_p4_idx_in),
        .p5_idx_in          (k1_p5_idx_in),
        .p6_idx_in          (k1_p6_idx_in),
        .p7_idx_in          (k1_p7_idx_in),
        .p0_l2_dist         (k1_p0_l2_dist),
        .p1_l2_dist         (k1_p1_l2_dist),
        .p2_l2_dist         (k1_p2_l2_dist),
        .p3_l2_dist         (k1_p3_l2_dist),
        .p4_l2_dist         (k1_p4_l2_dist),
        .p5_l2_dist         (k1_p5_l2_dist),
        .p6_l2_dist         (k1_p6_l2_dist),
        .p7_l2_dist         (k1_p7_l2_dist),
        .p0_idx_out         (k1_p0_idx_out),
        .p1_idx_out         (k1_p1_idx_out),
        .p2_idx_out         (k1_p2_idx_out),
        .p3_idx_out         (k1_p3_idx_out),
        .p4_idx_out         (k1_p4_idx_out),
        .p5_idx_out         (k1_p5_idx_out),
        .p6_idx_out         (k1_p6_idx_out),
        .p7_idx_out         (k1_p7_idx_out)
    );

    assign k1_p0_data       =   k1_exactfstrow ?leaf_mem_rpatch_data0[0] :leaf_mem_rpatch_data1[0];
    assign k1_p1_data       =   k1_exactfstrow ?leaf_mem_rpatch_data0[1] :leaf_mem_rpatch_data1[1];
    assign k1_p2_data       =   k1_exactfstrow ?leaf_mem_rpatch_data0[2] :leaf_mem_rpatch_data1[2];
    assign k1_p3_data       =   k1_exactfstrow ?leaf_mem_rpatch_data0[3] :leaf_mem_rpatch_data1[3];
    assign k1_p4_data       =   k1_exactfstrow ?leaf_mem_rpatch_data0[4] :leaf_mem_rpatch_data1[4];
    assign k1_p5_data       =   k1_exactfstrow ?leaf_mem_rpatch_data0[5] :leaf_mem_rpatch_data1[5];
    assign k1_p6_data       =   k1_exactfstrow ?leaf_mem_rpatch_data0[6] :leaf_mem_rpatch_data1[6];
    assign k1_p7_data       =   k1_exactfstrow ?leaf_mem_rpatch_data0[7] :leaf_mem_rpatch_data1[7];
    assign k1_p0_idx_in     =   k1_exactfstrow ?leaf_mem_rpatch_idx0[0] :leaf_mem_rpatch_idx1[0];
    assign k1_p1_idx_in     =   k1_exactfstrow ?leaf_mem_rpatch_idx0[1] :leaf_mem_rpatch_idx1[1];
    assign k1_p2_idx_in     =   k1_exactfstrow ?leaf_mem_rpatch_idx0[2] :leaf_mem_rpatch_idx1[2];
    assign k1_p3_idx_in     =   k1_exactfstrow ?leaf_mem_rpatch_idx0[3] :leaf_mem_rpatch_idx1[3];
    assign k1_p4_idx_in     =   k1_exactfstrow ?leaf_mem_rpatch_idx0[4] :leaf_mem_rpatch_idx1[4];
    assign k1_p5_idx_in     =   k1_exactfstrow ?leaf_mem_rpatch_idx0[5] :leaf_mem_rpatch_idx1[5];
    assign k1_p6_idx_in     =   k1_exactfstrow ?leaf_mem_rpatch_idx0[6] :leaf_mem_rpatch_idx1[6];
    assign k1_p7_idx_in     =   k1_exactfstrow ?leaf_mem_rpatch_idx0[7] :leaf_mem_rpatch_idx1[7];

    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n) k1_leaf_idx_in <= '0;
        else if (~leaf_mem_csb1) begin
            k1_leaf_idx_in <= leaf_mem_addr1;
        end
    end


    BitonicSorter sorter1_inst(
        .clk                (clk),
        .rst_n              (rst_n),
        .query_first_in     (s1_query_first_in),
        .query_first_out    (s1_query_first_out),
        .query_last_in      (s1_query_last_in),
        .query_last_out     (s1_query_last_out),
        .valid_in           (s1_valid_in),
        .valid_out          (s1_valid_out),
        .data_in_0          (s1_data_in_0),
        .data_in_1          (s1_data_in_1),
        .data_in_2          (s1_data_in_2),
        .data_in_3          (s1_data_in_3),
        .data_in_4          (s1_data_in_4),
        .data_in_5          (s1_data_in_5),
        .data_in_6          (s1_data_in_6),
        .data_in_7          (s1_data_in_7),
        .idx_in_0           (s1_idx_in_0),
        .idx_in_1           (s1_idx_in_1),
        .idx_in_2           (s1_idx_in_2),
        .idx_in_3           (s1_idx_in_3),
        .idx_in_4           (s1_idx_in_4),
        .idx_in_5           (s1_idx_in_5),
        .idx_in_6           (s1_idx_in_6),
        .idx_in_7           (s1_idx_in_7),
        .leaf_idx_in        (s1_leaf_idx_in),
        .leaf_idx_out       (s1_leaf_idx_out),
        .data_out_0         (s1_data_out_0),
        .data_out_1         (s1_data_out_1),
        .data_out_2         (s1_data_out_2),
        .data_out_3         (s1_data_out_3),
        .idx_out_0          (s1_idx_out_0),
        .idx_out_1          (s1_idx_out_1),
        .idx_out_2          (s1_idx_out_2),
        .idx_out_3          (s1_idx_out_3)
    );

    assign s1_query_first_in    =   k1_query_first_out;
    assign s1_query_last_in     =   k1_query_last_out;
    assign s1_valid_in          =   k1_dist_valid;
    assign s1_data_in_0         =   k1_p0_l2_dist;
    assign s1_data_in_1         =   k1_p1_l2_dist;
    assign s1_data_in_2         =   k1_p2_l2_dist;
    assign s1_data_in_3         =   k1_p3_l2_dist;
    assign s1_data_in_4         =   k1_p4_l2_dist;
    assign s1_data_in_5         =   k1_p5_l2_dist;
    assign s1_data_in_6         =   k1_p6_l2_dist;
    assign s1_data_in_7         =   k1_p7_l2_dist;
    assign s1_idx_in_0          =   k1_p0_idx_out;
    assign s1_idx_in_1          =   k1_p1_idx_out;
    assign s1_idx_in_2          =   k1_p2_idx_out;
    assign s1_idx_in_3          =   k1_p3_idx_out;
    assign s1_idx_in_4          =   k1_p4_idx_out;
    assign s1_idx_in_5          =   k1_p5_idx_out;
    assign s1_idx_in_6          =   k1_p6_idx_out;
    assign s1_idx_in_7          =   k1_p7_idx_out;
    assign s1_leaf_idx_in       =   k1_leaf_idx_out;

    SortedList sl1(
        .clk                    (clk),
        .rst_n                  (rst_n),
        .restart                (sl1_restart),
        .insert                 (sl1_insert),
        .last_in                (sl1_last_in),
        .l2_dist_in             (sl1_l2_dist_in),
        .merged_idx_in          (sl1_merged_idx_in),
        .valid_out              (sl1_valid_out),
        .l2_dist_0              (sl1_l2_dist_0),
        .l2_dist_1              (sl1_l2_dist_1),
        .l2_dist_2              (sl1_l2_dist_2),
        .l2_dist_3              (sl1_l2_dist_3),
        .merged_idx_0           (sl1_merged_idx_0),
        .merged_idx_1           (sl1_merged_idx_1),
        .merged_idx_2           (sl1_merged_idx_2),
        .merged_idx_3           (sl1_merged_idx_3)
    );

    assign sl1_restart          =   s1_query_first_out;
    assign sl1_insert           =   s1_valid_out;
    assign sl1_last_in          =   s1_query_last_out;
    assign sl1_l2_dist_in       =   s1_data_out_0;
    assign sl1_merged_idx_in    =   {s1_leaf_idx_out, s1_idx_out_0};

endmodule
