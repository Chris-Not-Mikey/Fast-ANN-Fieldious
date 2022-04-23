`define DATA_WIDTH 11
`define FETCH_WIDTH 6
`define PATCH_SIZE 5


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
	
    always #100 wbclk = ~wbclk; //Clock for wishbone
	



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
    wbclk <= 0;

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




    end


  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
    #90000;
    $finish(2);
  end


  endmodule