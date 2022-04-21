`define DATA_WIDTH 55
`define STORAGE_WIDTH 22
`define ADDRESS_WIDTH 8
`define DSIZE 11
`define ASIZE 4
`define FETCH_WIDTH 6
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
  reg [`DATA_WIDTH - 1 : 0] patch_two_in;

 


  // Async Fifo Stuff
  logic [`DSIZE-1:0] rdata;
  logic wfull;
  logic rempty;
  logic [`DSIZE-1:0] wdata;
  logic winc, wclk, wrst_n;
  logic rinc, rrst_n;
	
  //Aggregator Stuff
  reg change_fetch_width;
  reg [2:0] input_fetch_width;


  //Tree specific things
  wire [`ADDRESS_WIDTH-1:0] leaf_index;
  wire [`ADDRESS_WIDTH-1:0] leaf_index_two;
  wire leaf_en;
  wire leaf_two_en;
  reg patch_en;
  reg patch_two_en;
  
  reg fsm_enable;
  reg sender_enable;
  

  //File I/O Stuff
  integer               data_file    ; // file handler
  integer               scan_file    ; // file handler
  logic   signed [`DSIZE-1:0] captured_data;


  always #6.666667 clk =~clk;
  always #20 wclk =~wclk;
	
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
    .sender_empty_n(rempty),
    .sender_deq(fifo_deq),
    .receiver_data(receiver_din),
    .receiver_full_n(receiver_full_n),
    .receiver_enq(receiver_enq),
    .change_fetch_width(change_fetch_width),
    .input_fetch_width(input_fetch_width)
  );

  
//   async_fifo1 #(
//     .DSIZE(`DSIZE),
//     .ASIZE(`ASIZE)
//   )
//   dut (
    
//     .winc(fifo_enq), .wclk(wclk), .wrst_n(wrst_n),
//     .rinc(fifo_deq), .rclk(clk), .rrst_n(rrst_n),
//     .wdata(wdata),
//     .rdata(rdata),
//     .wfull(wfull),
//     .rempty(rempty)
    
//   );

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
  .sender_data(receiver_din[21:0]),
  .patch_en(patch_en),
  .patch_two_en(patch_two_en),
  .patch_in(patch_in),
   .patch_in_two(patch_two_in),
  .leaf_index(leaf_index),
  .leaf_index_two(leaf_index_two),
  .receiver_en(leaf_en),
  .receiver_two_en(leaf_two_en)
	  
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
    patch_two_in <= 0;
    fsm_enable <= 0;
    sender_enable <= 0;
    receiver_full_n <=0;
    invalid <= 0;
    patch_en <=0;
    patch_two_en <=0;
    change_fetch_width <= 0;
   input_fetch_width <= 3'd2;

 
    wrst_n <= 1'b0;
    rrst_n <= 1'b0;
   

    #40 rst_n <= 1;
    change_fetch_width <= 1'b1;
    wrst_n <= 1'b1;
    rrst_n <= 1'b1;
    receiver_full_n <=1;
    fsm_enable <= 1;
	   
    #21400
    fsm_enable <= 0; //Turn off to stop overwriting data
    patch_en <= 1;
    patch_in <= 55'b0000000001100000000011000000000110000000000100000000011;
    #20
    patch_en <= 0;
	   
	   
    #100
    // Expected Index: 59
    // Patch: [251. -26.  -1. -88.  79.]
    patch_en <= 1;
    patch_in <= 55'b0001111101111111100110111111111111111010100000001001111;
   // patch_in <= 55'b0000100111111110101000111111111111111110011000011111011;


    //Expected Index: 60
    //[279. -18. -55. -22.  18.]
    patch_two_en <= 1;
    patch_two_in <= 55'b0010001011111111101110111110010011111110101000000010010;
    //patch_two_in <= 55'b0000001001011111101010111110010011111110111000100010111;


    #20
    patch_en <= 0;
    patch_two_en <= 0;
	   
    #100
    assert(7'd59 == leaf_index);
    assert(7'd60 == leaf_index_two);
    $display("%t: received = %d, expected = %d", $time, leaf_index, 7'd59);
    $display("%t: received = %d, expected = %d", $time, leaf_index_two, 7'd60);
    fsm_enable <= 0; //Turn off to stop overwriting data
	   
  
    // #20
    // patch_en <= 0;
    // #100
    // assert(7'd60 == leaf_index);
    // $display("%t: received = %d, expected = %d", $time, leaf_index, 7'd60);
	   
	   
     // 22
     // [ -72. -213.  201.   45.  235.]
    patch_en <= 1;
    //patch_in <= 55'b11110111000 11100101011 00011001001 00000101101 00011101011;
    patch_in <= 55'b0001110101100000101101000110010011110010101111110111000;
    #20
    patch_en <= 0;
    #100
    assert(7'd22 == leaf_index);
    $display("%t: received = %d, expected = %d", $time, leaf_index, 7'd22);
	   
	   
     // 5
     // [-245. -199.   45.   58.  177.]
    patch_two_en <= 1;
    //patch_two_in <= 55'b11100001011 11100111001 00000101101 00000111010 00010110001;
    patch_two_in <= 55'b0001011000100000111010000001011011110011100111100001011;
    #20
    patch_two_en <= 0;
   
    #100
    assert(7'd5 == leaf_index_two);
    $display("%t: received = %d, expected = %d", $time, leaf_index_two, 7'd5);
	   
    
	// 24
	// [ -50.  -64. -298.  245. -141.]
     patch_en <= 1;
     patch_in <= 55'b1111100111011111000000110110101100001111010111101110011;  
    //  #20
    //  patch_en <= 0;
    //  #100
    //  assert(7'd24 == leaf_index);
    //  $display("%t: received = %d, expected = %d", $time, leaf_index, 7'd24);
    //  fsm_enable <= 0; //Turn off to stop overwriting data
	   
	   
    //  //Last 3 tests except pipelined
	   
    // patch_en <= 1;  
    // patch_in <= 55'b1111011100011100101011000110010010000010110100011101011;
    // #13.33334
    // patch_in <= 55'b1110000101111100111001000001011010000011101000010110001;
    // #13.33334
    // patch_in <= 55'b1111100111011111000000110110101100001111010111101110011; 
    // #13.33334
    // patch_en <= 0;
	   	     
    // #40
    // assert(7'd22 == leaf_index);
    // $display("%t: received = %d, expected = %d", $time, leaf_index, 7'd22);
    
    // #13.33334
    // assert(7'd5 == leaf_index);
    // $display("%t: received = %d, expected = %d", $time, leaf_index, 7'd5);
	   
    //  #13.33334
    //  assert(7'd24 == leaf_index);
    //  $display("%t: received = %d, expected = %d", $time, leaf_index, 7'd24);
    //  fsm_enable <= 0; //Turn off to stop overwriting data
     
	   
   
	   

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

  assign fifo_enq = wrst_n && (wfull) && (!stall);
	

  always @ (posedge wclk) begin
 
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

      #30000;
      $finish(2);
    end
     
endmodule
