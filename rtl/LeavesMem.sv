module LeavesMem
#(
    parameter DATA_WIDTH = 11,
    parameter IDX_WIDTH = 9,
    parameter LEAF_SIZE = 8,
    parameter PATCH_SIZE = 5,
    parameter NUM_LEAVES = 64,
    parameter LEAF_ADDRW = $clog2(NUM_LEAVES)
)
(
    input logic clk,

    input logic [LEAF_SIZE-1:0]                         csb0,
    input logic [LEAF_SIZE-1:0]                         web0,
    input logic [LEAF_ADDRW-1:0]                        addr0,
    input logic [PATCH_SIZE*DATA_WIDTH+IDX_WIDTH-1:0]   wleaf0,
    output logic [63:0] [LEAF_SIZE-1:0]                 rleaf0,  // for wishbone
    output logic [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]      rpatch_data0 [LEAF_SIZE-1:0],
    output logic [IDX_WIDTH-1:0]                        rpatch_idx0 [LEAF_SIZE-1:0],
    input logic                                         csb1,
    input logic [LEAF_ADDRW-1:0]                        addr1,
    output logic [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]      rpatch_data1 [LEAF_SIZE-1:0],
    output logic [IDX_WIDTH-1:0]                        rpatch_idx1 [LEAF_SIZE-1:0]
);

    logic [7:0] ram_addr0;
    logic [7:0] ram_addr1;
    logic [63:0] rdata0 [LEAF_SIZE-1:0];
    logic [63:0] rdata1 [LEAF_SIZE-1:0];

    assign ram_addr0 = {'0, addr0};
    assign ram_addr1 = {'0, addr1};
    
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
            .csb0(csb0[i]),
            .web0(web0[i]),
            .addr0(ram_addr0),
            .din0(wleaf0),
            .dout0(rdata0[i]),
            .clk1(clk),
            .csb1(csb1),
            .addr1(ram_addr1),
            .dout1(rdata1[i])
        );

        assign rpatch_data0[i] = rdata0[i][PATCH_SIZE*DATA_WIDTH-1:0];
        assign rpatch_idx0[i] = rdata0[i][63:PATCH_SIZE*DATA_WIDTH];
        assign rpatch_data1[i] = rdata1[i][PATCH_SIZE*DATA_WIDTH-1:0];
        assign rpatch_idx1[i] = rdata1[i][63:PATCH_SIZE*DATA_WIDTH];
        assign rleaf0[i] = rdata0[i];
    end
    endgenerate

endmodule