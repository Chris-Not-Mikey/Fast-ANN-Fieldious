`timescale 1 ns / 1 ps
module Sorter_tb();
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
    logic valid_in;
    logic valid_out;
    logic [DIST_WIDTH-1:0] data_in_0;
    logic [DIST_WIDTH-1:0] data_in_1;
    logic [DIST_WIDTH-1:0] data_in_2;
    logic [DIST_WIDTH-1:0] data_in_3;
    logic [DIST_WIDTH-1:0] data_in_4;
    logic [DIST_WIDTH-1:0] data_in_5;
    logic [DIST_WIDTH-1:0] data_in_6;
    logic [DIST_WIDTH-1:0] data_in_7;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0] idx_in_0;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0] idx_in_1;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0] idx_in_2;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0] idx_in_3;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0] idx_in_4;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0] idx_in_5;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0] idx_in_6;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0] idx_in_7;
    logic [DIST_WIDTH-1:0] data_out_0;
    logic [DIST_WIDTH-1:0] data_out_1;
    logic [DIST_WIDTH-1:0] data_out_2;
    logic [DIST_WIDTH-1:0] data_out_3;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0] idx_out_0;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0] idx_out_1;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0] idx_out_2;
    logic [LEAF_ADDRW+IDX_WIDTH-1:0] idx_out_3;

    BitonicSorter dut(
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .valid_out(valid_out),
        .data_in_0(data_in_0),
        .data_in_1(data_in_1),
        .data_in_2(data_in_2),
        .data_in_3(data_in_3),
        .data_in_4(data_in_4),
        .data_in_5(data_in_5),
        .data_in_6(data_in_6),
        .data_in_7(data_in_7),
        .idx_in_0(idx_in_0),
        .idx_in_1(idx_in_1),
        .idx_in_2(idx_in_2),
        .idx_in_3(idx_in_3),
        .idx_in_4(idx_in_4),
        .idx_in_5(idx_in_5),
        .idx_in_6(idx_in_6),
        .idx_in_7(idx_in_7),
        .data_out_0(data_out_0),
        .data_out_1(data_out_1),
        .data_out_2(data_out_2),
        .data_out_3(data_out_3),
        .idx_out_0(idx_out_0),
        .idx_out_1(idx_out_1),
        .idx_out_2(idx_out_2),
        .idx_out_3(idx_out_3)
    );

    initial begin 
        clk = 0;
        forever begin
            #10 clk = ~clk;
        end 
    end

    initial begin
        rst_n = 0;
        data_in_0 = '0;
        data_in_1 = '0;
        data_in_2 = '0;
        data_in_3 = '0;
        data_in_4 = '0;
        data_in_5 = '0;
        data_in_6 = '0;
        data_in_7 = '0;
        idx_in_0 = '0;
        idx_in_1 = '0;
        idx_in_2 = '0;
        idx_in_3 = '0;
        idx_in_4 = '0;
        idx_in_5 = '0;
        idx_in_6 = '0;
        idx_in_7 = '0;
        valid_in = 1'b0;
        #20 rst_n = 1;
        #20;

        @(negedge clk);
        data_in_0 = 3;
        data_in_1 = 20;
        data_in_2 = 124;
        data_in_3 = 826;
        data_in_4 = 0;
        data_in_5 = 125;
        data_in_6 = 83;
        data_in_7 = 283;
        idx_in_0 = 1;
        idx_in_1 = 2;
        idx_in_2 = 4;
        idx_in_3 = 7;
        idx_in_4 = 0;
        idx_in_5 = 5;
        idx_in_6 = 3;
        idx_in_7 = 6;
        valid_in = 1'b1;
        
        @(negedge clk);
        data_in_0 = 300;
        data_in_1 = 2;
        data_in_2 = 1;
        data_in_3 = 11;
        data_in_4 = 16;
        data_in_5 = 2;
        data_in_6 = 12;
        data_in_7 = 339;
        idx_in_0 = 6;
        idx_in_1 = 2;
        idx_in_2 = 0;
        idx_in_3 = 3;
        idx_in_4 = 5;
        idx_in_5 = 1;
        idx_in_6 = 4;
        idx_in_7 = 7;
        valid_in = 1'b1;

        @(negedge clk);
        valid_in = 1'b0;
        
        wait(valid_out == 1'b1);
        @(negedge clk);
        assert(data_out_0 == 0);
        assert(idx_out_0 == 0);
        assert(data_out_1 == 3);
        assert(idx_out_1 == 1);
        assert(data_out_2 == 20);
        assert(idx_out_2 == 2);
        assert(data_out_3 == 83);
        assert(idx_out_3 == 3);
        @(negedge clk);
        assert(data_out_0 == 1);
        assert(idx_out_0 == 0);
        assert(data_out_1 == 2);
        assert(idx_out_1 == 1);
        assert(data_out_2 == 2);
        assert(idx_out_2 == 2);
        assert(data_out_3 == 11);
        assert(idx_out_3 == 3);
        //$display("p0_candidate_leaf is %d", p0_candidate_leaf);
        wait(valid_out == 1'b0);
        #20;
        $finish;

    end

endmodule