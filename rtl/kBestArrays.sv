module kBestArrays #(
    parameter DATA_WIDTH = 11,
    parameter K = 4,
)
(
    input                                               clk,
    input                                               rst_n,
    input                                               wen,
    input [7:0]                                         waddr, // idx of the row, matches the ram addr width
    input [DATA_WIDTH-1:0]                              l2_dist_in [K-1:0],
    input [8:0]                                         indices_in [K-1:0],
    input                                               ren,
    input [7:0]                                         raddr,
    output [DATA_WIDTH-1:0]                             l2_dist_out [K-1:0],
    output [8:0]                                        indices_out
);

    logic [31:0] rdata [K-1:0];
    genvar i;
    generate
    for (i=0; i<K; i=i+1) begin : loop_best_array_gen
        sram_1kbyte_1rw1r best_dist_array_inst (
            .clk0(clk),
            .csb0(~best_wen),
            .web0(1'b0),
            .addr0(query_idx),
            .din0({'0, best_indices_in[i], best_l2_dist_in[i]}),
            .dout0(),
            .clk1(clk),
            .csb1(~best_ren),
            .addr1(raddr),
            .dout1(rdata[i])
        );
        l2_dist_out[i] = rdata[i][DATA_WIDTH-1:0];
        l2_indices_out[i] = rdata[i][DATA_WIDTH+8:DATA_WIDTH];
    end
    endgenerate

endmodule