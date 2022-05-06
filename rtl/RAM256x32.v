//ModifiedRTL from DFF Compilier
//WARNING: Need to diff with actually generated RTL

 module DFFRAM_RTL_256
 (
     CLK,
     WE,
     EN0,
     EN1,
     Di,
     Do0,
     Do1,
     A0,
     A1
 );
    localparam A_WIDTH = 8;

    input   wire            CLK;
    input   wire    [3:0]   WE;
    input   wire            EN0;
    input   wire            EN1;
    input   wire    [31:0]  Di;
    output  reg     [31:0]  Do0;
    output  reg     [31:0]  Do1;
    input   wire    [(A_WIDTH - 1): 0]   A0;
    input   wire    [(A_WIDTH - 1): 0]   A1;
    reg [31:0] RAM[(256)-1 : 0];

   always @(posedge CLK) begin
        if(EN0) begin
          Do0 <= RAM[A0];
          if(WE[0]) RAM[A0][ 7: 0] <= Di[7:0];
          if(WE[1]) RAM[A0][15:8] <= Di[15:8];
          if(WE[2]) RAM[A0][23:16] <= Di[23:16];
          if(WE[3]) RAM[A0][31:24] <= Di[31:24];
        end
        else begin
            Do0 <= 32'b0;
        end
    end
  
   always @(posedge CLK) begin
        if(EN1) begin
          Do1 <= RAM[A1];
        end
        else begin
           Do1 <= 32'b0;
        end
    end
  
 endmodule
