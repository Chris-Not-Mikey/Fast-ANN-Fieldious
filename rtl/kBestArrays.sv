module kBestArrays #(
    parameter DATA_WIDTH = 11,
    parameter K = 4,
    // parameter LEAF_SIZE = 8,
    // parameter PATCH_SIZE = 5,
    parameter ROW_SIZE = 32, // 26, rounded to 2^n
    parameter NUM_LEAVES = 64,
)
(
    input                                               clk,
    input                                               rst_n,
    // TODO
    input                                               query_idx,
    input                                               best_wen,
    input [DATA_WIDTH-1:0]                              best_l2_dist_in [K-1:0],
    input [8:0]                                         best_indices_in [K-1:0],
    input                                               best_ren,
    output [8:0]                                        best_indices_out
);

    genvar i;
    generate
    for (i=0; i<K; i=i+1) begin : loop_best_array_gen
        ram_sync_1r1w
        #(
            .DATA_WIDTH(DATA_WIDTH),
            .ADDR_WIDTH(ADDR_WIDTH),
            .DEPTH(ROW_SIZE)
        ) best_dist_array_inst (
            .clk(clk),
            .wen(wen),
            .wadr(wadr),
            .wdata(wdata[i]),
            .ren(ren),
            .radr(radr),
            .rdata(rdata[i])
        );
    end
    endgenerate

endmodule