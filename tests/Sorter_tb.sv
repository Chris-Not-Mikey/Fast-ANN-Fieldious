`timescale 1 ns / 1 ps
module Sorter_tb();
    localparam  DATA_WIDTH = 11;
    logic clk;
    logic rst_n;
    logic valid_in;
    logic valid_out;
    logic [10:0] data_in_0;
    logic [10:0] data_in_1;
    logic [10:0] data_in_2;
    logic [10:0] data_in_3;
    logic [10:0] data_in_4;
    logic [10:0] data_in_5;
    logic [10:0] data_in_6;
    logic [10:0] data_in_7;
    logic [8:0] indices_in_0;
    logic [8:0] indices_in_1;
    logic [8:0] indices_in_2;
    logic [8:0] indices_in_3;
    logic [8:0] indices_in_4;
    logic [8:0] indices_in_5;
    logic [8:0] indices_in_6;
    logic [8:0] indices_in_7;
    logic [10:0] data_out_0;
    logic [10:0] data_out_1;
    logic [10:0] data_out_2;
    logic [10:0] data_out_3;
    logic [8:0] indices_out_0;
    logic [8:0] indices_out_1;
    logic [8:0] indices_out_2;
    logic [8:0] indices_out_3;

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
        .indices_in_0(indices_in_0),
        .indices_in_1(indices_in_1),
        .indices_in_2(indices_in_2),
        .indices_in_3(indices_in_3),
        .indices_in_4(indices_in_4),
        .indices_in_5(indices_in_5),
        .indices_in_6(indices_in_6),
        .indices_in_7(indices_in_7),
        .data_out_0(data_out_0),
        .data_out_1(data_out_1),
        .data_out_2(data_out_2),
        .data_out_3(data_out_3),
        .indices_out_0(indices_out_0),
        .indices_out_1(indices_out_1),
        .indices_out_2(indices_out_2),
        .indices_out_3(indices_out_3)
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
        indices_in_0 = '0;
        indices_in_1 = '0;
        indices_in_2 = '0;
        indices_in_3 = '0;
        indices_in_4 = '0;
        indices_in_5 = '0;
        indices_in_6 = '0;
        indices_in_7 = '0;
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
        indices_in_0 = 1;
        indices_in_1 = 2;
        indices_in_2 = 4;
        indices_in_3 = 7;
        indices_in_4 = 0;
        indices_in_5 = 5;
        indices_in_6 = 3;
        indices_in_7 = 6;
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
        indices_in_0 = 6;
        indices_in_1 = 2;
        indices_in_2 = 0;
        indices_in_3 = 3;
        indices_in_4 = 5;
        indices_in_5 = 1;
        indices_in_6 = 4;
        indices_in_7 = 7;
        valid_in = 1'b1;

        @(negedge clk);
        valid_in = 1'b0;
        
        wait(valid_out == 1'b1);
        //$display("p0_candidate_leaf is %d", p0_candidate_leaf);
        wait(valid_out == 1'b0);
        #20;
        $finish;

    end

endmodule