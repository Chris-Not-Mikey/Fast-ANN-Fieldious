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

    logic                                                    wbs_node_mem_web;
    logic [31:0]                                             wbs_node_mem_addr;
    logic [31:0]                                             wbs_node_mem_wdata;
    logic [31:0]                                             wbs_node_mem_rdata;

    localparam WBS_ADDR_MASK        = 32'hF000_0000;
    localparam WBS_MODE_ADDR        = 32'h3000_0000;
    localparam WBS_DEBUG_ADDR       = 32'h3000_0001;
    localparam WBS_QUERY_ADDR       = 32'h3100_0000;
    localparam WBS_LEAF_ADDR        = 32'h3200_0000;
    localparam WBS_BEST_ADDR        = 32'h3300_0000;
    localparam WBS_NODE_ADDR        = 32'h3400_0000;
    
    initial begin 
        wb_clk_i = 0;
        forever begin
            #5 wb_clk_i = ~wb_clk_i;
        end 
    end

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
        .wbs_node_mem_rdata                     (wbs_node_mem_rdata)
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
        wbs_adr_i = WBS_QUERY_ADDR + (1<<1) + 0; // addr 1, lower
        
        @(negedge (~wbs_qp_mem_csb0 & wbs_qp_mem_web0));
        wbs_qp_mem_rpatch0 = 55'h00_1010_DEAD_BEEF;

        @(posedge wbs_ack_o) assert(wbs_dat_o == 32'hDEAD_BEEF);
        @(negedge wbs_ack_o);
        wbs_cyc_i = 1'b1;
        wbs_stb_i = 1'b1;
        wbs_we_i = 1'b0;
        wbs_sel_i = '1;
        wbs_adr_i = WBS_QUERY_ADDR + (1<<1) + 1; // addr 1, upper
        
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
        wbs_adr_i = WBS_QUERY_ADDR + (2<<1) + 0; // addr 2, lower
        
        @(negedge wbs_ack_o);
        wbs_cyc_i = 1'b1;
        wbs_stb_i = 1'b1;
        wbs_we_i = 1'b1;
        wbs_sel_i = '1;
        wbs_dat_i = 32'h000bcdef;
        wbs_adr_i = WBS_QUERY_ADDR + (2<<1) + 1; // addr 2, upper
        
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
        wbs_adr_i = WBS_LEAF_ADDR + (7<<1) + 0; // addr 1, lower
        
        @(negedge (~wbs_leaf_mem_csb0[7] & wbs_leaf_mem_web0[7]));
        wbs_leaf_mem_rleaf0[7] = 63'h1100_1010_DEAD_BEEF;

        @(posedge wbs_ack_o) assert(wbs_dat_o == 32'hDEAD_BEEF);
        @(negedge wbs_ack_o);
        wbs_cyc_i = 1'b1;
        wbs_stb_i = 1'b1;
        wbs_we_i = 1'b0;
        wbs_sel_i = '1;
        wbs_adr_i = WBS_LEAF_ADDR + (7<<1) + 1; // addr 1, upper
        
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
        wbs_adr_i = WBS_LEAF_ADDR + (3<<1) + 0; // addr 2, lower
        
        @(negedge wbs_ack_o);
        wbs_cyc_i = 1'b1;
        wbs_stb_i = 1'b1;
        wbs_we_i = 1'b1;
        wbs_sel_i = '1;
        wbs_dat_i = 32'hfedcba98;
        wbs_adr_i = WBS_LEAF_ADDR + (3<<1) + 1; // addr 2, upper
        
        @(negedge wbs_ack_o);
        wbs_cyc_i = 1'b0;
        wbs_stb_i = 1'b0;
        wbs_we_i = 1'b0;
        wbs_dat_i = '0;
        wbs_adr_i = '0;


         // iternal node mem
        $display("time %t, internal node tree debugging", $time);
        // mem read
        @(posedge wb_clk_i);
        wbs_cyc_i = 1'b1;
        wbs_stb_i = 1'b1;
        wbs_we_i = 1'b0;
        wbs_sel_i = '1;
        wbs_adr_i = WBS_NODE_ADDR + (1<<1)+ 0; // addr 1 (first idx and median)
        
        @(negedge (wbs_node_mem_web));
        wbs_node_mem_rdata = 32'{10'b0, 11'd0, 8'b0, 3'b111}; //10 0's, median of 0, and index of -1 (wrt to 3 bits)  (default values)

        @(posedge wbs_ack_o) assert(wbs_dat_o == 32'{10'b0, 11'd0, 8'b0, 3'b111});
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
        wbs_dat_i = 32'{10'b0, 11'd55, 11'd1}; //10 0's, median of 55, and index of 1 
        wbs_adr_i = WBS_NODE_ADDR + (1<<1) + 0; // addr 1
    
        @(negedge wbs_ack_o);
        wbs_cyc_i = 1'b0;
        wbs_stb_i = 1'b0;
        wbs_we_i = 1'b0;
        wbs_dat_i = '0;
        wbs_adr_i = '0;

        $finish();

    end

endmodule
