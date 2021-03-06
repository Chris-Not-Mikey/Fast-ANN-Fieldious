`define DATA_WIDTH 55
`define STORAGE_WIDTH 22


module internal_node_tb;

  reg clk;
  reg rst_n;
  reg wen;
  reg valid;

  reg [`STORAGE_WIDTH -1 : 0] wdata;
  reg [`DATA_WIDTH - 1 : 0] patch_in;
  wire [`DATA_WIDTH - 1 : 0] patch_out; //Same patch, but we will be pipeling so it will be useful to adopt this input/ouput scheme
  wire valid_left;
  wire valid_right;
    wire valid_left_two;
  wire valid_right_two;


  always #10 clk =~clk;


  internal_node
  #(
   .DATA_WIDTH(`DATA_WIDTH),
   .STORAGE_WIDTH(`STORAGE_WIDTH)
  ) dut (
  .clk(clk),
  .rst_n(rst_n),
  .wen(wen), //Determined by FSM, reciever enq, and DECODER from KD Tree
  .valid(valid),
  .valid_two(valid),
  .wdata(wdata),
  .patch_in(patch_in),
  .patch_in_two(patch_in),
  .patch_out(patch_out), //Same patch, but we will be pipeling so it will be useful to adopt this input/ouput scheme
  .valid_left(valid_left),
  .valid_right(valid_right),
   .valid_left_two(valid_left_two),
  .valid_right_two(valid_right_two)
    
  );



   initial begin
    clk <= 0;
    rst_n <= 0;
    wen <= 0;
    valid <= 0;
    wdata <= 0;
    patch_in <= 0;
   

    #40 rst_n <= 1;
    //Index 1, Median 2
    wdata <= 22'b0000000001000000000001;
    wen <= 1;
    #20
    wen <= 0; 
    patch_in <= 55'b0000000001100000000011000000000110000000000100000000011; //This will give use left if indexed properly (Value 1 at index 1)
    valid <=1;
    #20
    assert(valid_left == 1'b1);
    assert(valid_right == 1'b0);
    patch_in <= 55'b0000000001100000000011000000000110000000001100000000011; //This will give us right (Value 3 at index 1)
    #20
    assert(valid_left == 1'b0);
    assert(valid_right == 1'b1);
    valid <=0;
    //Index 4, Median 2
    wdata <= 22'b0000000001000000000100;
    wen <= 1;
    #20
    wen <=0;
    patch_in <= 55'b0000000000000000000011000000000110000000001100000000011; //This will give use left if indexed properly (Value 0, at index 4)
    valid <=1;
    #20
    assert(valid_left == 1'b1);
    assert(valid_right == 1'b0);
    patch_in <= 55'b0100000000000000000011000000000110000000001100000000011; //This will give use right if indexed properly (Value 1024, at index 4)
    #20
    valid <=1;
    assert(valid_left == 1'b0);
    assert(valid_right == 1'b1);
    patch_in <= 55'b1000000000000000000011000000000110000000001100000000011; //This will give use right if signed binary comparison is correct (Value -2048, at index 4)
    #20
    valid <=1;
    assert(valid_left == 1'b1);
    assert(valid_right == 1'b0);
    #20
    valid <=0;
     
    

   end



    initial begin
      $dumpfile("dump.vcd");
      $dumpvars;

      #2000;
      $finish(2);
    end
     
endmodule

