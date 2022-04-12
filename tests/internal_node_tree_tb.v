`define DATA_WIDTH 55
`define STORAGE_WIDTH 22
`define ADDRESS_WIDTH 8
`define DSIZE 11
`define ASIZE 4
`define FETCH_WIDTH 2
`define NULL 0  


module internal_node_tree_tb;

  reg clk;
  reg rst_n;


  wire fifo_deq;
  wire [`FETCH_WIDTH * `DSIZE - 1 : 0] receiver_din;
  reg receiver_full_n;
  wire receiver_enq;

  wire fifo_enq;

  reg stall;
  reg fifo_valid; 

  reg [1:0] iseven;
  wire even;



  reg [`STORAGE_WIDTH -1 : 0] sender_data;
  reg [`DATA_WIDTH - 1 : 0] patch_in;
  wire [`DATA_WIDTH - 1 : 0] patch_out; //Same patch, but we will be pipeling so it will be useful to adopt this input/ouput scheme
 


  // Async Fifo Stuff
  logic [`DSIZE-1:0] rdata;
  logic wfull;
  logic rempty;
  logic [`DSIZE-1:0] wdata;
  logic winc, wclk, wrst_n;
  logic rinc, rrst_n;


  //Tree specific things
  wire [`ADDRESS_WIDTH-1:0] leaf_index;
  reg fsm_enable;
  reg sender_enable;

  //File I/O Stuff
  integer               data_file    ; // file handler
  integer               scan_file    ; // file handler
  logic   signed [`DSIZE-1:0] captured_data;


  always #10 clk =~clk;
  always #10 wclk =~wclk;
	
  reg invalid;

  aggregator
  #(
    .DATA_WIDTH(`DSIZE),
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


  internal_node_tree
  #(
   .INTERNAL_WIDTH(`STORAGE_WIDTH),
   .PATCH_WIDTH(`DATA_WIDTH),
   .ADDRESS_WIDTH(`ADDRESS_WIDTH)
  ) tree_dut (
  .clk(clk),
  .rst_n(rst_n),
  .fsm_enable(fsm_enable), //based on whether we are at the proper I/O portion
  .sender_enable(receiver_enq),
  .sender_data(receiver_din),
  .patch_in(patch_in),
  .leaf_index(leaf_index)
  );


initial begin
  data_file = $fopen("./data/IO_data/internalNodes.txt", "r");
  if (data_file == `NULL) begin
    $display("data_file handle was NULL");
    $finish;
  end
  

  scan_file = $fscanf(data_file, "%d\n", wdata[10:0]); 
	
	
end



   initial begin
    clk <= 0;
    wclk <= 0;
    stall <= 0;
    rst_n <= 0;
    wdata <= 0;
    patch_in <= 0;
    fsm_enable <= 0;
    sender_enable <= 0;
    receiver_full_n <=0;
    invalid <= 0;

 
    wrst_n <= 1'b0;
    rrst_n <= 1'b0;
   

    #40 rst_n <= 1;
    wrst_n <= 1'b1;
    rrst_n <= 1'b1;
    receiver_full_n <=1;
    fsm_enable <= 1;
	   
    #5100
     fsm_enable <= 0; //Turn off to stop overwriting data
    patch_in <= 55'b0000000001100000000011000000000110000000000100000000011;
	   
	   
    #300
    // Expected Index: 63
    // Patch: [251. -26.  -1. -88.  79.]
    patch_in <= 55'b0001111101111111100110111111111111111010100000001001111;
    #300
    assert(7'd63 == leaf_index);
    $display("%t: received = %d, expected = %d", $time, leaf_index, 7'd63);
    fsm_enable <= 0; //Turn off to stop overwriting data
	   
    //63
    //[279. -18. -55. -22.  18.]
    patch_in <= 55'b0010001011111111101110111110010011111110101000000010010;
    #300
    assert(7'd63 == leaf_index);
    $display("%t: received = %d, expected = %d", $time, leaf_index, 7'd63);
	   
	   
     // 5
     // [ -72. -213.  201.   45.  235.]
    patch_in <= 55'b1111011100011100101011000110010010000010110100011101011;
    #300
    assert(7'd5 == leaf_index);
    $display("%t: received = %d, expected = %d", $time, leaf_index, 7'd5);
	   
	   
     // 5
     // [-245. -199.   45.   58.  177.]
    patch_in <= 55'b11100001011111001110010000010110100000111010 00010110001;
    #300
    assert(7'd5 == leaf_index);
    $display("%t: received = %d, expected = %d", $time, leaf_index, 7'd5);
	   
    
	// 4
	// [ -50.  -64. -298.  245. -141.]
     patch_in <= 1111100111011111000000110110101100001111010111101110011;  
     #300
     assert(7'd4 == leaf_index);
     $display("%t: received = %d, expected = %d", $time, leaf_index, 7'd4);
     
	   
   
	   

    // //Index 1, Median 2
    // wdata <= 22'b0000000001000000000001;
    // fsm_enable <= 1;
    // sender_enable <= 1;

    // #20
    // wdata <= 22'b0000000001000000000011;
    // sender_enable <= 1;
     
    // #20
    // sender_enable <= 0;

   end

  assign fifo_enq = wrst_n && (!wfull) && (!stall);
	

  always @ (posedge clk) begin
 
    //Into FIFO
	  if (wrst_n) begin
	    stall <= $urandom % 2;
	    receiver_full_n <= 1;
	    if (fifo_enq) begin
	       //scan_file = $fscanf(data_file, "%d\n", captured_data); 
		    
          reg [21:0] temp_capture;
          //Read Data from  I/O
          scan_file = $fscanf(data_file, "%d\n", temp_capture[10:0]); 
	  wdata <= temp_capture[10:0];
          //Prepare to send to FIFO
          if (!$feof(data_file)) begin
            //use captured_data as you would any other wire or reg value;
            invalid <= 1;
	   
          end
	     end
	  end
  end


  //Into of KD Tree and check
  always @ (posedge clk) begin
  
  if (receiver_enq) begin
      invalid <= 1;
  end
//   if (invalid) begin
// 	  #50
// 	  fsm_enable <= 0;
//   end
 

    //   ren <= 1;
    //   read_latency_counter <= 0;
   // end 
    // if (ren) begin
    //     //NOTE RAM read has a one cycle latency, so we make a counter to handle this difference
    //   if (1) begin
	   
	//      //Read from cannonical data. Output of RAM should match
    //    //IMPORTANT: To test other than 2 11 bit values aggregated, one must MANUALLY CHANGE the below
	//      reg [21:0] hold_expected;
	//       expected_scan_file = $fscanf(expected_data_file, "%d\n", hold_expected[10:0]); 

		
	//       expected_scan_file = $fscanf(expected_data_file, "%d\n", hold_expected[21:11]); 

    //     if (!$feof(data_file)) begin
    //       ren <= 0;
    //       radr <= radr + 1;
    //       assert(ram_output == hold_expected);
    //       $display("%t: received = %d, expected = %d", $time, ram_output, hold_expected);
    //       $display("%t: received = %d, expected = %d", $time, ram_output[10:0], hold_expected[10:0]);
    //       $display("%t: received = %d, expected = %d", $time, ram_output[21:11], hold_expected[21:11]);
          
    //     end
		
    //   end
    //   else begin 
    //       ren <= 1; //Handling one cycle latency
    //       read_latency_counter <= read_latency_counter + 1;
    //   end
      
  end



    initial begin
      $dumpfile("dump.vcd");
      $dumpvars;

      #20000;
      $finish(2);
    end
     
endmodule
