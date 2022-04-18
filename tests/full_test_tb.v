`define DATA_WIDTH 11
`define FETCH_WIDTH 48 //(this is max for leaves. We dynamically change to the others)
`define DSIZE 11
`define PATCH_SIZE 5
`define ASIZE 4
`define ADDRESS_WIDTH 9
`define DEPTH 512
`define RAM_WIDTH 11
`define NULL 0   
`define STORAGE_WIDTH 22
`define LEAF_SIZE 8

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

  reg fsm_rst_agg_n;


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
  logic [`DSIZE-1:0] rdata_io;
  logic wfull_io;
  logic rempty_io;
  logic [`DSIZE-1:0] wdata;
  logic winc, wclk, wrst_n;
  logic rinc, rrst_n;

  reg [7:0] node_counter;
  reg [8:0] patch_counter;
  reg [11:0] leaf_counter;
  reg [8:0] read_patch_counter;

  // Query RAM Stuff
  logic                                       csb0; //Write
  logic                                       web0;
  logic [`ADDRESS_WIDTH-1:0]                      addr0;
  logic [(`DATA_WIDTH*`PATCH_SIZE)-1:0]         wpatch0;
  logic  [(`DATA_WIDTH*`PATCH_SIZE)-1:0]       rpatch0;
  logic                                       csb1; //Read
  logic [`ADDRESS_WIDTH-1:0]                      addr1;
  logic  [(`DATA_WIDTH*`PATCH_SIZE)-1:0]       rpatch1;
	
  reg [5 * `DATA_WIDTH - 1 : 0] receiver_din_storage;


 // Leaf RAM Stuff

   logic                                       leaf_csb0;
   logic                                       leaf_web0;
	logic [5:0]                      leaf_addr0;
	logic [`PATCH_SIZE-1:0] [`DATA_WIDTH-1:0]     wleaf0 [`LEAF_SIZE-1:0];
	logic  [`PATCH_SIZE:0] [`DATA_WIDTH-1:0]   rleaf0 [`LEAF_SIZE-1:0]; //note PATCH size is 6 here
    logic                                       leaf_csb1;
	logic [5:0]                      leaf_addr1;
	logic  [`PATCH_SIZE:0] [`DATA_WIDTH-1:0]   rleaf1 [`LEAF_SIZE-1:0];

	reg [(6 * `DATA_WIDTH ) - 1 : 0] receiver_din_leaf_storage [`LEAF_SIZE-1:0];
    reg leaf_write_disable;
    reg leaf_wen;




	
  logic fsm_enable;
	
	
  //TREE stuff
  reg patch_en;
  wire [7 : 0] leaf_index;
  wire leaf_en;
	
	
  //Wish bone stuff
  reg wish_bone_en;
  wire fifo_enq_wb;
  reg wbclk;
	
  logic [`DSIZE-1:0] rdata_wb;
  logic wfull_wb;
  logic rempty_wb;
	
	
  logic [`DSIZE-1:0] rdata;
  logic wfull;
  logic rempty;
	
	
 


  //File I/O Stuff
  integer               data_file    ; // file handler
  integer               scan_file    ; // file handler
  logic   signed [`DSIZE-1:0] captured_data;
	
  integer               expected_data_file    ; // file handler
  integer               expected_scan_file    ; // file handler
  logic   signed [`DSIZE-1:0] expected_captured_data;
	
	
   integer               expected_leaf_data_file    ; // file handler
  integer               expected_leaf_scan_file    ; // file handler
 logic   signed [`DSIZE-1:0] expected_leaf_captured_data;
     
     
  
  always #6.66666667 clk =~clk; //Conceptually, rlck = clk (read clock is normal clock
  always #20 wclk =~wclk;
	
  always #100 wbclk = ~wbclk; //Clock for wishbone
	
	
	
  
  aggregator
  #(
    .DATA_WIDTH(`DATA_WIDTH),
    .FETCH_WIDTH(48)
  ) aggregator_inst
  (
    .clk(clk),
    .rst_n(rst_n && fsm_rst_agg_n),
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
	    .sENQ(fifo_enq && !wish_bone_en),
      .sD_IN(wdata),
	    .sFULL_N(wfull_io),
      .dDEQ(fifo_deq),
	    .dD_OUT(rdata_io),
	    .dEMPTY_N(rempty_io)
    );
	

   SyncFIFO #(`DATA_WIDTH, 16, 4)
    wishbone_dut (
      .sCLK(wbclk),
      .sRST(wrst_n),
      .dCLK(clk),
	    .sENQ(fifo_enq && wish_bone_en),
      .sD_IN(wdata),
      .sFULL_N(wfull_wb),
      .dDEQ(fifo_deq),
      .dD_OUT(rdata_wb),
      .dEMPTY_N(rempty_wb)
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


  LeavesMem
#(
    .DATA_WIDTH(`DATA_WIDTH),
    .LEAF_SIZE(`LEAF_SIZE),
    .PATCH_SIZE(6), //need index as sixth input
    .NUM_LEAVES(64),
    .ADDR_WIDTH(6)
)
(
    .clk(clk),
    .csb0(leaf_csb0),
    .web0(leaf_web0),
    .addr0(leaf_addr0),
    .wleaf0(receiver_din_leaf_storage),
    .rleaf0(rleaf0),
    .csb1(leaf_csb1),
    .addr1(leaf_addr1),
    .rleaf1(rleaf1) 
);


   internal_node_tree
  #(
   .INTERNAL_WIDTH(`STORAGE_WIDTH),
   .PATCH_WIDTH(55),
   .ADDRESS_WIDTH(`ADDRESS_WIDTH - 1)
  ) tree_dut (
  .clk(clk),
  .rst_n(rst_n),
  .fsm_enable(fsm_enable), //based on whether we are at the proper I/O portion
  .sender_enable(receiver_enq),
  .sender_data(receiver_din[21:0]),
  .patch_en(patch_en),
  .patch_in(rpatch0),
  .leaf_index(leaf_index),
  .receiver_en(leaf_en)
	  
  );

