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
    input logic [DATA_WIDTH-1:0]                        wdist_0 [K-1:0],
    input logic [IDX_WIDTH-1:0]                         widx_0 [K-1:0],
    input logic [LEAF_ADDRW-1:0]                        wleaf_idx_0 [K-1:0],
    output logic [DATA_WIDTH-1:0]                       rdist_0 [K-1:0],
    output logic [IDX_WIDTH-1:0]                        ridx_0 [K-1:0],
    output logic [LEAF_ADDRW-1:0]                       rleaf_idx_0 [K-1:0],
    input logic [K-1:0]                                 csb1,
    input logic [8:0]                                   addr1,
    output logic [DATA_WIDTH-1:0]                       rdist_1 [K-1:0],
    output logic [IDX_WIDTH-1:0]                        ridx_1 [K-1:0],
    output logic [LEAF_ADDRW-1:0]                       rleaf_idx_1 [K-1:0]
);

    logic [31:0] dout0 [K-1:0];
    logic [31:0] dout1 [K-1:0];
    genvar i;
    generate
    for (i=0; i<K; i=i+1) begin : loop_best_array_gen
        dffram_wrapper
        #(
            .DATA_WIDTH(32), // round(PATCH_SIZE * DATA_WIDTH)
            .ADDR_WIDTH(9),
            .RAM_DEPTH(512) // NUM_PATCHES
        ) best_dist_array_inst (
            .clk0(clk),
            .csb0(csb0),
            .web0(web0),
            .addr0(addr0),
            .din0({{(32 - LEAF_ADDRW - IDX_WIDTH - DATA_WIDTH){1'b0}}, wleaf_idx_0[i], widx_0[i], wdist_0[i]}),
            .dout0(dout0[i]),
            .clk1(clk),
            .csb1(csb1[i]),
            .addr1(addr1),
            .dout1(dout1[i])
        );
        assign rdist_0[i] = dout0[i][DATA_WIDTH-1:0];
        assign ridx_0[i] = dout0[i][DATA_WIDTH+IDX_WIDTH-1:DATA_WIDTH];
        assign rleaf_idx_0[i] = dout0[i][DATA_WIDTH+IDX_WIDTH+LEAF_ADDRW-1:DATA_WIDTH+IDX_WIDTH];
        assign rdist_1[i] = dout1[i][DATA_WIDTH-1:0];
        assign ridx_1[i] = dout1[i][DATA_WIDTH+IDX_WIDTH-1:DATA_WIDTH];
        assign rleaf_idx_1[i] = dout1[i][DATA_WIDTH+IDX_WIDTH+LEAF_ADDRW-1:DATA_WIDTH+IDX_WIDTH];
    end
    endgenerate

endmodule
