module ClockMux (
    input select,
    input clk0,
    input clk1,
    output out_clk
);
    wire q_t0;
    wire q_t1;
    wire q_b0;
    wire q_b1;

    CW_ff #(1) t0
    (
        .CLK(clk1),
        .D(!q_b1 & select),
        .Q(q_t0)
    );

    CW_ff #(1) t1
    (
        .CLK(!clk1),
        .D(q_t0),
        .Q(q_t1)
    );

    CW_ff #(1) b0
    (
        .CLK(clk0),
        .D(!q_t1 & !select),
        .Q(q_b0)
    );

    CW_ff #(1) b1
    (
        .CLK(!clk0),
        .D(q_b0),
        .Q(q_b1)
    );

    assign out_clk = (clk1 & q_t1) | (clk0 & q_b1);

endmodule

module CW_ff(CLK,D,Q);
parameter wD=1;
input CLK;
input [wD-1:0] D;
output [wD-1:0] Q;
reg [wD-1:0] Q;
wire [wD-1:0] D2 = D;
always @(posedge CLK) Q <= D2;
endmodule