initial begin

//   node_file = $fopen("./data/IO_data/internalNodes.txt", "r");
//   if (node_file == `NULL) begin
//     $display("data_file handle was NULL");
//     $finish;
//   end
  


  data_file = $fopen("./data/IO_data/nodes_patches_leaves.txt", "r");
  if (data_file == `NULL) begin
    $display("data_file handle was NULL");
    $finish;
  end
  
  expected_data_file = $fopen("./data/IO_data/expected_patches.txt", "r");
  if (expected_data_file == `NULL) begin
    $display("expected_data_file handle was NULL");
    $finish;
  end
	
  expected_leaf_data_file = $fopen("./data/IO_data/expected_leaves.txt", "r");
  if (expected_leaf_data_file == `NULL) begin
    $display("expected_leaf_data_file handle was NULL");
    $finish;
  end


  scan_file = $fscanf(data_file, "%d\n", wdata[10:0]); 
  //wdata[10:0] = captured_data; //11'b0; Let FILE handle provide data
	
 // #20
	
 // scan_file = $fscanf(data_file, "%d\n", wdata[10:0]); 
	
	
  // scan_file = $fscanf(data_file, "%d\n", wdata[21:11]); 
   //wdata[21:11] = captured_data; //11'b0; Let FILE handle provide data
	
	
end


 



  initial begin
    clk <= 0;
    wclk <= 0;
    wbclk <= 0;
    fifo_valid <=0;
    rst_n <= 0;
    fsm_rst_agg_n <= 0;
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
    leaf_write_disable = 0;
    receiver_din_storage = 0;
    wdata = 0;
    i_o_state = 0;
	  fsm_enable = 0;
      node_counter = 0;
	  patch_counter = 0;
      leaf_counter = 0;
	  read_patch_counter = 0;
	  patch_en = 0;
	  wish_bone_en = 0;

	  
    //Agg
    change_fetch_width = 0;
    input_fetch_width = 3'd2;


    // Query RAM
    csb0 = 1; //Write
    web0 = 1;
    addr0 = 0;
    wpatch0 = 0;
    csb1 = 1; //Read
    addr1 = 0;


    // Leaf RAM
    leaf_csb0 = 1; //Write
    leaf_web0 = 1;
    leaf_addr0 = 0;
   // wleaf0 = 0;
    leaf_csb1 = 1; //Read
    leaf_addr1 = 0;
    leaf_wen = 0;


    #100 
    wish_bone_en = 0;
    receiver_full_n <= 1;
    wrst_n = 1'b1;
    rst_n = 1'b1;
    fsm_rst_agg_n =  1'b1;
    //change_fetch_width = 1;
    
    #20
    change_fetch_width = 0;


    fifo_valid <=1;


    //Write to internal Tree
    #40 rst_n <= 1;
    //input_fetch_width = 3'd2;
    //change_fetch_width <= 1'b1;
    receiver_full_n <=1;

	   
    // #10200
    // fsm_enable <= 0; //Turn off to stop overwriting data

	   
   
	//Write to Query Patch Memory

//     #190000

//     //Now read from memory
//     addr0 <= 0;
//     write_disable <= 1;
//     #100
//     ren <= 1;
    
//     read_latency_counter <= 0;
	  
  end

	assign fifo_enq = wrst_n && (wfull) && (!stall);
	//assign fifo_enq_wb = wrst_n && (wfull) && (!stall) && wish_bone_en;

	
	//Determine proper rdata,rempty,wfull depending on wish bone toggle
	reg write_clock;
	always @(*) begin
		if (wish_bone_en) begin
			rdata = rdata_wb;
			wfull = wfull_wb;
			rempty = rempty_wb;
			write_clock = wbclk;
	
		end
		else begin
			rdata = rdata_io;
			wfull = wfull_io;
			rempty = rempty_io;
			write_clock = wclk;
	
		end
	end
	
	

  reg [10:0] temp_capture;
	reg [10:0] temp1;
	reg [10:0] temp2;
 reg [2:0] counter;


	



//Read from FIFO and stop if we reach a interput signal in FIFO
//"The interupt" signal, is actually just a counter register
//Since we know the size of the input is fixed, we simply count inputs until we are done
//This is poor design for generality, but for a system where I/O is a concern, this is foolproof way
// to work with I/O, wishbone, without altering any input streams

 always @ (posedge clk) begin

    // (TOP LEVEL: Include counter register like this)
	 if (((leaf_counter == 12'd3072) && (i_o_state == 3'b0 ) && (rempty) )) begin  //Condition seperating I/O portions (don't read into FIFO)
        //Change fetch width if we are done

        leaf_web0 <= 1'b1; //active low
        leaf_csb0 <= 0; //Must activate to write as well
       // leaf_addr0 <= 0; //change back to original leaf address (for verification)
     
        change_fetch_width <= 1;
        input_fetch_width <= 3'd2;
	    i_o_state <= i_o_state + 1;
	    fsm_rst_agg_n <= 0;
		 fsm_enable <= 1;
    end
    else if ( (i_o_state == 3'b0  ) && (rempty)) begin
        leaf_counter <= leaf_counter + 1;  
	 fsm_rst_agg_n <= 1;
        leaf_web0 <= 1'b1; //active low
        leaf_csb0 <= 0; //Must activate to write as well
    end

    else begin
	     leaf_counter <= leaf_counter;  
	    fsm_rst_agg_n <= 1;
    end


    //If we have agregated eough data
    if (receiver_enq && !write_disable && (i_o_state == 3'b00)) begin //If aggregated 5, write to RAM
      leaf_web0 <= 1'b1; //active low
      leaf_csb0 <= 0; //Must activate to write as well
     
      write_latency_counter <= 0;

      leaf_wen <= 1;
	  
    end 
	  
   if (leaf_wen && !write_disable) begin
	   
	   write_latency_counter <= write_latency_counter + 1;
	   if (write_latency_counter == 3'b01) begin
		   leaf_web0 <= 1'b0; 
		   receiver_din_leaf_storage[0] <= receiver_din[65:0];
		   receiver_din_leaf_storage[1] <= receiver_din[131:66];
		   receiver_din_leaf_storage[2] <= receiver_din[197:132];
		   receiver_din_leaf_storage[3] <= receiver_din[263:198];
		   receiver_din_leaf_storage[4] <= receiver_din[329:264];
		   receiver_din_leaf_storage[5] <= receiver_din[395:330];
		   receiver_din_leaf_storage[6] <= receiver_din[461:396];
		   receiver_din_leaf_storage[7] <= receiver_din[527:462];
		    
		    leaf_wen <= 1;
		    //addr0 <= addr0 + 1;
	   end
	   
	   
	   if (write_latency_counter == 3'b10) begin
		    leaf_web0 <= 1'b1; 
		    leaf_wen <= 0;
		    leaf_addr0 <= leaf_addr0 + 1;
	   end

   end

 end





//Read from FIFO and stop if we reach a interput signal in FIFO
//"The interupt" signal, is actually just a counter register
//Since we know the size of the input is fixed, we simply count inputs until we are done
//This is poor design for generality, but for a system where I/O is a concern, this is foolproof way
// to work with I/O, wishbone, without altering any input streams

 always @ (posedge clk) begin

   // (TOP LEVEL: Include counter register like this)
   if (((node_counter == 8'd127) && (i_o_state == 3'b1 ) && (fifo_deq) && (rempty) )) begin  //Condition seperating I/O portions (don't read into FIFO)
        //Change fetch width if we are done
        fsm_enable <= 0;
        change_fetch_width <= 1;
        input_fetch_width <= 3'd5;
        i_o_state <= i_o_state + 1;
        fsm_rst_agg_n <= 0;
	   leaf_addr0 <= 0; //for verifcation(weird spot for this, but should happen several cycles after)
    end
    else if ((fifo_deq) && (rempty)) begin
        node_counter <= node_counter + 1;  
	 fsm_rst_agg_n <= 1;
    end

    else begin
	     node_counter <= node_counter;  
	    fsm_rst_agg_n <= 1;
    end

 end
	
	
	

//Write to FIFO
always @ (posedge write_clock) begin
 
    //Into FIFO
	  if (wrst_n) begin
	    stall <= 20 % 2;
	    receiver_full_n <= 1;
	    if (fifo_enq) begin
	       //scan_file = $fscanf(data_file, "%d\n", captured_data); 
		    

		  //Read Data from  I/O
		    scan_file = $fscanf(data_file, "%d\n", temp_capture[10:0]); 


		    if (!$feof(data_file)) begin
			//use captured_data as you would any other wire or reg value;
			counter <= 0;
			wdata <= temp_capture[10:0];

		    end
		end
    end
end

	
  reg [54:0] hold_expected;
  reg [527:0] hold_leaf_expected;
	reg [65:0] hold_leaf_debug;
	reg [65:0] hold_leaf_8_debug;

  //RAM and check (both LEAF and Query)
  always @ (posedge clk) begin
  //$display("%t: received = %d", $time, rpatch1);
  if (receiver_enq && !write_disable && (i_o_state == 3'b10)) begin //If aggregated 5, write to RAM
      web0 <= 1'b1; //active low
      csb0 <= 0; //Must activate to write as well
     
      write_latency_counter <= 0;
	  
	  if (patch_counter == 9'd442) begin
		  
		  //Stop writing, start reading (TOP LEVEL: Include counter register like this)
		write_disable <= 1;
		addr0 <= 0;
		ren <= 1;
		read_latency_counter <= 0;
		  
		  
	  end
	  else begin
		   wen <= 1;
		  patch_counter <= patch_counter + 1;
	  end
     
      
    end 
	  
   if (wen && !write_disable) begin
	   
	   write_latency_counter <= write_latency_counter + 1;
	   if (write_latency_counter == 3'b01) begin
		    web0 <= 1'b0; 
		   receiver_din_storage <= receiver_din[54:0];
		    
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
	

		 
	  //Query
	  addr0 <= addr0 + 1;
          read_latency_counter <= 0;
		 
	  read_patch_counter <= read_patch_counter + 1;
		 //The first patch contains garbadge values, so we simply flush it out)
	 if (read_patch_counter != 0) begin
		 
	   patch_en <= 1; //Start streaming patches to Tree to get index
		 
	    expected_scan_file = $fscanf(expected_data_file, "%d\n", hold_expected[10:0]); 
	    expected_scan_file = $fscanf(expected_data_file, "%d\n", hold_expected[21:11]); 
            expected_scan_file = $fscanf(expected_data_file, "%d\n", hold_expected[32:22]); 
	    expected_scan_file = $fscanf(expected_data_file, "%d\n", hold_expected[43:33]); 
            expected_scan_file = $fscanf(expected_data_file, "%d\n", hold_expected[54:44]); 
		 
		 
	

	     if (!$feof(expected_data_file)) begin
	//	ren <= 0;

            	//csb0 <= 0; //active low
     		assert(rpatch0 == hold_expected);
// 		    $display("%t: received = %d, expected = %d", $time, rpatch0, hold_expected);
// 		    $display("%t: received = %d, expected = %d", $time, rpatch0[10:0], hold_expected[10:0]);
// 		    $display("%t: received = %d, expected = %d", $time, rpatch0[21:11], hold_expected[21:11]);
// 		    $display("%t: received = %d, expected = %d", $time, rpatch0[32:22], hold_expected[32:22]);
// 		    $display("%t: received = %d, expected = %d", $time, rpatch0[43:33], hold_expected[43:33]);
// 		    $display("%t: received = %d, expected = %d", $time, rpatch0[54:44], hold_expected[54:44]);



	     end

	 end
		 
	//Leaf
	   leaf_addr0 <= leaf_addr0 + 1;
          read_latency_counter <= 0;
		 
	  //read_patch_counter <= read_patch_counter + 1;
		 //The first patch contains garbadge values, so we simply flush it out)
	 if (read_patch_counter != 0) begin
		 
	   //patch_en <= 1; //Start streaming patches to Tree to get index
		 
	    expected_leaf_scan_file = $fscanf(expected_leaf_data_file, "%d\n", hold_leaf_expected[10:0]); 
	    expected_leaf_scan_file = $fscanf(expected_leaf_data_file, "%d\n", hold_leaf_expected[21:11]); 
      expected_leaf_scan_file = $fscanf(expected_leaf_data_file, "%d\n", hold_leaf_expected[32:22]); 
	    expected_leaf_scan_file = $fscanf(expected_leaf_data_file, "%d\n", hold_leaf_expected[43:33]); 
      expected_leaf_scan_file = $fscanf(expected_leaf_data_file, "%d\n", hold_leaf_expected[54:44]); 

      expected_leaf_scan_file = $fscanf(expected_leaf_data_file, "%d\n", hold_leaf_expected[65:55]); 
	    expected_leaf_scan_file = $fscanf(expected_leaf_data_file, "%d\n", hold_leaf_expected[76:66]); 
      expected_leaf_scan_file = $fscanf(expected_leaf_data_file, "%d\n", hold_leaf_expected[87:77]); 
	    expected_leaf_scan_file = $fscanf(expected_leaf_data_file, "%d\n", hold_leaf_expected[98:88]); 
      expected_leaf_scan_file = $fscanf(expected_leaf_data_file, "%d\n", hold_leaf_expected[109:99]); 

      expected_leaf_scan_file = $fscanf(expected_leaf_data_file, "%d\n", hold_leaf_expected[120:110]); 
	    expected_leaf_scan_file = $fscanf(expected_leaf_data_file, "%d\n", hold_leaf_expected[131:121]); 
      expected_leaf_scan_file = $fscanf(expected_leaf_data_file, "%d\n", hold_leaf_expected[142:132]); 
	    expected_leaf_scan_file = $fscanf(expected_leaf_data_file, "%d\n", hold_leaf_expected[153:143]); 
      expected_leaf_scan_file = $fscanf(expected_leaf_data_file, "%d\n", hold_leaf_expected[164:154]); 

      expected_leaf_scan_file = $fscanf(expected_leaf_data_file, "%d\n", hold_leaf_expected[175:165]); 
	    expected_leaf_scan_file = $fscanf(expected_leaf_data_file, "%d\n", hold_leaf_expected[186:176]); 
      expected_leaf_scan_file = $fscanf(expected_leaf_data_file, "%d\n", hold_leaf_expected[197:187]); 
	    expected_leaf_scan_file = $fscanf(expected_leaf_data_file, "%d\n", hold_leaf_expected[208:198]); 
      expected_leaf_scan_file = $fscanf(expected_leaf_data_file, "%d\n", hold_leaf_expected[219:209]); 

      expected_leaf_scan_file = $fscanf(expected_leaf_data_file, "%d\n", hold_leaf_expected[230:220]); 
	    expected_leaf_scan_file = $fscanf(expected_leaf_data_file, "%d\n", hold_leaf_expected[241:231]); 
      expected_leaf_scan_file = $fscanf(expected_leaf_data_file, "%d\n", hold_leaf_expected[252:242]); 
	    expected_leaf_scan_file = $fscanf(expected_leaf_data_file, "%d\n", hold_leaf_expected[263:253]); 
      expected_leaf_scan_file = $fscanf(expected_leaf_data_file, "%d\n", hold_leaf_expected[274:264]); 

      expected_leaf_scan_file = $fscanf(expected_leaf_data_file, "%d\n", hold_leaf_expected[285:275]); 
	    expected_leaf_scan_file = $fscanf(expected_leaf_data_file, "%d\n", hold_leaf_expected[296:286]); 
      expected_leaf_scan_file = $fscanf(expected_leaf_data_file, "%d\n", hold_leaf_expected[307:297]); 
	    expected_leaf_scan_file = $fscanf(expected_leaf_data_file, "%d\n", hold_leaf_expected[318:308]); 
      expected_leaf_scan_file = $fscanf(expected_leaf_data_file, "%d\n", hold_leaf_expected[329:319]); 


      expected_leaf_scan_file = $fscanf(expected_leaf_data_file, "%d\n", hold_leaf_expected[340:330]); 
	    expected_leaf_scan_file = $fscanf(expected_leaf_data_file, "%d\n", hold_leaf_expected[351:341]); 
      expected_leaf_scan_file = $fscanf(expected_leaf_data_file, "%d\n", hold_leaf_expected[362:352]); 
	    expected_leaf_scan_file = $fscanf(expected_leaf_data_file, "%d\n", hold_leaf_expected[373:363]); 
      expected_leaf_scan_file = $fscanf(expected_leaf_data_file, "%d\n", hold_leaf_expected[384:374]); 

      expected_leaf_scan_file = $fscanf(expected_leaf_data_file, "%d\n", hold_leaf_expected[395:385]); 
	    expected_leaf_scan_file = $fscanf(expected_leaf_data_file, "%d\n", hold_leaf_expected[406:396]); 
      expected_leaf_scan_file = $fscanf(expected_leaf_data_file, "%d\n", hold_leaf_expected[417:407]); 
	    expected_leaf_scan_file = $fscanf(expected_leaf_data_file, "%d\n", hold_leaf_expected[428:418]); 
      expected_leaf_scan_file = $fscanf(expected_leaf_data_file, "%d\n", hold_leaf_expected[439:429]); 

       expected_leaf_scan_file = $fscanf(expected_leaf_data_file, "%d\n", hold_leaf_expected[450:440]); 
	    expected_leaf_scan_file = $fscanf(expected_leaf_data_file, "%d\n", hold_leaf_expected[461:451]); 
      expected_leaf_scan_file = $fscanf(expected_leaf_data_file, "%d\n", hold_leaf_expected[472:462]); 
	    expected_leaf_scan_file = $fscanf(expected_leaf_data_file, "%d\n", hold_leaf_expected[483:473]); 
      expected_leaf_scan_file = $fscanf(expected_leaf_data_file, "%d\n", hold_leaf_expected[494:484]); 

      expected_leaf_scan_file = $fscanf(expected_leaf_data_file, "%d\n", hold_leaf_expected[505:495]); 
	    expected_leaf_scan_file = $fscanf(expected_leaf_data_file, "%d\n", hold_leaf_expected[516:506]); 
      expected_leaf_scan_file = $fscanf(expected_leaf_data_file, "%d\n", hold_leaf_expected[527:517]); 
	   
		 
		 
	     hold_leaf_debug = rleaf0[0];
// 	    hold_leaf_8_debug = rleaf0[8];

	     if (!$feof(expected_leaf_data_file)) begin
	//	ren <= 0;

            	//csb0 <= 0; //active low
		     assert(rleaf0[0] == hold_leaf_expected[65:0]);
		     $display("%t: (LEAF) received = %d, expected = %d", $time, rleaf0[0], hold_leaf_expected[47:0]);
		     $display("%t: (LEAF) received = %d, expected = %d", $time, hold_leaf_debug[10:0], hold_leaf_expected[10:0]);
		     $display("%t: (LEAF) received = %d, expected = %d", $time, hold_leaf_debug[21:11], hold_leaf_expected[21:11]);
		     $display("%t: (LEAF) received = %d, expected = %d", $time, hold_leaf_debug[32:22], hold_leaf_expected[32:22]);
		     $display("%t: (LEAF) received = %d, expected = %d", $time, hold_leaf_debug[43:33], hold_leaf_expected[43:33]);
		     $display("%t: (LEAF) received = %d, expected = %d", $time, hold_leaf_debug[54:44], hold_leaf_expected[54:44]);
		     $display("%t: (LEAF) received = %d, expected = %d", $time, hold_leaf_debug[65:55], hold_leaf_expected[65:55]);
		     
// 		     $display("%t: (LEAF) received = %d, expected = %d", $time, rleaf0[7], hold_leaf_expected[47:0]);
// 		     $display("%t: (LEAF) received = %d, expected = %d", $time, hold_leaf_8_debug[10:0], hold_leaf_expected[10:0]);
// 		     $display("%t: (LEAF) received = %d, expected = %d", $time, hold_leaf_8_debug[21:11], hold_leaf_expected[21:11]);
// 		     $display("%t: (LEAF) received = %d, expected = %d", $time, hold_leaf_8_debug[32:22], hold_leaf_expected[32:22]);
// 		     $display("%t: (LEAF) received = %d, expected = %d", $time, hold_leaf_8_debug[43:33], hold_leaf_expected[43:33]);
// 		     $display("%t: (LEAF) received = %d, expected = %d", $time, hold_leaf_8_debug[54:44], hold_leaf_expected[54:44]);
// 		    $display("%t: received = %d, expected = %d", $time, rpatch0[32:22], hold_expected[32:22]);
// 		    $display("%t: received = %d, expected = %d", $time, rpatch0[43:33], hold_expected[43:33]);
// 		    $display("%t: received = %d, expected = %d", $time, rpatch0[54:44], hold_expected[54:44]);



	     end

	 end
		 
	//End check
	    
	
	   
     end

  end

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
//     $vcdplusmemon();
//     $vcdpluson(0, aggregator_tb);
    #218000;
    $finish(2);
  end

endmodule
