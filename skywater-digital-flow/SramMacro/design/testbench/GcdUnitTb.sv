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




    sram_1kbyte_1rw1r
    #(
        .DATA_WIDTH(64), // round_up(PATCH_SIZE * DATA_WIDTH)
        .ADDR_WIDTH(9),
        .RAM_DEPTH(256) // round_up(26*19)
    ) dut (
        .clk0(clk),
        .csb0(1'b0),
        .web0(1'b0),
        .addr0(),
        .din0(),
        .dout0(),
        .clk1(clk),
        .csb1(1'b1),
        .addr1(),
        .dout1()
    );





   initial begin
    clk <= 0;
    rst_n <= 0;
    wen <= 0;
    valid <= 0;
    wdata <= 0;
    patch_in <= 0;
   

    
     
    

   end



    initial begin
      $dumpfile("dump.vcd");
      $dumpvars;

      #2000;
      $finish(2);
    end
     
endmodule

