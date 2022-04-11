`timescale 1 ns / 1 ps
module L2Kernel_tb();
    localparam  DATA_WIDTH = 11;
    logic clk;
    logic [5:0] leaf_idx;
    logic signed [4:0] [DATA_WIDTH-1:0] p0_candidate_leaf;
    logic signed [4:0] [DATA_WIDTH-1:0] p1_candidate_leaf;
    logic signed [4:0] [DATA_WIDTH-1:0] p2_candidate_leaf;
    logic signed [4:0] [DATA_WIDTH-1:0] p3_candidate_leaf;
    logic signed [4:0] [DATA_WIDTH-1:0] p4_candidate_leaf;
    logic signed [4:0] [DATA_WIDTH-1:0] p5_candidate_leaf;
    logic signed [4:0] [DATA_WIDTH-1:0] p6_candidate_leaf;
    logic signed [4:0] [DATA_WIDTH-1:0] p7_candidate_leaf;
    logic signed [4:0] [DATA_WIDTH-1:0] query_patch;
    logic query_valid;
    logic rst_n;
    logic dist_valid;
    logic [8:0] p0_indices;
    logic [DATA_WIDTH-1:0] p0_l2_dist;
    logic [8:0] p1_indices;
    logic [DATA_WIDTH-1:0] p1_l2_dist;
    logic [8:0] p2_indices;
    logic [DATA_WIDTH-1:0] p2_l2_dist;
    logic [8:0] p3_indices;
    logic [DATA_WIDTH-1:0] p3_l2_dist;
    logic [8:0] p4_indices;
    logic [DATA_WIDTH-1:0] p4_l2_dist;
    logic [8:0] p5_indices;
    logic [DATA_WIDTH-1:0] p5_l2_dist;
    logic [8:0] p6_indices;
    logic [DATA_WIDTH-1:0] p6_l2_dist;
    logic [8:0] p7_indices;
    logic [DATA_WIDTH-1:0] p7_l2_dist;

    L2Kernel dut(
        .clk(clk),
        .rst_n(rst_n),
        .leaf_idx(leaf_idx),
        .p0_candidate_leaf(p0_candidate_leaf),
        .p1_candidate_leaf(p1_candidate_leaf),
        .p2_candidate_leaf(p2_candidate_leaf),
        .p3_candidate_leaf(p3_candidate_leaf),
        .p4_candidate_leaf(p4_candidate_leaf),
        .p5_candidate_leaf(p5_candidate_leaf),
        .p6_candidate_leaf(p6_candidate_leaf),
        .p7_candidate_leaf(p7_candidate_leaf),
        .query_patch(query_patch),
        .query_valid(query_valid),
        .dist_valid(dist_valid),
        .p0_indices(p0_indices),
        .p1_indices(p1_indices),
        .p2_indices(p2_indices),
        .p3_indices(p3_indices),
        .p4_indices(p4_indices),
        .p5_indices(p5_indices),
        .p6_indices(p6_indices),
        .p7_indices(p7_indices),
        .p0_l2_dist(p0_l2_dist),
        .p1_l2_dist(p1_l2_dist),
        .p2_l2_dist(p2_l2_dist),
        .p3_l2_dist(p3_l2_dist),
        .p4_l2_dist(p4_l2_dist),
        .p5_l2_dist(p5_l2_dist),
        .p6_l2_dist(p6_l2_dist),
        .p7_l2_dist(p7_l2_dist)
    );

    initial begin 
        clk = 0;
        forever begin
            #10 clk = ~clk;
        end 
    end

    initial begin
        rst_n = 0;
        p0_candidate_leaf = '0;
        p1_candidate_leaf = '0;
        p2_candidate_leaf = '0;
        p3_candidate_leaf = '0;
        p4_candidate_leaf = '0;
        p5_candidate_leaf = '0;
        p6_candidate_leaf = '0;
        p7_candidate_leaf = '0;
        query_patch = '0;
        query_valid = 1'b0;
        leaf_idx = '0;
        #20 rst_n = 1;
        #20;

        @(negedge clk);
        leaf_idx = 2;
        query_valid = 1'b1;
        query_patch = {11'd0, -11'd20, 11'd0, 11'd20, 11'd0};
        p0_candidate_leaf = {11'd20, 11'd0, -11'd20, 11'd0, 11'd20};

        @(negedge clk);
        leaf_idx = '0;
        query_valid = 1'b0;
        query_patch = '0;
        p0_candidate_leaf = '0;
        
        wait(query_valid == 1'b1);
        //$display("p0_candidate_leaf is %d", p0_candidate_leaf);
        wait(query_valid == 1'b0);
        #20;
        $finish;

    end

endmodule