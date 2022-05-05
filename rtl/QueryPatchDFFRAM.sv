module QueryPatchDFFRAM
#(
  parameter DATA_WIDTH = 11,
  parameter PATCH_SIZE = 5,
  parameter ADDR_WIDTH = 9,
  parameter DEPTH = 512,
  parameter WB_ADDRESS_OFFSET = 557
)
(

    input logic                                       clk,
    input logic                                       csb0,
    input logic                                       web0,
    input logic [ADDR_WIDTH-1:0]                      addr0,
    input logic [DATA_WIDTH*PATCH_SIZE-1:0]           wpatch0,
    output logic  [DATA_WIDTH*PATCH_SIZE-1:0]         rpatch0,
    input logic                                       csb1,
    input logic [ADDR_WIDTH-1:0]                      addr1,
    output logic  [DATA_WIDTH*PATCH_SIZE-1:0]         rpatch1,

    input wb_mode,
    input wb_clk_i, 
    input wb_rst_i, 
    input wbs_stb_i, 
    input wbs_cyc_i, 
    input wbs_we_i, 
    input [3:0] wbs_sel_i, 
    input [31:0] wbs_dat_i, 
    input [31:0] wbs_adr_i, 
    output wbs_ack_o, 
    output [31:0] wbs_dat_o

);
  
  
    
    logic [63:0] wdata0;
    logic [63:0] rdata0;
    logic [63:0] rdata1;
    logic [7:0] wmask;
    logic wen;
    logic [ADDR_WIDTH-1:0] ram_addr0;
  

    reg [7:0] wb_mask; //We will determine wmask based on on the input data
    wire [7:0] io_mask; //Fully permissice mask that is used in non-wishbone mode
    assign io_mask = 8'hFF;


    reg [31:0] wb_addr;
    reg [63:0] wb_wdata0;
    reg [31:0] wb_dat_o;


    always @(*) begin

        wb_addr = wbs_adr_i - WB_ADDRESS_OFFSET;

       if (wb_mode && wbs_we_i) begin

            //Determine what the mask should be
            //and place the darta in the appropiate section
            //Logically we would read in 11 bits at a time. However, this does not work will with the SRAM. Thus we read 8 bits at a time
            

            case(wbs_dat_i[13:11]) 

                3'b000: begin 
                    wb_mask = 8'b00000001;     
                    wb_wdata0 = {56'b0, wbs_dat_i[7:0]};
                end
                3'b001: begin
                    wb_mask = 8'b00000010;
                    wb_wdata0 = {48'b0, wbs_dat_i[7:0], 8'b0};
                end
                3'b010: begin 
                    wb_mask = 8'b00000100;
                    wb_wdata0 = {40'b0, wbs_dat_i[7:0], 16'b0};
                end
                3'b011: begin
                    wb_mask = 8'b00001000;
                    wb_wdata0 = {32'b0, wbs_dat_i[7:0], 24'b0};
                end
                3'b100: begin
                    wb_mask = 8'b00010000;
                    wb_wdata0 = {24'b0, wbs_dat_i[7:0], 32'b0};
                end
                3'b101: begin
                    wb_mask = 8'b00100000;
                    wb_wdata0 = {16'b0, wbs_dat_i[7:0], 40'b0};
                end
                3'b110: begin
                    wb_mask = 8'b01000000;
                    wb_wdata0 = {8'b0, wbs_dat_i[7:0], 48'b0};
                end
                3'b111: begin
                    wb_mask = 8'b10000000;
                    wb_wdata0 = {wbs_dat_i[7:0], 56'b0};
                end

                default: begin
                    wb_mask = 8'b00000001;
                    wb_wdata0 = {56'b0, wbs_dat_i[7:0]};
                end


            endcase

       end

            //Reading Logic

            else if (wb_mode && !wbs_we_i) begin

            
            end


        //If not wb
        else begin
            wb_mask = 8'hFF;
        end

    end



  
   

    assign wdata0 = wb_mode ? wb_wdata0 :  {'0, wpatch0};
    assign wmask = wb_mode ? wb_mask :  io_mask;

    assign wen = wb_mode ? !wbs_we_i : web0;
    assign ram_addr0 = wb_mode ? wb_addr[ADDR_WIDTH-1:0] : addr0;


    assign rpatch0 = rdata0[PATCH_SIZE*DATA_WIDTH-1:0];
    assign rpatch1 = rdata1[PATCH_SIZE*DATA_WIDTH-1:0];
    assign wbs_dat_o = (!wbs_dat_i[11]) ? rpatch0[31:0] : {9'b0, rpatch0[54:32]} ;

    dffram_wrapper
    #(
        .DATA_WIDTH(64), // round_up(PATCH_SIZE * DATA_WIDTH)
        .ADDR_WIDTH(ADDR_WIDTH),
        .RAM_DEPTH(DEPTH) // round_up(26*19)
    ) ram_patch_inst (
        .clk0(clk),
        .csb0(csb0),
        .web0(wen),
        .addr0(ram_addr0),
        .din0(wdata0),
        .dout0(rdata0),
        .clk1(clk),
        .csb1(csb1),
        .addr1(addr1),
        .dout1(rdata1),
        .wmask0(wmask)
    );

endmodule
