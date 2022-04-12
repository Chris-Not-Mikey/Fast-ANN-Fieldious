module LeavesMem
#(
    parameter DATA_WIDTH = 11,
    parameter LEAF_SIZE = 8,
    parameter PATCH_SIZE = 5,
    parameter NUM_LEAVES = 64,
    parameter ADDR_WIDTH = $clog2(NUM_LEAVES)
)
(
    input logic clk,

    input logic                                       csb0,
    input logic                                       web0,
    input logic [ADDR_WIDTH-1:0]                      addr0,
    input logic [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]     wleaf0 [LEAF_SIZE-1:0],
    output logic  [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]   rleaf0 [LEAF_SIZE-1:0],
    input logic                                       csb1,
    input logic [ADDR_WIDTH-1:0]                      addr1,
    output logic  [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]   rleaf1 [LEAF_SIZE-1:0]
);

    logic [63:0] wdata0 [LEAF_SIZE-1:0];
    logic [63:0] rdata0 [LEAF_SIZE-1:0];
    logic [63:0] rdata1 [LEAF_SIZE-1:0];

    genvar i;
    generate
    for (i=0; i<LEAF_SIZE; i=i+1) begin : loop_ram_patch_gen
        sram_1kbyte_1rw1r
        #(
            .DATA_WIDTH(64), // round(PATCH_SIZE * DATA_WIDTH)
            .ADDR_WIDTH(8),
            .RAM_DEPTH(256) // NUM_LEAVES
        ) ram_patch_inst (
            .clk0(clk),
            .csb0(csb0),
            .web0(web0),
            .addr0({2'b0, addr0}),
            .din0(wdata0[i]),
            .dout0(rdata0[i]),
            .clk1(clk),
            .csb1(csb1),
            .addr1({2'b0, addr1}),
            .dout1(rdata1[i])
        );

        assign wdata0[i] = {'0, wleaf0[i]};
        assign rleaf0[i] = rdata0[i][PATCH_SIZE*DATA_WIDTH-1:0];
        assign rleaf1[i] = rdata1[i][PATCH_SIZE*DATA_WIDTH-1:0];
    end
    endgenerate

endmodule