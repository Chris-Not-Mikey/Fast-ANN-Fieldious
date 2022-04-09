/*
  A Wrapper for a 1w1r Ram that will hold the current patch queries.
  The idea is that as query image patches are read in via I/O, they are stored in this SRAM
  so that they can be used later for computation.

  There is an internal register that holds the current address counter for writing. 

  Currently assums to read in 5 patches at a time, and to read out 5 patches at a time.
  


  Author: Chris Calloway, cmc2374@stanford.edu
*/


module query_row_double_buffer
#(
  parameter DATA_WIDTH = 55,
  parameter ADDR_WIDTH = 7,
  parameter DEPTH = 128
)
(
  input clk,
  input rst_n,
  input fsm_enable, //based on whether we are at the proper I/O portion
  input sender_enable,
  input ren,
  input [ADDR_WIDTH -1 : 0] radr,
  input [DATA_WIDTH - 1 : 0] sender_data,
  output [DATA_WIDTH - 1 : 0] receiver_data

);

wire wen;
reg [ADDR_WIDTH -1 : 0] wadr;

//Writing is enabled if we recived a valid signal from the FSM and a valid signal from the aggregator
assign wen = fsm_enable && sender_enable;

  //Ram instantiaion 
  ram_sync_1r1w
  #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .DEPTH(DEPTH)
  ) ram_query_inst (
    .clk(clk),
    .wen(wen),
    .wadr(wadr),
    .wdata(sender_data),
    .ren(ren),
    .radr(radr),
    .rdata(receiver_data)
  ]

  //Update internal wadr register.
  //If rst_n is low, we set wadr to 0.
  //If we are writing to RAM, we increment the address by 1
  //Otherwise, no change to wadr

  always @ (posedge clk) begin

      if (rst_n == 0) begin
          wadr <= 0;
      end
      else if (wen) begin
          wadr <= wadr + 1;
      end
      else begin
          wadr <= wadr;
      end

  end
