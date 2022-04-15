`define DATA_WIDTH 11
`define FETCH_WIDTH 6
`define DSIZE 11
`define PATCH_SIZE 5
`define ASIZE 4
`define ADDRESS_WIDTH 9
`define DEPTH 512
`define RAM_WIDTH 11
`define NULL 0   
`define STORAGE_WIDTH 22

// The difference between this testbench and query_row_double_buffer_tb is
// that this one uses REAL DATA generated by the gold model, whereas the  other
// testbnech simply uses data counted up from 0,1,2 ... N


module search_containing_leaf_tb;

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


  reg [2:0] read_latency_counter;
  reg [2:0] write_latency_counter;
  reg [`FETCH_WIDTH * `DATA_WIDTH - 1 : 0] expected_ram_dout;
  reg ren;
  reg wen;
  reg write_disable;

  //FSM stuff
  reg [2:0] i_o_state;


  //Aggregator Stuff
  reg change_fetch_width;
  reg [2:0] input_fetch_width;


  // Async Fifo Stuff
  logic [`DSIZE-1:0] rdata;
  logic wfull;
  logic rempty;
  logic [`DSIZE-1:0] wdata;
  logic winc, wclk, wrst_n;
  logic rinc, rrst_n;

  // RAM Stuff
  logic                                       csb0; //Write
  logic                                       web0;
  logic [`ADDRESS_WIDTH-1:0]                      addr0;
  logic [(`DATA_WIDTH*`PATCH_SIZE)-1:0]         wpatch0;
  logic  [(`DATA_WIDTH*`PATCH_SIZE)-1:0]       rpatch0;
  logic                                       csb1; //Read
  logic [`ADDRESS_WIDTH-1:0]                      addr1;
  logic  [(`DATA_WIDTH*`PATCH_SIZE)-1:0]       rpatch1;
	
  reg [`FETCH_WIDTH * `DATA_WIDTH - 1 : 0] receiver_din_storage;
	
  logic fsm_enable;


  //File I/O Stuff
  integer               data_file    ; // file handler
  integer               scan_file    ; // file handler
  logic   signed [`DSIZE-1:0] captured_data;
	
  integer               expected_data_file    ; // file handler
  integer               expected_scan_file    ; // file handler
  logic   signed [`DSIZE-1:0] expected_captured_data;
     
  
  always #6.66666667 clk =~clk; //Conceptually, rlck = clk (read clock is normal clock
  always #20 wclk =~wclk;
	
	
	
  
  aggregator
  #(
    .DATA_WIDTH(`DATA_WIDTH),
    .FETCH_WIDTH(6)
  ) aggregator_inst
  (
    .clk(clk),
    .rst_n(rst_n),
    .sender_data(rdata),
    .sender_empty_n(rempty),
    .sender_deq(fifo_deq),
    .receiver_data(receiver_din),
    .receiver_full_n(receiver_full_n),
    .receiver_enq(receiver_enq),
    .change_fetch_width(change_fetch_width),
    .input_fetch_width(input_fetch_width)
  );

  
  SyncFIFO #(`DATA_WIDTH, 16, 4)
    dut (
      .sCLK(wclk),
      .sRST(wrst_n),
      .dCLK(clk),
      .sENQ(fifo_enq),
      .sD_IN(wdata),
      .sFULL_N(wfull),
      .dDEQ(fifo_deq),
      .dD_OUT(rdata),
      .dEMPTY_N(rempty)
    );
	


  QueryPatchMem
  #(
    .DATA_WIDTH(`DATA_WIDTH),
    .PATCH_SIZE(`PATCH_SIZE),
    .ADDR_WIDTH(9),
    .DEPTH(512)
  ) query_mem_inst
  (
      .clk(clk),
      .csb0(csb0),
      .web0(web0),
      .addr0(addr0),
      .wpatch0(receiver_din_storage),
      .rpatch0(rpatch0),
      .csb1(csb1),
      .addr1(addr1),
      .rpatch1(rpatch1)
  );


   internal_node_tree
  #(
   .INTERNAL_WIDTH(`STORAGE_WIDTH),
   .PATCH_WIDTH(`DATA_WIDTH),
   .ADDRESS_WIDTH(`ADDRESS_WIDTH - 1)
  ) tree_dut (
  .clk(clk),
  .rst_n(rst_n),
  .fsm_enable(fsm_enable), //based on whether we are at the proper I/O portion
  .sender_enable(receiver_enq),
  .sender_data(receiver_din[21:0]),
  .patch_en(patch_en),
  .patch_in(patch_in),
  .leaf_index(leaf_index),
  .receiver_en(leaf_en)
	  
  );

initial begin

//   node_file = $fopen("./data/IO_data/internalNodes.txt", "r");
//   if (node_file == `NULL) begin
//     $display("data_file handle was NULL");
//     $finish;
//   end
  


  data_file = $fopen("./data/IO_data/nodes_patches.txt", "r");
  if (data_file == `NULL) begin
    $display("data_file handle was NULL");
    $finish;
  end
  
  expected_data_file = $fopen("./data/IO_data/expected_patches.txt", "r");
  if (expected_data_file == `NULL) begin
    $display("expected_data_file handle was NULL");
    $finish;
  end

  scan_file = $fscanf(data_file, "%d\n", wdata[10:0]); 
  //wdata[10:0] = captured_data; //11'b0; Let FILE handle provide data
	
  #20
	
  scan_file = $fscanf(data_file, "%d\n", wdata[10:0]); 
	
	
  // scan_file = $fscanf(data_file, "%d\n", wdata[21:11]); 
   //wdata[21:11] = captured_data; //11'b0; Let FILE handle provide data
	
	
