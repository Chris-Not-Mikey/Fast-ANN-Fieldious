// TB to verify async_fifo
//source: https://github.com/Jagannaths3/async_fifo/blob/master/async_fifo_tb.v

`default_nettype none
`timescale 1ps/1ps

module async_fifo_tb ();

parameter DSIZE = 8;
parameter ASIZE = 4;
parameter WCLK_PERIOD = 10;
parameter RCLK_PERIOD = 40;

reg wreq, wclk, wrst_n, rreq, rclk, rrst_n;
reg [DSIZE-1:0] wdata;
wire [DSIZE-1:0] rdata;
wire wfull, rempty;

// Instance
async_fifo 
#(     
    .DSIZE(DSIZE),
    .ASIZE(ASIZE)
)
u_async_fifo
(
    .wreq (wreq), .wrst_n(wrst_n), .wclk(wclk),
    .rreq(rreq), .rclk(rclk), .rrst_n(rrst_n),
    .wdata(wdata), .rdata(rdata), .wfull(wfull), .rempty(rempty)
);

initial begin
    wrst_n = 0;
    wclk = 0;
    wreq = 0;
    wdata = 0;
    repeat (2) #(WCLK_PERIOD/2) wclk = ~wclk;
    wrst_n = 1;
    forever #(WCLK_PERIOD/2) wclk = ~wclk;
end

initial begin
    rrst_n = 0;
    rclk = 0;
    rreq = 0;
    repeat (2) #(RCLK_PERIOD/2) rclk = ~rclk;
    rrst_n = 1;
    forever  #(RCLK_PERIOD/2) rclk = ~rclk;
end

initial 
  begin
    $dumpfile("dump.vcd"); 
    $dumpvars;
end  


initial begin
    repeat (4) @ (posedge wclk);
     @(negedge wclk); wreq = 1;wdata = 8'd1;
     @(negedge wclk); wreq = 1;wdata = 8'd2;
     @(negedge wclk); wreq = 1;wdata = 8'd3;
     @(negedge wclk); wreq = 1;wdata = 8'd4;
     @(negedge wclk); wreq = 1;wdata = 8'd5;
     @(negedge wclk); wreq = 1;wdata = 8'd6;
     @(negedge wclk); wreq = 1;wdata = 8'd7;
     @(negedge wclk); wreq = 1;wdata = 8'd8;
     @(negedge wclk); wreq = 1;wdata = 8'd9;
     @(negedge wclk); wreq = 1;wdata = 8'd10;
     @(negedge wclk); wreq = 1;wdata = 8'd11;
     @(negedge wclk); wreq = 1;wdata = 8'd12;
     @(negedge wclk); wreq = 1;wdata = 8'd13;
     @(negedge wclk); wreq = 1;wdata = 8'd14;
     @(negedge wclk); wreq = 1;wdata = 8'd15;
     @(negedge wclk); wreq = 1;wdata = 8'd16;
     @(negedge wclk); wreq = 0;

     @(negedge rclk); rreq = 1;
     repeat (17) @(posedge rclk);
     rreq=0;

     #100;
     $finish;
end

endmodule
