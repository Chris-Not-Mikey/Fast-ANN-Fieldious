`timescale 1 ns / 1 ps
module WishBoneCtrl_tb();

    parameter DATA_WIDTH = 11;
    parameter LEAF_SIZE = 8;
    parameter PATCH_SIZE = 5;
    parameter ROW_SIZE = 24;
    parameter COL_SIZE = 17;
    parameter NUM_QUERYS = ROW_SIZE * COL_SIZE;
    parameter K = 4;
    parameter NUM_LEAVES = 64;
    parameter LEAF_ADDRW = $clog2(NUM_LEAVES);
    parameter NUM_NODES = NUM_LEAVES - 1;

    logic                                                   wb_clk_i;
    logic                                                   wb_rst_i;
    logic                                                   wbs_stb_i;
    logic                                                   wbs_cyc_i;
    logic                                                   wbs_we_i;
    logic [3:0]                                             wbs_sel_i;
    logic [31:0]                                            wbs_dat_i;
    logic [31:0]                                            wbs_adr_i;
    logic                                                   wbs_ack_o;
    logic [31:0]                                            wbs_dat_o;
    logic                                                   wbs_mode;
    logic                                                   wbs_debug;
    logic                                                   wbs_qp_mem_csb0;
    logic                                                   wbs_qp_mem_web0;
    logic [$clog2(NUM_QUERYS)-1:0]                          wbs_qp_mem_addr0;
    logic [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]                 wbs_qp_mem_wpatch0;
    logic [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]                 wbs_qp_mem_rpatch0;
    logic [LEAF_SIZE-1:0]                                   wbs_leaf_mem_csb0;
    logic [LEAF_SIZE-1:0]                                   wbs_leaf_mem_web0;
    logic [LEAF_ADDRW-1:0]                                  wbs_leaf_mem_addr0;
    logic [63:0]                                            wbs_leaf_mem_wleaf0;
    logic [63:0]                                            wbs_leaf_mem_rleaf0 [LEAF_SIZE-1:0];
    logic                                                   wbs_best_arr_csb1;
    logic [7:0]                                             wbs_best_arr_addr1;
    logic [63:0]                                            wbs_best_arr_rdata1;

    logic                                                   wbs_node_mem_web;
    logic [31:0]                                            wbs_node_mem_addr;
    logic [31:0]                                            wbs_node_mem_wdata;
    logic [31:0]                                            wbs_node_mem_rdata;

    localparam WBS_ADDR_MASK        = 32'hFFFF_0000;
    localparam WBS_MODE_ADDR        = 32'h3000_0000;
    localparam WBS_DEBUG_ADDR       = 32'h3000_0004;
    localparam WBS_DONE_ADDR        = 32'h3000_0008;
    localparam WBS_QUERY_ADDR       = 32'h3001_0000;
    localparam WBS_LEAF_ADDR        = 32'h3002_0000;
    localparam WBS_BEST_ADDR        = 32'h3003_0000;
    localparam WBS_NODE_ADDR        = 32'h3004_0000;
    
    initial begin 
        wb_clk_i = 0;
        forever begin
            #5 wb_clk_i = ~wb_clk_i;
        end 
    end

   logic [31:0]                                            wbs_dat_nod_o;

    wbsCtrl #(
        .DATA_WIDTH                             (DATA_WIDTH),
        .LEAF_SIZE                              (LEAF_SIZE),
        .PATCH_SIZE                             (PATCH_SIZE),
        .ROW_SIZE                               (ROW_SIZE),
        .COL_SIZE                               (COL_SIZE),
        .K                                      (K),
        .NUM_LEAVES                             (NUM_LEAVES)
    ) wbsctrl_inst (
        .wb_clk_i                               (wb_clk_i),
        .wb_rst_i                               (wb_rst_i),
        .wbs_stb_i                              (wbs_stb_i),
        .wbs_cyc_i                              (wbs_cyc_i),
        .wbs_we_i                               (wbs_we_i),
        .wbs_sel_i                              (wbs_sel_i),
        .wbs_dat_i                              (wbs_dat_i),
        .wbs_adr_i                              (wbs_adr_i),
        .wbs_ack_o                              (wbs_ack_o),
        .wbs_dat_o                              (wbs_dat_o),
        .wbs_mode                               (wbs_mode),
        .wbs_debug                              (wbs_debug),
        .wbs_qp_mem_csb0                        (wbs_qp_mem_csb0),
        .wbs_qp_mem_web0                        (wbs_qp_mem_web0),
        .wbs_qp_mem_addr0                       (wbs_qp_mem_addr0),
        .wbs_qp_mem_wpatch0                     (wbs_qp_mem_wpatch0),
        .wbs_qp_mem_rpatch0                     (wbs_qp_mem_rpatch0),
        .wbs_leaf_mem_csb0                      (wbs_leaf_mem_csb0),
        .wbs_leaf_mem_web0                      (wbs_leaf_mem_web0),
        .wbs_leaf_mem_addr0                     (wbs_leaf_mem_addr0),
        .wbs_leaf_mem_wleaf0                    (wbs_leaf_mem_wleaf0),
        .wbs_leaf_mem_rleaf0                    (wbs_leaf_mem_rleaf0),
        .wbs_node_mem_web                       (wbs_node_mem_web),
        .wbs_node_mem_addr                      (wbs_node_mem_addr),
        .wbs_node_mem_wdata                     (wbs_node_mem_wdata),
        .wbs_node_mem_rdata                     (wbs_dat_nod_o),
        .wbs_best_arr_csb1                      (wbs_best_arr_csb1),
        .wbs_best_arr_addr1                     (wbs_best_arr_addr1),
        .wbs_best_arr_rdata1                    (wbs_best_arr_rdata1)
    );


    logic [7:0] leaf_index;
    logic [7:0] leaf_index_two;
    logic leaf_en;
    logic leaf_two_en;

    
    internal_node_tree #(
        .INTERNAL_WIDTH(22),
        .PATCH_WIDTH(55),
        .ADDRESS_WIDTH(8)
    ) tree_dut (
        .clk(wb_clk_i),
        .rst_n(!wb_rst_i),
        .fsm_enable(wbs_we_i), //based on whether we are at the proper I/O portion
        .sender_enable(wbs_we_i),
        .sender_data(wbs_dat_i),
        .patch_en(1'b0),
        .patch_two_en(1'b0),
        .patch_in(55'b0),
        .patch_in_two(55'b0),
        .leaf_index(leaf_index),
        .leaf_index_two(leaf_index_two),
        .receiver_en(leaf_en),
        .receiver_two_en(leaf_two_en),
        .wb_mode(wbs_mode),
        .wbs_we_i(wbs_we_i && wbs_node_mem_web), 
        .wbs_adr_i(wbs_adr_i), 
        .wbs_dat_o(wbs_dat_nod_o)
     );

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars;

        wb_rst_i = 1'b1;
        wbs_stb_i = 1'b0;
        wbs_cyc_i = 1'b0;
        wbs_we_i = 1'b0;
        wbs_sel_i = '1;
        wbs_dat_i = '0;
        wbs_adr_i = '0;
        #10;

        wb_rst_i = 1'b0;
        #10;

        // reg
        $display("time %t, reg debugging", $time);
        @(posedge wb_clk_i);
        wbs_cyc_i = 1'b1;
        wbs_stb_i = 1'b1;
        wbs_we_i = 1'b1;
        wbs_sel_i = '1;
        wbs_adr_i = WBS_DEBUG_ADDR;
        wbs_dat_i = 32'd1;

        @(negedge wbs_ack_o);
        wbs_cyc_i = 1'b1;
        wbs_stb_i = 1'b1;
        wbs_we_i = 1'b1;
        wbs_sel_i = '1;
        wbs_adr_i = WBS_MODE_ADDR;
        wbs_dat_i = 32'd1;
        
        @(negedge wbs_ack_o);
        wbs_stb_i = 1'b0;
        wbs_we_i = 1'b0;
        wbs_dat_i = '0;
        wbs_adr_i = '0;

        @(posedge wb_clk_i);
        wbs_cyc_i = 1'b1;
        wbs_stb_i = 1'b1;
        wbs_we_i = 1'b1;
        wbs_sel_i = '1;
        wbs_adr_i = WBS_DEBUG_ADDR;
        wbs_dat_i = 32'd0;

        @(negedge wbs_ack_o);
        wbs_cyc_i = 1'b0;
        wbs_stb_i = 1'b0;
        wbs_we_i = 1'b0;
        wbs_dat_i = '0;
        wbs_adr_i = '0;

        
        // qp mem
        $display("time %t, qp mem debugging", $time);
        // mem read
        @(posedge wb_clk_i);
        wbs_cyc_i = 1'b1;
        wbs_stb_i = 1'b1;
        wbs_we_i = 1'b0;
        wbs_sel_i = '1;
        wbs_adr_i = WBS_QUERY_ADDR + (1<<3) + (0<<2);  // addr 1, lower, byte address
        
        @(negedge (~wbs_qp_mem_csb0 & wbs_qp_mem_web0));
        wbs_qp_mem_rpatch0 = 55'h00_1010_DEAD_BEEF;

        @(posedge wbs_ack_o) assert(wbs_dat_o == 32'hDEAD_BEEF);
        @(negedge wbs_ack_o);
        wbs_cyc_i = 1'b1;
        wbs_stb_i = 1'b1;
        wbs_we_i = 1'b0;
        wbs_sel_i = '1;
        wbs_adr_i = WBS_QUERY_ADDR + (1<<3) + (1<<2);  // addr 1, upper
        
        @(negedge (~wbs_qp_mem_csb0 & wbs_qp_mem_web0));
        wbs_qp_mem_rpatch0 = 55'h00_1010_DEAD_BEEF;

        @(posedge wbs_ack_o) assert(wbs_dat_o == 32'h0000_1010);
        @(negedge wbs_ack_o);
        wbs_cyc_i = 1'b0;
        wbs_stb_i = 1'b0;
        wbs_we_i = 1'b0;
        wbs_dat_i = '0;
        wbs_adr_i = '0;

        // mem write
        @(posedge wb_clk_i);
        wbs_cyc_i = 1'b1;
        wbs_stb_i = 1'b1;
        wbs_we_i = 1'b1;
        wbs_sel_i = '1;
        wbs_dat_i = 32'h01234567;
        wbs_adr_i = WBS_QUERY_ADDR + (2<<3) + (0<<2);  // addr 2, lower
        
        @(negedge wbs_ack_o);
        wbs_cyc_i = 1'b1;
        wbs_stb_i = 1'b1;
        wbs_we_i = 1'b1;
        wbs_sel_i = '1;
        wbs_dat_i = 32'h000bcdef;
        wbs_adr_i = WBS_QUERY_ADDR + (2<<3) + (1<<2);  // addr 2, upper
        
        @(negedge wbs_ack_o);
        wbs_cyc_i = 1'b0;
        wbs_stb_i = 1'b0;
        wbs_we_i = 1'b0;
        wbs_dat_i = '0;
        wbs_adr_i = '0;


        // leaf mem
        $display("time %t, leaf mem debugging", $time);
        // mem read
        @(posedge wb_clk_i);
        wbs_cyc_i = 1'b1;
        wbs_stb_i = 1'b1;
        wbs_we_i = 1'b0;
        wbs_sel_i = '1;
        wbs_adr_i = WBS_LEAF_ADDR + (7<<3) + (0<<2);  // addr 0, 7th leaf, lower
        
        @(negedge (~wbs_leaf_mem_csb0[7] & wbs_leaf_mem_web0[7]));
        wbs_leaf_mem_rleaf0[7] = 63'h1100_1010_DEAD_BEEF;

        @(posedge wbs_ack_o) assert(wbs_dat_o == 32'hDEAD_BEEF);
        @(negedge wbs_ack_o);
        wbs_cyc_i = 1'b1;
        wbs_stb_i = 1'b1;
        wbs_we_i = 1'b0;
        wbs_sel_i = '1;
        wbs_adr_i = WBS_LEAF_ADDR + (7<<3) + (1<<2);  // addr 0, 7th leaf, upper
        
        @(negedge (~wbs_leaf_mem_csb0[7] & wbs_leaf_mem_web0[7]));
        wbs_leaf_mem_rleaf0[7] = 63'h1100_1010_DEAD_BEEF;

        @(posedge wbs_ack_o) assert(wbs_dat_o == 32'h1100_1010);
        @(negedge wbs_ack_o);
        wbs_cyc_i = 1'b0;
        wbs_stb_i = 1'b0;
        wbs_we_i = 1'b0;
        wbs_dat_i = '0;
        wbs_adr_i = '0;

        // mem write
        @(posedge wb_clk_i);
        wbs_cyc_i = 1'b1;
        wbs_stb_i = 1'b1;
        wbs_we_i = 1'b1;
        wbs_sel_i = '1;
        wbs_dat_i = 32'h76543210;
        wbs_adr_i = WBS_LEAF_ADDR + (3<<3) + (0<<2);  // addr 3, lower
        
        @(negedge wbs_ack_o);
        wbs_cyc_i = 1'b1;
        wbs_stb_i = 1'b1;
        wbs_we_i = 1'b1;
        wbs_sel_i = '1;
        wbs_dat_i = 32'hfedcba98;
        wbs_adr_i = WBS_LEAF_ADDR + (3<<3) + (1<<2);  // addr 3, upper
        
        @(negedge wbs_ack_o);
        wbs_cyc_i = 1'b0;
        wbs_stb_i = 1'b0;
        wbs_we_i = 1'b0;
        wbs_dat_i = '0;
        wbs_adr_i = '0;


        // best arr
        $display("time %t, best array debugging", $time);
        // mem read
        @(posedge wb_clk_i);
        wbs_cyc_i = 1'b1;
        wbs_stb_i = 1'b1;
        wbs_we_i = 1'b0;
        wbs_sel_i = '1;
        wbs_adr_i = WBS_BEST_ADDR + (7<<3) + (0<<2); // addr 7, lower
        
        @(negedge (~wbs_best_arr_csb1));
        wbs_best_arr_rdata1 = 63'h1100_1010_DEAD_BEEF;

        @(posedge wbs_ack_o) assert(wbs_dat_o == 32'hDEAD_BEEF);
        @(negedge wbs_ack_o);
        wbs_cyc_i = 1'b1;
        wbs_stb_i = 1'b1;
        wbs_we_i = 1'b0;
        wbs_sel_i = '1;
        wbs_adr_i = WBS_BEST_ADDR + (7<<3) + (1<<2);  // addr 7, upper
        
        @(negedge (~wbs_best_arr_csb1));
        wbs_best_arr_rdata1 = 63'h1100_1010_DEAD_BEEF;

        @(posedge wbs_ack_o) assert(wbs_dat_o == 32'h1100_1010);
        @(negedge wbs_ack_o);
        wbs_cyc_i = 1'b0;
        wbs_stb_i = 1'b0;
        wbs_we_i = 1'b0;
        wbs_dat_i = '0;
        wbs_adr_i = '0;


         // internal node mem
        $display("time %t, internal node tree debugging", $time);
        // mem read
        @(posedge wb_clk_i);
        wbs_cyc_i = 1'b1;
        wbs_stb_i = 1'b1;
        wbs_we_i = 1'b0;
        wbs_sel_i = '1;
        wbs_adr_i = WBS_NODE_ADDR + (1'b1) + 0; // addr 1 (first idx and median)
      

        @(posedge (wbs_ack_o));
        wbs_node_mem_rdata = {10'b0, 11'd0, 8'b0, 3'b111}; //10 0's, median of 0, and index of -1 (wrt to 3 bits)  (default values)


        @(posedge (wbs_ack_o)); // assert(wbs_dat_o == {10'b0, 11'd0, 8'b0, 3'b111});
        //@(negedge wbs_ack_o) assert(wbs_dat_o == {10'b0, 11'd0, 8'b0, 3'b111});
        @(negedge wbs_ack_o);
        wbs_cyc_i = 1'b0;
        wbs_stb_i = 1'b0;
        wbs_we_i = 1'b0;
        wbs_dat_i = '0;
        wbs_adr_i = '0;

        // mem write
        @(posedge wb_clk_i);
        wbs_cyc_i = 1'b1;
        wbs_stb_i = 1'b1;
        wbs_we_i = 1'b1;
        wbs_sel_i = '1;
        wbs_dat_i = {10'b0, 11'd55, 11'd1}; //10 0's, median of 55, and index of 1 
        wbs_adr_i = WBS_NODE_ADDR + 1'b1  + 0; // addr 1
    
        @(negedge wbs_ack_o);
        wbs_cyc_i = 1'b1;
        wbs_stb_i = 1'b1;
        wbs_we_i = 1'b0;
        wbs_dat_i = '0;
 

        @(negedge wbs_ack_o);
        wbs_cyc_i = 1'b0;
        wbs_stb_i = 1'b0;
        wbs_we_i = 1'b0;
        wbs_dat_i = '0;

        //wbs_adr_i = '0;

        #10
        assert(wbs_dat_o == {10'b0, 11'd55, 11'b1});
        //$finish();


        // mem write (last element)
        @(posedge wb_clk_i);
        wbs_cyc_i = 1'b1;
        wbs_stb_i = 1'b1;
        wbs_we_i = 1'b1;
        wbs_sel_i = '1;
        wbs_dat_i = {10'b0, 11'd42, 11'd2}; //10 0's, median of 55, and index of 1 
        wbs_adr_i = WBS_NODE_ADDR + 8'd63  + 0; // addr 1
    
        @(negedge wbs_ack_o);
        wbs_cyc_i = 1'b1;
        wbs_stb_i = 1'b1;
        wbs_we_i = 1'b0;
        wbs_dat_i = '0;


        @(negedge wbs_ack_o);
        wbs_cyc_i = 1'b0;
        wbs_stb_i = 1'b0;
        wbs_we_i = 1'b0;
        wbs_dat_i = '0;

        //wbs_adr_i = '0;

        #10
        assert(wbs_dat_o == {10'b0, 11'd42, 11'd2});
        $finish();

    end

endmodule
