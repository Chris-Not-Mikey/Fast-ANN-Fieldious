module top
#(
    parameter DATA_WIDTH = 11,
    parameter LEAF_SIZE = 8,
    parameter PATCH_SIZE = 5,
    parameter NUM_LEAVES = 64,
    parameter ADDR_WIDTH = $clog2(NUM_LEAVES)
)
(
    input logic clk,
    input logic rst_n,

    // testbench use
    input logic fsm_start


);


    logic                                       leaf_mem_wen;
    logic [ADDR_WIDTH-1:0]                      leaf_mem_wadr;
    logic [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]     leaf_mem_wdata [LEAF_SIZE-1:0];
    logic                                       leaf_mem_ren;
    logic [ADDR_WIDTH-1:0]                      leaf_mem_radr;
    logic [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]     leaf_mem_rdata [LEAF_SIZE-1:0];

    logic [5:0]                                 k0_leaf_idx;
    logic                                       k0_query_valid;
    logic signed [4:0] [DATA_WIDTH-1:0]         k0_query_patch;
    logic                                       k0_dist_valid;
    logic signed [4:0] [DATA_WIDTH-1:0]         k0_p0_candidate_leaf;
    logic signed [4:0] [DATA_WIDTH-1:0]         k0_p1_candidate_leaf;
    logic signed [4:0] [DATA_WIDTH-1:0]         k0_p2_candidate_leaf;
    logic signed [4:0] [DATA_WIDTH-1:0]         k0_p3_candidate_leaf;
    logic signed [4:0] [DATA_WIDTH-1:0]         k0_p4_candidate_leaf;
    logic signed [4:0] [DATA_WIDTH-1:0]         k0_p5_candidate_leaf;
    logic signed [4:0] [DATA_WIDTH-1:0]         k0_p6_candidate_leaf;
    logic signed [4:0] [DATA_WIDTH-1:0]         k0_p7_candidate_leaf;
    logic [8:0]                                 k0_p0_indices;
    logic [DATA_WIDTH-1:0]                      k0_p0_l2_dist;
    logic [8:0]                                 k0_p1_indices;
    logic [DATA_WIDTH-1:0]                      k0_p1_l2_dist;
    logic [8:0]                                 k0_p2_indices;
    logic [DATA_WIDTH-1:0]                      k0_p2_l2_dist;
    logic [8:0]                                 k0_p3_indices;
    logic [DATA_WIDTH-1:0]                      k0_p3_l2_dist;
    logic [8:0]                                 k0_p4_indices;
    logic [DATA_WIDTH-1:0]                      k0_p4_l2_dist;
    logic [8:0]                                 k0_p5_indices;
    logic [DATA_WIDTH-1:0]                      k0_p5_l2_dist;
    logic [8:0]                                 k0_p6_indices;
    logic [DATA_WIDTH-1:0]                      k0_p6_l2_dist;
    logic [8:0]                                 k0_p7_indices;
    logic [DATA_WIDTH-1:0]                      k0_p7_l2_dist;
    
    logic                                       rm_restart;
    logic                                       rm_valid_in;
    logic                                       rm_valid_out;
    logic [8:0]                                 rm_p0_indices;
    logic [DATA_WIDTH-1:0]                      rm_p0_l2_dist;
    logic [8:0]                                 rm_p1_indices;
    logic [DATA_WIDTH-1:0]                      rm_p1_l2_dist;
    logic [8:0]                                 rm_p2_indices;
    logic [DATA_WIDTH-1:0]                      rm_p2_l2_dist;
    logic [8:0]                                 rm_p3_indices;
    logic [DATA_WIDTH-1:0]                      rm_p3_l2_dist;
    logic [8:0]                                 rm_p4_indices;
    logic [DATA_WIDTH-1:0]                      rm_p4_l2_dist;
    logic [8:0]                                 rm_p5_indices;
    logic [DATA_WIDTH-1:0]                      rm_p5_l2_dist;
    logic [8:0]                                 rm_p6_indices;
    logic [DATA_WIDTH-1:0]                      rm_p6_l2_dist;
    logic [8:0]                                 rm_p7_indices;
    logic [DATA_WIDTH-1:0]                      rm_p7_l2_dist;
    logic [8:0]                                 rm_p0_indices_min;
    logic [DATA_WIDTH-1:0]                      rm_p0_l2_dist_min;
    logic [8:0]                                 rm_p1_indices_min;
    logic [DATA_WIDTH-1:0]                      rm_p1_l2_dist_min;
    logic [8:0]                                 rm_p2_indices_min;
    logic [DATA_WIDTH-1:0]                      rm_p2_l2_dist_min;
    logic [8:0]                                 rm_p3_indices_min;
    logic [DATA_WIDTH-1:0]                      rm_p3_l2_dist_min;
    logic [8:0]                                 rm_p4_indices_min;
    logic [DATA_WIDTH-1:0]                      rm_p4_l2_dist_min;
    logic [8:0]                                 rm_p5_indices_min;
    logic [DATA_WIDTH-1:0]                      rm_p5_l2_dist_min;
    logic [8:0]                                 rm_p6_indices_min;
    logic [DATA_WIDTH-1:0]                      rm_p6_l2_dist_min;
    logic [8:0]                                 rm_p7_indices_min;
    logic [DATA_WIDTH-1:0]                      rm_p7_l2_dist_min;

    logic                                       s0_valid_in;
    logic                                       s0_valid_out;
    logic [10:0]                                s0_data_in_0;
    logic [10:0]                                s0_data_in_1;
    logic [10:0]                                s0_data_in_2;
    logic [10:0]                                s0_data_in_3;
    logic [10:0]                                s0_data_in_4;
    logic [10:0]                                s0_data_in_5;
    logic [10:0]                                s0_data_in_6;
    logic [10:0]                                s0_data_in_7;
    logic [8:0]                                 s0_indices_in_0;
    logic [8:0]                                 s0_indices_in_1;
    logic [8:0]                                 s0_indices_in_2;
    logic [8:0]                                 s0_indices_in_3;
    logic [8:0]                                 s0_indices_in_4;
    logic [8:0]                                 s0_indices_in_5;
    logic [8:0]                                 s0_indices_in_6;
    logic [8:0]                                 s0_indices_in_7;
    logic [10:0]                                s0_data_out_0;
    logic [10:0]                                s0_data_out_1;
    logic [10:0]                                s0_data_out_2;
    logic [10:0]                                s0_data_out_3;
    logic [8:0]                                 s0_indices_out_0;
    logic [8:0]                                 s0_indices_out_1;
    logic [8:0]                                 s0_indices_out_2;
    logic [8:0]                                 s0_indices_out_3;


    MainFSM #(
        .DATA_WIDTH         (DATA_WIDTH),
        .LEAF_SIZE          (LEAF_SIZE),
        .PATCH_SIZE         (PATCH_SIZE),
        .NUM_LEAVES         (NUM_LEAVES)
    ) main_fsm_inst (
        .clk                (clk),
        .rst_n              (rst_n),
        .fsm_start          (fsm_start),
        .leaf_mem_wen       (leaf_mem_wen),
        .leaf_mem_wadr      (leaf_mem_wadr),
        .leaf_mem_wdata     (leaf_mem_wdata),
        .leaf_mem_ren       (leaf_mem_ren),
        .leaf_mem_radr      (leaf_mem_radr),
        .k0_query_valid     (k0_query_valid),
        .rm_restart         (rm_restart),
        .s0_valid_in        (s0_valid_in),
        .s0_valid_out       (s0_valid_out)
    );

    LeavesMem #(
        .DATA_WIDTH         (DATA_WIDTH),
        .LEAF_SIZE          (LEAF_SIZE),
        .PATCH_SIZE         (PATCH_SIZE),
        .NUM_LEAVES         (NUM_LEAVES)
    ) leaf_mem_inst (
        .clk                (clk),
        .wen                (leaf_mem_wen),
        .wadr               (leaf_mem_wadr),
        .wdata              (leaf_mem_wdata),
        .ren                (leaf_mem_ren),
        .radr               (leaf_mem_radr),
        .rdata              (leaf_mem_rdata)
    );

    L2Kernel l2_k0_inst (
        .clk                (clk),
        .rst_n              (rst_n),
        .leaf_idx           (k0_leaf_idx),
        .query_valid        (k0_query_valid),
        .query_patch        (k0_query_patch),
        .dist_valid         (k0_dist_valid),
        .p0_candidate_leaf  (k0_p0_candidate_leaf),
        .p1_candidate_leaf  (k0_p1_candidate_leaf),
        .p2_candidate_leaf  (k0_p2_candidate_leaf),
        .p3_candidate_leaf  (k0_p3_candidate_leaf),
        .p4_candidate_leaf  (k0_p4_candidate_leaf),
        .p5_candidate_leaf  (k0_p5_candidate_leaf),
        .p6_candidate_leaf  (k0_p6_candidate_leaf),
        .p7_candidate_leaf  (k0_p7_candidate_leaf),
        .p0_l2_dist         (k0_p0_l2_dist),
        .p1_l2_dist         (k0_p1_l2_dist),
        .p2_l2_dist         (k0_p2_l2_dist),
        .p3_l2_dist         (k0_p3_l2_dist),
        .p4_l2_dist         (k0_p4_l2_dist),
        .p5_l2_dist         (k0_p5_l2_dist),
        .p6_l2_dist         (k0_p6_l2_dist),
        .p7_l2_dist         (k0_p7_l2_dist),
        .p0_indices         (k0_p0_indices),
        .p1_indices         (k0_p1_indices),
        .p2_indices         (k0_p2_indices),
        .p3_indices         (k0_p3_indices),
        .p4_indices         (k0_p4_indices),
        .p5_indices         (k0_p5_indices),
        .p6_indices         (k0_p6_indices),
        .p7_indices         (k0_p7_indices)
    );

    assign k0_query_patch = '0;
    assign k0_p0_candidate_leaf = leaf_mem_rdata[0];
    assign k0_p1_candidate_leaf = leaf_mem_rdata[1];
    assign k0_p2_candidate_leaf = leaf_mem_rdata[2];
    assign k0_p3_candidate_leaf = leaf_mem_rdata[3];
    assign k0_p4_candidate_leaf = leaf_mem_rdata[4];
    assign k0_p5_candidate_leaf = leaf_mem_rdata[5];
    assign k0_p6_candidate_leaf = leaf_mem_rdata[6];
    assign k0_p7_candidate_leaf = leaf_mem_rdata[7];

    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n) k0_leaf_idx <= '0;
        else if (leaf_mem_ren) begin
            k0_leaf_idx <= leaf_mem_radr;
        end
    end


    RunningMin running_min_inst (
        .clk                (clk),
        .rst_n              (rst_n),
        .restart            (rm_restart),
        .valid_in           (rm_valid_in),
        .valid_out          (rm_valid_out),
        .p0_l2_dist         (rm_p0_l2_dist),
        .p1_l2_dist         (rm_p1_l2_dist),
        .p2_l2_dist         (rm_p2_l2_dist),
        .p3_l2_dist         (rm_p3_l2_dist),
        .p4_l2_dist         (rm_p4_l2_dist),
        .p5_l2_dist         (rm_p5_l2_dist),
        .p6_l2_dist         (rm_p6_l2_dist),
        .p7_l2_dist         (rm_p7_l2_dist),
        .p0_indices         (rm_p0_indices),
        .p1_indices         (rm_p1_indices),
        .p2_indices         (rm_p2_indices),
        .p3_indices         (rm_p3_indices),
        .p4_indices         (rm_p4_indices),
        .p5_indices         (rm_p5_indices),
        .p6_indices         (rm_p6_indices),
        .p7_indices         (rm_p7_indices),
        .p0_l2_dist_min     (rm_p0_l2_dist_min),
        .p1_l2_dist_min     (rm_p1_l2_dist_min),
        .p2_l2_dist_min     (rm_p2_l2_dist_min),
        .p3_l2_dist_min     (rm_p3_l2_dist_min),
        .p4_l2_dist_min     (rm_p4_l2_dist_min),
        .p5_l2_dist_min     (rm_p5_l2_dist_min),
        .p6_l2_dist_min     (rm_p6_l2_dist_min),
        .p7_l2_dist_min     (rm_p7_l2_dist_min),
        .p0_indices_min     (rm_p0_indices_min),
        .p1_indices_min     (rm_p1_indices_min),
        .p2_indices_min     (rm_p2_indices_min),
        .p3_indices_min     (rm_p3_indices_min),
        .p4_indices_min     (rm_p4_indices_min),
        .p5_indices_min     (rm_p5_indices_min),
        .p6_indices_min     (rm_p6_indices_min),
        .p7_indices_min     (rm_p7_indices_min)
    );

    assign rm_valid_in   = k0_dist_valid;
    assign rm_p0_l2_dist = k0_p0_l2_dist;
    assign rm_p1_l2_dist = k0_p1_l2_dist;
    assign rm_p2_l2_dist = k0_p2_l2_dist;
    assign rm_p3_l2_dist = k0_p3_l2_dist;
    assign rm_p4_l2_dist = k0_p4_l2_dist;
    assign rm_p5_l2_dist = k0_p5_l2_dist;
    assign rm_p6_l2_dist = k0_p6_l2_dist;
    assign rm_p7_l2_dist = k0_p7_l2_dist;
    assign rm_p0_indices = k0_p0_indices;
    assign rm_p1_indices = k0_p1_indices;
    assign rm_p2_indices = k0_p2_indices;
    assign rm_p3_indices = k0_p3_indices;
    assign rm_p4_indices = k0_p4_indices;
    assign rm_p5_indices = k0_p5_indices;
    assign rm_p6_indices = k0_p6_indices;
    assign rm_p7_indices = k0_p7_indices;


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
        .indices_in_0       (s0_indices_in_0),
        .indices_in_1       (s0_indices_in_1),
        .indices_in_2       (s0_indices_in_2),
        .indices_in_3       (s0_indices_in_3),
        .indices_in_4       (s0_indices_in_4),
        .indices_in_5       (s0_indices_in_5),
        .indices_in_6       (s0_indices_in_6),
        .indices_in_7       (s0_indices_in_7),
        .data_out_0         (s0_data_out_0),
        .data_out_1         (s0_data_out_1),
        .data_out_2         (s0_data_out_2),
        .data_out_3         (s0_data_out_3),
        .indices_out_0      (s0_indices_out_0),
        .indices_out_1      (s0_indices_out_1),
        .indices_out_2      (s0_indices_out_2),
        .indices_out_3      (s0_indices_out_3)
    );

    assign s0_data_in_0     =   rm_p0_l2_dist_min;
    assign s0_data_in_1     =   rm_p1_l2_dist_min;
    assign s0_data_in_2     =   rm_p2_l2_dist_min;
    assign s0_data_in_3     =   rm_p3_l2_dist_min;
    assign s0_data_in_4     =   rm_p4_l2_dist_min;
    assign s0_data_in_5     =   rm_p5_l2_dist_min;
    assign s0_data_in_6     =   rm_p6_l2_dist_min;
    assign s0_data_in_7     =   rm_p7_l2_dist_min;
    assign s0_indices_in_0  =   rm_p0_indices_min;
    assign s0_indices_in_1  =   rm_p1_indices_min;
    assign s0_indices_in_2  =   rm_p2_indices_min;
    assign s0_indices_in_3  =   rm_p3_indices_min;
    assign s0_indices_in_4  =   rm_p4_indices_min;
    assign s0_indices_in_5  =   rm_p5_indices_min;
    assign s0_indices_in_6  =   rm_p6_indices_min;
    assign s0_indices_in_7  =   rm_p7_indices_min;


endmodule