`timescale 1 ns / 1 ps
module L2Kernel_tb();
    parameter DATA_WIDTH = 11;
    parameter DIST_WIDTH = 25; // maximum 25
    parameter IDX_WIDTH = 9; // index of patch in the original image
    parameter LEAF_SIZE = 8;
    parameter PATCH_SIZE = 5; //excluding the index
    parameter ROW_SIZE = 26;
    parameter COL_SIZE = 19;
    parameter NUM_QUERYS = ROW_SIZE * COL_SIZE;
    parameter K = 4;
    parameter NUM_LEAVES = 64;
    parameter BLOCKING = 4;
    parameter LEAF_ADDRW = $clog2(NUM_LEAVES);


    logic clk;
    logic rst_n;
    logic                                                       query_first_in;
    logic                                                       query_first_out;
    logic                                                       query_last_in;
    logic                                                       query_last_out;
    logic                                                       query_valid;
    logic signed [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]              query_patch;
    logic                                                       dist_valid;
    logic [LEAF_ADDRW-1:0]                                      leaf_idx_in;
    logic [LEAF_ADDRW-1:0]                                      leaf_idx_out;
    logic signed [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]              p0_data;
    logic signed [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]              p1_data;
    logic signed [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]              p2_data;
    logic signed [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]              p3_data;
    logic signed [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]              p4_data;
    logic signed [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]              p5_data;
    logic signed [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]              p6_data;
    logic signed [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]              p7_data;
    logic [IDX_WIDTH-1:0]                                       p0_idx_in;
    logic [IDX_WIDTH-1:0]                                       p1_idx_in;
    logic [IDX_WIDTH-1:0]                                       p2_idx_in;
    logic [IDX_WIDTH-1:0]                                       p3_idx_in;
    logic [IDX_WIDTH-1:0]                                       p4_idx_in;
    logic [IDX_WIDTH-1:0]                                       p5_idx_in;
    logic [IDX_WIDTH-1:0]                                       p6_idx_in;
    logic [IDX_WIDTH-1:0]                                       p7_idx_in;
    logic [DIST_WIDTH-1:0]                                      p0_l2_dist;
    logic [DIST_WIDTH-1:0]                                      p1_l2_dist;
    logic [DIST_WIDTH-1:0]                                      p2_l2_dist;
    logic [DIST_WIDTH-1:0]                                      p3_l2_dist;
    logic [DIST_WIDTH-1:0]                                      p4_l2_dist;
    logic [DIST_WIDTH-1:0]                                      p5_l2_dist;
    logic [DIST_WIDTH-1:0]                                      p6_l2_dist;
    logic [DIST_WIDTH-1:0]                                      p7_l2_dist;
    logic [IDX_WIDTH-1:0]                                       p0_idx_out;
    logic [IDX_WIDTH-1:0]                                       p1_idx_out;
    logic [IDX_WIDTH-1:0]                                       p2_idx_out;
    logic [IDX_WIDTH-1:0]                                       p3_idx_out;
    logic [IDX_WIDTH-1:0]                                       p4_idx_out;
    logic [IDX_WIDTH-1:0]                                       p5_idx_out;
    logic [IDX_WIDTH-1:0]                                       p6_idx_out;
    logic [IDX_WIDTH-1:0]                                       p7_idx_out;

    L2Kernel dut(
        .clk                (clk),
        .rst_n              (rst_n),
        .query_first_in     (query_first_in),
        .query_first_out    (query_first_out),
        .query_last_in      (query_last_in),
        .query_last_out     (query_last_out),
        .query_valid        (query_valid),
        .query_patch        (query_patch),
        .dist_valid         (dist_valid),
        .leaf_idx_in        (leaf_idx_in),
        .leaf_idx_out       (leaf_idx_out),
        .p0_data            (p0_data),
        .p1_data            (p1_data),
        .p2_data            (p2_data),
        .p3_data            (p3_data),
        .p4_data            (p4_data),
        .p5_data            (p5_data),
        .p6_data            (p6_data),
        .p7_data            (p7_data),
        .p0_idx_in          (p0_idx_in),
        .p1_idx_in          (p1_idx_in),
        .p2_idx_in          (p2_idx_in),
        .p3_idx_in          (p3_idx_in),
        .p4_idx_in          (p4_idx_in),
        .p5_idx_in          (p5_idx_in),
        .p6_idx_in          (p6_idx_in),
        .p7_idx_in          (p7_idx_in),
        .p0_l2_dist         (p0_l2_dist),
        .p1_l2_dist         (p1_l2_dist),
        .p2_l2_dist         (p2_l2_dist),
        .p3_l2_dist         (p3_l2_dist),
        .p4_l2_dist         (p4_l2_dist),
        .p5_l2_dist         (p5_l2_dist),
        .p6_l2_dist         (p6_l2_dist),
        .p7_l2_dist         (p7_l2_dist),
        .p0_idx_out         (p0_idx_out),
        .p1_idx_out         (p1_idx_out),
        .p2_idx_out         (p2_idx_out),
        .p3_idx_out         (p3_idx_out),
        .p4_idx_out         (p4_idx_out),
        .p5_idx_out         (p5_idx_out),
        .p6_idx_out         (p6_idx_out),
        .p7_idx_out         (p7_idx_out)
    );

    initial begin 
        clk = 0;
        forever begin
            #10 clk = ~clk;
        end 
    end

    initial begin
        rst_n = 0;
        p0_data = '0;
        p1_data = '0;
        p2_data = '0;
        p3_data = '0;
        p4_data = '0;
        p5_data = '0;
        p6_data = '0;
        p7_data = '0;
        query_patch = '0;
        query_valid = 1'b0;
        leaf_idx_in = '0;
        #20 rst_n = 1;
        #20;

        @(negedge clk);
        leaf_idx_in = 2;
        query_valid = 1'b1;
        query_patch = {11'd0, -11'd20, 11'd0, 11'd20, 11'd0};
        p0_data = {11'd20, 11'd0, -11'd20, 11'd0, 11'd20};

        @(negedge clk);
        leaf_idx_in = '0;
        query_valid = 1'b0;
        query_patch = '0;
        p0_data = '0;
        
        wait(query_valid == 1'b1);
        //$display("p0_data is %d", p0_data);
        wait(query_valid == 1'b0);
        #20;
        $finish;

    end

endmodule