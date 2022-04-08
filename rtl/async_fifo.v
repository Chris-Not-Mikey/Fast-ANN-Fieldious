// Asynchronous memory with gray code pointer exchange
// 2^n depth supported
// Source: https://github.com/Jagannaths3/async_fifo/blob/master/async_fifo.v

`default_nettype none
`timescale 1ps/1ps

module async_fifo #(
    parameter DSIZE = 8,
    parameter ASIZE = 4
) (
    input   valid,
    input   wreq, wclk, wrst_n,
    input   rreq, rclk, rrst_n,
    input   [DSIZE-1:0] wdata,
    output  [DSIZE-1:0] rdata,
    output  reg wfull,
    output  reg rempty
);

reg     [ASIZE:0]   wq2_rptr, wq1_rptr, rptr;
reg     [ASIZE:0]   rq2_wptr, rq1_wptr, wptr;
wire    rempty_val;
wire    [ASIZE : 0] rptr_nxt;
wire    [ASIZE-1:0] raddr;
reg     [ASIZE:0] rbin;
wire    [ASIZE:0] rbin_nxt;
wire    [ASIZE-1:0] waddr;
reg     [ASIZE:0] wbin;
wire    [ASIZE:0] wbin_nxt;
wire    [ASIZE : 0] wptr_nxt;

// synchronizing rptr to wclk
always @(posedge wclk or negedge wrst_n) begin
    if(!wrst_n)
        {wq2_rptr, wq1_rptr} <= 2'b0;
    else
        {wq2_rptr, wq1_rptr} <= {wq1_rptr, rptr};
end

// synchronizing wptr to rclk
always @(posedge rclk or negedge rrst_n) begin
    if(!rrst_n)
        {rq2_wptr, rq1_wptr} <= 2'b0;
    else
        {rq2_wptr, rq1_wptr} <= {rq1_wptr, wptr};
end

// generating rempty condition
//reg     rempty;
assign  rempty_val = (rptr_nxt == rq2_wptr); 

always @(posedge rclk or negedge rrst_n) begin
    if(!rrst_n)
        rempty <= 1'b0;
    else
        rempty <= rempty_val;
end

// generating read address for fifomem
assign rbin_nxt = rbin + (rreq & ~rempty);

always @ (posedge rclk or negedge rrst_n) 
    if (!rrst_n)
        rbin <= 0;
    else 
        rbin <= rbin_nxt;
assign raddr = rbin[ASIZE-1:0]; 

// generating rptr to send to wclk domain
// convert from binary to gray
assign rptr_nxt = rbin_nxt ^ (rbin_nxt>>1);

always @ (posedge rclk or negedge rrst_n)
    if (!rrst_n)
        rptr <= 0;
    else 
        rptr <= rptr_nxt;

// generating write address for fifomem
assign wbin_nxt = wbin + (wreq & valid & !wfull);

always @ (posedge wclk or negedge wrst_n)
    if(!wrst_n)
        wbin <= 0;
    else
        wbin <= wbin_nxt;

assign waddr = wbin [ASIZE-1:0];

// generating wptr to send to rclk domain
// convert from binary to gray
assign wptr_nxt = (wbin_nxt>>1) ^ wbin_nxt; 

always @ (posedge wclk or negedge wrst_n)
    if(!wrst_n)
        wptr <= 0;
    else
        wptr <= wptr_nxt;

// generate wfull condition
wire wfull_val;
assign wfull_val = (wq2_rptr == {~wptr[ASIZE : ASIZE-1],wptr[ASIZE-2 : 0]});

always @ (posedge wclk or negedge wrst_n)
    if (!wrst_n)
        wfull <= 0;
    else 
        wfull <= wfull_val;

// fifomem
// Using Verilog memory model
localparam DEPTH = (1 << (ASIZE));
reg [DSIZE-1 : 0] mem [0: DEPTH -1];

assign rdata = mem[raddr];

always @ (posedge wclk)
    if (wreq & valid & !wfull) mem[waddr] <= wdata;

endmodule
