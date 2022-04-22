module top
#(
    parameter DATA_WIDTH = 11,
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
    logic [DATA_WIDTH-1:0]                                  k0_p0_l2_dist;
    logic [DATA_WIDTH-1:0]                                  k0_p1_l2_dist;
    logic [DATA_WIDTH-1:0]                                  k0_p2_l2_dist;
    logic [DATA_WIDTH-1:0]                                  k0_p3_l2_dist;
    logic [DATA_WIDTH-1:0]                                  k0_p4_l2_dist;
    logic [DATA_WIDTH-1:0]                                  k0_p5_l2_dist;
    logic [DATA_WIDTH-1:0]                                  k0_p6_l2_dist;
    logic [DATA_WIDTH-1:0]                                  k0_p7_l2_dist;
    logic [IDX_WIDTH-1:0]                                   k0_p0_idx_out;
    logic [IDX_WIDTH-1:0]                                   k0_p1_idx_out;
    logic [IDX_WIDTH-1:0]                                   k0_p2_idx_out;
    logic [IDX_WIDTH-1:0]                                   k0_p3_idx_out;
    logic [IDX_WIDTH-1:0]                                   k0_p4_idx_out;
    logic [IDX_WIDTH-1:0]                                   k0_p5_idx_out;
    logic [IDX_WIDTH-1:0]                                   k0_p6_idx_out;
    logic [IDX_WIDTH-1:0]                                   k0_p7_idx_out;

    logic                                                   rm_restart;
    logic                                                   rm_valid_in;
    logic                                                   rm_valid_out;
    logic                                                   rm_query_last_in;
    logic                                                   rm_query_last_out;
    logic [LEAF_ADDRW-1:0]                                  rm_leaf_idx_in;
    logic [DATA_WIDTH-1:0]                                  rm_p0_l2_dist;
    logic [DATA_WIDTH-1:0]                                  rm_p1_l2_dist;
    logic [DATA_WIDTH-1:0]                                  rm_p2_l2_dist;
    logic [DATA_WIDTH-1:0]                                  rm_p3_l2_dist;
    logic [DATA_WIDTH-1:0]                                  rm_p4_l2_dist;
    logic [DATA_WIDTH-1:0]                                  rm_p5_l2_dist;
    logic [DATA_WIDTH-1:0]                                  rm_p6_l2_dist;
    logic [DATA_WIDTH-1:0]                                  rm_p7_l2_dist;
    logic [IDX_WIDTH-1:0]                                   rm_p0_idx;
    logic [IDX_WIDTH-1:0]                                   rm_p1_idx;
    logic [IDX_WIDTH-1:0]                                   rm_p2_idx;
    logic [IDX_WIDTH-1:0]                                   rm_p3_idx;
    logic [IDX_WIDTH-1:0]                                   rm_p4_idx;
    logic [IDX_WIDTH-1:0]                                   rm_p5_idx;
    logic [IDX_WIDTH-1:0]                                   rm_p6_idx;
    logic [IDX_WIDTH-1:0]                                   rm_p7_idx;
    logic [DATA_WIDTH-1:0]                                  rm_p0_l2_dist_min;
    logic [DATA_WIDTH-1:0]                                  rm_p1_l2_dist_min;
    logic [DATA_WIDTH-1:0]                                  rm_p2_l2_dist_min;
    logic [DATA_WIDTH-1:0]                                  rm_p3_l2_dist_min;
    logic [DATA_WIDTH-1:0]                                  rm_p4_l2_dist_min;
    logic [DATA_WIDTH-1:0]                                  rm_p5_l2_dist_min;
    logic [DATA_WIDTH-1:0]                                  rm_p6_l2_dist_min;
    logic [DATA_WIDTH-1:0]                                  rm_p7_l2_dist_min;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0]                        rm_p0_idx_min;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0]                        rm_p1_idx_min;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0]                        rm_p2_idx_min;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0]                        rm_p3_idx_min;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0]                        rm_p4_idx_min;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0]                        rm_p5_idx_min;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0]                        rm_p6_idx_min;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0]                        rm_p7_idx_min;

    logic                                                   s0_valid_in;
    logic                                                   s0_valid_out;
    logic [DATA_WIDTH-1:0]                                  s0_data_in_0;
    logic [DATA_WIDTH-1:0]                                  s0_data_in_1;
    logic [DATA_WIDTH-1:0]                                  s0_data_in_2;
    logic [DATA_WIDTH-1:0]                                  s0_data_in_3;
    logic [DATA_WIDTH-1:0]                                  s0_data_in_4;
    logic [DATA_WIDTH-1:0]                                  s0_data_in_5;
    logic [DATA_WIDTH-1:0]                                  s0_data_in_6;
    logic [DATA_WIDTH-1:0]                                  s0_data_in_7;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0]                        s0_idx_in_0;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0]                        s0_idx_in_1;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0]                        s0_idx_in_2;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0]                        s0_idx_in_3;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0]                        s0_idx_in_4;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0]                        s0_idx_in_5;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0]                        s0_idx_in_6;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0]                        s0_idx_in_7;
    logic [DATA_WIDTH-1:0]                                  s0_data_out_0;
    logic [DATA_WIDTH-1:0]                                  s0_data_out_1;
    logic [DATA_WIDTH-1:0]                                  s0_data_out_2;
    logic [DATA_WIDTH-1:0]                                  s0_data_out_3;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0]                        s0_idx_out_0;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0]                        s0_idx_out_1;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0]                        s0_idx_out_2;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0]                        s0_idx_out_3;


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
        .qp_mem_csb0                            (qp_mem_csb0),
        .qp_mem_web0                            (qp_mem_web0),
        .qp_mem_addr0                           (qp_mem_addr0),
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
        .out_fifo_wenq                          (out_fifo_wenq),
        .out_fifo_wfull_n                       (out_fifo_wfull_n),
        .k0_query_valid                         (k0_query_valid),
        .k0_query_first_in                      (k0_query_first_in),
        .k0_query_last_in                       (k0_query_last_in),
        .k0_query_patch                         (k0_query_patch),
        .s0_valid_out                           (s0_valid_out),
        .best_arr_wleaf_idx_0                   (best_arr_wleaf_idx_0)
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

    // reads only the best
    assign out_fifo_wdata = best_arr_ridx_1[0];


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
        .receiver_en        (int_node_leaf_valid)
    );

    assign int_node_sender_enable = agg_receiver_enq;
    assign int_node_sender_data = agg_receiver_data[2*DATA_WIDTH-1:0];
    assign int_node_patch_in = qp_mem_rpatch1;

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

    assign best_arr_csb0 = ~s0_valid_out;
    assign best_arr_web0 = 1'b0;
    assign best_arr_wdist_0 = { s0_data_out_3,
                                s0_data_out_2,
                                s0_data_out_1,
                                s0_data_out_0 };
    assign best_arr_widx_0 = {  s0_idx_out_3[IDX_WIDTH-1:0],
                                s0_idx_out_2[IDX_WIDTH-1:0],
                                s0_idx_out_1[IDX_WIDTH-1:0],
                                s0_idx_out_0[IDX_WIDTH-1:0] };
    assign best_arr_wleaf_idx_0 = { s0_idx_out_3[LEAF_ADDRW+IDX_WIDTH-1:IDX_WIDTH],
                                    s0_idx_out_2[LEAF_ADDRW+IDX_WIDTH-1:IDX_WIDTH],
                                    s0_idx_out_1[LEAF_ADDRW+IDX_WIDTH-1:IDX_WIDTH],
                                    s0_idx_out_0[LEAF_ADDRW+IDX_WIDTH-1:IDX_WIDTH] };


    // Computes
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

    RunningMin running_min_inst (
        .clk                (clk),
        .rst_n              (rst_n),
        .restart            (rm_restart),
        .valid_in           (rm_valid_in),
        .valid_out          (rm_valid_out),
        .query_last_in      (rm_query_last_in),
        .query_last_out     (rm_query_last_out),
        .leaf_idx_in        (rm_leaf_idx_in),
        .p0_l2_dist         (rm_p0_l2_dist),
        .p1_l2_dist         (rm_p1_l2_dist),
        .p2_l2_dist         (rm_p2_l2_dist),
        .p3_l2_dist         (rm_p3_l2_dist),
        .p4_l2_dist         (rm_p4_l2_dist),
        .p5_l2_dist         (rm_p5_l2_dist),
        .p6_l2_dist         (rm_p6_l2_dist),
        .p7_l2_dist         (rm_p7_l2_dist),
        .p0_idx             (rm_p0_idx),
        .p1_idx             (rm_p1_idx),
        .p2_idx             (rm_p2_idx),
        .p3_idx             (rm_p3_idx),
        .p4_idx             (rm_p4_idx),
        .p5_idx             (rm_p5_idx),
        .p6_idx             (rm_p6_idx),
        .p7_idx             (rm_p7_idx),
        .p0_l2_dist_min     (rm_p0_l2_dist_min),
        .p1_l2_dist_min     (rm_p1_l2_dist_min),
        .p2_l2_dist_min     (rm_p2_l2_dist_min),
        .p3_l2_dist_min     (rm_p3_l2_dist_min),
        .p4_l2_dist_min     (rm_p4_l2_dist_min),
        .p5_l2_dist_min     (rm_p5_l2_dist_min),
        .p6_l2_dist_min     (rm_p6_l2_dist_min),
        .p7_l2_dist_min     (rm_p7_l2_dist_min),
        .p0_idx_min         (rm_p0_idx_min),
        .p1_idx_min         (rm_p1_idx_min),
        .p2_idx_min         (rm_p2_idx_min),
        .p3_idx_min         (rm_p3_idx_min),
        .p4_idx_min         (rm_p4_idx_min),
        .p5_idx_min         (rm_p5_idx_min),
        .p6_idx_min         (rm_p6_idx_min),
        .p7_idx_min         (rm_p7_idx_min)
    );

    assign rm_valid_in      =   k0_dist_valid;
    assign rm_restart       =   k0_query_first_out;
    assign rm_query_last_in =   k0_query_last_out;
    assign rm_leaf_idx_in   =   k0_leaf_idx_out;
    assign rm_p0_l2_dist    =   k0_p0_l2_dist;
    assign rm_p1_l2_dist    =   k0_p1_l2_dist;
    assign rm_p2_l2_dist    =   k0_p2_l2_dist;
    assign rm_p3_l2_dist    =   k0_p3_l2_dist;
    assign rm_p4_l2_dist    =   k0_p4_l2_dist;
    assign rm_p5_l2_dist    =   k0_p5_l2_dist;
    assign rm_p6_l2_dist    =   k0_p6_l2_dist;
    assign rm_p7_l2_dist    =   k0_p7_l2_dist;
    assign rm_p0_idx        =   k0_p0_idx_out;
    assign rm_p1_idx        =   k0_p1_idx_out;
    assign rm_p2_idx        =   k0_p2_idx_out;
    assign rm_p3_idx        =   k0_p3_idx_out;
    assign rm_p4_idx        =   k0_p4_idx_out;
    assign rm_p5_idx        =   k0_p5_idx_out;
    assign rm_p6_idx        =   k0_p6_idx_out;
    assign rm_p7_idx        =   k0_p7_idx_out;


    BitonicSorter sorter0_inst(
        .clk                (clk),
        .rst_n              (rst_n),
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

    assign s0_valid_in      =   rm_query_last_out;
    assign s0_data_in_0     =   rm_p0_l2_dist_min;
    assign s0_data_in_1     =   rm_p1_l2_dist_min;
    assign s0_data_in_2     =   rm_p2_l2_dist_min;
    assign s0_data_in_3     =   rm_p3_l2_dist_min;
    assign s0_data_in_4     =   rm_p4_l2_dist_min;
    assign s0_data_in_5     =   rm_p5_l2_dist_min;
    assign s0_data_in_6     =   rm_p6_l2_dist_min;
    assign s0_data_in_7     =   rm_p7_l2_dist_min;
    assign s0_idx_in_0      =   rm_p0_idx_min;
    assign s0_idx_in_1      =   rm_p1_idx_min;
    assign s0_idx_in_2      =   rm_p2_idx_min;
    assign s0_idx_in_3      =   rm_p3_idx_min;
    assign s0_idx_in_4      =   rm_p4_idx_min;
    assign s0_idx_in_5      =   rm_p5_idx_min;
    assign s0_idx_in_6      =   rm_p6_idx_min;
    assign s0_idx_in_7      =   rm_p7_idx_min;


endmodule