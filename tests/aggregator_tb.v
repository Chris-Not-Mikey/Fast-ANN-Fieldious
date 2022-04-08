`define DATA_WIDTH 11
`define FETCH_WIDTH 2
`define DSIZE 11
`define ASIZE 3

module aggregator_tb;

  reg clk;
  reg rst_n;
  wire [`DATA_WIDTH - 1 : 0] fifo_dout;
  wire fifo_empty_n;
  wire fifo_deq;
  wire [`FETCH_WIDTH * `DATA_WIDTH - 1 : 0] receiver_din;
  reg  [`FETCH_WIDTH * `DATA_WIDTH - 1 : 0] expected_dout;
  reg receiver_full_n;
  wire receiver_enq;
  reg [`DATA_WIDTH - 1 : 0] fifo_din;
  wire fifo_enq;
  wire fifo_full_n;
  reg stall;
  reg fifo_valid;

   
  logic [`DSIZE-1:0] rdata;
  logic wfull;
  logic rempty;
  logic [`DSIZE-1:0] wdata;
  logic winc, wclk, wrst_n;
  logic rinc, rrst_n;
  
  
  always #20 clk =~clk;
  always #20 wclk =~wclk;
  
  aggregator
  #(
    .DATA_WIDTH(`DATA_WIDTH),
    .FETCH_WIDTH(`FETCH_WIDTH)
  ) aggregator_inst
  (
    .clk(clk),
    .rst_n(rst_n),
    .sender_data(rdata),
    .sender_empty_n(!rempty),
    .sender_deq(fifo_deq),
    .receiver_data(receiver_din),
    .receiver_full_n(receiver_full_n),
    .receiver_enq(receiver_enq)
  );



//   async_fifo 
//   #(     
//       .DSIZE(`DSIZE),
//       .ASIZE(`ASIZE)
//   )
//   u_async_fifo
//   ( 
//       .valid(fifo_valid),
//       .wreq (fifo_enq), .wrst_n(wrst_n), .wclk(wclk),
//       .rreq(fifo_deq), .rclk(clk), .rrst_n(rrst_n),
//       .wdata(wdata), .rdata(rdata), .wfull(wfull), .rempty(rempty)
//   );
  
  async_fifo1 #(
    .DSIZE(`DSIZE),
    .ASIZE(`ASIZE)
  )
  dut (
    
    .winc(winc), .wclk(wclk), .wrst_n(wrst_n),
    .rinc(rinc), .rclk(clk), .rrst_n(rrst_n),
    .wdata(wdata),
    .rdata(rdata),
    .wfull(wfull),
    .rempty(rempty)
    
  );

  initial begin
    clk <= 0;
    wclk <= 0;
    wreq <= 0;
    rreq <= 0;
    wdata <= 0;
    

    fifo_valid <=0;
    rst_n <= 0;
    rrst_n <= 0;
    wrst_n <=0;
    stall <= 0; 
    expected_dout <= 0;
    receiver_full_n <= 0;
    #20 rst_n <= 0;
    rrst_n <= 0;
    wrst_n <= 0;
    receiver_full_n <= 1;
    #20 rst_n <= 1;
    rrst_n <= 1;
    wrst_n <= 1;
    fifo_valid <=1;
  end

    //comment
  assign fifo_enq = wrst_n && (!wfull) && (!stall);

  always @ (posedge clk) begin
    if (wrst_n) begin
      stall <= $urandom % 2;
      receiver_full_n <= 1;
      if (fifo_enq) begin
        wdata <= wdata + 1;
      end
    end else begin
      wdata <= 0;
    end
  end

  genvar i;
  generate
    for (i = 0; i < `FETCH_WIDTH; i++) begin
      always @ (posedge clk) begin
        if (receiver_enq) begin
          assert(receiver_din[(i + 1)*`DATA_WIDTH - 1 : i * `DATA_WIDTH] == expected_dout + i);
          $display("%t: received = %d, expected = %d", $time, 
            receiver_din[(i + 1)*`DATA_WIDTH - 1 : i * `DATA_WIDTH], expected_dout + i);
        end
      end
    end
  endgenerate

  always @ (posedge clk) begin
    if (receiver_enq) begin
      expected_dout <= expected_dout + `FETCH_WIDTH;
    end 
  end

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
//     $vcdplusmemon();
//     $vcdpluson(0, aggregator_tb);
    #2000;
    $finish(2);
  end

endmodule
