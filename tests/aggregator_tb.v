`define DATA_WIDTH 8
`define FETCH_WIDTH 2
`define DSIZE 8
`define ASIZE 4

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

  reg [1:0] iseven;
  wire even;
	
  reg [2:0] local_fetch_width;
  reg change_fetch_width;
	
	


  logic [`DSIZE-1:0] rdata;
  logic wfull_n;
  logic rempty_n;
  logic [`DSIZE-1:0] wdata;
  logic winc, wclk, wrst_n;
  logic rinc, rrst_n;
	
  
  
  
  always #6.66666667 clk =~clk; //Conceptually, rlck = clk (read clock is normal clock
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
    .sender_empty_n(rempty_n),
    .sender_deq(fifo_deq),
    .receiver_data(receiver_din),
    .receiver_full_n(receiver_full_n),
    .receiver_enq(receiver_enq),
    .change_fetch_width(change_fetch_width),
    .input_fetch_width(local_fetch_width)
  );

 
	
 SyncFIFO #(`DATA_WIDTH, 4, 2)
  dut (
   
    .sCLK(wclk),
    .sRST(wrst_n),
    .dCLK(clk),
    .sENQ(fifo_enq),
    .sD_IN(wdata),
    .sFULL_N(wfull_n),
    .dDEQ(fifo_deq),
    .dD_OUT(rdata),
    .dEMPTY_N(rempty_n)
  
  );

  initial begin
    winc = 1'b0;
    iseven = 2'b10;
    wdata = '0;
    wrst_n = 1'b0;
    rst_n = 1'b0;
    local_fetch_width = 2;
    change_fetch_width = 0;
	  
    repeat(5) @(posedge wclk);
    //#5
    wrst_n = 1'b1;
    rst_n = 1'b1;
    //iseven = 1'b0;
  end

  initial begin
    rinc = 1'b0;

    rrst_n = 1'b0;
    repeat(8) @(posedge clk);
    rrst_n = 1'b1;

  end




  initial begin
    clk <= 0;
    wclk <= 0;
    wdata <= 11'b0;
    

    fifo_valid <=0;
    //rst_n <= 0;
   
    stall <= 0; 
    expected_dout <= 11'b0;
    receiver_full_n <= 0;
    #20 //rst_n <= 0;
    receiver_full_n <= 1;
    #20 //rst_n <= 1;

 
    fifo_valid <=1;
  end

    //comment
  assign fifo_enq = wrst_n && (wfull_n) && (!stall);


  always @ (posedge clk) begin
    if (wrst_n) begin
      stall <= $urandom % 2;
      receiver_full_n <= 1;
      if (fifo_enq) begin
        wdata <= wdata + 11'b1;
      end
    end else begin
      wdata <= 0;
    end
  end

  genvar i;
  generate
    for (i = 0; i < `FETCH_WIDTH; i++) begin
      always @ (posedge clk) begin
        if (receiver_enq  ) begin
          assert(receiver_din[(i + 1)*`DATA_WIDTH - 1 : i * `DATA_WIDTH] == expected_dout + i);
          $display("%t: received = %d, expected = %d", $time, 
            receiver_din[(i + 1)*`DATA_WIDTH - 1 : i * `DATA_WIDTH], expected_dout + i);
        end
      end
    end
  endgenerate

always @ (posedge clk) begin
    if (receiver_enq ) begin
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
