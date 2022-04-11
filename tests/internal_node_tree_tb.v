`define DATA_WIDTH 55
`define STORAGE_WIDTH 22
`define ADDRESS_WIDTH 8


module internal_node_tree_tb;

  reg clk;
  reg rst_n;

  reg [`STORAGE_WIDTH -1 : 0] wdata;
  reg [`DATA_WIDTH - 1 : 0] patch_in;
  wire [`DATA_WIDTH - 1 : 0] patch_out; //Same patch, but we will be pipeling so it will be useful to adopt this input/ouput scheme
 

  //Tree specific things
  wire [`ADDRESS_WIDTH-1:0] leaf_index;
  reg fsm_enable;
  reg sender_enable;


  always #10 clk =~clk;


  internal_node_tree
  #(
   .INTERNAL_WIDTH(`STORAGE_WIDTH),
   .PATCH_WIDTH(`DATA_WIDTH),
   .ADDRESS_WIDTH(`ADDRESS_WIDTH)
  ) dut (
  .clk(clk),
  .rst_n(rst_n),
  .fsm_enable(fsm_enable), //based on whether we are at the proper I/O portion
  .sender_enable(sender_enable),
  .sender_data(wdata),
  .patch_in(patch_in),
  .leaf_index(leaf_index)
  );



   initial begin
    clk <= 0;
    rst_n <= 0;
    wdata <= 0;
    patch_in <= 0;
    fsm_enable <= 0;
    sender_enable <= 0;
   

    #40 rst_n <= 1;

    //Index 1, Median 2
    wdata <= 22'b0000000001000000000001;
    fsm_enable <= 1;
    sender_enable <= 1;

    #20
    wdata <= 22'b0000000001000000000011;
    sender_enable <= 1;
     
    #20
    sender_enable <= 0;



    
    
     
    

   end



    initial begin
      $dumpfile("dump.vcd");
      $dumpvars;

      #2000;
      $finish(2);
    end
     
endmodule
