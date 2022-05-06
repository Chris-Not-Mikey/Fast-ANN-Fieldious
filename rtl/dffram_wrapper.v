//Original Author: CryptoChip (Sam and Kylee)
//Modified: Chris Calloway, cmc2374@stanford.edu


`default_nettype wire
module dffram_wrapper
#(
  parameter DATA_WIDTH = 32,
  parameter ADDR_WIDTH = 8,
  parameter RAM_DEPTH = 128,               
  parameter NUM_WMASKS = 4,
 
)(
//   input CLK,
//   input [( (DATA_WIDTH + 8 - 1) / 8) - 1 : 0]WE,
//   input EN,
//   input [ADDR_WIDTH - 1 : 0] A,
//   input [DATA_WIDTH - 1 : 0] Di,
//   output [DATA_WIDTH - 1 : 0] Do
  
  
  input  clk0, // clock
  input   csb0, // active low chip select
  input  web0, // active low write control
  input [ADDR_WIDTH-1:0]  addr0,
  input [DATA_WIDTH-1:0]  din0,
  output [DATA_WIDTH-1:0] dout0,
  input  clk1, // clock
  input   csb1, // active low chip select
  input [ADDR_WIDTH-1:0]  addr1,
  output [DATA_WIDTH-1:0] dout1
);
  
  
  
  reg [ADDR_WIDTH-1:0]  addr0_r;
  reg [ADDR_WIDTH-1:0]  addr1_r;
  always @ (posedge clk1) begin
    addr0_r <= addr0;
    addr1_r <= addr1;
  end

  wire [DATA_WIDTH-1:0] dout0_w [RAM_DEPTH/256-1:0];
  wire [DATA_WIDTH-1:0] dout1_w [RAM_DEPTH/256-1:0];
  genvar i, j;
  generate 
    for (i=0; i<RAM_DEPTH/256; i=i+1) begin : loop_depth_gen
      for (j=0; j<DATA_WIDTH/32; j=j+1) begin : loop_width_gen
        if (ADDR_WIDTH == 8) begin
          DFFRAM_RTL_256 dffram (
          .CLK(clk0),
            .WE(4'hF), //Wen and Mask Equivelent to SRAM
          .EN0(csb0),// CS equivlaent to SRAM. Note: Convert from active low to active high
            .EN1(csb1),
            .Di(din0[j*32+:32]), //DIN
          .Do0(dout0_w[i][j*32+:32]),
          .Do1(dout1_w[i][j*32+:32]),
          .A0(addr0[7:0]),
          .A1(addr1[7:0])
        );
        end
        
        else begin
          
          DFFRAM_RTL_256 dffram (
          .CLK(clk0),
            .WE(4'hF), // Wen Mask Equivelent to SRAM
          .EN0(addr0[ADDR_WIDTH-1:8] == i ? csb0 : 1'b1 ),// CS equivlaent to SRAM. Note: Convert from active low to active high
          .EN1(addr1[ADDR_WIDTH-1:8] == i ? csb1 : 1'b1 ),
          .Di(din0[j*32+:32]), //DIN
          .Do0(dout0_w[i][j*32+:32]),
          .Do1(dout1_w[i][j*32+:32]),
          .A0(addr0[7:0]),
          .A1(addr1[7:0])
        );
          
        end
  
    
      end
    end
    
    if (ADDR_WIDTH == 8)
      assign dout0 = dout0_w[0];
    else 
      assign dout0 = dout0_w[addr0_r[ADDR_WIDTH-1:8]];

    if (ADDR_WIDTH == 8)
      assign dout1 = dout1_w[0];
    else 
      assign dout1 = dout1_w[addr1_r[ADDR_WIDTH-1:8]];
  endgenerate
  
  
endmodule
