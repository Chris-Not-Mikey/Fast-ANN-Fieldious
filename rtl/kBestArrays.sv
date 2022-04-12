module kBestArrays #(
    parameter DATA_WIDTH = 11,
    parameter K = 4
)
(
    input                                               clk,
    input logic                                         csb0,
    input logic                                         web0,
    input logic [7:0]                                   addr0,
    input logic [DATA_WIDTH-1:0]                        wdist_0 [K-1:0],
    input logic [8:0]                                   windices_0 [K-1:0],
    output logic [DATA_WIDTH-1:0]                       rdist_0 [K-1:0],
    output logic [8:0]                                  rindices_0 [K-1:0],
    input logic                                         csb1,
    input logic [7:0]                                   addr1,
    output logic [DATA_WIDTH-1:0]                       rdist_1 [K-1:0],
    output logic [8:0]                                  rindices_1 [K-1:0]
);

    logic [31:0] dout0 [K-1:0];
    logic [31:0] dout1 [K-1:0];
    genvar i;
    generate
    for (i=0; i<K; i=i+1) begin : loop_best_array_gen
        sky130_sram_1kbyte_1rw1r_32x256_8 best_dist_array_inst (
            .clk0(clk),
            .csb0(csb0),
            .web0(web0),
            .wmask0(4'hF),
            .addr0(addr0),
            .din0({12'b0, windices_0[i], wdist_0[i]}),
            .dout0(dout0[i]),
            .clk1(clk),
            .csb1(csb1),
            .addr1(addr1),
            .dout1(dout1[i])
        );
        assign rdist_0[i] = dout0[i][DATA_WIDTH-1:0];
        assign rindices_0[i] = dout0[i][DATA_WIDTH+8:DATA_WIDTH];
        assign rdist_1[i] = dout1[i][DATA_WIDTH-1:0];
        assign rindices_1[i] = dout1[i][DATA_WIDTH+8:DATA_WIDTH];
    end
    endgenerate

endmodule