end


 



  initial begin
    clk <= 0;
    wclk <= 0;
    fifo_valid <=0;
    rst_n <= 0;
    wrst_n = 1'b0;
    stall <= 0; 
    expected_dout <= 11'b0;
    receiver_full_n <= 0;
    read_latency_counter = 3'b0;
    write_latency_counter = 3'b0;
    expected_ram_dout = 0;
    ren = 0;
    wen = 0;
    write_disable = 0;
    receiver_din_storage = 0;
    wdata = 0;
    i_o_state = 0;
	  fsm_enable = 0;
	  
    //Agg
    change_fetch_width = 0;
    input_fetch_width = 3'd2;


    csb0 = 1; //Write
    web0 = 1;
    addr0 = 0;
    wpatch0 = 0;
    csb1 = 1; //Read
    addr1 = 0;


    #100 
    receiver_full_n <= 1;
    wrst_n = 1'b1;
    rst_n = 1'b1;
    change_fetch_width = 1;
    wdata <= 11'd251;
    #20
    change_fetch_width = 0;


    fifo_valid <=1;


    //Write to internal Tree
    #40 rst_n <= 1;
    input_fetch_width = 3'd2;
    change_fetch_width <= 1'b1;
    receiver_full_n <=1;
    fsm_enable <= 1;
	   
    // #10200
    // fsm_enable <= 0; //Turn off to stop overwriting data

	   
   
	//Write to Query Patch Memory

    #190000

    //Now read from memory
    addr0 <= 0;
    write_disable <= 1;
    #100
    ren <= 1;
    
    read_latency_counter <= 0;
	  
  end

  assign fifo_enq = wrst_n && (wfull) && (!stall);


  always @ (posedge wclk) begin
 
    //Into FIFO
	  if (wrst_n) begin
	    stall <= 20 % 2;
	    receiver_full_n <= 1;
	    if (fifo_enq) begin
	       //scan_file = $fscanf(data_file, "%d\n", captured_data); 
		    
          reg [21:0] temp_capture;
          //Read Data from  I/O
          scan_file = $fscanf(data_file, "%d\n", temp_capture[10:0]); 

          if (temp_capture == 11'b10000000000) begin  //Condition seperating I/O portions (don't read into FIFO)
              change_fetch_width <= 1;
              input_fetch_width <= 3'd5;
              i_o_state <= i_o_state + 1;
              fsm_enable <= 1'b0;

          end

          //Prepare to send to FIFO
          else if (!$feof(data_file)) begin
            //use captured_data as you would any other wire or reg value;
            change_fetch_width <= 0;
            wdata <= temp_capture[10:0];
            
          end
    
	     end
	  end
  end

	
  reg [54:0] hold_expected;

  //RAM and check
  always @ (posedge clk) begin
  //$display("%t: received = %d", $time, rpatch1);
  if (receiver_enq && !write_disable && (i_o_state == 3'b1)) begin //If aggregated 5, write to RAM
      web0 <= 1'b1; //active low
      csb0 <= 0; //Must activate to write as well
      wen <= 1;
      write_latency_counter <= 0;
     
      
    end 
	  
   if (wen && !write_disable) begin
	   
	   write_latency_counter <= write_latency_counter + 1;
	   if (write_latency_counter == 3'b01) begin
		    web0 <= 1'b0; 
		    receiver_din_storage <= receiver_din;
		    
		    wen <= 1;
		    //addr0 <= addr0 + 1;
	   end
	   
	   
	   if (write_latency_counter == 3'b10) begin
		    web0 <= 1'b1; 
		    wen <= 0;
		    addr0 <= addr0 + 1;
	   end

   end
	  
	 

   if (ren && (read_latency_counter != 3'b11)) begin
	    read_latency_counter <= read_latency_counter + 1;
	    
	    csb0 <= 0;
	    web0 <= 1'b1;
	   // $display("%t: received = %d", $time, rpatch0);
    end

	 else if (ren && (read_latency_counter == 3'b11)) begin 
	
	  ren <= 1;
	  addr0 <= addr0 + 1;
      read_latency_counter <= 0;
	  
	    
	    expected_scan_file = $fscanf(expected_data_file, "%d\n", hold_expected[10:0]); 
	    expected_scan_file = $fscanf(expected_data_file, "%d\n", hold_expected[21:11]); 
        expected_scan_file = $fscanf(expected_data_file, "%d\n", hold_expected[32:22]); 
	    expected_scan_file = $fscanf(expected_data_file, "%d\n", hold_expected[43:33]); 
        expected_scan_file = $fscanf(expected_data_file, "%d\n", hold_expected[54:44]); 
	 

	    if (!$feof(expected_data_file)) begin
		//ren <= 0;

            csb0 <= 0; //active low

            assert(rpatch0 == hold_expected);
            $display("%t: received = %d, expected = %d", $time, rpatch0, hold_expected);
            $display("%t: received = %d, expected = %d", $time, rpatch0[10:0], hold_expected[10:0]);
            $display("%t: received = %d, expected = %d", $time, rpatch0[21:11], hold_expected[21:11]);
            $display("%t: received = %d, expected = %d", $time, rpatch0[32:22], hold_expected[32:22]);
            $display("%t: received = %d, expected = %d", $time, rpatch0[43:33], hold_expected[43:33]);
            $display("%t: received = %d, expected = %d", $time, rpatch0[54:44], hold_expected[54:44]);

	     end
	   
     end

  end

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
//     $vcdplusmemon();
//     $vcdpluson(0, aggregator_tb);
    #290000;
    $finish(2);
  end

endmodule