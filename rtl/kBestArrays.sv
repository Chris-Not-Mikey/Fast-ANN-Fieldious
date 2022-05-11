module kBestArrays #(
    parameter DATA_WIDTH = 11,
    parameter IDX_WIDTH = 9,
    parameter K = 4,
    parameter NUM_LEAVES = 64,
    parameter LEAF_ADDRW = $clog2(NUM_LEAVES)
)
(
    input                                               clk,
    input logic                                         csb0,
    input logic                                         web0,
    input logic [8:0]                                   addr0,
    input logic [LEAF_ADDRW+IDX_WIDTH-1:0]              compute0_widx_0 [K-1:0],
    input logic [LEAF_ADDRW+IDX_WIDTH-1:0]              compute1_widx_0 [K-1:0],
    output logic [LEAF_ADDRW+IDX_WIDTH-1:0]             compute0_ridx_0 [K-1:0],
    output logic [LEAF_ADDRW+IDX_WIDTH-1:0]             compute1_ridx_0 [K-1:0],
    input logic [K-1:0]                                 csb1,
    input logic [8:0]                                   addr1,
    output logic [LEAF_ADDRW+IDX_WIDTH-1:0]             compute0_ridx_1 [K-1:0],
    output logic [LEAF_ADDRW+IDX_WIDTH-1:0]             compute1_ridx_1 [K-1:0]
);

    logic [31:0] dout0 [K-1:0];
    logic [31:0] dout1 [K-1:0];
    genvar i;
    generate
    for (i=0; i<K; i=i+1) begin : loop_best_array_gen
        sram_1kbyte_1rw1r
        #(
            .DATA_WIDTH(32), // round(PATCH_SIZE * DATA_WIDTH)
            .ADDR_WIDTH(9),
            .RAM_DEPTH(512) // NUM_PATCHES
        ) best_dist_array_inst (
            .clk0(clk),
            .csb0(csb0),
            .web0(web0),
            .addr0(addr0),
            .din0({{(32 - LEAF_ADDRW * 2 - IDX_WIDTH * 2){1'b0}}, compute1_widx_0[i], compute0_widx_0[i]}),
            .dout0(dout0[i]),
            .clk1(clk),
            .csb1(csb1[i]),
            .addr1(addr1),
            .dout1(dout1[i])
        );
        assign compute0_ridx_0[i] = dout0[i][LEAF_ADDRW+IDX_WIDTH-1:0];
        assign compute1_ridx_0[i] = dout0[i][31-2:LEAF_ADDRW+IDX_WIDTH];
        assign compute0_ridx_1[i] = dout1[i][LEAF_ADDRW+IDX_WIDTH-1:0];
        assign compute1_ridx_1[i] = dout1[i][31-2:LEAF_ADDRW+IDX_WIDTH];
    end
    endgenerate

endmodule