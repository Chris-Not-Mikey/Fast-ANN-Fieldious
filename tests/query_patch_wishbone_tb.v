`define DATA_WIDTH 11
`define FETCH_WIDTH 6
`define PATCH_SIZE 5
`define ADDRESS_WIDTH 9


module query_patch_wishbone_tb;

  reg clk;
  reg rst_n;


 // RAM Stuff
  logic                                       csb0; //Write
  logic                                       web0;
  logic [`ADDRESS_WIDTH-1:0]                      addr0;
  logic [(`DATA_WIDTH*`PATCH_SIZE)-1:0]         wpatch0;
  logic  [(`DATA_WIDTH*`PATCH_SIZE)-1:0]       rpatch0;
  logic                                       csb1; //Read
  logic [`ADDRESS_WIDTH-1:0]                      addr1;
  logic  [(`DATA_WIDTH*`PATCH_SIZE)-1:0]       rpatch1;


    logic wb_mode;
    logic wb_clk_i; 
    logic wb_rst_i; 
    logic wbs_stb_i; 
    logic wbs_cyc_i; 
    logic wbs_we_i; 
    logic [3:0] wbs_sel_i; 
    logic [31:0] wbs_dat_i; 
    logic [31:0] wbs_adr_i; 
    logic wbs_ack_o; 
    logic [31:0] wbs_dat_o;

    always #6.66666667 clk =~clk; //Conceptually, rlck = clk (read clock is normal clock
	
    always #100 wb_clk_i = ~wb_clk_i; //Clock for wishbone
	



   QueryPatchMem2
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
      .wpatch0(wpatch0),
      .rpatch0(rpatch0),
      .csb1(csb1),
      .addr1(addr1),
      .rpatch1(rpatch1),
     .wb_mode(wb_mode),
     .wb_clk_i(wb_clk_i), 
     .wb_rst_i(wb_rst_i), 
     .wbs_stb_i(wbs_stb_i), 
     .wbs_cyc_i(wbs_cyc_i), 
     .wbs_we_i(wbs_we_i), 
     .wbs_sel_i(wbs_sel_i), 
     .wbs_dat_i(wbs_dat_i), 
     .wbs_adr_i(wbs_adr_i), 
     .wbs_ack_o(wbs_ack_o), 
     .wbs_dat_o(wbs_dat_o)

  );


    initial begin
    //Clock Signals
    clk <= 0;
    wb_clk_i <= 0;

    //Ram Signals
    csb0 <= 0; //Write
    web0 <= 1;
    addr0 <= 0;
    wpatch0 <= 0;
    csb1 <= 1; //Read
    addr1 <= 0;

    //Wishbone Stuff
    wb_mode <= 0;
    wbs_we_i <= 0;
    wbs_dat_i <= 0;
    wbs_adr_i <= 0;


    //Write once without wishbone
    #100

    web0 = 0;
    wpatch0 = {44'b0, 11'b1};
	    
    #100
     web0 = 1;
     wpatch0 = 0;
	    

	    
    //Wishbone writing
    #100
    wb_mode = 1;
    wbs_we_i = 1;
    wbs_adr_i = 32'd557;    
    wbs_dat_i = {21'b0, 11'd2};
	    
    #200
	    
     wbs_dat_i = {21'b0, 11'd3};
     wbs_adr_i = 32'd558;
	    
	    
     #200
	    
     wbs_dat_i = {18'b0, 3'd1, 11'd4};
     wbs_adr_i = 32'd558;
	    
	    
     #200
	    
     wbs_dat_i = {18'b0, 3'd2, 11'd5};
     wbs_adr_i = 32'd558;
	    
	    
      #200
	    
     wbs_dat_i = {18'b0, 3'd3, 11'd6};
     wbs_adr_i = 32'd558;
	    
	    
      #200
	    
     wbs_dat_i = {18'b0, 3'd4, 11'd7};
     wbs_adr_i = 32'd558;
	    
	    
     #200
    
     wbs_dat_i = {18'b0, 3'd5, 11'd8};
     wbs_adr_i = 32'd558;
	    
     #200
    
     wbs_dat_i = {18'b0, 3'd6, 11'd9};
     wbs_adr_i = 32'd558;
	    

     #200
    
     wbs_dat_i = {18'b0, 3'd7, 11'd10};
     wbs_adr_i = 32'd558;
	    
	    
    #200
     wbs_we_i = 0;
     wb_mode = 1;
     addr0 = 9'b1;
   #200 
   wbs_dat_i = {18'b0, 3'd0, 11'd10};
	
    


    end


  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
    #90000;
    $finish(2);
  end


  endmodule
