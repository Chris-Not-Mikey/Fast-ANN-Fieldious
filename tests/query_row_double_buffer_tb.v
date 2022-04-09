`define DATA_WIDTH 11
`define FETCH_WIDTH 1
`define DSIZE 11
`define ASIZE 4
`define ADDRESS_WIDTH 7
`define DEPTH 128
`define RAM_WIDTH 11


module query_row_double_buffer_tb;

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


  // Async Fifo Stuff
  logic [`DSIZE-1:0] rdata;
  logic wfull;
  logic rempty;
  logic [`DSIZE-1:0] wdata;
  logic winc, wclk, wrst_n;
  logic rinc, rrst_n;

  // RAM Stuff
  logic ren;
  logic [`ADDRESS_WIDTH -1:0] radr;
  logic [`RAM_WIDTH-1:0] ram_output;
  logic [1:0] read_latency_counter; 
  logic  [`FETCH_WIDTH * `DATA_WIDTH - 1 : 0] expected_ram_dout;
  
  always #10 clk =~clk; //Conceptually, rlck = clk (read clock is normal clock
  always #30 wclk =~wclk;
  
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

  
  async_fifo1 #(
    .DSIZE(`DSIZE),
    .ASIZE(`ASIZE)
  )
  dut (
    
    .winc(fifo_enq), .wclk(wclk), .wrst_n(wrst_n),
    .rinc(fifo_deq), .rclk(clk), .rrst_n(rrst_n),
    .wdata(wdata),
    .rdata(rdata),
    .wfull(wfull),
    .rempty(rempty)
    
  );


 query_row_double_buffer
 #(
  .DATA_WIDTH(`RAM_WIDTH), 
  .ADDR_WIDTH(`ADDRESS_WIDTH),
  .DEPTH(`DEPTH)
 )
 query_dut(
  .clk(clk),
  .rst_n(rst_n),
  .fsm_enable(1), //based on whether we are at the proper I/O portion
  .sender_enable(receiver_enq),
  .ren(ren),
  .radr(radr),
  .sender_data(receiver_din),
  .receiver_data(ram_output)  

);


  initial begin

    //RAM Stuff
    ren = 1'b0;
    radr = 0;
    read_latency_counter = 2'b0;
    expected_ram_dout = 0;

    winc = 1'b0;
    iseven = 2'b10;
    wdata = '0;
    wrst_n = 1'b0;
    rst_n = 1'b0;
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
    #20 
    receiver_full_n <= 1;
    #20

 
    fifo_valid <=1;
  end

    //comment
  assign fifo_enq = wrst_n && (!wfull) && (!stall);
  assign even = (iseven == 2'b10) || (iseven == 2'b00);

  always @ (posedge clk) begin
       
	#1 
	iseven <= (iseven == 2'b10) ? 2'b00: iseven+2'b01; 
  end

  always @ (posedge clk) begin
  if (even) begin
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
  end

  genvar i;
  generate
    for (i = 0; i < `FETCH_WIDTH; i++) begin
     always @ (negedge clk) begin
      if (receiver_enq && even ) begin
          assert(receiver_din[(i + 1)*`DATA_WIDTH - 1 : i * `DATA_WIDTH] == expected_dout + i);
          $display("%t: received = %d, expected = %d", $time, 
            receiver_din[(i + 1)*`DATA_WIDTH - 1 : i * `DATA_WIDTH], expected_dout + i);
        end
      end
    end
  endgenerate
 
  always @ (negedge clk) begin
   if (receiver_enq && even) begin
      expected_dout <= expected_dout + `FETCH_WIDTH;
    end 
  end


  always @ (negedge clk) begin
  if (receiver_enq && even) begin
      ren <= 1;
      read_latency_counter <= 0;
    end 
    if (ren) begin
        if (read_latency_counter == 2'b01) begin
	     ren <= 0;
	     radr <= radr + 1;
	     expected_ram_dout <= expected_ram_dout + 1;
	     assert(ram_output == expected_ram_dout);
	     $display("%t: received = %d,  expected = %d", $time, ram_output, expected_ram_dout);
        end
	else begin
	    ren <= 1;
      	    read_latency_counter <= read_latency_counter + 1;
		
	end
      

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
