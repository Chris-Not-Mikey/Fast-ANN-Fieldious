`timescale 1 ns / 1 ps
module SortedList_tb();
    localparam  DATA_WIDTH = 25;
    
    logic clk;
    logic rst_n;

    logic restart;
    logic insert;
    logic last_in;
    logic [DATA_WIDTH-1:0] l2_dist_in;
    logic [DATA_WIDTH-1:0] merged_idx_in;
    logic valid_out;
    logic [DATA_WIDTH-1:0] l2_dist_0;
    logic [DATA_WIDTH-1:0] l2_dist_1;
    logic [DATA_WIDTH-1:0] l2_dist_2;
    logic [DATA_WIDTH-1:0] l2_dist_3;
    logic [14:0] merged_idx_0;
    logic [14:0] merged_idx_1;
    logic [14:0] merged_idx_2;
    logic [14:0] merged_idx_3;

    SortedList dut(
        .clk                    (clk),
        .rst_n                  (rst_n),
        .restart                (restart),
        .insert                 (insert),
        .last_in                (last_in),
        .l2_dist_in             (l2_dist_in),
        .merged_idx_in          (merged_idx_in),
        .valid_out              (valid_out),
        .l2_dist_0              (l2_dist_0),
        .l2_dist_1              (l2_dist_1),
        .l2_dist_2              (l2_dist_2),
        .l2_dist_3              (l2_dist_3),
        .merged_idx_0           (merged_idx_0),
        .merged_idx_1           (merged_idx_1),
        .merged_idx_2           (merged_idx_2),
        .merged_idx_3           (merged_idx_3)
    );

    initial begin 
        clk = 0;
        forever begin
            #10 clk = ~clk;
        end 
    end

    initial begin
        rst_n = 0;
        restart = '0;
        insert = '0;
        last_in = '0;
        l2_dist_in = '0;
        merged_idx_in = '0;

        #20 rst_n = 1;
        #20;

        @(negedge clk);
        restart = 1'b1;
        insert = 1'b1;
        l2_dist_in = 2046;
        merged_idx_in = 0 << 9;
        
        @(negedge clk);
        assert(l2_dist_0 == 2046)
            else $error("l2_dist_0 expected to be 3, but received %d", l2_dist_0);
        assert(merged_idx_0 == 0);
        restart = 1'b0;
        insert = 1'b1;
        l2_dist_in = 3;
        merged_idx_in = 1 << 9;
        
        @(negedge clk);
        assert(l2_dist_0 == 3);
        assert(l2_dist_1 == 2046);
        assert(merged_idx_0 == 1 << 9);
        assert(merged_idx_1 == 0 << 9);
        insert = 1'b1;
        l2_dist_in = 2046;
        merged_idx_in = 2 << 9;
        
        @(negedge clk);
        assert(l2_dist_0 == 3);
        assert(l2_dist_1 == 2046);
        assert(l2_dist_2 == 2046);
        assert(merged_idx_0 == 1 << 9);
        assert(merged_idx_1 == 2 << 9);
        assert(merged_idx_2 == 0 << 9);
        insert = 1'b1;
        l2_dist_in = 2047;
        merged_idx_in = 3 << 9;
        
        @(negedge clk);
        assert(l2_dist_0 == 3);
        assert(l2_dist_1 == 2046);
        assert(l2_dist_2 == 2046);
        assert(l2_dist_3 == 2047);
        assert(merged_idx_0 == 1 << 9);
        assert(merged_idx_1 == 2 << 9);
        assert(merged_idx_2 == 0 << 9);
        assert(merged_idx_3 == 3 << 9);
        insert = 1'b1;
        l2_dist_in = 2;
        merged_idx_in = 0 << 9;
        
        @(negedge clk);
        assert(l2_dist_0 == 2);
        assert(l2_dist_1 == 3);
        assert(l2_dist_2 == 2046);
        assert(l2_dist_3 == 2047);
        assert(merged_idx_0 == 0 << 9);
        assert(merged_idx_1 == 1 << 9);
        assert(merged_idx_2 == 2 << 9);
        assert(merged_idx_3 == 3 << 9);
        insert = 1'b1;
        l2_dist_in = 2;
        merged_idx_in = 5 << 9;
        
        @(negedge clk);
        assert(l2_dist_0 == 2);
        assert(l2_dist_1 == 2);
        assert(l2_dist_2 == 3);
        assert(l2_dist_3 == 2046);
        assert(merged_idx_0 == 5 << 9);
        assert(merged_idx_1 == 0 << 9);
        assert(merged_idx_2 == 1 << 9);
        assert(merged_idx_3 == 2 << 9);
        insert = 1'b1;
        l2_dist_in = 1;
        merged_idx_in = 5 << 9;

        @(negedge clk);
        assert(l2_dist_0 == 1);
        assert(l2_dist_1 == 2);
        assert(l2_dist_2 == 3);
        assert(l2_dist_3 == 2046);
        assert(merged_idx_0 == 5 << 9);
        assert(merged_idx_1 == 0 << 9);
        assert(merged_idx_2 == 1 << 9);
        assert(merged_idx_3 == 2 << 9);
        insert = 1'b1;
        l2_dist_in = 0;
        merged_idx_in = 1 << 9;

        @(negedge clk);
        assert(l2_dist_0 == 0);
        assert(l2_dist_1 == 1);
        assert(l2_dist_2 == 2);
        assert(l2_dist_3 == 2046);
        assert(merged_idx_0 == 1 << 9);
        assert(merged_idx_1 == 5 << 9);
        assert(merged_idx_2 == 0 << 9);
        assert(merged_idx_3 == 2 << 9);
        restart = 1'b1;
        insert = 1'b1;
        l2_dist_in = 20;
        merged_idx_in = 6 << 9;

        @(negedge clk);
        assert(l2_dist_0 == 20);
        assert(merged_idx_0 == 6 << 9);
        #20;
        $finish;

    end

endmodule