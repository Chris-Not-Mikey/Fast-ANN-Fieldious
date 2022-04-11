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

    input                                       wen,
    input [ADDR_WIDTH-1:0]                      wadr,
    input [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]     wdata [LEAF_SIZE-1:0],
    input                                       ren,
    input [ADDR_WIDTH-1:0]                      radr,
    output [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]    rdata [LEAF_SIZE-1:0]
);


    genvar i;
    generate
    for (i=0; i<LEAF_SIZE; i=i+1) begin : loop_ram_patch_gen
        ram_sync_1r1w
        #(
            .DATA_WIDTH(DATA_WIDTH * PATCH_SIZE),
            .ADDR_WIDTH(ADDR_WIDTH),
            .DEPTH(NUM_LEAVES)
        ) ram_patch_inst (
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