module kBestArrays #(
    parameter DATA_WIDTH = 32,
    parameter IDX_WIDTH = 9,
    parameter K = 4,
    parameter NUM_LEAVES = 64,
    parameter LEAF_ADDRW = $clog2(NUM_LEAVES)
)
(
    input                                               clk,
    input logic                                         csb0,
    input logic                                         web0,
    input logic [7:0]                                   addr0,
    input logic [DATA_WIDTH-1:0]                        wdata0 [K-1:0],
    output logic [DATA_WIDTH-1:0]                       rdata0 [K-1:0],
    input logic [K-1:0]                                 csb1,
    input logic [7:0]                                   addr1,
    output logic [DATA_WIDTH-1:0]                       rdata1 [K-1:0]
);

    logic [DATA_WIDTH-1:0] dout0 [K-1:0];
    logic [DATA_WIDTH-1:0] dout1 [K-1:0];
    // stores results of 2 computes at the same address 
    // {compute1 leafidx, compute1 idx, compute0 leafidx, compute0 idx}
    genvar i;
    generate
    for (i=0; i<K; i=i+1) begin : loop_best_array_gen
        sram_1kbyte_1rw1r
        #(
            .DATA_WIDTH(DATA_WIDTH), // round(PATCH_SIZE * DATA_WIDTH)
            .ADDR_WIDTH(8),
            .RAM_DEPTH(256) // NUM_PATCHES
        ) best_dist_array_inst (
            .clk0(clk),
            .csb0(csb0),
            .web0(web0),
            .addr0(addr0),
            .din0(wdata0[i]),
            .dout0(dout0[i]),
            .clk1(clk),
            .csb1(csb1[i]),
            .addr1(addr1),
            .dout1(dout1[i])
        );
        assign rdata0[i] = dout0[i];
        assign rdata1[i] = dout1[i];
    end
    endgenerate

endmodule