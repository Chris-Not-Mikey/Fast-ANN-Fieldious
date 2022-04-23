module sram_1kbyte_1rw1r#(
  parameter NUM_WMASKS = 4,
  parameter DATA_WIDTH = 32,
  parameter ADDR_WIDTH = 8,
  parameter RAM_DEPTH = 256,
  parameter DELAY = 1
)(
  input  clk0, // clock
  input   csb0, // active low chip select
  input  web0, // active low write control
  input [ADDR_WIDTH-1:0]  addr0,
  input [DATA_WIDTH-1:0]  din0,
  output [DATA_WIDTH-1:0] dout0,
  input  clk1, // clock
  input   csb1, // active low chip select
  input [ADDR_WIDTH-1:0]  addr1,
  output [DATA_WIDTH-1:0] dout1,
  input [7:0] wmask0
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
          sky130_sram_1kbyte_1rw1r_32x256_8 #(.DELAY(DELAY)) 
          sram_macro (
            .clk0(clk0),.csb0(csb0),.web0(web0),.wmask0(wmask0[((j+1)*4) -1 :(j*4)]),.addr0(addr0[7:0]),.din0(din0[j*32+:32]), .dout0(dout0_w[i][j*32+:32]),
            .clk1(clk1),.csb1(csb1),.addr1(addr1[7:0]),.dout1(dout1_w[i][j*32+:32])
          );
        end
        else begin
          sky130_sram_1kbyte_1rw1r_32x256_8 #(.DELAY(DELAY)) 
          sram_macro (
            .clk0(clk0),.csb0(addr0[ADDR_WIDTH-1:8] == i ? csb0 : 1'b1),.web0(web0),.wmask0(wmask0[((j+1)*4) -1 :(j*4)]),.addr0(addr0[7:0]),.din0(din0[j*32+:32]), .dout0(dout0_w[i][j*32+:32]),
            .clk1(clk1),.csb1(addr1[ADDR_WIDTH-1:8] == i ? csb1 : 1'b1),.addr1(addr1[7:0]),.dout1(dout1_w[i][j*32+:32])
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
