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
    parameter NUM_LEAVES = 64,
    parameter BLOCKING = 4,
    parameter LEAF_ADDRW = $clog2(NUM_LEAVES)
)
(
    input logic clk,
    input logic rst_n,

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


    logic                                                   in_fifo_deq;
    logic [DATA_WIDTH-1:0]                                  in_fifo_rdata;
    logic                                                   in_fifo_rempty_n;
    logic                                                   out_fifo_wdata_sel;
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

    logic                                                   int_node_fsm_enable;
    logic                                                   int_node_sender_enable;
    logic [2*DATA_WIDTH-1:0]                                int_node_sender_data;
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
    logic [8:0]                                             best_arr_addr0;
    logic [DATA_WIDTH-1:0]                                  best_arr_wdist_0 [K-1:0];
    logic [IDX_WIDTH-1:0]                                   best_arr_widx_0 [K-1:0];
    logic [LEAF_ADDRW-1:0]                                  best_arr_wleaf_idx_0 [K-1:0];
    logic [DATA_WIDTH-1:0]                                  best_arr_rdist_0 [K-1:0];
    logic [IDX_WIDTH-1:0]                                   best_arr_ridx_0 [K-1:0];
    logic [LEAF_ADDRW-1:0]                                  best_arr_rleaf_idx_0 [K-1:0];
    logic [K-1:0]                                           best_arr_csb1;
    logic [8:0]                                             best_arr_addr1;
    logic [DATA_WIDTH-1:0]                                  best_arr_rdist_1 [K-1:0];
    logic [IDX_WIDTH-1:0]                                   best_arr_ridx_1 [K-1:0];
    logic [LEAF_ADDRW-1:0]                                  best_arr_rleaf_idx_1 [K-1:0];

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
    logic [LEAF_ADDRW+IDX_WIDTH-1:0]                        s0_idx_in_0;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0]                        s0_idx_in_1;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0]                        s0_idx_in_2;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0]                        s0_idx_in_3;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0]                        s0_idx_in_4;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0]                        s0_idx_in_5;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0]                        s0_idx_in_6;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0]                        s0_idx_in_7;
    logic [DIST_WIDTH-1:0]                                  s0_data_out_0;
    logic [DIST_WIDTH-1:0]                                  s0_data_out_1;
    logic [DIST_WIDTH-1:0]                                  s0_data_out_2;
    logic [DIST_WIDTH-1:0]                                  s0_data_out_3;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0]                        s0_idx_out_0;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0]                        s0_idx_out_1;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0]                        s0_idx_out_2;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0]                        s0_idx_out_3;
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
    logic [LEAF_ADDRW+IDX_WIDTH-1:0]                        s1_idx_in_0;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0]                        s1_idx_in_1;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0]                        s1_idx_in_2;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0]                        s1_idx_in_3;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0]                        s1_idx_in_4;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0]                        s1_idx_in_5;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0]                        s1_idx_in_6;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0]                        s1_idx_in_7;
    logic [DIST_WIDTH-1:0]                                  s1_data_out_0;
    logic [DIST_WIDTH-1:0]                                  s1_data_out_1;
    logic [DIST_WIDTH-1:0]                                  s1_data_out_2;
    logic [DIST_WIDTH-1:0]                                  s1_data_out_3;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0]                        s1_idx_out_0;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0]                        s1_idx_out_1;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0]                        s1_idx_out_2;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0]                        s1_idx_out_3;
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
        .load_kdtree                            (load_kdtree),
        .fsm_start                              (fsm_start),
        .fsm_done                               (fsm_done),
        .send_best_arr                          (send_best_arr),
        .agg_receiver_enq                       (agg_receiver_enq),
        .agg_receiver_full_n                    (agg_receiver_full_n),
        .agg_change_fetch_width                 (agg_change_fetch_width),
        .agg_input_fetch_width                  (agg_input_fetch_width),
        .int_node_fsm_enable                    (int_node_fsm_enable),
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


    // I/O FIFO and Aggregator
    SyncFIFO #(
        .dataWidth          (DATA_WIDTH),
        .depth              (16),
        .indxWidth          (4)
    ) input_fifo_inst (
        .sCLK               (io_clk),
        .sRST               (io_rst_n),
        .sENQ               (in_fifo_wenq),
        .sD_IN              (in_fifo_wdata),
        .sFULL_N            (in_fifo_wfull_n),
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
        .dDEQ               (out_fifo_deq),
        .dD_OUT             (out_fifo_rdata),
        .dEMPTY_N           (out_fifo_rempty_n)
    );

    // reads only the best patch idx
    assign out_fifo_wdata = out_fifo_wdata_sel ?best_arr_ridx_1[0] :best_arr_rdist_1[0][IDX_WIDTH-1:0]; //TODO
    // if you want to read only the best leaf idx
    // assign out_fifo_wdata = best_arr_rleaf_idx_1[0];


    // Memories
    internal_node_tree
    #(
        .INTERNAL_WIDTH     (2*DATA_WIDTH),
        .PATCH_WIDTH        (PATCH_SIZE*DATA_WIDTH),
        .ADDRESS_WIDTH      (LEAF_ADDRW)
    ) internal_node_inst (
        .clk                (clk),
        .rst_n              (rst_n),
        .fsm_enable         (int_node_fsm_enable), //based on whether we are at the proper I/O portion
        .sender_enable      (int_node_sender_enable),
        .sender_data        (int_node_sender_data),
        .patch_en           (int_node_patch_en),
        .patch_in           (int_node_patch_in),
        .leaf_index         (int_node_leaf_index),
        .receiver_en        (int_node_leaf_valid),
        .patch_two_en       (int_node_patch_en2),
        .patch_in_two       (int_node_patch_in2),
        .leaf_index_two     (int_node_leaf_index2),
        .receiver_two_en    (int_node_leaf_valid2),
        .wb_mode            (1'b0)
    );

    assign int_node_sender_enable = agg_receiver_enq;
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
        .csb0               (leaf_mem_csb0),
        .web0               (leaf_mem_web0),
        .addr0              (leaf_mem_addr0),
        .wleaf0             (leaf_mem_wleaf0),
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
        .csb0               (qp_mem_csb0),
        .web0               (qp_mem_web0),
        .addr0              (qp_mem_addr0),
        .wpatch0            (qp_mem_wpatch0),
        .rpatch0            (qp_mem_rpatch0),
        .csb1               (qp_mem_csb1),
        .addr1              (qp_mem_addr1),
        .rpatch1            (qp_mem_rpatch1)
    );

    assign qp_mem_wpatch0 = agg_receiver_data;

    kBestArrays #(
        .DATA_WIDTH         (DATA_WIDTH),
        .IDX_WIDTH          (IDX_WIDTH),
        .K                  (K),
        .NUM_LEAVES         (NUM_LEAVES)
    ) k_best_array_inst (
        .clk                (clk),
        .csb0               (best_arr_csb0),
        .web0               (best_arr_web0),
        .addr0              (best_arr_addr0),
        .wdist_0            (best_arr_wdist_0),
        .widx_0             (best_arr_widx_0),
        .wleaf_idx_0        (best_arr_wleaf_idx_0),
        .rdist_0            (best_arr_rdist_0),
        .ridx_0             (best_arr_ridx_0),
        .rleaf_idx_0        (best_arr_rleaf_idx_0),
        .csb1               (best_arr_csb1),
        .addr1              (best_arr_addr1),
        .rdist_1            (best_arr_rdist_1),
        .ridx_1             (best_arr_ridx_1),
        .rleaf_idx_1        (best_arr_rleaf_idx_1)
    );


    //TODO: rename/redesign bestarrays input ports
    // 1. to store only computes0 and computes1's best patch idx
    // 2. to store only the best, not K best

    assign best_arr_csb0 = ~sl0_valid_out;
    assign best_arr_web0 = 1'b0;
    // skip storing distances
    // assign best_arr_wdist_0 = { {DATA_WIDTH{1'b0}},
    //                             {DATA_WIDTH{1'b0}},
    //                             {DATA_WIDTH{1'b0}},
    //                             {DATA_WIDTH{1'b0}} };
    // assign best_arr_wdist_0 = { sl0_l2_dist_3,
    //                             sl0_l2_dist_2,
    //                             sl0_l2_dist_1,
    //                             sl0_l2_dist_0 };
    assign best_arr_widx_0 = {  sl0_merged_idx_3[IDX_WIDTH-1:0],
                                sl0_merged_idx_2[IDX_WIDTH-1:0],
                                sl0_merged_idx_1[IDX_WIDTH-1:0],
                                sl0_merged_idx_0[IDX_WIDTH-1:0] };
    assign best_arr_wleaf_idx_0 = computes0_leaf_idx;
    assign computes0_leaf_idx   = { sl0_merged_idx_3[LEAF_ADDRW+IDX_WIDTH-1:IDX_WIDTH],
                                    sl0_merged_idx_2[LEAF_ADDRW+IDX_WIDTH-1:IDX_WIDTH],
                                    sl0_merged_idx_1[LEAF_ADDRW+IDX_WIDTH-1:IDX_WIDTH],
                                    sl0_merged_idx_0[LEAF_ADDRW+IDX_WIDTH-1:IDX_WIDTH] };
    
    // temporarily using dist_0 bits to store the computes2 patch idx results
    assign best_arr_wdist_0     = { {2'b0, sl1_merged_idx_3[IDX_WIDTH-1:0]},
                                    {2'b0, sl1_merged_idx_2[IDX_WIDTH-1:0]},
                                    {2'b0, sl1_merged_idx_1[IDX_WIDTH-1:0]},
                                    {2'b0, sl1_merged_idx_0[IDX_WIDTH-1:0]} };
    // the propagated leaf idx are store in registers in the main fsm
    // so we do not need to store in best arrays
    assign computes1_leaf_idx   = { sl1_merged_idx_3[LEAF_ADDRW+IDX_WIDTH-1:IDX_WIDTH],
                                    sl1_merged_idx_2[LEAF_ADDRW+IDX_WIDTH-1:IDX_WIDTH],
                                    sl1_merged_idx_1[LEAF_ADDRW+IDX_WIDTH-1:IDX_WIDTH],
                                    sl1_merged_idx_0[LEAF_ADDRW+IDX_WIDTH-1:IDX_WIDTH] };


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
    assign s0_valid_in          =   {k0_leaf_idx_out, k0_dist_valid};
    assign s0_data_in_0         =   {k0_leaf_idx_out, k0_p0_l2_dist};
    assign s0_data_in_1         =   {k0_leaf_idx_out, k0_p1_l2_dist};
    assign s0_data_in_2         =   {k0_leaf_idx_out, k0_p2_l2_dist};
    assign s0_data_in_3         =   {k0_leaf_idx_out, k0_p3_l2_dist};
    assign s0_data_in_4         =   {k0_leaf_idx_out, k0_p4_l2_dist};
    assign s0_data_in_5         =   {k0_leaf_idx_out, k0_p5_l2_dist};
    assign s0_data_in_6         =   {k0_leaf_idx_out, k0_p6_l2_dist};
    assign s0_data_in_7         =   {k0_leaf_idx_out, k0_p7_l2_dist};
    assign s0_idx_in_0          =   {k0_leaf_idx_out, k0_p0_idx_out};
    assign s0_idx_in_1          =   {k0_leaf_idx_out, k0_p1_idx_out};
    assign s0_idx_in_2          =   {k0_leaf_idx_out, k0_p2_idx_out};
    assign s0_idx_in_3          =   {k0_leaf_idx_out, k0_p3_idx_out};
    assign s0_idx_in_4          =   {k0_leaf_idx_out, k0_p4_idx_out};
    assign s0_idx_in_5          =   {k0_leaf_idx_out, k0_p5_idx_out};
    assign s0_idx_in_6          =   {k0_leaf_idx_out, k0_p6_idx_out};
    assign s0_idx_in_7          =   {k0_leaf_idx_out, k0_p7_idx_out};

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
    assign sl0_merged_idx_in    =   s0_idx_out_0;
    
    
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
        .leaf_idx_in        (k1_leaf_idx_in),
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
        // a special case to reduce the number of SRAM reads
        else if (k1_exactfstrow & (~leaf_mem_csb0) & leaf_mem_web0) begin
            k1_leaf_idx_in <= leaf_mem_addr0;
        end
        else if (~k1_exactfstrow & (~leaf_mem_csb1)) begin
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
    assign s1_valid_in          =   {k1_leaf_idx_out, k1_dist_valid};
    assign s1_data_in_0         =   {k1_leaf_idx_out, k1_p0_l2_dist};
    assign s1_data_in_1         =   {k1_leaf_idx_out, k1_p1_l2_dist};
    assign s1_data_in_2         =   {k1_leaf_idx_out, k1_p2_l2_dist};
    assign s1_data_in_3         =   {k1_leaf_idx_out, k1_p3_l2_dist};
    assign s1_data_in_4         =   {k1_leaf_idx_out, k1_p4_l2_dist};
    assign s1_data_in_5         =   {k1_leaf_idx_out, k1_p5_l2_dist};
    assign s1_data_in_6         =   {k1_leaf_idx_out, k1_p6_l2_dist};
    assign s1_data_in_7         =   {k1_leaf_idx_out, k1_p7_l2_dist};
    assign s1_idx_in_0          =   {k1_leaf_idx_out, k1_p0_idx_out};
    assign s1_idx_in_1          =   {k1_leaf_idx_out, k1_p1_idx_out};
    assign s1_idx_in_2          =   {k1_leaf_idx_out, k1_p2_idx_out};
    assign s1_idx_in_3          =   {k1_leaf_idx_out, k1_p3_idx_out};
    assign s1_idx_in_4          =   {k1_leaf_idx_out, k1_p4_idx_out};
    assign s1_idx_in_5          =   {k1_leaf_idx_out, k1_p5_idx_out};
    assign s1_idx_in_6          =   {k1_leaf_idx_out, k1_p6_idx_out};
    assign s1_idx_in_7          =   {k1_leaf_idx_out, k1_p7_idx_out};

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
    assign sl1_merged_idx_in    =   s1_idx_out_0;

endmodule



module MainFSM #(
    parameter DATA_WIDTH = 11,
    parameter LEAF_SIZE = 8,
    parameter PATCH_SIZE = 5,
    parameter ROW_SIZE = 26,
    parameter COL_SIZE = 19,
    parameter NUM_QUERYS = ROW_SIZE * COL_SIZE,
    parameter K = 4,
    parameter NUM_LEAVES = 64,
    parameter NUM_NODES = NUM_LEAVES - 1,
    parameter BLOCKING = 4,
    // with 1 kernel
    // parameter NUM_OUTER_BLOCK = (ROW_SIZE + BLOCKING - 1) / BLOCKING, // ceiling(ROW_SIZE/BLOCKING)
    // parameter LAST_BLOCK_REMAINDER = (ROW_SIZE) % BLOCKING,
    // with 2 kernels
    parameter NUM_OUTER_BLOCK = (ROW_SIZE / 2 + BLOCKING - 1) / BLOCKING, // ceiling(ROW_SIZE/2/BLOCKING)
    parameter LAST_BLOCK_REMAINDER = (ROW_SIZE / 2) % BLOCKING,
    parameter NUM_LAST_BLOCK = (LAST_BLOCK_REMAINDER==0) ?BLOCKING :LAST_BLOCK_REMAINDER,
    parameter LEAF_ADDRW = $clog2(NUM_LEAVES)
)
(
    input                                                           clk,
    input                                                           rst_n,
    input logic                                                     load_kdtree,
    input logic                                                     fsm_start,
    output logic                                                    fsm_done,
    input logic                                                     send_best_arr,

    input logic                                                     agg_receiver_enq,
    output logic                                                    agg_receiver_full_n,
    output logic                                                    agg_change_fetch_width,
    output logic [2:0]                                              agg_input_fetch_width,

    output logic                                                    int_node_fsm_enable,
    output logic                                                    int_node_patch_en,
    input logic [LEAF_ADDRW-1:0]                                    int_node_leaf_index,
    output logic                                                    int_node_patch_en2,
    input logic [LEAF_ADDRW-1:0]                                    int_node_leaf_index2,

    output logic                                                    qp_mem_csb0,
    output logic                                                    qp_mem_web0,
    output logic [$clog2(NUM_QUERYS)-1:0]                           qp_mem_addr0,
    input logic [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]                   qp_mem_rpatch0,
    output logic                                                    qp_mem_csb1,
    output logic [$clog2(NUM_QUERYS)-1:0]                           qp_mem_addr1,
    input logic [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]                   qp_mem_rpatch1,

    output logic [LEAF_SIZE-1:0]                                    leaf_mem_csb0,
    output logic [LEAF_SIZE-1:0]                                    leaf_mem_web0,
    output logic [LEAF_ADDRW-1:0]                                   leaf_mem_addr0,
    output logic                                                    leaf_mem_csb1,
    output logic [LEAF_ADDRW-1:0]                                   leaf_mem_addr1,

    output logic [8:0]                                              best_arr_addr0,
    output logic [K-1:0]                                            best_arr_csb1,
    output logic [8:0]                                              best_arr_addr1,

    output logic                                                    out_fifo_wdata_sel,
    output logic                                                    out_fifo_wenq,
    input logic                                                     out_fifo_wfull_n,

    output logic                                                    k0_query_valid,
    output logic                                                    k0_query_first_in,
    output logic                                                    k0_query_last_in,
    output logic signed [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]           k0_query_patch,
    input logic                                                     sl0_valid_out,
    input logic [LEAF_ADDRW-1:0]                                    computes0_leaf_idx [K-1:0],
    
    output logic                                                    k1_exactfstrow,
    output logic                                                    k1_query_valid,
    output logic                                                    k1_query_first_in,
    output logic                                                    k1_query_last_in,
    output logic signed [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]           k1_query_patch,
    input logic                                                     sl1_valid_out,
    input logic [LEAF_ADDRW-1:0]                                    computes1_leaf_idx [K-1:0]

);


    typedef enum {  Idle,
                    LoadInternalNodes,
                    LoadLeaves,
                    LoadQuerys,
                    ExactFstRow,
                    ExactFstRowLast,
                    ExactFstRowDone,
                    SLPR0,
                    SLPR1,
                    SLPR2,
                    SLPR3,
                    SLPR4,
                    SLPR5,
                    SLPR6,
                    SLPR7,
                    SLPR8,
                    SLPR9,
                    SendBestIdx,
                    SendBestIdx2
    } stateCoding_t;

    (* fsm_encoding = "one_hot" *) stateCoding_t currState;
    // stateCoding_t currState;
    stateCoding_t nextState;

    logic [LEAF_SIZE-1:0] leaf_mem_wr_sel;
    logic counter_en;
    logic counter_done;
    logic [15:0] counter_in;
    logic [15:0] counter;
    logic [$clog2(NUM_QUERYS)-1:0] qp_mem_rd_addr;
    logic [$clog2(NUM_QUERYS)-1:0] qp_mem_rd_addr2;
    logic qp_mem_rd_addr_rst;
    logic qp_mem_rd_addr_set;
    logic qp_mem_rd_addr_incr_col;
    logic qp_mem_rd_addr_incr_row;
    logic qp_mem_rd_addr_incr_row_special;
    logic [8:0] best_arr_addr_r;
    logic best_arr_addr_rst;
    logic signed [PATCH_SIZE-1:0] [DATA_WIDTH-1:0] cur_query_patch0;
    logic signed [PATCH_SIZE-1:0] [DATA_WIDTH-1:0] cur_query_patch1;
    logic qp_mem_rvalid0;
    logic qp_mem_rvalid1;
    logic [LEAF_ADDRW-1:0] prop_leaf_idx_r0 [BLOCKING-1:0] [K-1:0];
    logic [LEAF_ADDRW-1:0] prop_leaf_idx_r1 [BLOCKING-1:0] [K-1:0];
    logic [1:0] prop_leaf_wr_idx;
    logic [1:0] row_blocking_cnt;
    logic row_blocking_cnt_incr;
    logic [$clog2(NUM_OUTER_BLOCK+1)-1:0] row_outer_cnt;
    logic row_outer_cnt_incr;
    logic [$clog2(COL_SIZE)-1:0] col_query_cnt;
    logic col_query_cnt_incr;


    // CONTROLLER

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            currState <= Idle;
        end else begin
            currState <= nextState;
        end
    end

    always_comb begin
        nextState = currState;

        fsm_done = '0;

        agg_change_fetch_width = '0;
        agg_input_fetch_width = '0;
        agg_receiver_full_n = '0;
        int_node_fsm_enable = '0;
        int_node_patch_en = '0;
        int_node_patch_en2 = '0;
        qp_mem_csb0 = 1'b1;
        qp_mem_web0 = 1'b1;
        qp_mem_addr0 = '0;
        qp_mem_csb1 = 1'b1;
        qp_mem_addr1 = '0;
        leaf_mem_csb0 = '1;
        leaf_mem_web0 = '1;
        leaf_mem_addr0 = '0;
        leaf_mem_csb1 = 1'b1;
        leaf_mem_addr1 = '0;
        k0_query_valid = '0;
        k0_query_first_in = '0;
        k0_query_last_in = '0;
        k0_query_patch = '0;
        k1_exactfstrow = '0;
        k1_query_valid = '0;
        k1_query_first_in = '0;
        k1_query_last_in = '0;
        k1_query_patch = '0;
        best_arr_csb1 = {K{1'b1}};
        best_arr_addr1 = '0;
        out_fifo_wdata_sel = '0;
        
        counter_en = '0;
        counter_in = '0;
        qp_mem_rvalid0 = '0;
        qp_mem_rvalid1 = '0;
        qp_mem_rd_addr_rst = '0;
        qp_mem_rd_addr_set = '0;
        qp_mem_rd_addr_incr_col = '0;
        qp_mem_rd_addr_incr_row = '0;
        qp_mem_rd_addr_incr_row_special = '0;
        best_arr_addr_rst = '0;
        col_query_cnt_incr = '0;
        row_blocking_cnt_incr = '0;
        row_outer_cnt_incr = '0;

        unique case (currState)
            Idle: begin
                qp_mem_rd_addr_set = 1'b1;
                if (load_kdtree) begin
                    nextState = LoadInternalNodes;
                    agg_change_fetch_width = 1'b1;
                    agg_input_fetch_width = 3'd1;
                end
                
                if (fsm_start) begin
                    nextState = ExactFstRow;
                    counter_en = 1'b1;
                    counter_in = NUM_LEAVES - 1;
                    leaf_mem_csb0 = '0;
                    leaf_mem_web0 = '1;
                    leaf_mem_addr0 = counter;
                    qp_mem_csb0 = 1'b0;
                    qp_mem_web0 = 1'b1;
                    qp_mem_addr0 = qp_mem_rd_addr;
                    qp_mem_csb1 = 1'b0;
                    qp_mem_addr1 = qp_mem_rd_addr2;
                    row_outer_cnt_incr = 1'b1;
                end

                if (send_best_arr)
                    nextState = SendBestIdx;
            end

            LoadInternalNodes: begin
                counter_in = NUM_NODES - 1;
                agg_receiver_full_n = 1'b1;
                int_node_fsm_enable = 1'b1;
                if (agg_receiver_enq) begin
                    counter_en = 1'b1;
                    if (counter_done) begin
                        nextState = LoadLeaves;
                        agg_change_fetch_width = 1'b1;
                        agg_input_fetch_width = 3'd5;
                    end
                end
            end

            LoadLeaves: begin
                counter_in = NUM_LEAVES * LEAF_SIZE - 1;
                agg_receiver_full_n = 1'b1;
                if (agg_receiver_enq) begin
                    counter_en = 1'b1;
                    leaf_mem_csb0 = leaf_mem_wr_sel;
                    leaf_mem_web0 = leaf_mem_wr_sel;
                    leaf_mem_addr0 = counter[LEAF_ADDRW+3-1:3];
                    if (counter_done) begin
                        nextState = LoadQuerys;
                        agg_change_fetch_width = 1'b1;
                        agg_input_fetch_width = 3'd4;
                    end
                end
            end

            LoadQuerys: begin
                counter_in = NUM_QUERYS - 1;
                agg_receiver_full_n = 1'b1;
                if (agg_receiver_enq) begin
                    counter_en = 1'b1;
                    qp_mem_csb0 = 1'b0;
                    qp_mem_web0 = 1'b0;
                    qp_mem_addr0 = counter;
                    if (counter_done) begin
                        nextState = Idle;
                    end
                end
            end

            // process BLOCKING or NUM_LAST_BLOCK queries
            ExactFstRow: begin
                counter_en = 1'b1;
                counter_in = NUM_LEAVES - 1;
                leaf_mem_csb0 = '0;
                leaf_mem_web0 = '1;
                leaf_mem_addr0 = counter;

                k0_query_valid = 1'b1;
                k0_query_patch = cur_query_patch0;

                k1_exactfstrow = 1'b1;
                k1_query_valid = 1'b1;
                k1_query_patch = cur_query_patch1;

                if (counter_done) begin
                    if ((prop_leaf_wr_idx == BLOCKING - 1) || 
                        ((row_outer_cnt == NUM_OUTER_BLOCK) && (prop_leaf_wr_idx == NUM_LAST_BLOCK - 1)))
                        nextState = ExactFstRowLast;
                end

                if (counter == 1) begin
                    k0_query_first_in = 1'b1;
                    qp_mem_rvalid0 = 1'b1;
                    k0_query_patch = qp_mem_rpatch0;
                    
                    k1_query_first_in = 1'b1;
                    qp_mem_rvalid1 = 1'b1;
                    k1_query_patch = qp_mem_rpatch1;
                end

                if (counter == 0) begin
                    qp_mem_csb0 = 1'b0;
                    qp_mem_web0 = 1'b1;
                    qp_mem_addr0 = qp_mem_rd_addr;
                    k0_query_last_in = 1'b1;
                    
                    qp_mem_csb1 = 1'b0;
                    qp_mem_addr1 = qp_mem_rd_addr2;
                    k1_query_last_in = 1'b1;
                end

                if (counter_done) begin
                    if ((row_outer_cnt == NUM_OUTER_BLOCK) && (prop_leaf_wr_idx == NUM_LAST_BLOCK - 1))
                        qp_mem_rd_addr_incr_row_special = 1'b1;
                    else if (prop_leaf_wr_idx == BLOCKING - 1)
                        qp_mem_rd_addr_incr_row = 1'b1;
                    else
                        qp_mem_rd_addr_incr_col = 1'b1;
                end
            end

            ExactFstRowLast: begin
                // according to the latency in the waveform,
                // the last sl0_valid_out will arrive just after we have finished the second query
                // therefore, if NUM_LAST_BLOCK <= 2, we need to wait for sl0 to finish
                if ((row_outer_cnt == NUM_OUTER_BLOCK) && (NUM_LAST_BLOCK <= 2))
                    nextState = ExactFstRowDone;
                else begin
                    nextState = SLPR0;
                    col_query_cnt_incr = 1'b1;
                    // read query for the first SearchLeaf
                    qp_mem_csb0 = 1'b0;
                    qp_mem_web0 = 1'b1;
                    qp_mem_addr0 = qp_mem_rd_addr;
                    qp_mem_csb1 = 1'b0;
                    qp_mem_addr1 = qp_mem_rd_addr2;
                end

                k0_query_valid = 1'b1;
                k0_query_last_in = 1'b1;
                k0_query_patch = cur_query_patch0;

                k1_query_valid = 1'b1;
                k1_query_last_in = 1'b1;
                k1_query_patch = cur_query_patch1;
            end

            ExactFstRowDone: begin
                // assumes sl1_valid_out arrives at the same time
                if (sl0_valid_out) begin
                    nextState = SLPR0;
                    col_query_cnt_incr = 1'b1;
                    // read query for the first SearchLeaf
                    qp_mem_csb0 = 1'b0;
                    qp_mem_web0 = 1'b1;
                    qp_mem_addr0 = qp_mem_rd_addr;
                    qp_mem_csb1 = 1'b0;
                    qp_mem_addr1 = qp_mem_rd_addr2;
                end
            end

            SLPR0: begin
                counter_in = 1;
                counter_en = 1'b1;
                
                if (counter == 0) begin
                    int_node_patch_en = 1'b1;
                    int_node_patch_en2 = 1'b1;
                end

                if (counter_done) begin
                    nextState = SLPR1;
                end
            end
            
            // read prop 0
            // read the next query
            SLPR1: begin
                nextState = SLPR2;
                leaf_mem_csb0 = '0;
                leaf_mem_web0 = '1;
                leaf_mem_addr0 = prop_leaf_idx_r0[row_blocking_cnt][0];
                leaf_mem_csb1 = '0;
                leaf_mem_addr1 = prop_leaf_idx_r1[row_blocking_cnt][0];

                qp_mem_csb0 = 1'b0;
                qp_mem_web0 = 1'b1;
                qp_mem_addr0 = qp_mem_rd_addr;
                qp_mem_csb1 = 1'b0;
                qp_mem_addr1 = qp_mem_rd_addr2;
                qp_mem_rd_addr_incr_col = 1'b1;
            end

            // send prop 0 and query to l2_k0 with query_first
            // read prop 1
            SLPR2: begin
                nextState = SLPR3;

                k0_query_first_in = 1'b1;
                k0_query_valid = 1'b1;
                k0_query_patch = qp_mem_rpatch0;
                k1_query_first_in = 1'b1;
                k1_query_valid = 1'b1;
                k1_query_patch = qp_mem_rpatch1;
                
                leaf_mem_csb0 = '0;
                leaf_mem_web0 = '1;
                leaf_mem_addr0 = prop_leaf_idx_r0[row_blocking_cnt][1];
                leaf_mem_csb1 = '0;
                leaf_mem_addr1 = prop_leaf_idx_r1[row_blocking_cnt][1];
                
                // store the query for reuse
                qp_mem_rvalid0 = 1'b1;
                qp_mem_rvalid1 = 1'b1;
            end

            // send prop 1 and query to l2_k0
            // read prop 2
            // read the next query for SearchLeaf
            SLPR3: begin
                nextState = SLPR4;
                k0_query_valid = 1'b1;
                k0_query_patch = cur_query_patch0;
                k1_query_valid = 1'b1;
                k1_query_patch = cur_query_patch1;
                
                leaf_mem_csb0 = '0;
                leaf_mem_web0 = '1;
                leaf_mem_addr0 = prop_leaf_idx_r0[row_blocking_cnt][2];
                leaf_mem_csb1 = '0;
                leaf_mem_addr1 = prop_leaf_idx_r1[row_blocking_cnt][2];

                if (~((row_outer_cnt == NUM_OUTER_BLOCK) && (row_blocking_cnt == NUM_LAST_BLOCK - 1))) begin
                    qp_mem_csb0 = 1'b0;
                    qp_mem_web0 = 1'b1;
                    qp_mem_addr0 = qp_mem_rd_addr;
                    qp_mem_csb1 = 1'b0;
                    qp_mem_addr1 = qp_mem_rd_addr2;
                end
            end

            // send prop 2 and query to l2_k0
            // read prop 3
            // send the next query to SearchLeaf
            SLPR4: begin
                nextState = SLPR5;
                k0_query_valid = 1'b1;
                k0_query_patch = cur_query_patch0;
                k1_query_valid = 1'b1;
                k1_query_patch = cur_query_patch1;
                
                leaf_mem_csb0 = '0;
                leaf_mem_web0 = '1;
                leaf_mem_addr0 = prop_leaf_idx_r0[row_blocking_cnt][3];
                leaf_mem_csb1 = '0;
                leaf_mem_addr1 = prop_leaf_idx_r1[row_blocking_cnt][3];
                
                if (~((row_outer_cnt == NUM_OUTER_BLOCK) && (row_blocking_cnt == NUM_LAST_BLOCK - 1)))
                    int_node_patch_en = 1'b1;
                    int_node_patch_en2 = 1'b1;
            end

            // send prop 3 and query to l2_k0
            // read SearchLeaf result
            SLPR5: begin
                if ((col_query_cnt == COL_SIZE - 1) && (row_blocking_cnt == BLOCKING - 1))
                    nextState = SLPR7;
                else begin
                    if ((row_outer_cnt == NUM_OUTER_BLOCK) && (row_blocking_cnt == NUM_LAST_BLOCK - 1))
                        nextState = SLPR9;
                    else
                        nextState = SLPR6;
                end
                k0_query_valid = 1'b1;
                k0_query_patch = cur_query_patch0;
                k1_query_valid = 1'b1;
                k1_query_patch = cur_query_patch1;
                
                leaf_mem_csb0 = '0;
                leaf_mem_web0 = '1;
                leaf_mem_addr0 = int_node_leaf_index;
                leaf_mem_csb1 = '0;
                leaf_mem_addr1 = int_node_leaf_index2;
                
                row_blocking_cnt_incr = 1'b1;
                if (row_blocking_cnt == BLOCKING - 1) begin
                    col_query_cnt_incr = 1'b1;
                end
            end

            // send SearchLeaf result and query to l2_k0 with query_last
            // read prop 0
            // read the next query
            SLPR6: begin
                nextState = SLPR2;
                k0_query_last_in = 1'b1;
                k0_query_valid = 1'b1;
                k0_query_patch = cur_query_patch0;
                k1_query_last_in = 1'b1;
                k1_query_valid = 1'b1;
                k1_query_patch = cur_query_patch1;

                leaf_mem_csb0 = '0;
                leaf_mem_web0 = '1;
                leaf_mem_addr0 = prop_leaf_idx_r0[row_blocking_cnt][0];
                leaf_mem_csb1 = '0;
                leaf_mem_addr1 = prop_leaf_idx_r1[row_blocking_cnt][0];

                qp_mem_csb0 = 1'b0;
                qp_mem_web0 = 1'b1;
                qp_mem_addr0 = qp_mem_rd_addr;
                qp_mem_csb1 = 1'b0;
                qp_mem_addr1 = qp_mem_rd_addr2;
                // the next query can be in the first row or in the next row or at the right 
                if ((col_query_cnt == COL_SIZE - 1) && (row_blocking_cnt == BLOCKING - 1))
                    qp_mem_rd_addr_set = 1'b1;
                if (row_blocking_cnt == BLOCKING - 1)
                    qp_mem_rd_addr_incr_row = 1'b1;
                else
                    qp_mem_rd_addr_incr_col = 1'b1;
            end

            // send SearchLeaf result and query to l2_k0 with query_last
            // finished all rows and incr outer count
            SLPR7: begin
                row_outer_cnt_incr = 1'b1;
                if (row_outer_cnt == NUM_OUTER_BLOCK) begin
                    nextState = SLPR8;
                end
                else begin
                    nextState = ExactFstRow;
                    counter_en = 1'b1;
                    counter_in = NUM_LEAVES - 1;
                    leaf_mem_csb0 = '0;
                    leaf_mem_web0 = '1;
                    leaf_mem_addr0 = counter;
                    qp_mem_csb0 = 1'b0;
                    qp_mem_web0 = 1'b1;
                    qp_mem_addr0 = qp_mem_rd_addr;
                    qp_mem_csb1 = 1'b0;
                    qp_mem_addr1 = qp_mem_rd_addr2;
                end

                k0_query_last_in = 1'b1;
                k0_query_valid = 1'b1;
                k0_query_patch = cur_query_patch0;
                k1_query_last_in = 1'b1;
                k1_query_valid = 1'b1;
                k1_query_patch = cur_query_patch1;
            end

            // wait 12 more cycles for the pipeline to flush
            // 5 cycles for l2_k0
            // 1 cycles for running min
            // 6 cycles for sorter
            SLPR8: begin
                counter_en = 1'b1;
                counter_in = 11;
                if (counter_done) begin
                    nextState = Idle;
                    fsm_done = 1'b1;
                    qp_mem_rd_addr_rst = 1'b1;
                    best_arr_addr_rst = 1'b1;
                end
            end

            // for the last blocking, we may need to insert dummy cycles
            // if the ROW_SIZE is not multiples of BLOCKING
            SLPR9: begin
                counter_en = 1'b1;
                counter_in = (BLOCKING - NUM_LAST_BLOCK) * 5;

                if (counter == 0) begin
                    k0_query_last_in = 1'b1;
                    k0_query_valid = 1'b1;
                    k0_query_patch = cur_query_patch0;
                    k1_query_last_in = 1'b1;
                    k1_query_valid = 1'b1;
                    k1_query_patch = cur_query_patch1;
                end

                if (counter < BLOCKING - NUM_LAST_BLOCK) begin
                    row_blocking_cnt_incr = 1'b1;
                end

                if (counter < BLOCKING - NUM_LAST_BLOCK - 1) begin
                    row_blocking_cnt_incr = 1'b1;
                    qp_mem_rd_addr_incr_col = 1'b1;
                end

                if (counter == BLOCKING - NUM_LAST_BLOCK) begin
                    qp_mem_rd_addr_incr_row = 1'b1;
                end

                // read next query for SearchLeaf
                if (counter == (BLOCKING - NUM_LAST_BLOCK) * 5 - 3) begin
                    qp_mem_csb0 = 1'b0;
                    qp_mem_web0 = 1'b1;
                    qp_mem_addr0 = qp_mem_rd_addr;
                    qp_mem_csb1 = 1'b0;
                    qp_mem_addr1 = qp_mem_rd_addr2;
                end

                // send to SearchLeaf
                if (counter == (BLOCKING - NUM_LAST_BLOCK) * 5 - 2) begin
                    int_node_patch_en = 1'b1;
                    int_node_patch_en2 = 1'b1;
                end

                if (counter_done) begin
                    col_query_cnt_incr = 1'b1;
                    if (col_query_cnt == COL_SIZE - 1) begin
                        nextState = SLPR8;
                        row_outer_cnt_incr = 1'b1;
                    end
                    else begin
                        nextState = SLPR2;
                        leaf_mem_csb0 = '0;
                        leaf_mem_web0 = '1;
                        leaf_mem_addr0 = prop_leaf_idx_r0[0][0];
                        leaf_mem_csb1 = '0;
                        leaf_mem_addr1 = prop_leaf_idx_r1[0][0];

                        qp_mem_csb0 = 1'b0;
                        qp_mem_web0 = 1'b1;
                        qp_mem_addr0 = qp_mem_rd_addr;
                        qp_mem_csb1 = 1'b0;
                        qp_mem_addr1 = qp_mem_rd_addr2;
                        qp_mem_rd_addr_incr_col = 1'b1;
                    end
                end
            end

            // read out the best array
            // results of computes0
            SendBestIdx: begin
                counter_in = NUM_QUERYS / 2 - 1;
                out_fifo_wdata_sel = 1'b1;
                if (~out_fifo_wenq & out_fifo_wfull_n) begin
                    // reads only the best
                    best_arr_csb1 = {{(K-1){1'b1}}, 1'b0};
                    best_arr_addr1 = counter;
                end

                if (out_fifo_wenq) begin
                    counter_en = 1'b1;
                    if (counter_done)
                        nextState = SendBestIdx2;
                end
            end

            // results of computes1
            SendBestIdx2: begin
                counter_in = NUM_QUERYS / 2 - 1;
                out_fifo_wdata_sel = 1'b0;
                if (~out_fifo_wenq & out_fifo_wfull_n) begin
                    // reads only the best
                    best_arr_csb1 = {{(K-1){1'b1}}, 1'b0};
                    best_arr_addr1 = counter;
                end

                if (out_fifo_wenq) begin
                    counter_en = 1'b1;
                    if (counter_done)
                        nextState = Idle;
                end
            end

        endcase
    end



    // DATAPATH

    // binary to one-hot encoder
    always_comb begin
        leaf_mem_wr_sel = '1;
        leaf_mem_wr_sel[counter[2:0]] = 1'b0;
    end

    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n) counter <= '0;
        else if (counter_en) begin
            if (counter == counter_in)
                counter <= '0;
            else
                counter <= counter + 1'b1;
        end
    end
    assign counter_done = counter == counter_in;

    // ExactFstRow and SearchLeaf: used to read from the query patch memory
    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n | qp_mem_rd_addr_rst) begin
            qp_mem_rd_addr <= '0;
            qp_mem_rd_addr2 <= '0;
        end else if (qp_mem_rd_addr_set) begin
            qp_mem_rd_addr <= row_outer_cnt * BLOCKING;
            qp_mem_rd_addr2 <= row_outer_cnt * BLOCKING + ROW_SIZE / 2;
        end else if (qp_mem_rd_addr_incr_col) begin
            qp_mem_rd_addr <= qp_mem_rd_addr + 1'b1;
            qp_mem_rd_addr2 <= qp_mem_rd_addr2 + 1'b1;
        end else if (qp_mem_rd_addr_incr_row) begin
            // we have gone BLOCKING right before going to the next row
            qp_mem_rd_addr <= qp_mem_rd_addr + ROW_SIZE - (BLOCKING - 1);
            qp_mem_rd_addr2 <= qp_mem_rd_addr2 + ROW_SIZE - (BLOCKING - 1);
        end else if (qp_mem_rd_addr_incr_row_special) begin
            // when blocking is not multiples of 4
            // ExactFstRow needs this special increment
            qp_mem_rd_addr <= qp_mem_rd_addr + ROW_SIZE - (NUM_LAST_BLOCK - 1);
            qp_mem_rd_addr2 <= qp_mem_rd_addr2 + ROW_SIZE - (NUM_LAST_BLOCK - 1);
        end
    end

    // stores the next addr of best arrays
    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n | best_arr_addr_rst) best_arr_addr_r <= '0;
        else if (sl0_valid_out) begin
            best_arr_addr_r <= best_arr_addr_r + 1'b1;
        end
    end
    assign best_arr_addr0 = best_arr_addr_r;
    
    // used to store propagated leaves
    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            prop_leaf_wr_idx <= '0;
            for (int i=0; i<BLOCKING; i=i+1) begin
                prop_leaf_idx_r0[i][0] <= '0;
                prop_leaf_idx_r0[i][1] <= '0;
                prop_leaf_idx_r0[i][2] <= '0;
                prop_leaf_idx_r0[i][3] <= '0;
                prop_leaf_idx_r1[i][0] <= '0;
                prop_leaf_idx_r1[i][1] <= '0;
                prop_leaf_idx_r1[i][2] <= '0;
                prop_leaf_idx_r1[i][3] <= '0;
            end
        end
        else if (sl0_valid_out) begin
            if (((row_outer_cnt == NUM_OUTER_BLOCK) && (prop_leaf_wr_idx == NUM_LAST_BLOCK - 1))
                    || (prop_leaf_wr_idx == BLOCKING - 1) )
                prop_leaf_wr_idx <= '0;
            else
                prop_leaf_wr_idx <= prop_leaf_wr_idx + 1'b1;
            prop_leaf_idx_r0[prop_leaf_wr_idx][0] <= computes0_leaf_idx[0];
            prop_leaf_idx_r0[prop_leaf_wr_idx][1] <= computes0_leaf_idx[1];
            prop_leaf_idx_r0[prop_leaf_wr_idx][2] <= computes0_leaf_idx[2];
            prop_leaf_idx_r0[prop_leaf_wr_idx][3] <= computes0_leaf_idx[3];
            prop_leaf_idx_r1[prop_leaf_wr_idx][0] <= computes1_leaf_idx[0];
            prop_leaf_idx_r1[prop_leaf_wr_idx][1] <= computes1_leaf_idx[1];
            prop_leaf_idx_r1[prop_leaf_wr_idx][2] <= computes1_leaf_idx[2];
            prop_leaf_idx_r1[prop_leaf_wr_idx][3] <= computes1_leaf_idx[3];
        end
    end
    
    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n) col_query_cnt <= '0;
        else if ( col_query_cnt_incr) begin
            if ( col_query_cnt == COL_SIZE - 1)
                col_query_cnt <= '0;
            else
                col_query_cnt <= col_query_cnt + 1'b1;
        end
    end
    
    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n) row_blocking_cnt <= '0;
        else if (row_blocking_cnt_incr) begin
            if (row_blocking_cnt == BLOCKING - 1)
                row_blocking_cnt <= '0;
            else
                row_blocking_cnt <= row_blocking_cnt + 1'b1;
        end
    end

    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n) row_outer_cnt <= '0;
        else if (row_outer_cnt_incr) begin
            if (row_outer_cnt == NUM_OUTER_BLOCK)
                row_outer_cnt <= '0;
            else
                row_outer_cnt <= row_outer_cnt + 1'b1;
        end
    end
    
    // used to store and reuse the current query patch
    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n) cur_query_patch0 <= '0;
        else if (qp_mem_rvalid0) begin
            cur_query_patch0 <= qp_mem_rpatch0;
        end
    end

    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n) cur_query_patch1 <= '0;
        else if (qp_mem_rvalid1) begin
            cur_query_patch1 <= qp_mem_rpatch1;
        end
    end

    // writes to out fifo after reading out from best arrays
    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n) out_fifo_wenq <= '0;
        else begin
            out_fifo_wenq <= ~(&best_arr_csb1);
        end
    end

endmodule

`ifdef BSV_ASSIGNMENT_DELAY
`else
  `define BSV_ASSIGNMENT_DELAY
`endif

`ifdef BSV_POSITIVE_RESET
  `define BSV_RESET_VALUE 1'b1
  `define BSV_RESET_EDGE posedge
`else
  `define BSV_RESET_VALUE 1'b0
  `define BSV_RESET_EDGE negedge
`endif

`ifdef BSV_RESET_FIFO_HEAD
 `define BSV_RESET_EDGE_HEAD or `BSV_RESET_EDGE dRST
`else
 `define BSV_RESET_EDGE_HEAD
`endif

// SOURCE: https://github.com/B-Lang-org/bsc 
// A clock synchronization FIFO where the enqueue and dequeue sides are in
// different clock domains.
// There are no restrictions w.r.t. clock frequencies
// The depth of the FIFO must be a power of 2 (2,4,8,...) since the
// indexing uses a Gray code counter.
// FULL and EMPTY signal are pessimistic, that is, they are asserted
// immediately when the FIFO becomes FULL or EMPTY, but their deassertion
// is delayed due to synchronization latency.
module SyncFIFO(
                sCLK,
                sRST,
                dCLK,
                sENQ,
                sD_IN,
                sFULL_N,
                dDEQ,
                dD_OUT,
                dEMPTY_N
                ) ;


   parameter                 dataWidth = 1 ;
   parameter                 depth = 2 ; // minimum 2
   parameter                 indxWidth = 1 ; // minimum 1

   // input clock domain ports
   input                     sCLK ;
   input                     sRST ;
   input                     sENQ ;
   input [dataWidth -1 : 0]  sD_IN ;
   output                    sFULL_N ;

   // destination clock domain ports
   input                     dCLK ;
   input                     dDEQ ;
   output                    dEMPTY_N ;
   output [dataWidth -1 : 0] dD_OUT ;

   // constants for bit masking of the gray code
   wire [indxWidth : 0]      msbset  = ~({(indxWidth + 1){1'b1}} >> 1) ;
   wire [indxWidth - 1 : 0]  msb2set = ~({(indxWidth + 0){1'b1}} >> 1) ;
   wire [indxWidth : 0]      msb12set = msbset | {1'b0, msb2set} ; // 'b11000...

   // FIFO Memory
   reg [dataWidth -1 : 0]    fifoMem [0: depth -1 ] ;
   reg [dataWidth -1 : 0]    dDoutReg ;

   // Enqueue Pointer support
   reg [indxWidth +1 : 0]    sGEnqPtr, sGEnqPtr1 ; // Flops
   reg                       sNotFullReg ;
   wire                      sNextNotFull, sFutureNotFull ;

   // Dequeue Pointer support
   reg [indxWidth+1 : 0]       dGDeqPtr, dGDeqPtr1 ; // Flops
   reg                       dNotEmptyReg ;
   wire                      dNextNotEmpty;

   // Reset generation
   wire                      dRST ;

   // flops to sychronize enqueue and dequeue point across domains
   reg [indxWidth : 0]       dSyncReg1, dEnqPtr ;
   reg [indxWidth : 0]       sSyncReg1, sDeqPtr ;

   wire [indxWidth - 1 :0]   sEnqPtrIndx, dDeqPtrIndx ;

   // Resets
   assign                    dRST = sRST ;

   // Outputs
   assign                    dD_OUT   = dDoutReg     ;
   assign                    dEMPTY_N = dNotEmptyReg ;
   assign                    sFULL_N  = sNotFullReg  ;

   // Indexes are truncated from the Gray counter with parity
   assign                    sEnqPtrIndx  = sGEnqPtr[indxWidth-1:0];
   assign                    dDeqPtrIndx  = dGDeqPtr[indxWidth-1:0];

   // Fifo memory write
   always @(posedge sCLK)
     begin
        if ( sENQ )
          fifoMem[sEnqPtrIndx] <= `BSV_ASSIGNMENT_DELAY sD_IN ;
     end // always @ (posedge sCLK)

   ////////////////////////////////////////////////////////////////////////
   // Enqueue Pointer and increment logic
   assign sNextNotFull   = (sGEnqPtr [indxWidth+1:1] ^ msb12set) != sDeqPtr ;
   assign sFutureNotFull = (sGEnqPtr1[indxWidth+1:1] ^ msb12set) != sDeqPtr ;

   always @(posedge sCLK or `BSV_RESET_EDGE sRST)
     begin
        if (sRST == `BSV_RESET_VALUE)
          begin
             sGEnqPtr    <= `BSV_ASSIGNMENT_DELAY {(indxWidth +2 ) {1'b0}} ;
             sGEnqPtr1   <= `BSV_ASSIGNMENT_DELAY { {indxWidth {1'b0}}, 2'b11} ;
             sNotFullReg <= `BSV_ASSIGNMENT_DELAY 1'b0 ; // Mark as full during reset to avoid spurious loads
          end // if (sRST == `BSV_RESET_VALUE)
        else
           begin
              if ( sENQ )
                begin
                   sGEnqPtr1   <= `BSV_ASSIGNMENT_DELAY incrGrayP( sGEnqPtr1 ) ;
                   sGEnqPtr    <= `BSV_ASSIGNMENT_DELAY sGEnqPtr1 ;
                   sNotFullReg <= `BSV_ASSIGNMENT_DELAY sFutureNotFull ;
                end // if ( sENQ )
              else
                begin
                   sNotFullReg <= `BSV_ASSIGNMENT_DELAY  sNextNotFull ;
                end // else: !if( sENQ )
           end // else: !if(sRST == `BSV_RESET_VALUE)
     end // always @ (posedge sCLK or `BSV_RESET_EDGE sRST)


   // Enqueue pointer synchronizer to dCLK
   always @(posedge dCLK  or `BSV_RESET_EDGE dRST)
     begin
        if (dRST == `BSV_RESET_VALUE)
          begin
             dSyncReg1 <= `BSV_ASSIGNMENT_DELAY {(indxWidth + 1) {1'b0}} ;
             dEnqPtr   <= `BSV_ASSIGNMENT_DELAY {(indxWidth + 1) {1'b0}} ;
          end // if (dRST == `BSV_RESET_VALUE)
        else
          begin
             dSyncReg1 <= `BSV_ASSIGNMENT_DELAY sGEnqPtr[indxWidth+1:1] ; // Clock domain crossing
             dEnqPtr   <= `BSV_ASSIGNMENT_DELAY dSyncReg1 ;
          end // else: !if(dRST == `BSV_RESET_VALUE)
     end // always @ (posedge dCLK  or `BSV_RESET_EDGE dRST)
   ////////////////////////////////////////////////////////////////////////


   ////////////////////////////////////////////////////////////////////////
   // Enqueue Pointer and increment logic
   assign dNextNotEmpty   = dGDeqPtr[indxWidth+1:1]  != dEnqPtr ;

   always @(posedge dCLK or `BSV_RESET_EDGE dRST)
     begin
        if (dRST == `BSV_RESET_VALUE)
          begin
             dGDeqPtr     <= `BSV_ASSIGNMENT_DELAY {(indxWidth + 2) {1'b0}} ;
             dGDeqPtr1    <= `BSV_ASSIGNMENT_DELAY {{indxWidth {1'b0}}, 2'b11 } ;
             dNotEmptyReg <= `BSV_ASSIGNMENT_DELAY 1'b0 ;
          end // if (dRST == `BSV_RESET_VALUE)
        else
           begin
              if ((!dNotEmptyReg || dDEQ) && dNextNotEmpty) begin
                 dGDeqPtr     <= `BSV_ASSIGNMENT_DELAY dGDeqPtr1 ;
                 dGDeqPtr1    <= `BSV_ASSIGNMENT_DELAY incrGrayP( dGDeqPtr1 );
                 dNotEmptyReg <= `BSV_ASSIGNMENT_DELAY 1'b1;
              end
              else if (dDEQ && !dNextNotEmpty) begin
                 dNotEmptyReg <= `BSV_ASSIGNMENT_DELAY 1'b0;
              end
           end // else: !if(dRST == `BSV_RESET_VALUE)
     end // always @ (posedge dCLK or `BSV_RESET_EDGE dRST)


   always @(posedge dCLK `BSV_RESET_EDGE_HEAD)
     begin
`ifdef  BSV_RESET_FIFO_HEAD
        if (dRST == `BSV_RESET_VALUE)
          begin
             dDoutReg    <= `BSV_ASSIGNMENT_DELAY {dataWidth {1'b0}} ;
          end // if (dRST == `BSV_RESET_VALUE)
        else
`endif
          begin
             if ((!dNotEmptyReg || dDEQ) && dNextNotEmpty) begin
                dDoutReg     <= `BSV_ASSIGNMENT_DELAY fifoMem[dDeqPtrIndx] ;
             end
          end
     end

    // Dequeue pointer synchronized to sCLK
    always @(posedge sCLK  or `BSV_RESET_EDGE sRST)
      begin
         if (sRST == `BSV_RESET_VALUE)
           begin
              sSyncReg1 <= `BSV_ASSIGNMENT_DELAY {(indxWidth + 1) {1'b0}} ;
              sDeqPtr   <= `BSV_ASSIGNMENT_DELAY {(indxWidth + 1) {1'b0}} ; // When reset mark as not empty
           end // if (sRST == `BSV_RESET_VALUE)
         else
           begin
              sSyncReg1 <= `BSV_ASSIGNMENT_DELAY dGDeqPtr[indxWidth+1:1] ; // clock domain crossing
              sDeqPtr   <= `BSV_ASSIGNMENT_DELAY sSyncReg1 ;
           end // else: !if(sRST == `BSV_RESET_VALUE)
      end // always @ (posedge sCLK  or `BSV_RESET_EDGE sRST)
   ////////////////////////////////////////////////////////////////////////

`ifdef BSV_NO_INITIAL_BLOCKS
`else // not BSV_NO_INITIAL_BLOCKS
   // synopsys translate_off
   initial
     begin : initBlock
        integer i ;

        // initialize the FIFO memory with aa's
        for (i = 0; i < depth; i = i + 1)
          begin
             fifoMem[i] = {((dataWidth + 1)/2){2'b10}} ;
          end
        dDoutReg     = {((dataWidth + 1)/2){2'b10}} ;

        // initialize the pointer
        sGEnqPtr = {((indxWidth + 2)/2){2'b10}} ;
        sGEnqPtr1 = sGEnqPtr ;
        sNotFullReg = 1'b0 ;

        dGDeqPtr = sGEnqPtr ;
        dGDeqPtr1 = sGEnqPtr ;
        dNotEmptyReg = 1'b0;


        // initialize other registers
        sSyncReg1 = sGEnqPtr ;
        sDeqPtr   = sGEnqPtr ;
        dSyncReg1 = sGEnqPtr ;
        dEnqPtr   = sGEnqPtr ;
     end // block: initBlock
   // synopsys translate_on



   // synopsys translate_off
   initial
     begin : parameter_assertions
        integer ok ;
        integer i, expDepth ;

        ok = 1;
        expDepth = 1 ;

        // calculate x = 2 ** (indxWidth - 1)
        for( i = 0 ; i < indxWidth ; i = i + 1 )
          begin
             expDepth = expDepth * 2 ;
          end // for ( i = 0 ; i < indxWidth ; i = i + 1 )

        if ( expDepth != depth )
          begin
             ok = 0;
             $display ( "ERROR SyncFiFO.v: index size and depth do not match;" ) ;
             $display ( "\tdepth must equal 2 ** index size. expected %0d", expDepth );
          end

        #0
        if ( ok == 0 ) $finish ;

      end // initial begin
   // synopsys translate_on
`endif // BSV_NO_INITIAL_BLOCKS

   function [indxWidth+1:0] incrGrayP ;
      input [indxWidth+1:0] grayPin;

      begin: incrGrayPBlock
         reg [indxWidth :0] g;
         reg                p ;
         reg [indxWidth :0] i;

         g = grayPin[indxWidth+1:1];
         p = grayPin[0];
         i = incrGray (g,p);
         incrGrayP = {i,~p};
      end
   endfunction
   function [indxWidth:0] incrGray ;
      input [indxWidth:0] grayin;
      input parity ;

      begin: incrGrayBlock
         integer               i;
         reg [indxWidth: 0]    tempshift;
         reg [indxWidth: 0]    flips;

         flips[0] = ! parity ;
         for ( i = 1 ; i < indxWidth ; i = i+1 )
           begin
              tempshift = grayin << (2 + indxWidth - i ) ;
              flips[i]  = parity & grayin[i-1] & ~(| tempshift ) ;
           end
         tempshift = grayin << 2 ;
         flips[indxWidth] = parity & ~(| tempshift ) ;

         incrGray = flips ^ grayin ;
      end
   endfunction

endmodule // FIFOSync



module aggregator
#(
  parameter DATA_WIDTH = 16,
  parameter FETCH_WIDTH = 40 //40 is the most we will use, so we will use this by default
)
(
  input clk,
  input rst_n,
  input [DATA_WIDTH - 1 : 0] sender_data,
  input sender_empty_n,
  output sender_deq,
  output [FETCH_WIDTH*DATA_WIDTH - 1 : 0] receiver_data, //For Internal Nodes and Query patches this is too large by defualy
  input receiver_full_n,
  output reg receiver_enq,
  input change_fetch_width,
  input [2:0] input_fetch_width
  
);

  localparam COUNTER_WIDTH = $clog2(FETCH_WIDTH);
  reg [COUNTER_WIDTH - 1 : 0] count_r;
  
  reg [DATA_WIDTH - 1 : 0] receiver_data_unpacked [FETCH_WIDTH - 1 : 0]; 
  wire sender_deq_w;

  assign sender_deq_w = rst_n && sender_empty_n && receiver_full_n;
  assign sender_deq = sender_deq_w;

  genvar i;
  generate
    for (i = 0; i < FETCH_WIDTH; i++) begin: unpack
      assign receiver_data[(i + 1)*DATA_WIDTH - 1 : i*DATA_WIDTH] = receiver_data_unpacked[i];
    end
  endgenerate
  
  
  reg [5:0] LOCAL_FETCH_WIDTH;
  always @ (posedge clk) begin
    if (!rst_n) begin
       LOCAL_FETCH_WIDTH <= FETCH_WIDTH;
      count_r <= 0;
    end
    
    else if (change_fetch_width) begin
      LOCAL_FETCH_WIDTH <= {3'b0, input_fetch_width};
    end
    
    else begin
      LOCAL_FETCH_WIDTH <= LOCAL_FETCH_WIDTH;
    end
    
  end

  always @ (posedge clk) begin
    if (rst_n) begin
      if (sender_deq_w) begin
        receiver_data_unpacked[count_r] <= sender_data;
        count_r <= (count_r == LOCAL_FETCH_WIDTH) ? 0 : count_r + 1;
        receiver_enq <= (count_r == LOCAL_FETCH_WIDTH); 
      end else begin
        receiver_enq <= 0;
      end
    end else begin
      receiver_enq <= 0;
      count_r <= 0;
    end
  end
endmodule


/*
 A module for an register based tree of internal node of a KD-Tree
 A set of these nodes will be instantiated together to make an actual tree,
 this is a physical description of the node of the tree. 
  Author: Chris Calloway, cmc2374@stanford.edu
*/


module internal_node_tree
#(
  parameter INTERNAL_WIDTH = 22,
  parameter PATCH_WIDTH = 55,
  parameter ADDRESS_WIDTH = 8,
  parameter WB_ADDRESS_OFFSET = 495
)
(
  input clk,
  input rst_n,
  input fsm_enable, //based on whether we are at the proper I/O portion
  input sender_enable,
  input [INTERNAL_WIDTH - 1 : 0] sender_data,
  input patch_en,
  input patch_two_en, 
  input [PATCH_WIDTH - 1 : 0] patch_in,
  input [PATCH_WIDTH - 1 : 0] patch_in_two,
  output logic [ADDRESS_WIDTH - 1 : 0] leaf_index,
  output logic [ADDRESS_WIDTH - 1 : 0] leaf_index_two,
  output receiver_en,
  output receiver_two_en,
    input wb_mode,
    input wb_clk_i, 
    input wb_rst_i, 
    input wbs_stb_i, 
    input wbs_cyc_i, 
    input wbs_we_i, 
    input [3:0] wbs_sel_i, 
    input [31:0] wbs_dat_i, 
    input [31:0] wbs_adr_i, 
    output wbs_ack_o, 
    output [31:0] wbs_dat_o


);

wire wen;

assign wen = fsm_enable && sender_enable && (!wb_mode);


//Wishbone interface

reg [INTERNAL_WIDTH-1:0] rdata_storage [63:0]; //For index and median read from tree

reg [INTERNAL_WIDTH - 1 : 0]  write_data;

reg wb_wen;
reg [31:0] wb_out;
reg ack;
wire signed [31:0] wb_addr; //Will only use top 6 bits of this

assign wb_addr = wbs_adr_i - WB_ADDRESS_OFFSET;
 assign wbs_ack_o = ack;
 
 


 assign wbs_dat_o = {21'b0, wb_out[10:0]};


always @(*) begin 

    if (wb_mode) begin


        if (wbs_we_i) begin //active high wen

           if (wbs_dat_i[11] == 1'b0) begin
                write_data[10:0] = wbs_dat_i[10:0]; //if index is 0
                wb_wen = 1'b0;
                ack = 1'b0;

            end
            else begin
                write_data[21:11] = wbs_dat_i[10:0]; //second half
                wb_wen = 1'b1; //written all data so set wen

                ack = 1'b1;
            
            end
        end

        //if not write, then read

        else begin
         
           wb_wen = 1'b0;

           if (wbs_dat_i[11] == 1'b0) begin
 

                wb_out[10:0] = rdata_storage[wb_addr[5:0]][10:0]; //read address is same as write address
                ack = 1'b1;

            end
            else begin
                wb_out[10:0] = rdata_storage[wb_addr[5:0]][21:11]; //read address is same as write address
                ack = 1'b1;
            
            end

        end




    end
    //Normal I/O mode
    else begin 
        write_data = sender_data;
       
    end

end

 



reg [5:0] wadr; //Internal state holding current address to be read (2^6 internal nodes)
reg  one_hot_address_en [63:0]; //TODO: Fix width on these
wire [PATCH_WIDTH - 1 : 0] patch_out;


 

 //Register for keeping track of whether output is valid (keeps track of pipelined inputs as well.
 // This handles the 6 cycle latency of this setup
reg latency_track_reciever_en [5:0];
reg latency_track_reciever_two_en [5:0];
 
 always @ (posedge clk) begin
     if (rst_n == 0) begin
      latency_track_reciever_en[0] <= 0;
      latency_track_reciever_en[1] <= 0;
      latency_track_reciever_en[2] <= 0;
      latency_track_reciever_en[3] <= 0;
      latency_track_reciever_en[4] <= 0;
      latency_track_reciever_en[5] <= 0;

      latency_track_reciever_two_en[0] <= 0;
      latency_track_reciever_two_en[1] <= 0;
      latency_track_reciever_two_en[2] <= 0;
      latency_track_reciever_two_en[3] <= 0;
      latency_track_reciever_two_en[4] <= 0;
      latency_track_reciever_two_en[5] <= 0;
    end
    else begin
      latency_track_reciever_en[0] <= patch_en;
      latency_track_reciever_en[1] <= latency_track_reciever_en[0];
      latency_track_reciever_en[2] <= latency_track_reciever_en[1];
      latency_track_reciever_en[3] <= latency_track_reciever_en[2];
      latency_track_reciever_en[4] <= latency_track_reciever_en[3];
      latency_track_reciever_en[5] <= latency_track_reciever_en[4];

      latency_track_reciever_two_en[0] <= patch_two_en;
      latency_track_reciever_two_en[1] <= latency_track_reciever_two_en[0];
      latency_track_reciever_two_en[2] <= latency_track_reciever_two_en[1];
      latency_track_reciever_two_en[3] <= latency_track_reciever_two_en[2];
      latency_track_reciever_two_en[4] <= latency_track_reciever_two_en[3];
      latency_track_reciever_two_en[5] <= latency_track_reciever_two_en[4];
    end
  
 end
 
 assign receiver_en = latency_track_reciever_en[5];
 assign receiver_two_en = latency_track_reciever_two_en[5];


//Register for storing and updating address
always @ (posedge clk) begin

    if (rst_n == 0) begin
        wadr <= 0;
    end
    else if (wen) begin
        wadr <= wadr + 1;
    end
    else begin
        wadr <= wadr;
    end

end

//Create 7:128 Decoder to create address system for writing to internal nodes
//Result is a 1 hot signal, where the index that includes the 1 corresponds to the internal_node that will be written to.
always @(*) begin 

    for (int q = 0; q < 128; q++) begin

        if (wb_mode) begin  //If in wishbone mode, this will read from the wb_addr
            if (q == wb_addr) begin
                one_hot_address_en[q] = 1'b1; 
            end
            else begin
                one_hot_address_en[q] = 1'b0;
            end

        end
        else begin
            if (q == wadr) begin
                one_hot_address_en[q] = 1'b1; //TODO: Does this synthesize well?
            end
            else begin
                one_hot_address_en[q] = 1'b0;
            end
        end
    end
end




// Generate the internal kd tree

reg [PATCH_WIDTH-1:0] level_patches [7:0]; //For storing patch
reg [PATCH_WIDTH-1:0] level_patches_two [7:0]; //For storing patch
reg level_valid [63:0][7:0]; //for storing valid signals
reg level_valid_two [63:0][7:0]; //for storing valid signals
wire level_valid_storage [63:0][7:0]; //for storing valid signals
wire level_valid_storage_two [63:0][7:0]; //for storing valid signals


 


always @(*) begin
    
    level_valid[0][0] = 255'b1;
    level_valid_two[0][0] = 255'b1;
    level_patches[0] = patch_in;
    level_patches_two[0] = patch_in_two;

end
 
 
 
genvar i, j;

generate 
    
   for (i = 0; i < 6; i = i +1) begin

        // wire [2*(2**i)] valid_output;
        //Fan out like a tree (TODO: Check that 2**i doesn't cause synthesis problems)
    
       //NEW! We do patch pipeling in the outer loop. See the diagram of how the patch is moved through the registers
      // For more clarity
      //level_patches_storage[i] = level_patches[i];
      
        for (j =0; j < (2**i); j = j +1 ) begin
         
     
         //((i * (2**i)) + j) i * (number of iterations of j)+ j //Keep track of one_hot_address_en
         
            internal_node
            #(
            .DATA_WIDTH(PATCH_WIDTH),
            .STORAGE_WIDTH(INTERNAL_WIDTH)
            )
            node
            (
            .clk(clk),
            .rst_n(rst_n),
            .wen((wen || wb_wen ) && one_hot_address_en[(((2**i)) + j-1)]), //Determined by FSM, reciever enq, and DECODER indexed at i. TODO Check slice
            .valid(level_valid[j][i]),
            .valid_two(level_valid_two[j][i]),
            .wdata(write_data), //writing mechanics are NOT pipelined
            .patch_in(level_patches[i]),
            .patch_in_two(level_patches_two[i]),
            .valid_left(level_valid_storage[j*2][i]),
            .valid_right(level_valid_storage[(j*2)+1][i]),
            .valid_left_two(level_valid_storage_two[j*2][i]),
            .valid_right_two(level_valid_storage_two[(j*2)+1][i]),
            .rdata(rdata_storage[(((2**i)) + j-1)])
            );

        //  assign valid_output[(j*2)+1:(j*2)] = vl;
        //  assign valid_output[(j*2)+2:(j*2)+1] = vr;
      
            
        end



        
        //Create register per depth that holds current patch and valids

        always @ (posedge clk) begin

            if (rst_n == 0) begin
                level_patches[i+1] <= 0;
                level_patches_two[i+1] <= 0 ;
                 for (int r = 0; r < 64; r++) begin
                     level_valid[r][i+1] = 1'b0;
                      level_valid_two[r][i+1] = 1'b0;
                 end
             
            end
            else begin
                level_patches[i+1] <= level_patches[i];
                level_patches_two[i+1] <= level_patches_two[i];
                //level_valid[i+1] <= level_valid[i];
                 for (int r = 0; r < 64; r++) begin
                    level_valid[r][i+1] = level_valid_storage[r][i];
                    level_valid_two[r][i+1] = level_valid_storage_two[r][i];
                 end
            end

        end

        
    end


endgenerate


//From the last row, determine the leaf index
//Algo source: https://stackoverflow.com/a/62776453

always @(*) begin

    leaf_index = 0;
    for (int i = 0; i < 64; i++) begin
        if (level_valid[i][6] == 1'b1) begin
          leaf_index = i;
        end
    end


    leaf_index_two = 0;
    for (int i = 0; i < 64; i++) begin
        if (level_valid_two[i][6] == 1'b1) begin
          leaf_index_two = i;
        end
    end


end

endmodule

/*
 A module for an internal node of a KD-Tree
 A set of these nodes will be instantiated together to make an actual tree,
 this is a physical description of the node of the tree. 
  Author: Chris Calloway, cmc2374@stanford.edu
*/


module internal_node
#(
  parameter DATA_WIDTH = 55,
  parameter STORAGE_WIDTH = 22
)
(
  input clk,
  input rst_n,
  input wen, //Determined by FSM, reciever enq, and DECODER from KD Tree
  input valid,
  input valid_two,
  input [STORAGE_WIDTH -1 : 0] wdata,
  input [DATA_WIDTH - 1 : 0] patch_in,
  input [DATA_WIDTH - 1 : 0] patch_in_two,
  output [DATA_WIDTH - 1 : 0] patch_out, //Same patch, but we will be pipeling so it will be useful to adopt this input/ouput scheme
  output valid_left,
  output valid_right,
  output valid_left_two,
  output valid_right_two,
  output [STORAGE_WIDTH-1: 0] rdata

);


reg [2:0] idx;
reg signed [10: 0] median; 
reg signed [10: 0] sliced_patch;
reg signed [10: 0] sliced_patch_two;

 
 

wire comparison;
wire comparison_two;

//Wdata: 1st 11 bits is Index (which can slice to the  3 LSB bits) since we gave 5 indeces, and 5 < 2^3.
// 2nd 11 bits are the Median, for which we must store the entire 11 bits

//IDX Storage
always @ (clk) begin

    if (rst_n == 0) begin
        idx <= 3'b111; //-1 is an invalid index, this by default we know this to be untrue
    end
    else if (wen) begin
        idx <= wdata[2:0]; //Get 3 LSB
    end
    else begin
        idx <= idx; //No change / persist in memory 
    end

end


//Median Storage
always @ (clk) begin

    if (rst_n == 0) begin
        median <= 0; //0 is an urealistic median, this by default we (likely) know this to be untrue. The -1 idx is the true debug test
    end
    else if (wen) begin
        median <= wdata[21:11]; //Get Median
    end
    else begin
        median <= median; //No change / persist in memory 
    end

end

//Slice Component to get the proper value from the incoming patch based on stored dimension.
 //NOTE: some testbenches have this order flipped (think endianess) You may need to flip the order of these case statements
always @(*) begin 
    case(idx)
       3'b000 :   begin
                sliced_patch = patch_in[10:0];
                sliced_patch_two = patch_in_two[10:0];
       end
       3'b001 :  begin
            sliced_patch = patch_in[21:11];
             sliced_patch_two = patch_in_two[21:11];
       end
       3'b010 : begin
            sliced_patch = patch_in[32:22];
            sliced_patch_two = patch_in_two[32:22];
       end   
 
       3'b011 :   begin
            sliced_patch = patch_in[43:33];
            sliced_patch_two = patch_in_two[43:33];
       end    
       3'b100 :  begin
            sliced_patch = patch_in[54:44];
            sliced_patch_two = patch_in_two[54:44];
       end

       default :  begin
            sliced_patch = 11'b0;;
            sliced_patch_two =11'b0;;
       end
       
       
        // sliced_patch = 11'b0;
    endcase 
end


assign comparison = (sliced_patch < median);
assign comparison_two = (sliced_patch_two < median);

assign valid_left = comparison && valid;
assign valid_right = (!comparison) && valid;


assign valid_left_two = comparison_two && valid_two;
assign valid_right_two = (!comparison_two) && valid_two;



assign patch_out = patch_in; //deprecated

assign rdata = {median, 8'b0, idx}; //fill to 22 in width



endmodule


module LeavesMem
#(
    parameter DATA_WIDTH = 11,
    parameter IDX_WIDTH = 9,
    parameter LEAF_SIZE = 8,
    parameter PATCH_SIZE = 5,
    parameter NUM_LEAVES = 64,
    parameter LEAF_ADDRW = $clog2(NUM_LEAVES)
)
(
    input logic clk,

    input logic [LEAF_SIZE-1:0]                         csb0,
    input logic [LEAF_SIZE-1:0]                         web0,
    input logic [LEAF_ADDRW-1:0]                        addr0,
    input logic [PATCH_SIZE*DATA_WIDTH+IDX_WIDTH-1:0]   wleaf0,
    output logic [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]      rpatch_data0 [LEAF_SIZE-1:0],
    output logic [IDX_WIDTH-1:0]                        rpatch_idx0 [LEAF_SIZE-1:0],
    input logic                                         csb1,
    input logic [LEAF_ADDRW-1:0]                        addr1,
    output logic [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]      rpatch_data1 [LEAF_SIZE-1:0],
    output logic [IDX_WIDTH-1:0]                        rpatch_idx1 [LEAF_SIZE-1:0]
);

    logic [7:0] ram_addr0;
    logic [7:0] ram_addr1;
    logic [63:0] rdata0 [LEAF_SIZE-1:0];
    logic [63:0] rdata1 [LEAF_SIZE-1:0];

    assign ram_addr0 = {'0, addr0};
    assign ram_addr1 = {'0, addr1};
    
    genvar i;
    generate
    for (i=0; i<LEAF_SIZE; i=i+1) begin : loop_ram_patch_gen
        sram_1kbyte_1rw1r
        #(
            .DATA_WIDTH(64), // round(PATCH_SIZE * DATA_WIDTH)
            .ADDR_WIDTH(8),
            .RAM_DEPTH(256) // NUM_LEAVES
        ) ram_patch_inst (
            .clk0(clk),
            .csb0(csb0[i]),
            .web0(web0[i]),
            .addr0(ram_addr0),
            .din0(wleaf0),
            .dout0(rdata0[i]),
            .clk1(clk),
            .csb1(csb1),
            .addr1(ram_addr1),
            .dout1(rdata1[i])
        );

        assign rpatch_data0[i] = rdata0[i][PATCH_SIZE*DATA_WIDTH-1:0];
        assign rpatch_idx0[i] = rdata0[i][63:PATCH_SIZE*DATA_WIDTH];
        assign rpatch_data1[i] = rdata1[i][PATCH_SIZE*DATA_WIDTH-1:0];
        assign rpatch_idx1[i] = rdata1[i][63:PATCH_SIZE*DATA_WIDTH];
    end
    endgenerate

endmodule

module QueryPatchMem2
#(
  parameter DATA_WIDTH = 11,
  parameter PATCH_SIZE = 5,
  parameter ADDR_WIDTH = 9,
  parameter DEPTH = 512,
  parameter WB_ADDRESS_OFFSET = 557
)
(

    input logic                                       clk,
    input logic                                       csb0,
    input logic                                       web0,
    input logic [ADDR_WIDTH-1:0]                      addr0,
    input logic [DATA_WIDTH*PATCH_SIZE-1:0]           wpatch0,
    output logic  [DATA_WIDTH*PATCH_SIZE-1:0]         rpatch0,
    input logic                                       csb1,
    input logic [ADDR_WIDTH-1:0]                      addr1,
    output logic  [DATA_WIDTH*PATCH_SIZE-1:0]         rpatch1,

    input wb_mode,
    input wb_clk_i, 
    input wb_rst_i, 
    input wbs_stb_i, 
    input wbs_cyc_i, 
    input wbs_we_i, 
    input [3:0] wbs_sel_i, 
    input [31:0] wbs_dat_i, 
    input [31:0] wbs_adr_i, 
    output wbs_ack_o, 
    output [31:0] wbs_dat_o

);
  
  
    
    logic [63:0] wdata0;
    logic [63:0] rdata0;
    logic [63:0] rdata1;
    logic [7:0] wmask;
    logic wen;
    logic [ADDR_WIDTH-1:0] ram_addr0;
  

    reg [7:0] wb_mask; //We will determine wmask based on on the input data
    wire [7:0] io_mask; //Fully permissice mask that is used in non-wishbone mode
    assign io_mask = 8'hFF;


    reg [31:0] wb_addr;
    reg [63:0] wb_wdata0;
    reg [31:0] wb_dat_o;


    always @(*) begin

        wb_addr = wbs_adr_i - WB_ADDRESS_OFFSET;

       if (wb_mode && wbs_we_i) begin

            //Determine what the mask should be
            //and place the darta in the appropiate section
            //Logically we would read in 11 bits at a time. However, this does not work will with the SRAM. Thus we read 8 bits at a time
            

            case(wbs_dat_i[13:11]) 

                3'b000: begin 
                    wb_mask = 8'b00000001;     
                    wb_wdata0 = {56'b0, wbs_dat_i[7:0]};
                end
                3'b001: begin
                    wb_mask = 8'b00000010;
                    wb_wdata0 = {48'b0, wbs_dat_i[7:0], 8'b0};
                end
                3'b010: begin 
                    wb_mask = 8'b00000100;
                    wb_wdata0 = {40'b0, wbs_dat_i[7:0], 16'b0};
                end
                3'b011: begin
                    wb_mask = 8'b00001000;
                    wb_wdata0 = {32'b0, wbs_dat_i[7:0], 24'b0};
                end
                3'b100: begin
                    wb_mask = 8'b00010000;
                    wb_wdata0 = {24'b0, wbs_dat_i[7:0], 32'b0};
                end
                3'b101: begin
                    wb_mask = 8'b00100000;
                    wb_wdata0 = {16'b0, wbs_dat_i[7:0], 40'b0};
                end
                3'b110: begin
                    wb_mask = 8'b01000000;
                    wb_wdata0 = {8'b0, wbs_dat_i[7:0], 48'b0};
                end
                3'b111: begin
                    wb_mask = 8'b10000000;
                    wb_wdata0 = {wbs_dat_i[7:0], 56'b0};
                end

                default: begin
                    wb_mask = 8'b00000001;
                    wb_wdata0 = {56'b0, wbs_dat_i[7:0]};
                end


            endcase

       end

            //Reading Logic

            else if (wb_mode && !wbs_we_i) begin

            
            end


        //If not wb
        else begin
            wb_mask = 8'hFF;
        end

    end



  
   

    assign wdata0 = wb_mode ? wb_wdata0 :  {'0, wpatch0};
    assign wmask = wb_mode ? wb_mask :  io_mask;

    assign wen = wb_mode ? !wbs_we_i : web0;
    assign ram_addr0 = wb_mode ? wb_addr[ADDR_WIDTH-1:0] : addr0;


    assign rpatch0 = rdata0[PATCH_SIZE*DATA_WIDTH-1:0];
    assign rpatch1 = rdata1[PATCH_SIZE*DATA_WIDTH-1:0];
    assign wbs_dat_o = (!wbs_dat_i[11]) ? rpatch0[31:0] : {9'b0, rpatch0[54:32]} ;

    sram_1kbyte_1rw1r
    #(
        .DATA_WIDTH(64), // round_up(PATCH_SIZE * DATA_WIDTH)
        .ADDR_WIDTH(ADDR_WIDTH),
        .RAM_DEPTH(DEPTH) // round_up(26*19)
    ) ram_patch_inst (
        .clk0(clk),
        .csb0(csb0),
        .web0(wen),
        .addr0(ram_addr0),
        .din0(wdata0),
        .dout0(rdata0),
        .clk1(clk),
        .csb1(csb1),
        .addr1(addr1),
        .dout1(rdata1),
        .wmask0(wmask)
    );

endmodule

module kBestArrays #(
    parameter DATA_WIDTH = 11,
    parameter IDX_WIDTH = 9,
    parameter K = 4,
    parameter NUM_LEAVES = 64,
    parameter LEAF_ADDRW = $clog2(NUM_LEAVES)
)
(
    input                                               clk,
    input logic                                         csb0,
    input logic                                         web0,
    input logic [8:0]                                   addr0,
    input logic [DATA_WIDTH-1:0]                        wdist_0 [K-1:0],
    input logic [IDX_WIDTH-1:0]                         widx_0 [K-1:0],
    input logic [LEAF_ADDRW-1:0]                        wleaf_idx_0 [K-1:0],
    output logic [DATA_WIDTH-1:0]                       rdist_0 [K-1:0],
    output logic [IDX_WIDTH-1:0]                        ridx_0 [K-1:0],
    output logic [LEAF_ADDRW-1:0]                       rleaf_idx_0 [K-1:0],
    input logic [K-1:0]                                 csb1,
    input logic [8:0]                                   addr1,
    output logic [DATA_WIDTH-1:0]                       rdist_1 [K-1:0],
    output logic [IDX_WIDTH-1:0]                        ridx_1 [K-1:0],
    output logic [LEAF_ADDRW-1:0]                       rleaf_idx_1 [K-1:0]
);

    logic [31:0] dout0 [K-1:0];
    logic [31:0] dout1 [K-1:0];
    genvar i;
    generate
    for (i=0; i<K; i=i+1) begin : loop_best_array_gen
        sram_1kbyte_1rw1r
        #(
            .DATA_WIDTH(32), // round(PATCH_SIZE * DATA_WIDTH)
            .ADDR_WIDTH(9),
            .RAM_DEPTH(512) // NUM_PATCHES
        ) best_dist_array_inst (
            .clk0(clk),
            .csb0(csb0),
            .web0(web0),
            .addr0(addr0),
            .din0({{(32 - LEAF_ADDRW - IDX_WIDTH - DATA_WIDTH){1'b0}}, wleaf_idx_0[i], widx_0[i], wdist_0[i]}),
            .dout0(dout0[i]),
            .clk1(clk),
            .csb1(csb1[i]),
            .addr1(addr1),
            .dout1(dout1[i])
        );
        assign rdist_0[i] = dout0[i][DATA_WIDTH-1:0];
        assign ridx_0[i] = dout0[i][DATA_WIDTH+IDX_WIDTH-1:DATA_WIDTH];
        assign rleaf_idx_0[i] = dout0[i][DATA_WIDTH+IDX_WIDTH+LEAF_ADDRW-1:DATA_WIDTH+IDX_WIDTH];
        assign rdist_1[i] = dout1[i][DATA_WIDTH-1:0];
        assign ridx_1[i] = dout1[i][DATA_WIDTH+IDX_WIDTH-1:DATA_WIDTH];
        assign rleaf_idx_1[i] = dout1[i][DATA_WIDTH+IDX_WIDTH+LEAF_ADDRW-1:DATA_WIDTH+IDX_WIDTH];
    end
    endgenerate

endmodule

module L2Kernel (
  input logic clk,
  input logic [5:0] leaf_idx_in,
  input logic signed [4:0] [10:0] p0_data,
  input logic [8:0] p0_idx_in,
  input logic signed [4:0] [10:0] p1_data,
  input logic [8:0] p1_idx_in,
  input logic signed [4:0] [10:0] p2_data,
  input logic [8:0] p2_idx_in,
  input logic signed [4:0] [10:0] p3_data,
  input logic [8:0] p3_idx_in,
  input logic signed [4:0] [10:0] p4_data,
  input logic [8:0] p4_idx_in,
  input logic signed [4:0] [10:0] p5_data,
  input logic [8:0] p5_idx_in,
  input logic signed [4:0] [10:0] p6_data,
  input logic [8:0] p6_idx_in,
  input logic signed [4:0] [10:0] p7_data,
  input logic [8:0] p7_idx_in,
  input logic query_first_in,
  input logic query_last_in,
  input logic signed [4:0] [10:0] query_patch,
  input logic query_valid,
  input logic rst_n,
  output logic dist_valid,
  output logic [5:0] leaf_idx_out,
  output logic [8:0] p0_idx_out,
  output logic [24:0] p0_l2_dist,
  output logic [8:0] p1_idx_out,
  output logic [24:0] p1_l2_dist,
  output logic [8:0] p2_idx_out,
  output logic [24:0] p2_l2_dist,
  output logic [8:0] p3_idx_out,
  output logic [24:0] p3_l2_dist,
  output logic [8:0] p4_idx_out,
  output logic [24:0] p4_l2_dist,
  output logic [8:0] p5_idx_out,
  output logic [24:0] p5_l2_dist,
  output logic [8:0] p6_idx_out,
  output logic [24:0] p6_l2_dist,
  output logic [8:0] p7_idx_out,
  output logic [24:0] p7_l2_dist,
  output logic query_first_out,
  output logic query_last_out
);

logic [5:0] leaf_idx_r0;
logic [5:0] leaf_idx_r1;
logic [5:0] leaf_idx_r2;
logic [5:0] leaf_idx_r3;
logic [22:0] p0_add_tree0 [2:0];
logic [23:0] p0_add_tree1 [1:0];
logic [24:0] p0_add_tree2;
logic signed [21:0] p0_diff2 [4:0];
logic [21:0] p0_diff2_unsigned [4:0];
logic [8:0] p0_idx_r0;
logic [8:0] p0_idx_r1;
logic [8:0] p0_idx_r2;
logic [8:0] p0_idx_r3;
logic signed [10:0] p0_patch_diff [4:0];
logic [22:0] p1_add_tree0 [2:0];
logic [23:0] p1_add_tree1 [1:0];
logic [24:0] p1_add_tree2;
logic signed [21:0] p1_diff2 [4:0];
logic [21:0] p1_diff2_unsigned [4:0];
logic [8:0] p1_idx_r0;
logic [8:0] p1_idx_r1;
logic [8:0] p1_idx_r2;
logic [8:0] p1_idx_r3;
logic signed [10:0] p1_patch_diff [4:0];
logic [22:0] p2_add_tree0 [2:0];
logic [23:0] p2_add_tree1 [1:0];
logic [24:0] p2_add_tree2;
logic signed [21:0] p2_diff2 [4:0];
logic [21:0] p2_diff2_unsigned [4:0];
logic [8:0] p2_idx_r0;
logic [8:0] p2_idx_r1;
logic [8:0] p2_idx_r2;
logic [8:0] p2_idx_r3;
logic signed [10:0] p2_patch_diff [4:0];
logic [22:0] p3_add_tree0 [2:0];
logic [23:0] p3_add_tree1 [1:0];
logic [24:0] p3_add_tree2;
logic signed [21:0] p3_diff2 [4:0];
logic [21:0] p3_diff2_unsigned [4:0];
logic [8:0] p3_idx_r0;
logic [8:0] p3_idx_r1;
logic [8:0] p3_idx_r2;
logic [8:0] p3_idx_r3;
logic signed [10:0] p3_patch_diff [4:0];
logic [22:0] p4_add_tree0 [2:0];
logic [23:0] p4_add_tree1 [1:0];
logic [24:0] p4_add_tree2;
logic signed [21:0] p4_diff2 [4:0];
logic [21:0] p4_diff2_unsigned [4:0];
logic [8:0] p4_idx_r0;
logic [8:0] p4_idx_r1;
logic [8:0] p4_idx_r2;
logic [8:0] p4_idx_r3;
logic signed [10:0] p4_patch_diff [4:0];
logic [22:0] p5_add_tree0 [2:0];
logic [23:0] p5_add_tree1 [1:0];
logic [24:0] p5_add_tree2;
logic signed [21:0] p5_diff2 [4:0];
logic [21:0] p5_diff2_unsigned [4:0];
logic [8:0] p5_idx_r0;
logic [8:0] p5_idx_r1;
logic [8:0] p5_idx_r2;
logic [8:0] p5_idx_r3;
logic signed [10:0] p5_patch_diff [4:0];
logic [22:0] p6_add_tree0 [2:0];
logic [23:0] p6_add_tree1 [1:0];
logic [24:0] p6_add_tree2;
logic signed [21:0] p6_diff2 [4:0];
logic [21:0] p6_diff2_unsigned [4:0];
logic [8:0] p6_idx_r0;
logic [8:0] p6_idx_r1;
logic [8:0] p6_idx_r2;
logic [8:0] p6_idx_r3;
logic signed [10:0] p6_patch_diff [4:0];
logic [22:0] p7_add_tree0 [2:0];
logic [23:0] p7_add_tree1 [1:0];
logic [24:0] p7_add_tree2;
logic signed [21:0] p7_diff2 [4:0];
logic [21:0] p7_diff2_unsigned [4:0];
logic [8:0] p7_idx_r0;
logic [8:0] p7_idx_r1;
logic [8:0] p7_idx_r2;
logic [8:0] p7_idx_r3;
logic signed [10:0] p7_patch_diff [4:0];
logic [4:0] query_first_shft;
logic [4:0] query_last_shft;
logic [4:0] valid_shft;

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    query_first_shft <= 5'h0;
    query_last_shft <= 5'h0;
    valid_shft <= 5'h0;
  end
  else begin
    query_first_shft <= {query_first_shft[3:0], query_first_in};
    query_last_shft <= {query_last_shft[3:0], query_last_in};
    valid_shft <= {valid_shft[3:0], query_valid};
  end
end
assign query_first_out = query_first_shft[4];
assign query_last_out = query_last_shft[4];
assign dist_valid = valid_shft[4];

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    leaf_idx_r0 <= 6'h0;
    leaf_idx_r1 <= 6'h0;
    leaf_idx_r2 <= 6'h0;
    leaf_idx_r3 <= 6'h0;
    leaf_idx_out <= 6'h0;
  end
  else begin
    if (query_valid) begin
      leaf_idx_r0 <= leaf_idx_in;
    end
    if (valid_shft[0]) begin
      leaf_idx_r1 <= leaf_idx_r0;
    end
    if (valid_shft[1]) begin
      leaf_idx_r2 <= leaf_idx_r1;
    end
    if (valid_shft[2]) begin
      leaf_idx_r3 <= leaf_idx_r2;
    end
    if (valid_shft[3]) begin
      leaf_idx_out <= leaf_idx_r3;
    end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p0_idx_r0 <= 9'h0;
    p0_idx_r1 <= 9'h0;
    p0_idx_r2 <= 9'h0;
    p0_idx_r3 <= 9'h0;
    p0_idx_out <= 9'h0;
  end
  else begin
    if (query_valid) begin
      p0_idx_r0 <= p0_idx_in;
    end
    if (valid_shft[0]) begin
      p0_idx_r1 <= p0_idx_r0;
    end
    if (valid_shft[1]) begin
      p0_idx_r2 <= p0_idx_r1;
    end
    if (valid_shft[2]) begin
      p0_idx_r3 <= p0_idx_r2;
    end
    if (valid_shft[3]) begin
      p0_idx_out <= p0_idx_r3;
    end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p0_patch_diff[3'(p)] <= 11'h0;
      end
  end
  else if (query_valid) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p0_patch_diff[3'(p)] <= query_patch[3'(p)] - p0_data[3'(p)];
      end
  end
end
always_comb begin
  for (int unsigned p = 0; p < 5; p += 1) begin
      p0_diff2[3'(p)] = 22'(p0_patch_diff[3'(p)]) * 22'(p0_patch_diff[3'(p)]);
    end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p0_diff2_unsigned[3'(p)] <= 22'h0;
      end
  end
  else if (valid_shft[0]) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p0_diff2_unsigned[3'(p)] <= unsigned'(p0_diff2[3'(p)]);
      end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p0_add_tree0[0] <= 23'h0;
    p0_add_tree0[1] <= 23'h0;
    p0_add_tree0[2] <= 23'h0;
    p0_add_tree1[0] <= 24'h0;
    p0_add_tree1[1] <= 24'h0;
    p0_add_tree2 <= 25'h0;
  end
  else begin
    if (valid_shft[1]) begin
      p0_add_tree0[0] <= 23'(p0_diff2_unsigned[0]) + 23'(p0_diff2_unsigned[1]);
      p0_add_tree0[1] <= 23'(p0_diff2_unsigned[2]) + 23'(p0_diff2_unsigned[3]);
      p0_add_tree0[2] <= 23'(p0_diff2_unsigned[4]);
    end
    if (valid_shft[2]) begin
      p0_add_tree1[0] <= 24'(p0_add_tree0[0]) + 24'(p0_add_tree0[1]);
      p0_add_tree1[1] <= 24'(p0_add_tree0[2]);
    end
    if (valid_shft[3]) begin
      p0_add_tree2 <= 25'(p0_add_tree1[0]) + 25'(p0_add_tree1[1]);
    end
  end
end
assign p0_l2_dist = p0_add_tree2;

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p1_idx_r0 <= 9'h0;
    p1_idx_r1 <= 9'h0;
    p1_idx_r2 <= 9'h0;
    p1_idx_r3 <= 9'h0;
    p1_idx_out <= 9'h0;
  end
  else begin
    if (query_valid) begin
      p1_idx_r0 <= p1_idx_in;
    end
    if (valid_shft[0]) begin
      p1_idx_r1 <= p1_idx_r0;
    end
    if (valid_shft[1]) begin
      p1_idx_r2 <= p1_idx_r1;
    end
    if (valid_shft[2]) begin
      p1_idx_r3 <= p1_idx_r2;
    end
    if (valid_shft[3]) begin
      p1_idx_out <= p1_idx_r3;
    end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p1_patch_diff[3'(p)] <= 11'h0;
      end
  end
  else if (query_valid) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p1_patch_diff[3'(p)] <= query_patch[3'(p)] - p1_data[3'(p)];
      end
  end
end
always_comb begin
  for (int unsigned p = 0; p < 5; p += 1) begin
      p1_diff2[3'(p)] = 22'(p1_patch_diff[3'(p)]) * 22'(p1_patch_diff[3'(p)]);
    end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p1_diff2_unsigned[3'(p)] <= 22'h0;
      end
  end
  else if (valid_shft[0]) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p1_diff2_unsigned[3'(p)] <= unsigned'(p1_diff2[3'(p)]);
      end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p1_add_tree0[0] <= 23'h0;
    p1_add_tree0[1] <= 23'h0;
    p1_add_tree0[2] <= 23'h0;
    p1_add_tree1[0] <= 24'h0;
    p1_add_tree1[1] <= 24'h0;
    p1_add_tree2 <= 25'h0;
  end
  else begin
    if (valid_shft[1]) begin
      p1_add_tree0[0] <= 23'(p1_diff2_unsigned[0]) + 23'(p1_diff2_unsigned[1]);
      p1_add_tree0[1] <= 23'(p1_diff2_unsigned[2]) + 23'(p1_diff2_unsigned[3]);
      p1_add_tree0[2] <= 23'(p1_diff2_unsigned[4]);
    end
    if (valid_shft[2]) begin
      p1_add_tree1[0] <= 24'(p1_add_tree0[0]) + 24'(p1_add_tree0[1]);
      p1_add_tree1[1] <= 24'(p1_add_tree0[2]);
    end
    if (valid_shft[3]) begin
      p1_add_tree2 <= 25'(p1_add_tree1[0]) + 25'(p1_add_tree1[1]);
    end
  end
end
assign p1_l2_dist = p1_add_tree2;

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p2_idx_r0 <= 9'h0;
    p2_idx_r1 <= 9'h0;
    p2_idx_r2 <= 9'h0;
    p2_idx_r3 <= 9'h0;
    p2_idx_out <= 9'h0;
  end
  else begin
    if (query_valid) begin
      p2_idx_r0 <= p2_idx_in;
    end
    if (valid_shft[0]) begin
      p2_idx_r1 <= p2_idx_r0;
    end
    if (valid_shft[1]) begin
      p2_idx_r2 <= p2_idx_r1;
    end
    if (valid_shft[2]) begin
      p2_idx_r3 <= p2_idx_r2;
    end
    if (valid_shft[3]) begin
      p2_idx_out <= p2_idx_r3;
    end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p2_patch_diff[3'(p)] <= 11'h0;
      end
  end
  else if (query_valid) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p2_patch_diff[3'(p)] <= query_patch[3'(p)] - p2_data[3'(p)];
      end
  end
end
always_comb begin
  for (int unsigned p = 0; p < 5; p += 1) begin
      p2_diff2[3'(p)] = 22'(p2_patch_diff[3'(p)]) * 22'(p2_patch_diff[3'(p)]);
    end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p2_diff2_unsigned[3'(p)] <= 22'h0;
      end
  end
  else if (valid_shft[0]) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p2_diff2_unsigned[3'(p)] <= unsigned'(p2_diff2[3'(p)]);
      end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p2_add_tree0[0] <= 23'h0;
    p2_add_tree0[1] <= 23'h0;
    p2_add_tree0[2] <= 23'h0;
    p2_add_tree1[0] <= 24'h0;
    p2_add_tree1[1] <= 24'h0;
    p2_add_tree2 <= 25'h0;
  end
  else begin
    if (valid_shft[1]) begin
      p2_add_tree0[0] <= 23'(p2_diff2_unsigned[0]) + 23'(p2_diff2_unsigned[1]);
      p2_add_tree0[1] <= 23'(p2_diff2_unsigned[2]) + 23'(p2_diff2_unsigned[3]);
      p2_add_tree0[2] <= 23'(p2_diff2_unsigned[4]);
    end
    if (valid_shft[2]) begin
      p2_add_tree1[0] <= 24'(p2_add_tree0[0]) + 24'(p2_add_tree0[1]);
      p2_add_tree1[1] <= 24'(p2_add_tree0[2]);
    end
    if (valid_shft[3]) begin
      p2_add_tree2 <= 25'(p2_add_tree1[0]) + 25'(p2_add_tree1[1]);
    end
  end
end
assign p2_l2_dist = p2_add_tree2;

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p3_idx_r0 <= 9'h0;
    p3_idx_r1 <= 9'h0;
    p3_idx_r2 <= 9'h0;
    p3_idx_r3 <= 9'h0;
    p3_idx_out <= 9'h0;
  end
  else begin
    if (query_valid) begin
      p3_idx_r0 <= p3_idx_in;
    end
    if (valid_shft[0]) begin
      p3_idx_r1 <= p3_idx_r0;
    end
    if (valid_shft[1]) begin
      p3_idx_r2 <= p3_idx_r1;
    end
    if (valid_shft[2]) begin
      p3_idx_r3 <= p3_idx_r2;
    end
    if (valid_shft[3]) begin
      p3_idx_out <= p3_idx_r3;
    end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p3_patch_diff[3'(p)] <= 11'h0;
      end
  end
  else if (query_valid) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p3_patch_diff[3'(p)] <= query_patch[3'(p)] - p3_data[3'(p)];
      end
  end
end
always_comb begin
  for (int unsigned p = 0; p < 5; p += 1) begin
      p3_diff2[3'(p)] = 22'(p3_patch_diff[3'(p)]) * 22'(p3_patch_diff[3'(p)]);
    end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p3_diff2_unsigned[3'(p)] <= 22'h0;
      end
  end
  else if (valid_shft[0]) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p3_diff2_unsigned[3'(p)] <= unsigned'(p3_diff2[3'(p)]);
      end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p3_add_tree0[0] <= 23'h0;
    p3_add_tree0[1] <= 23'h0;
    p3_add_tree0[2] <= 23'h0;
    p3_add_tree1[0] <= 24'h0;
    p3_add_tree1[1] <= 24'h0;
    p3_add_tree2 <= 25'h0;
  end
  else begin
    if (valid_shft[1]) begin
      p3_add_tree0[0] <= 23'(p3_diff2_unsigned[0]) + 23'(p3_diff2_unsigned[1]);
      p3_add_tree0[1] <= 23'(p3_diff2_unsigned[2]) + 23'(p3_diff2_unsigned[3]);
      p3_add_tree0[2] <= 23'(p3_diff2_unsigned[4]);
    end
    if (valid_shft[2]) begin
      p3_add_tree1[0] <= 24'(p3_add_tree0[0]) + 24'(p3_add_tree0[1]);
      p3_add_tree1[1] <= 24'(p3_add_tree0[2]);
    end
    if (valid_shft[3]) begin
      p3_add_tree2 <= 25'(p3_add_tree1[0]) + 25'(p3_add_tree1[1]);
    end
  end
end
assign p3_l2_dist = p3_add_tree2;

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p4_idx_r0 <= 9'h0;
    p4_idx_r1 <= 9'h0;
    p4_idx_r2 <= 9'h0;
    p4_idx_r3 <= 9'h0;
    p4_idx_out <= 9'h0;
  end
  else begin
    if (query_valid) begin
      p4_idx_r0 <= p4_idx_in;
    end
    if (valid_shft[0]) begin
      p4_idx_r1 <= p4_idx_r0;
    end
    if (valid_shft[1]) begin
      p4_idx_r2 <= p4_idx_r1;
    end
    if (valid_shft[2]) begin
      p4_idx_r3 <= p4_idx_r2;
    end
    if (valid_shft[3]) begin
      p4_idx_out <= p4_idx_r3;
    end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p4_patch_diff[3'(p)] <= 11'h0;
      end
  end
  else if (query_valid) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p4_patch_diff[3'(p)] <= query_patch[3'(p)] - p4_data[3'(p)];
      end
  end
end
always_comb begin
  for (int unsigned p = 0; p < 5; p += 1) begin
      p4_diff2[3'(p)] = 22'(p4_patch_diff[3'(p)]) * 22'(p4_patch_diff[3'(p)]);
    end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p4_diff2_unsigned[3'(p)] <= 22'h0;
      end
  end
  else if (valid_shft[0]) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p4_diff2_unsigned[3'(p)] <= unsigned'(p4_diff2[3'(p)]);
      end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p4_add_tree0[0] <= 23'h0;
    p4_add_tree0[1] <= 23'h0;
    p4_add_tree0[2] <= 23'h0;
    p4_add_tree1[0] <= 24'h0;
    p4_add_tree1[1] <= 24'h0;
    p4_add_tree2 <= 25'h0;
  end
  else begin
    if (valid_shft[1]) begin
      p4_add_tree0[0] <= 23'(p4_diff2_unsigned[0]) + 23'(p4_diff2_unsigned[1]);
      p4_add_tree0[1] <= 23'(p4_diff2_unsigned[2]) + 23'(p4_diff2_unsigned[3]);
      p4_add_tree0[2] <= 23'(p4_diff2_unsigned[4]);
    end
    if (valid_shft[2]) begin
      p4_add_tree1[0] <= 24'(p4_add_tree0[0]) + 24'(p4_add_tree0[1]);
      p4_add_tree1[1] <= 24'(p4_add_tree0[2]);
    end
    if (valid_shft[3]) begin
      p4_add_tree2 <= 25'(p4_add_tree1[0]) + 25'(p4_add_tree1[1]);
    end
  end
end
assign p4_l2_dist = p4_add_tree2;

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p5_idx_r0 <= 9'h0;
    p5_idx_r1 <= 9'h0;
    p5_idx_r2 <= 9'h0;
    p5_idx_r3 <= 9'h0;
    p5_idx_out <= 9'h0;
  end
  else begin
    if (query_valid) begin
      p5_idx_r0 <= p5_idx_in;
    end
    if (valid_shft[0]) begin
      p5_idx_r1 <= p5_idx_r0;
    end
    if (valid_shft[1]) begin
      p5_idx_r2 <= p5_idx_r1;
    end
    if (valid_shft[2]) begin
      p5_idx_r3 <= p5_idx_r2;
    end
    if (valid_shft[3]) begin
      p5_idx_out <= p5_idx_r3;
    end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p5_patch_diff[3'(p)] <= 11'h0;
      end
  end
  else if (query_valid) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p5_patch_diff[3'(p)] <= query_patch[3'(p)] - p5_data[3'(p)];
      end
  end
end
always_comb begin
  for (int unsigned p = 0; p < 5; p += 1) begin
      p5_diff2[3'(p)] = 22'(p5_patch_diff[3'(p)]) * 22'(p5_patch_diff[3'(p)]);
    end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p5_diff2_unsigned[3'(p)] <= 22'h0;
      end
  end
  else if (valid_shft[0]) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p5_diff2_unsigned[3'(p)] <= unsigned'(p5_diff2[3'(p)]);
      end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p5_add_tree0[0] <= 23'h0;
    p5_add_tree0[1] <= 23'h0;
    p5_add_tree0[2] <= 23'h0;
    p5_add_tree1[0] <= 24'h0;
    p5_add_tree1[1] <= 24'h0;
    p5_add_tree2 <= 25'h0;
  end
  else begin
    if (valid_shft[1]) begin
      p5_add_tree0[0] <= 23'(p5_diff2_unsigned[0]) + 23'(p5_diff2_unsigned[1]);
      p5_add_tree0[1] <= 23'(p5_diff2_unsigned[2]) + 23'(p5_diff2_unsigned[3]);
      p5_add_tree0[2] <= 23'(p5_diff2_unsigned[4]);
    end
    if (valid_shft[2]) begin
      p5_add_tree1[0] <= 24'(p5_add_tree0[0]) + 24'(p5_add_tree0[1]);
      p5_add_tree1[1] <= 24'(p5_add_tree0[2]);
    end
    if (valid_shft[3]) begin
      p5_add_tree2 <= 25'(p5_add_tree1[0]) + 25'(p5_add_tree1[1]);
    end
  end
end
assign p5_l2_dist = p5_add_tree2;

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p6_idx_r0 <= 9'h0;
    p6_idx_r1 <= 9'h0;
    p6_idx_r2 <= 9'h0;
    p6_idx_r3 <= 9'h0;
    p6_idx_out <= 9'h0;
  end
  else begin
    if (query_valid) begin
      p6_idx_r0 <= p6_idx_in;
    end
    if (valid_shft[0]) begin
      p6_idx_r1 <= p6_idx_r0;
    end
    if (valid_shft[1]) begin
      p6_idx_r2 <= p6_idx_r1;
    end
    if (valid_shft[2]) begin
      p6_idx_r3 <= p6_idx_r2;
    end
    if (valid_shft[3]) begin
      p6_idx_out <= p6_idx_r3;
    end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p6_patch_diff[3'(p)] <= 11'h0;
      end
  end
  else if (query_valid) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p6_patch_diff[3'(p)] <= query_patch[3'(p)] - p6_data[3'(p)];
      end
  end
end
always_comb begin
  for (int unsigned p = 0; p < 5; p += 1) begin
      p6_diff2[3'(p)] = 22'(p6_patch_diff[3'(p)]) * 22'(p6_patch_diff[3'(p)]);
    end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p6_diff2_unsigned[3'(p)] <= 22'h0;
      end
  end
  else if (valid_shft[0]) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p6_diff2_unsigned[3'(p)] <= unsigned'(p6_diff2[3'(p)]);
      end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p6_add_tree0[0] <= 23'h0;
    p6_add_tree0[1] <= 23'h0;
    p6_add_tree0[2] <= 23'h0;
    p6_add_tree1[0] <= 24'h0;
    p6_add_tree1[1] <= 24'h0;
    p6_add_tree2 <= 25'h0;
  end
  else begin
    if (valid_shft[1]) begin
      p6_add_tree0[0] <= 23'(p6_diff2_unsigned[0]) + 23'(p6_diff2_unsigned[1]);
      p6_add_tree0[1] <= 23'(p6_diff2_unsigned[2]) + 23'(p6_diff2_unsigned[3]);
      p6_add_tree0[2] <= 23'(p6_diff2_unsigned[4]);
    end
    if (valid_shft[2]) begin
      p6_add_tree1[0] <= 24'(p6_add_tree0[0]) + 24'(p6_add_tree0[1]);
      p6_add_tree1[1] <= 24'(p6_add_tree0[2]);
    end
    if (valid_shft[3]) begin
      p6_add_tree2 <= 25'(p6_add_tree1[0]) + 25'(p6_add_tree1[1]);
    end
  end
end
assign p6_l2_dist = p6_add_tree2;

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p7_idx_r0 <= 9'h0;
    p7_idx_r1 <= 9'h0;
    p7_idx_r2 <= 9'h0;
    p7_idx_r3 <= 9'h0;
    p7_idx_out <= 9'h0;
  end
  else begin
    if (query_valid) begin
      p7_idx_r0 <= p7_idx_in;
    end
    if (valid_shft[0]) begin
      p7_idx_r1 <= p7_idx_r0;
    end
    if (valid_shft[1]) begin
      p7_idx_r2 <= p7_idx_r1;
    end
    if (valid_shft[2]) begin
      p7_idx_r3 <= p7_idx_r2;
    end
    if (valid_shft[3]) begin
      p7_idx_out <= p7_idx_r3;
    end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p7_patch_diff[3'(p)] <= 11'h0;
      end
  end
  else if (query_valid) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p7_patch_diff[3'(p)] <= query_patch[3'(p)] - p7_data[3'(p)];
      end
  end
end
always_comb begin
  for (int unsigned p = 0; p < 5; p += 1) begin
      p7_diff2[3'(p)] = 22'(p7_patch_diff[3'(p)]) * 22'(p7_patch_diff[3'(p)]);
    end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p7_diff2_unsigned[3'(p)] <= 22'h0;
      end
  end
  else if (valid_shft[0]) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p7_diff2_unsigned[3'(p)] <= unsigned'(p7_diff2[3'(p)]);
      end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p7_add_tree0[0] <= 23'h0;
    p7_add_tree0[1] <= 23'h0;
    p7_add_tree0[2] <= 23'h0;
    p7_add_tree1[0] <= 24'h0;
    p7_add_tree1[1] <= 24'h0;
    p7_add_tree2 <= 25'h0;
  end
  else begin
    if (valid_shft[1]) begin
      p7_add_tree0[0] <= 23'(p7_diff2_unsigned[0]) + 23'(p7_diff2_unsigned[1]);
      p7_add_tree0[1] <= 23'(p7_diff2_unsigned[2]) + 23'(p7_diff2_unsigned[3]);
      p7_add_tree0[2] <= 23'(p7_diff2_unsigned[4]);
    end
    if (valid_shft[2]) begin
      p7_add_tree1[0] <= 24'(p7_add_tree0[0]) + 24'(p7_add_tree0[1]);
      p7_add_tree1[1] <= 24'(p7_add_tree0[2]);
    end
    if (valid_shft[3]) begin
      p7_add_tree2 <= 25'(p7_add_tree1[0]) + 25'(p7_add_tree1[1]);
    end
  end
end
assign p7_l2_dist = p7_add_tree2;
endmodule   // L2Kernel


module BitonicSorter (
  input logic clk,
  input logic [24:0] data_in_0,
  input logic [24:0] data_in_1,
  input logic [24:0] data_in_2,
  input logic [24:0] data_in_3,
  input logic [24:0] data_in_4,
  input logic [24:0] data_in_5,
  input logic [24:0] data_in_6,
  input logic [24:0] data_in_7,
  input logic [14:0] idx_in_0,
  input logic [14:0] idx_in_1,
  input logic [14:0] idx_in_2,
  input logic [14:0] idx_in_3,
  input logic [14:0] idx_in_4,
  input logic [14:0] idx_in_5,
  input logic [14:0] idx_in_6,
  input logic [14:0] idx_in_7,
  input logic query_first_in,
  input logic query_last_in,
  input logic rst_n,
  input logic valid_in,
  output logic [24:0] data_out_0,
  output logic [24:0] data_out_1,
  output logic [24:0] data_out_2,
  output logic [24:0] data_out_3,
  output logic [14:0] idx_out_0,
  output logic [14:0] idx_out_1,
  output logic [14:0] idx_out_2,
  output logic [14:0] idx_out_3,
  output logic query_first_out,
  output logic query_last_out,
  output logic valid_out
);

logic [5:0] query_first_shft;
logic [5:0] query_last_shft;
logic [24:0] stage0_data [7:0];
logic [14:0] stage0_idx [7:0];
logic stage0_valid;
logic [24:0] stage1_data [7:0];
logic [14:0] stage1_idx [7:0];
logic stage1_valid;
logic [24:0] stage2_data [7:0];
logic [14:0] stage2_idx [7:0];
logic stage2_valid;
logic [24:0] stage3_data [3:0];
logic [14:0] stage3_idx [3:0];
logic stage3_valid;
logic [24:0] stage4_data [3:0];
logic [14:0] stage4_idx [3:0];
logic stage4_valid;
logic [24:0] stage5_data [3:0];
logic [14:0] stage5_idx [3:0];
logic stage5_valid;

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    query_first_shft <= 6'h0;
    query_last_shft <= 6'h0;
  end
  else begin
    query_first_shft <= {query_first_shft[4:0], query_first_in};
    query_last_shft <= {query_last_shft[4:0], query_last_in};
  end
end
assign query_first_out = query_first_shft[5];
assign query_last_out = query_last_shft[5];

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    stage0_valid <= 1'h0;
    for (int unsigned p = 0; p < 8; p += 1) begin
        stage0_data[3'(p)] <= 25'h0;
        stage0_idx[3'(p)] <= 15'h0;
      end
  end
  else begin
    stage0_valid <= valid_in;
    if (valid_in) begin
      stage0_data[0] <= (data_in_0 < data_in_1) ? data_in_0: data_in_1;
      stage0_data[1] <= (data_in_0 < data_in_1) ? data_in_1: data_in_0;
      stage0_data[2] <= (data_in_2 > data_in_3) ? data_in_2: data_in_3;
      stage0_data[3] <= (data_in_2 > data_in_3) ? data_in_3: data_in_2;
      stage0_data[4] <= (data_in_4 < data_in_5) ? data_in_4: data_in_5;
      stage0_data[5] <= (data_in_4 < data_in_5) ? data_in_5: data_in_4;
      stage0_data[6] <= (data_in_6 > data_in_7) ? data_in_6: data_in_7;
      stage0_data[7] <= (data_in_6 > data_in_7) ? data_in_7: data_in_6;
      stage0_idx[0] <= (data_in_0 < data_in_1) ? idx_in_0: idx_in_1;
      stage0_idx[1] <= (data_in_0 < data_in_1) ? idx_in_1: idx_in_0;
      stage0_idx[2] <= (data_in_2 > data_in_3) ? idx_in_2: idx_in_3;
      stage0_idx[3] <= (data_in_2 > data_in_3) ? idx_in_3: idx_in_2;
      stage0_idx[4] <= (data_in_4 < data_in_5) ? idx_in_4: idx_in_5;
      stage0_idx[5] <= (data_in_4 < data_in_5) ? idx_in_5: idx_in_4;
      stage0_idx[6] <= (data_in_6 > data_in_7) ? idx_in_6: idx_in_7;
      stage0_idx[7] <= (data_in_6 > data_in_7) ? idx_in_7: idx_in_6;
    end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    stage1_valid <= 1'h0;
    for (int unsigned p = 0; p < 8; p += 1) begin
        stage1_data[3'(p)] <= 25'h0;
        stage1_idx[3'(p)] <= 15'h0;
      end
  end
  else begin
    stage1_valid <= stage0_valid;
    if (stage0_valid) begin
      stage1_data[0] <= (stage0_data[0] < stage0_data[2]) ? stage0_data[0]: stage0_data[2];
      stage1_data[2] <= (stage0_data[0] < stage0_data[2]) ? stage0_data[2]: stage0_data[0];
      stage1_data[1] <= (stage0_data[1] < stage0_data[3]) ? stage0_data[1]: stage0_data[3];
      stage1_data[3] <= (stage0_data[1] < stage0_data[3]) ? stage0_data[3]: stage0_data[1];
      stage1_data[4] <= (stage0_data[4] > stage0_data[6]) ? stage0_data[4]: stage0_data[6];
      stage1_data[6] <= (stage0_data[4] > stage0_data[6]) ? stage0_data[6]: stage0_data[4];
      stage1_data[5] <= (stage0_data[5] > stage0_data[7]) ? stage0_data[5]: stage0_data[7];
      stage1_data[7] <= (stage0_data[5] > stage0_data[7]) ? stage0_data[7]: stage0_data[5];
      stage1_idx[0] <= (stage0_data[0] < stage0_data[2]) ? stage0_idx[0]: stage0_idx[2];
      stage1_idx[2] <= (stage0_data[0] < stage0_data[2]) ? stage0_idx[2]: stage0_idx[0];
      stage1_idx[1] <= (stage0_data[1] < stage0_data[3]) ? stage0_idx[1]: stage0_idx[3];
      stage1_idx[3] <= (stage0_data[1] < stage0_data[3]) ? stage0_idx[3]: stage0_idx[1];
      stage1_idx[4] <= (stage0_data[4] > stage0_data[6]) ? stage0_idx[4]: stage0_idx[6];
      stage1_idx[6] <= (stage0_data[4] > stage0_data[6]) ? stage0_idx[6]: stage0_idx[4];
      stage1_idx[5] <= (stage0_data[5] > stage0_data[7]) ? stage0_idx[5]: stage0_idx[7];
      stage1_idx[7] <= (stage0_data[5] > stage0_data[7]) ? stage0_idx[7]: stage0_idx[5];
    end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    stage2_valid <= 1'h0;
    for (int unsigned p = 0; p < 8; p += 1) begin
        stage2_data[3'(p)] <= 25'h0;
        stage2_idx[3'(p)] <= 15'h0;
      end
  end
  else begin
    stage2_valid <= stage1_valid;
    if (stage1_valid) begin
      stage2_data[0] <= (stage1_data[0] < stage1_data[1]) ? stage1_data[0]: stage1_data[1];
      stage2_data[1] <= (stage1_data[0] < stage1_data[1]) ? stage1_data[1]: stage1_data[0];
      stage2_data[2] <= (stage1_data[2] < stage1_data[3]) ? stage1_data[2]: stage1_data[3];
      stage2_data[3] <= (stage1_data[2] < stage1_data[3]) ? stage1_data[3]: stage1_data[2];
      stage2_data[4] <= (stage1_data[4] > stage1_data[5]) ? stage1_data[4]: stage1_data[5];
      stage2_data[5] <= (stage1_data[4] > stage1_data[5]) ? stage1_data[5]: stage1_data[4];
      stage2_data[6] <= (stage1_data[6] > stage1_data[7]) ? stage1_data[6]: stage1_data[7];
      stage2_data[7] <= (stage1_data[6] > stage1_data[7]) ? stage1_data[7]: stage1_data[6];
      stage2_idx[0] <= (stage1_data[0] < stage1_data[1]) ? stage1_idx[0]: stage1_idx[1];
      stage2_idx[1] <= (stage1_data[0] < stage1_data[1]) ? stage1_idx[1]: stage1_idx[0];
      stage2_idx[2] <= (stage1_data[2] < stage1_data[3]) ? stage1_idx[2]: stage1_idx[3];
      stage2_idx[3] <= (stage1_data[2] < stage1_data[3]) ? stage1_idx[3]: stage1_idx[2];
      stage2_idx[4] <= (stage1_data[4] > stage1_data[5]) ? stage1_idx[4]: stage1_idx[5];
      stage2_idx[5] <= (stage1_data[4] > stage1_data[5]) ? stage1_idx[5]: stage1_idx[4];
      stage2_idx[6] <= (stage1_data[6] > stage1_data[7]) ? stage1_idx[6]: stage1_idx[7];
      stage2_idx[7] <= (stage1_data[6] > stage1_data[7]) ? stage1_idx[7]: stage1_idx[6];
    end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    stage3_valid <= 1'h0;
    for (int unsigned p = 0; p < 4; p += 1) begin
        stage3_data[2'(p)] <= 25'h0;
        stage3_idx[2'(p)] <= 15'h0;
      end
  end
  else begin
    stage3_valid <= stage2_valid;
    if (stage2_valid) begin
      stage3_data[0] <= (stage2_data[0] < stage2_data[4]) ? stage2_data[0]: stage2_data[4];
      stage3_data[1] <= (stage2_data[1] < stage2_data[5]) ? stage2_data[1]: stage2_data[5];
      stage3_data[2] <= (stage2_data[2] < stage2_data[6]) ? stage2_data[2]: stage2_data[6];
      stage3_data[3] <= (stage2_data[3] < stage2_data[7]) ? stage2_data[3]: stage2_data[7];
      stage3_idx[0] <= (stage2_data[0] < stage2_data[4]) ? stage2_idx[0]: stage2_idx[4];
      stage3_idx[1] <= (stage2_data[1] < stage2_data[5]) ? stage2_idx[1]: stage2_idx[5];
      stage3_idx[2] <= (stage2_data[2] < stage2_data[6]) ? stage2_idx[2]: stage2_idx[6];
      stage3_idx[3] <= (stage2_data[3] < stage2_data[7]) ? stage2_idx[3]: stage2_idx[7];
    end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    stage4_valid <= 1'h0;
    for (int unsigned p = 0; p < 4; p += 1) begin
        stage4_data[2'(p)] <= 25'h0;
        stage4_idx[2'(p)] <= 15'h0;
      end
  end
  else begin
    stage4_valid <= stage3_valid;
    if (stage3_valid) begin
      stage4_data[0] <= (stage3_data[0] < stage3_data[2]) ? stage3_data[0]: stage3_data[2];
      stage4_data[2] <= (stage3_data[0] < stage3_data[2]) ? stage3_data[2]: stage3_data[0];
      stage4_data[1] <= (stage3_data[1] < stage3_data[3]) ? stage3_data[1]: stage3_data[3];
      stage4_data[3] <= (stage3_data[1] < stage3_data[3]) ? stage3_data[3]: stage3_data[1];
      stage4_idx[0] <= (stage3_data[0] < stage3_data[2]) ? stage3_idx[0]: stage3_idx[2];
      stage4_idx[2] <= (stage3_data[0] < stage3_data[2]) ? stage3_idx[2]: stage3_idx[0];
      stage4_idx[1] <= (stage3_data[1] < stage3_data[3]) ? stage3_idx[1]: stage3_idx[3];
      stage4_idx[3] <= (stage3_data[1] < stage3_data[3]) ? stage3_idx[3]: stage3_idx[1];
    end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    stage5_valid <= 1'h0;
    for (int unsigned p = 0; p < 4; p += 1) begin
        stage5_data[2'(p)] <= 25'h0;
        stage5_idx[2'(p)] <= 15'h0;
      end
  end
  else begin
    stage5_valid <= stage4_valid;
    if (stage4_valid) begin
      stage5_data[0] <= (stage4_data[0] < stage4_data[1]) ? stage4_data[0]: stage4_data[1];
      stage5_data[1] <= (stage4_data[0] < stage4_data[1]) ? stage4_data[1]: stage4_data[0];
      stage5_data[2] <= (stage4_data[2] < stage4_data[3]) ? stage4_data[2]: stage4_data[3];
      stage5_data[3] <= (stage4_data[2] < stage4_data[3]) ? stage4_data[3]: stage4_data[2];
      stage5_idx[0] <= (stage4_data[0] < stage4_data[1]) ? stage4_idx[0]: stage4_idx[1];
      stage5_idx[1] <= (stage4_data[0] < stage4_data[1]) ? stage4_idx[1]: stage4_idx[0];
      stage5_idx[2] <= (stage4_data[2] < stage4_data[3]) ? stage4_idx[2]: stage4_idx[3];
      stage5_idx[3] <= (stage4_data[2] < stage4_data[3]) ? stage4_idx[3]: stage4_idx[2];
    end
  end
end
assign valid_out = stage5_valid;
assign data_out_0 = stage5_data[0];
assign idx_out_0 = stage5_idx[0];
assign data_out_1 = stage5_data[1];
assign idx_out_1 = stage5_idx[1];
assign data_out_2 = stage5_data[2];
assign idx_out_2 = stage5_idx[2];
assign data_out_3 = stage5_data[3];
assign idx_out_3 = stage5_idx[3];
endmodule   // BitonicSorter


module SortedList (
  input logic clk,
  input logic insert,
  input logic [24:0] l2_dist_in,
  input logic last_in,
  input logic [14:0] merged_idx_in,
  input logic restart,
  input logic rst_n,
  output logic [24:0] l2_dist_0,
  output logic [24:0] l2_dist_1,
  output logic [24:0] l2_dist_2,
  output logic [24:0] l2_dist_3,
  output logic [14:0] merged_idx_0,
  output logic [14:0] merged_idx_1,
  output logic [14:0] merged_idx_2,
  output logic [14:0] merged_idx_3,
  output logic valid_out
);

logic [3:0] empty_n;
logic [3:0] same_leafidx;
logic [3:0] smaller;

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    valid_out <= 1'h0;
  end
  else valid_out <= last_in;
end
assign smaller[0] = l2_dist_in <= l2_dist_0;
assign same_leafidx[0] = merged_idx_0[14:9] == merged_idx_in[14:9];
assign smaller[1] = l2_dist_in <= l2_dist_1;
assign same_leafidx[1] = merged_idx_1[14:9] == merged_idx_in[14:9];
assign smaller[2] = l2_dist_in <= l2_dist_2;
assign same_leafidx[2] = merged_idx_2[14:9] == merged_idx_in[14:9];
assign smaller[3] = l2_dist_in <= l2_dist_3;
assign same_leafidx[3] = merged_idx_3[14:9] == merged_idx_in[14:9];

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    empty_n <= 4'h0;
    l2_dist_0 <= 25'h0;
    merged_idx_0 <= 15'h0;
    l2_dist_1 <= 25'h0;
    merged_idx_1 <= 15'h0;
    l2_dist_2 <= 25'h0;
    merged_idx_2 <= 15'h0;
    l2_dist_3 <= 25'h0;
    merged_idx_3 <= 15'h0;
  end
  else if (restart) begin
    empty_n <= 4'h0;
    if (insert) begin
      l2_dist_0 <= l2_dist_in;
      merged_idx_0 <= merged_idx_in;
      empty_n[0] <= 1'h1;
    end
  end
  else if (insert) begin
    if (|(same_leafidx & (same_leafidx ^ (~empty_n)))) begin
      if (same_leafidx[0] & smaller[0]) begin
        l2_dist_0 <= l2_dist_in;
      end
      else if (same_leafidx[1] & smaller[1]) begin
        if (smaller[0]) begin
          l2_dist_0 <= l2_dist_in;
          merged_idx_0 <= merged_idx_in;
          l2_dist_1 <= l2_dist_0;
          merged_idx_1 <= merged_idx_0;
        end
        else l2_dist_1 <= l2_dist_in;
      end
      else if (same_leafidx[2] & smaller[2]) begin
        if (smaller[0]) begin
          l2_dist_0 <= l2_dist_in;
          merged_idx_0 <= merged_idx_in;
          l2_dist_1 <= l2_dist_0;
          merged_idx_1 <= merged_idx_0;
          l2_dist_2 <= l2_dist_1;
          merged_idx_2 <= merged_idx_1;
        end
        else if (smaller[1]) begin
          l2_dist_1 <= l2_dist_in;
          merged_idx_1 <= merged_idx_in;
          l2_dist_2 <= l2_dist_1;
          merged_idx_2 <= merged_idx_1;
        end
        else l2_dist_2 <= l2_dist_in;
      end
      else if (same_leafidx[3] & smaller[3]) begin
        if (smaller[0]) begin
          l2_dist_0 <= l2_dist_in;
          merged_idx_0 <= merged_idx_in;
          l2_dist_1 <= l2_dist_0;
          merged_idx_1 <= merged_idx_0;
          l2_dist_2 <= l2_dist_1;
          merged_idx_2 <= merged_idx_1;
          l2_dist_3 <= l2_dist_2;
          merged_idx_3 <= merged_idx_2;
        end
        else if (smaller[1]) begin
          l2_dist_1 <= l2_dist_in;
          merged_idx_1 <= merged_idx_in;
          l2_dist_2 <= l2_dist_1;
          merged_idx_2 <= merged_idx_1;
          l2_dist_3 <= l2_dist_2;
          merged_idx_3 <= merged_idx_2;
        end
        else if (smaller[2]) begin
          l2_dist_2 <= l2_dist_in;
          merged_idx_2 <= merged_idx_in;
          l2_dist_3 <= l2_dist_2;
          merged_idx_3 <= merged_idx_2;
        end
        else l2_dist_3 <= l2_dist_in;
      end
    end
    else begin
      if ((~empty_n[3]) | (smaller[3] & (~same_leafidx[3]))) begin
        l2_dist_3 <= l2_dist_in;
        merged_idx_3 <= merged_idx_in;
        empty_n[3] <= 1'h1;
      end
      if ((~empty_n[2]) | (smaller[2] & (~same_leafidx[2]))) begin
        l2_dist_2 <= l2_dist_in;
        merged_idx_2 <= merged_idx_in;
        empty_n[2] <= 1'h1;
        l2_dist_3 <= l2_dist_2;
        merged_idx_3 <= merged_idx_2;
        empty_n[3] <= empty_n[2];
      end
      if ((~empty_n[1]) | (smaller[1] & (~same_leafidx[1]))) begin
        l2_dist_1 <= l2_dist_in;
        merged_idx_1 <= merged_idx_in;
        empty_n[1] <= 1'h1;
        l2_dist_2 <= l2_dist_1;
        merged_idx_2 <= merged_idx_1;
        empty_n[2] <= empty_n[1];
        l2_dist_3 <= l2_dist_2;
        merged_idx_3 <= merged_idx_2;
        empty_n[3] <= empty_n[2];
      end
      if ((~empty_n[0]) | (smaller[0] & (~same_leafidx[0]))) begin
        l2_dist_0 <= l2_dist_in;
        merged_idx_0 <= merged_idx_in;
        empty_n[0] <= 1'h1;
        l2_dist_1 <= l2_dist_0;
        merged_idx_1 <= merged_idx_0;
        empty_n[1] <= empty_n[0];
        l2_dist_2 <= l2_dist_1;
        merged_idx_2 <= merged_idx_1;
        empty_n[2] <= empty_n[1];
        l2_dist_3 <= l2_dist_2;
        merged_idx_3 <= merged_idx_2;
        empty_n[3] <= empty_n[2];
      end
    end
  end
end
endmodule   // SortedList



module sram_1kbyte_1rw1r#(
  parameter NUM_WMASKS = 4,
  parameter DATA_WIDTH = 32,
  parameter ADDR_WIDTH = 8,
  parameter RAM_DEPTH = 256,
  parameter DELAY = 1
)(
  input  clk0, // clock
  input   csb0, // active low chip select
  input  web0, // active low write control
  input [ADDR_WIDTH-1:0]  addr0,
  input [DATA_WIDTH-1:0]  din0,
  output [DATA_WIDTH-1:0] dout0,
  input  clk1, // clock
  input   csb1, // active low chip select
  input [ADDR_WIDTH-1:0]  addr1,
  output [DATA_WIDTH-1:0] dout1
);

  reg [ADDR_WIDTH-1:0]  addr0_r;
  reg [ADDR_WIDTH-1:0]  addr1_r;
  always @ (posedge clk1) begin
    addr0_r <= addr0;
    addr1_r <= addr1;
  end

  wire [DATA_WIDTH-1:0] dout0_w [RAM_DEPTH/256-1:0];
  wire [DATA_WIDTH-1:0] dout1_w [RAM_DEPTH/256-1:0];
  genvar i, j;
  generate 
    for (i=0; i<RAM_DEPTH/256; i=i+1) begin : loop_depth_gen
      for (j=0; j<DATA_WIDTH/32; j=j+1) begin : loop_width_gen
        if (ADDR_WIDTH == 8) begin
          sky130_sram_1kbyte_1rw1r_32x256_8 #(.DELAY(DELAY)) 
          sram_macro (
            .clk0(clk0),.csb0(csb0),.web0(web0),.wmask0(4'hF),.addr0(addr0[7:0]),.din0(din0[j*32+:32]), .dout0(dout0_w[i][j*32+:32]),
            .clk1(clk1),.csb1(csb1),.addr1(addr1[7:0]),.dout1(dout1_w[i][j*32+:32])
          );
        end
        else begin
          sky130_sram_1kbyte_1rw1r_32x256_8 #(.DELAY(DELAY)) 
          sram_macro (
            .clk0(clk0),.csb0(addr0[ADDR_WIDTH-1:8] == i ? csb0 : 1'b1),.web0(web0),.wmask0(4'hF),.addr0(addr0[7:0]),.din0(din0[j*32+:32]), .dout0(dout0_w[i][j*32+:32]),
            .clk1(clk1),.csb1(addr1[ADDR_WIDTH-1:8] == i ? csb1 : 1'b1),.addr1(addr1[7:0]),.dout1(dout1_w[i][j*32+:32])
          );
        end
      end
    end
    
    if (ADDR_WIDTH == 8)
      assign dout0 = dout0_w[0];
    else 
      assign dout0 = dout0_w[addr0_r[ADDR_WIDTH-1:8]];

    if (ADDR_WIDTH == 8)
      assign dout1 = dout1_w[0];
    else 
      assign dout1 = dout1_w[addr1_r[ADDR_WIDTH-1:8]];
  endgenerate


endmodule
