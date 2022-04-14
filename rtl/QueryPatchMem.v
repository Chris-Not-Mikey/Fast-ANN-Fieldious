/*
  A Wrapper for a 1w1r Ram that will hold the current patch queries.
  The idea is that as query image patches are read in via I/O, they are stored in this SRAM
  so that they can be used later for computation.
  There is an internal register that holds the current address counter for writing. 
  Currently assums to read in 5 patches at a time, and to read out 5 patches at a time.
  
  Author: Chris Calloway, cmc2374@stanford.edu
*/


module QueryPatchMem
#(
  parameter DATA_WIDTH = 11,
  parameter PATCH_SIZE = 5,
  parameter ADDR_WIDTH = 9,
  parameter DEPTH = 512
)
(

    input logic                                       clk,
    input logic                                       csb0,
    input logic                                       web0,
    input logic [ADDR_WIDTH-1:0]                      addr0,
    input logic [DATA_WIDTH*PATCH_SIZE-1:0]         wpatch0,
    output logic  [DATA_WIDTH*PATCH_SIZE-1:0]       rpatch0,
    input logic                                       csb1,
    input logic [ADDR_WIDTH-1:0]                      addr1,
    output logic  [DATA_WIDTH*PATCH_SIZE-1:0]       rpatch1

);
  
  reg macro_select_0;
  reg macro_select_1;
  
  
  reg [DATA_WIDTH*PATCH_SIZE-1:0]       rpatch0_0,
  reg [DATA_WIDTH*PATCH_SIZE-1:0]       rpatch0_1,
  reg [DATA_WIDTH*PATCH_SIZE-1:0]       rpatch1_0,
  reg [DATA_WIDTH*PATCH_SIZE-1:0]       rpatch1_1,
  
  
  
  
  
  
//   reg macro_select_2;
//   reg macro_select_3;
  
  
  always @(*) begin
    case(addr0[8])
       1'b0 :   begin
         macro_select_0 = 1;
         macro_select_1 = 0;
//          macro_select_2 = 0;
//          macro_select_3 = 0;
       end
       
      1'b1 :   begin
         macro_select_0 = 1;
         macro_select_1 = 0;
//          macro_select_2 = 0;
//          macro_select_3 = 0;
       end
      
      
      
      default :   begin
         macro_select_0 = 1;
         macro_select_1 = 0;
