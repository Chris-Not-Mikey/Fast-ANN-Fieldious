module ResetMux(
                select,
                rst0,
                rst1,
                out_rst
               ) ;

    input            select;
    input            rst0;
    input            rst1;
    output           out_rst;

    assign out_rst = select ?rst1 :rst0;
endmodule