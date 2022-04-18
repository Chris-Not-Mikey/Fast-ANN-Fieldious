module top
#(
    parameter DATA_WIDTH = 11,
    parameter IDX_WIDTH = 9, // index of patch in the original image
    parameter LEAF_SIZE = 8,
    parameter PATCH_SIZE = 5, //excluding the index
    parameter NUM_ROWS = 26,
    parameter NUM_COLS = 19,
    parameter NUM_QUERYS = NUM_ROWS * NUM_COLS,
    parameter K = 4,
    parameter NUM_LEAVES = 64,
    parameter LEAF_ADDRW = $clog2(NUM_LEAVES)
)
(
    input logic clk,
    input logic rst_n,

    input logic                                 load_kdtree,

    // FIFO
    input logic                                 in_fifo_wclk,
    input logic                                 in_fifo_wrst_n,
    input logic                                 in_fifo_wenq,
    input logic [DATA_WIDTH-1:0]                in_fifo_wdata,
    output logic                                in_fifo_wfull_n,


    // testbench use
    input logic fsm_start


);


    logic                                                   in_fifo_deq;
    logic [DATA_WIDTH-1:0]                                  in_fifo_rdata;
    logic                                                   in_fifo_rempty;

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
    logic [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]                 leaf_mem_rleaf_data0 [LEAF_SIZE-1:0];
    logic [IDX_WIDTH-1:0]                                   leaf_mem_rleaf_idx0 [LEAF_SIZE-1:0];
    logic                                                   leaf_mem_csb1;
    logic [LEAF_ADDRW-1:0]                                  leaf_mem_addr1;
    logic [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]                 leaf_mem_rleaf_data1 [LEAF_SIZE-1:0];
    logic [IDX_WIDTH-1:0]                                   leaf_mem_rleaf_idx1 [LEAF_SIZE-1:0];

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
    logic [DATA_WIDTH-1:0]                                  best_arr_wdist_0 [K-1:0];
    logic [IDX_WIDTH-1:0]                                   best_arr_widx_0 [K-1:0];
    logic [DATA_WIDTH-1:0]                                  best_arr_rdist_0 [K-1:0];
    logic [IDX_WIDTH-1:0]                                   best_arr_ridx_0 [K-1:0];
    logic                                                   best_arr_csb1;
    logic [7:0]                                             best_arr_addr1;
    logic [DATA_WIDTH-1:0]                                  best_arr_rdist_1 [K-1:0];
    logic [IDX_WIDTH-1:0]                                   best_arr_ridx_1 [K-1:0];

    logic                                                   k0_query_first_in;
    logic                                                   k0_query_first_out;
    logic                                                   k0_query_last_in;
    logic                                                   k0_query_last_out;
    logic                                                   k0_query_valid;
    logic signed [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]          k0_query_patch;
    logic                                                   k0_dist_valid;
    logic signed [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]          k0_p0_leaf_data;
    logic signed [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]          k0_p1_leaf_data;
    logic signed [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]          k0_p2_leaf_data;
    logic signed [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]          k0_p3_leaf_data;
    logic signed [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]          k0_p4_leaf_data;
    logic signed [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]          k0_p5_leaf_data;
    logic signed [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]          k0_p6_leaf_data;
    logic signed [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]          k0_p7_leaf_data;
    logic [IDX_WIDTH-1:0]                                   k0_p0_leaf_idx;
    logic [IDX_WIDTH-1:0]                                   k0_p1_leaf_idx;
    logic [IDX_WIDTH-1:0]                                   k0_p2_leaf_idx;
    logic [IDX_WIDTH-1:0]                                   k0_p3_leaf_idx;
    logic [IDX_WIDTH-1:0]                                   k0_p4_leaf_idx;
    logic [IDX_WIDTH-1:0]                                   k0_p5_leaf_idx;
    logic [IDX_WIDTH-1:0]                                   k0_p6_leaf_idx;
    logic [IDX_WIDTH-1:0]                                   k0_p7_leaf_idx;
    logic [DATA_WIDTH-1:0]                                  k0_p0_l2_dist;
    logic [DATA_WIDTH-1:0]                                  k0_p1_l2_dist;
    logic [DATA_WIDTH-1:0]                                  k0_p2_l2_dist;
    logic [DATA_WIDTH-1:0]                                  k0_p3_l2_dist;
    logic [DATA_WIDTH-1:0]                                  k0_p4_l2_dist;
    logic [DATA_WIDTH-1:0]                                  k0_p5_l2_dist;
    logic [DATA_WIDTH-1:0]                                  k0_p6_l2_dist;
    logic [DATA_WIDTH-1:0]                                  k0_p7_l2_dist;
    logic [IDX_WIDTH-1:0]                                   k0_p0_idx;
    logic [IDX_WIDTH-1:0]                                   k0_p1_idx;
    logic [IDX_WIDTH-1:0]                                   k0_p2_idx;
    logic [IDX_WIDTH-1:0]                                   k0_p3_idx;
    logic [IDX_WIDTH-1:0]                                   k0_p4_idx;
    logic [IDX_WIDTH-1:0]                                   k0_p5_idx;
    logic [IDX_WIDTH-1:0]                                   k0_p6_idx;
    logic [IDX_WIDTH-1:0]                                   k0_p7_idx;

    logic                                                   rm_restart;
    logic                                                   rm_valid_in;
    logic                                                   rm_valid_out;
    logic                                                   rm_query_last_in;
    logic                                                   rm_query_last_out;
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
    logic [IDX_WIDTH-1:0]                                   rm_p0_idx_min;
    logic [IDX_WIDTH-1:0]                                   rm_p1_idx_min;
    logic [IDX_WIDTH-1:0]                                   rm_p2_idx_min;
    logic [IDX_WIDTH-1:0]                                   rm_p3_idx_min;
    logic [IDX_WIDTH-1:0]                                   rm_p4_idx_min;
    logic [IDX_WIDTH-1:0]                                   rm_p5_idx_min;
    logic [IDX_WIDTH-1:0]                                   rm_p6_idx_min;
    logic [IDX_WIDTH-1:0]                                   rm_p7_idx_min;

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
    logic [IDX_WIDTH-1:0]                                   s0_idx_in_0;
    logic [IDX_WIDTH-1:0]                                   s0_idx_in_1;
    logic [IDX_WIDTH-1:0]                                   s0_idx_in_2;
    logic [IDX_WIDTH-1:0]                                   s0_idx_in_3;
    logic [IDX_WIDTH-1:0]                                   s0_idx_in_4;
    logic [IDX_WIDTH-1:0]                                   s0_idx_in_5;
    logic [IDX_WIDTH-1:0]                                   s0_idx_in_6;
    logic [IDX_WIDTH-1:0]                                   s0_idx_in_7;
    logic [DATA_WIDTH-1:0]                                  s0_data_out_0;
    logic [DATA_WIDTH-1:0]                                  s0_data_out_1;
    logic [DATA_WIDTH-1:0]                                  s0_data_out_2;
    logic [DATA_WIDTH-1:0]                                  s0_data_out_3;
    logic [IDX_WIDTH-1:0]                                   s0_idx_out_0;
    logic [IDX_WIDTH-1:0]                                   s0_idx_out_1;
    logic [IDX_WIDTH-1:0]                                   s0_idx_out_2;
    logic [IDX_WIDTH-1:0]                                   s0_idx_out_3;


    MainFSM #(
        .DATA_WIDTH                             (DATA_WIDTH),
        .LEAF_SIZE                              (LEAF_SIZE),
        .PATCH_SIZE                             (PATCH_SIZE),
        .NUM_ROWS                               (NUM_ROWS),
        .NUM_COLS                               (NUM_COLS),
        .K                                      (K),
        .NUM_LEAVES                             (NUM_LEAVES)
    ) main_fsm_inst (
        .clk                                    (clk),
        .rst_n                                  (rst_n),
        .load_kdtree                            (load_kdtree),
        .agg_receiver_enq                       (agg_receiver_enq),
        .agg_receiver_full_n                    (agg_receiver_full_n),
        .agg_change_fetch_width                 (agg_change_fetch_width),
        .agg_input_fetch_width                  (agg_input_fetch_width),
        .int_node_fsm_enable                    (int_node_fsm_enable),
        .fsm_start                              (fsm_start),
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
        .best_arr_ridx_1                        (best_arr_ridx_1),
        .k0_query_valid                         (k0_query_valid),
        .k0_query_first_in                      (k0_query_first_in),
        .k0_query_last_in                       (k0_query_last_in),
        .k0_query_patch                         (k0_query_patch),
        .s0_valid_out                           (s0_valid_out)
    );


    // I/O FIFO and Aggregator
    SyncFIFO #(
        .dataWidth          (DATA_WIDTH),
        .depth              (16),
        .indxWidth          (4)
    ) input_fifo_inst (
        .sCLK               (in_fifo_wclk),
        .sRST               (in_fifo_wrst_n),
        .sENQ               (in_fifo_wenq),
        .sD_IN              (in_fifo_wdata),
        .sFULL_N            (in_fifo_wfull_n),
        .dCLK               (clk),
        .dDEQ               (in_fifo_deq),
        .dD_OUT             (in_fifo_rdata),
        .dEMPTY_N           (in_fifo_rempty)
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
    assign agg_sender_empty_n = in_fifo_rempty;


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
        .rleaf_data0        (leaf_mem_rleaf_data0),
        .rleaf_idx0         (leaf_mem_rleaf_idx0),
        .csb1               (leaf_mem_csb1),
        .addr1              (leaf_mem_addr1),
        .rleaf_data1        (leaf_mem_rleaf_data1),
        .rleaf_idx1         (leaf_mem_rleaf_idx1)
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
        .K                  (K)
    ) k_best_array_inst (
        .clk                (clk),
        .csb0               (best_arr_csb0),
        .web0               (best_arr_web0),
        .addr0              (best_arr_addr0),
        .wdist_0            (best_arr_wdist_0),
        .widx_0             (best_arr_widx_0),
        .rdist_0            (best_arr_rdist_0),
        .ridx_0             (best_arr_ridx_0),
        .csb1               (best_arr_csb1),
        .addr1              (best_arr_addr1),
        .rdist_1            (best_arr_rdist_1),
        .ridx_1             (best_arr_ridx_1)
    );

    assign best_arr_csb0 = ~s0_valid_out;
    assign best_arr_web0 = 1'b0;
    assign best_arr_wdist_0 = { s0_data_out_0,
                                s0_data_out_1,
                                s0_data_out_2,
                                s0_data_out_3 };
    assign best_arr_widx_0 = {  s0_idx_out_0,
                                s0_idx_out_1,
                                s0_idx_out_2,
                                s0_idx_out_3 };


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
        .p0_leaf_data       (k0_p0_leaf_data),
        .p1_leaf_data       (k0_p1_leaf_data),
        .p2_leaf_data       (k0_p2_leaf_data),
        .p3_leaf_data       (k0_p3_leaf_data),
        .p4_leaf_data       (k0_p4_leaf_data),
        .p5_leaf_data       (k0_p5_leaf_data),
        .p6_leaf_data       (k0_p6_leaf_data),
        .p7_leaf_data       (k0_p7_leaf_data),
        .p0_leaf_idx        (k0_p0_leaf_idx),
        .p1_leaf_idx        (k0_p1_leaf_idx),
        .p2_leaf_idx        (k0_p2_leaf_idx),
        .p3_leaf_idx        (k0_p3_leaf_idx),
        .p4_leaf_idx        (k0_p4_leaf_idx),
        .p5_leaf_idx        (k0_p5_leaf_idx),
        .p6_leaf_idx        (k0_p6_leaf_idx),
        .p7_leaf_idx        (k0_p7_leaf_idx),
        .p0_l2_dist         (k0_p0_l2_dist),
        .p1_l2_dist         (k0_p1_l2_dist),
        .p2_l2_dist         (k0_p2_l2_dist),
        .p3_l2_dist         (k0_p3_l2_dist),
        .p4_l2_dist         (k0_p4_l2_dist),
        .p5_l2_dist         (k0_p5_l2_dist),
        .p6_l2_dist         (k0_p6_l2_dist),
        .p7_l2_dist         (k0_p7_l2_dist),
        .p0_idx             (k0_p0_idx),
        .p1_idx             (k0_p1_idx),
        .p2_idx             (k0_p2_idx),
        .p3_idx             (k0_p3_idx),
        .p4_idx             (k0_p4_idx),
        .p5_idx             (k0_p5_idx),
        .p6_idx             (k0_p6_idx),
        .p7_idx             (k0_p7_idx)
    );

    assign k0_p0_leaf_data = leaf_mem_rleaf_data0[0];
    assign k0_p1_leaf_data = leaf_mem_rleaf_data0[1];
    assign k0_p2_leaf_data = leaf_mem_rleaf_data0[2];
    assign k0_p3_leaf_data = leaf_mem_rleaf_data0[3];
    assign k0_p4_leaf_data = leaf_mem_rleaf_data0[4];
    assign k0_p5_leaf_data = leaf_mem_rleaf_data0[5];
    assign k0_p6_leaf_data = leaf_mem_rleaf_data0[6];
    assign k0_p7_leaf_data = leaf_mem_rleaf_data0[7];
    assign k0_p0_leaf_idx = leaf_mem_rleaf_idx0[0];
    assign k0_p1_leaf_idx = leaf_mem_rleaf_idx0[1];
    assign k0_p2_leaf_idx = leaf_mem_rleaf_idx0[2];
    assign k0_p3_leaf_idx = leaf_mem_rleaf_idx0[3];
    assign k0_p4_leaf_idx = leaf_mem_rleaf_idx0[4];
    assign k0_p5_leaf_idx = leaf_mem_rleaf_idx0[5];
    assign k0_p6_leaf_idx = leaf_mem_rleaf_idx0[6];
    assign k0_p7_leaf_idx = leaf_mem_rleaf_idx0[7];

    RunningMin running_min_inst (
        .clk                (clk),
        .rst_n              (rst_n),
        .restart            (rm_restart),
        .valid_in           (rm_valid_in),
        .valid_out          (rm_valid_out),
        .query_last_in      (rm_query_last_in),
        .query_last_out     (rm_query_last_out),
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
    assign rm_p0_l2_dist    =   k0_p0_l2_dist;
    assign rm_p1_l2_dist    =   k0_p1_l2_dist;
    assign rm_p2_l2_dist    =   k0_p2_l2_dist;
    assign rm_p3_l2_dist    =   k0_p3_l2_dist;
    assign rm_p4_l2_dist    =   k0_p4_l2_dist;
    assign rm_p5_l2_dist    =   k0_p5_l2_dist;
    assign rm_p6_l2_dist    =   k0_p6_l2_dist;
    assign rm_p7_l2_dist    =   k0_p7_l2_dist;
    assign rm_p0_idx        =   k0_p0_idx;
    assign rm_p1_idx        =   k0_p1_idx;
    assign rm_p2_idx        =   k0_p2_idx;
    assign rm_p3_idx        =   k0_p3_idx;
    assign rm_p4_idx        =   k0_p4_idx;
    assign rm_p5_idx        =   k0_p5_idx;
    assign rm_p6_idx        =   k0_p6_idx;
    assign rm_p7_idx        =   k0_p7_idx;


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