//          macro_select_2 = 0;
//          macro_select_3 = 0;
       end
         
    endcase 
    
    
    if (macro_select_0) begin
      rpatch0 = rpatch0_0;
      rpatch1 = rpatch1_0;
      
    end
    
    else begin
      rpatch0 = rpatch0_1;
      rpatch1 = rpatch1_1;
    end
    
    
  end
  


  //Ram instantiaion (8 1k blocks
  
    sky130_sram_1kbyte_1rw1r_32x256_8
    #(
      .DATA_WIDTH(32), // round(PATCH_SIZE * DATA_WIDTH)
      .ADDR_WIDTH(8),
      .RAM_DEPTH(256) // NUM_LEAVES
    ) ram_patch_inst_0_0 (
        .clk0(clk),  // Port 0: W
        .csb0(csb0),
        .web0(web0 && macro_select_0),
        .wmask0(4'hF), //TODO: investigate what mask exactly does?
        .addr0(addr0[7:0]),
        .din0(wpatch0[31:0]),
        .dout0(rpatch0_0[31:0]),
        .clk1(clk), // Port 1: R
        .csb1(csb1 && macro_select_0),
        .addr1(addr1[7:0]),
        .dout1(rpatch1_0[31:0])
    );
  
    
    sky130_sram_1kbyte_1rw1r_32x256_8
    #(
      .DATA_WIDTH(32), // round(PATCH_SIZE * DATA_WIDTH)
      .ADDR_WIDTH(8),
      .RAM_DEPTH(256) // NUM_LEAVES
    ) ram_patch_inst_0_1 (
        .clk0(clk),  // Port 0: W
        .csb0(csb0),
        .web0(web0 && macro_select_0),
        .wmask0(4'hF),
        .addr0(addr0[7:0]),
        .din0(wpatch0[54:32]),
        .dout0(rpatch0_0[54:32]),
        .clk1(clk), // Port 1: R
        .csb1(csb1 && macro_select_0),
        .addr1(addr1[7:0]),
        .dout1(rpatch1_0[54:32])
    );
  
  
  
  
  
    sky130_sram_1kbyte_1rw1r_32x256_8
    #(
      .DATA_WIDTH(32), // round(PATCH_SIZE * DATA_WIDTH)
      .ADDR_WIDTH(8),
      .RAM_DEPTH(256) // NUM_LEAVES
    ) ram_patch_inst_1_0 (
        .clk0(clk),
        .csb0(csb0),
        .web0(web0 && macro_select_1),
        .wmask0(4'hF),
        .addr0(addr0[7:0]),
        .din0(wpatch0[31:0]),
        .dout0(rpatch0_1[31:0]),
        .clk1(clk),
        .csb1(csb1 && macro_select_1),
        .addr1(addr1[7:0]),
        .dout1(rpatch1_1[31:0])
    );
  
  
    sky130_sram_1kbyte_1rw1r_32x256_8
    #(
      .DATA_WIDTH(32), // round(PATCH_SIZE * DATA_WIDTH)
      .ADDR_WIDTH(8),
      .RAM_DEPTH(256) // NUM_LEAVES
    ) ram_patch_inst_1_1 (
        .clk0(clk),
        .csb0(csb0),
        .web0(web0 && macro_select_1),
         .wmask0(4'hF),
        .addr0(addr0[7:0]),
        .din0(wpatch0[54:32]),
        .dout0(rpatch0_1[54:32]),
        .clk1(clk),
        .csb1(csb1 && macro_select_1),
        .addr1(addr1[7:0]),
        .dout1(rpatch1_1[54:32])
    );
  
  
  
//     sky130_sram_1kbyte_1rw1r_32x256_8
//     #(
//       .DATA_WIDTH(DATA_WIDTH), // round(PATCH_SIZE * DATA_WIDTH)
//       .ADDR_WIDTH(7),
//       .RAM_DEPTH(128) // NUM_LEAVES
//     ) ram_patch_inst_2_1 (
//         .clk0(clk),
//         .csb0(csb0),
//         .web0(web0 && macro_select_2),
//         .addr0(addr0),
//         .din0(wpatch0),
//         .dout0(rpatch0),
//         .clk1(clk),
//         .csb1(csb1 && macro_select_2),
//         .addr1(addr1),
//         .dout1(rpatch1)
//     );
  
//     sky130_sram_1kbyte_1rw1r_32x256_8
//     #(
//       .DATA_WIDTH(DATA_WIDTH), // round(PATCH_SIZE * DATA_WIDTH)
//       .ADDR_WIDTH(7),
//       .RAM_DEPTH(128) // NUM_LEAVES
//     ) ram_patch_inst_2_1 (
//         .clk0(clk),
//         .csb0(csb0),
//         .web0(web0 && macro_select_2),
//         .addr0(addr0),
//         .din0(wpatch0),
//         .dout0(rpatch0),
//         .clk1(clk),
//         .csb1(csb1 && macro_select_2),
//         .addr1(addr1),
//         .dout1(rpatch1)
//     );
  
  
//     sky130_sram_1kbyte_1rw1r_32x256_8
//     #(
//       .DATA_WIDTH(DATA_WIDTH), // round(PATCH_SIZE * DATA_WIDTH)
//       .ADDR_WIDTH(7),
//       .RAM_DEPTH(128) // NUM_LEAVES
//     ) ram_patch_inst_3_0 (
//         .clk0(clk),
//         .csb0(csb0),
//         .web0(web0 && macro_select_3),
//         .addr0(addr0),
//         .din0(wpatch0),
//         .dout0(rpatch0),
//         .clk1(clk),
//         .csb1(csb1 && macro_select_3),
//         .addr1(addr1),
//         .dout1(rpatch1)
//     );
  
  
//     sky130_sram_1kbyte_1rw1r_32x256_8
//     #(
//       .DATA_WIDTH(DATA_WIDTH), // round(PATCH_SIZE * DATA_WIDTH)
//       .ADDR_WIDTH(7),
//       .RAM_DEPTH(128) // NUM_LEAVES
//     ) ram_patch_inst_3_1 (
//         .clk0(clk),
//         .csb0(csb0),
//         .web0(web0 && macro_select_3),
//         .addr0(addr0),
//         .din0(wpatch0),
//         .dout0(rpatch0),
//         .clk1(clk),
//         .csb1(csb1 && macro_select_3),
//         .addr1(addr1),
//         .dout1(rpatch1)
//     );
  
  
  
  
  
  
//     genvar i;
//     generate
//      for (i=0; i<4; i=i+1) begin : loop_ram_patch_gen  //We need 4 1kilobyte RAMS
//         sram_1kbyte_1rw1r
//         #(
//           .DATA_WIDTH(DATA_WIDTH), // round(PATCH_SIZE * DATA_WIDTH)
//           .ADDR_WIDTH(7),
//           .RAM_DEPTH(128) // NUM_LEAVES
//         ) ram_patch_inst (
//             .clk0(clk),
//             .csb0(csb0),
//             .web0(web0),
//             .addr0({2'b0, addr0}),
//             .din0(wdata0[i]),
//             .dout0(rdata0[i]),
//             .clk1(clk),
//             .csb1(csb1),
//             .addr1({2'b0, addr1}),
//             .dout1(rdata1[i])
//         );

//         assign wdata0[i] = {'0, wleaf0[i]};
//         assign rleaf0[i] = rdata0[i][PATCH_SIZE*DATA_WIDTH-1:0];
//         assign rleaf1[i] = rdata1[i][PATCH_SIZE*DATA_WIDTH-1:0];
//     end
//     endgenerate
  
  
  
 //  Ideal but CANT synthesize
//   ram_sync_1r1w
//   #(
//     .DATA_WIDTH(DATA_WIDTH),
//     .ADDR_WIDTH(ADDR_WIDTH),
//     .DEPTH(DEPTH)
//   ) ram_query_inst (
//     .clk(clk),
//     .wen(wen),
//     .wadr(wadr),
//     .wdata(sender_data),
//     .ren(ren),
//     .radr(radr),
//     .rdata(receiver_data)
//   );
  
  
  
  
  
  



endmodule


// module LeavesMem
// #(
//     parameter DATA_WIDTH = 11,
//     parameter LEAF_SIZE = 8,
//     parameter PATCH_SIZE = 5,
//     parameter NUM_LEAVES = 64,
//     parameter ADDR_WIDTH = $clog2(NUM_LEAVES)
// )
// (
//     input logic clk,

//     input logic                                       csb0,
//     input logic                                       web0,
//     input logic [ADDR_WIDTH-1:0]                      addr0,
//     input logic [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]     wleaf0 [LEAF_SIZE-1:0],
//     output logic  [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]   rleaf0 [LEAF_SIZE-1:0],
//     input logic                                       csb1,
//     input logic [ADDR_WIDTH-1:0]                      addr1,
//     output logic  [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]   rleaf1 [LEAF_SIZE-1:0]
// );

//     logic [63:0] wdata0 [LEAF_SIZE-1:0];
//     logic [63:0] rdata0 [LEAF_SIZE-1:0];
//     logic [63:0] rdata1 [LEAF_SIZE-1:0];

//     genvar i;
//     generate
//     for (i=0; i<LEAF_SIZE; i=i+1) begin : loop_ram_patch_gen
//         sram_1kbyte_1rw1r
//         #(
//             .DATA_WIDTH(64), // round(PATCH_SIZE * DATA_WIDTH)
//             .ADDR_WIDTH(8),
//             .RAM_DEPTH(256) // NUM_LEAVES
//         ) ram_patch_inst (
//             .clk0(clk),
//             .csb0(csb0),
//             .web0(web0),
//             .addr0({2'b0, addr0}),
//             .din0(wdata0[i]),
//             .dout0(rdata0[i]),
//             .clk1(clk),
//             .csb1(csb1),
//             .addr1({2'b0, addr1}),
//             .dout1(rdata1[i])
//         );

//         assign wdata0[i] = {'0, wleaf0[i]};
//         assign rleaf0[i] = rdata0[i][PATCH_SIZE*DATA_WIDTH-1:0];
//         assign rleaf1[i] = rdata1[i][PATCH_SIZE*DATA_WIDTH-1:0];
//     end
//     endgenerate

// endmodule
