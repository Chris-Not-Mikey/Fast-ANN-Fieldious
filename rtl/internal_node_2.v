/*
 A module for an internal node of a KD-Tree
 A set of these nodes will be instantiated together to make an actual tree,
 this is a physical description of the node of the tree. 
  Author: Chris Calloway, cmc2374@stanford.edu
*/


module internal_node
#(
  parameter DATA_WIDTH = 55,
  parameter STORAGE_WIDTH = 22
)
(
  input clk,
  input rst_n,
  input wen, //Determined by FSM, reciever enq, and DECODER from KD Tree
  input valid,
  input valid_two,
  input [STORAGE_WIDTH -1 : 0] wdata,
  input [DATA_WIDTH - 1 : 0] patch_in,
  input [DATA_WIDTH - 1 : 0] patch_in_two,
//   output [DATA_WIDTH - 1 : 0] patch_out, //Same patch, but we will be pipeling so it will be useful to adopt this input/ouput scheme
  output valid_left,
  output valid_right,
  output valid_left_two,
  output valid_right_two,
  output [STORAGE_WIDTH-1: 0] rdata

);


reg [2:0] idx;
reg signed [10: 0] median; 
reg signed [10: 0] sliced_patch;
reg signed [10: 0] sliced_patch_two;

 
 

wire comparison;
wire comparison_two;

//Wdata: 1st 11 bits is Index (which can slice to the  3 LSB bits) since we gave 5 indeces, and 5 < 2^3.
// 2nd 11 bits are the Median, for which we must store the entire 11 bits

//IDX Storage
always @ (clk) begin

    if (rst_n == 0) begin
        idx <= 3'b111; //-1 is an invalid index, this by default we know this to be untrue
    end
    else if (wen) begin
        idx <= wdata[2:0]; //Get 3 LSB
    end
    else begin
        idx <= idx; //No change / persist in memory 
    end

end


//Median Storage
always @ (clk) begin

    if (rst_n == 0) begin
        median <= 0; //0 is an urealistic median, this by default we (likely) know this to be untrue. The -1 idx is the true debug test
    end
    else if (wen) begin
        median <= wdata[21:11]; //Get Median
    end
    else begin
        median <= median; //No change / persist in memory 
    end

end

//Slice Component to get the proper value from the incoming patch based on stored dimension.
 //NOTE: some testbenches have this order flipped (think endianess) You may need to flip the order of these case statements
always @(*) begin 
    case(idx)
       3'b000 :   begin
                sliced_patch = patch_in[10:0];
                sliced_patch_two = patch_in_two[10:0];
       end
       3'b001 :  begin
            sliced_patch = patch_in[21:11];
             sliced_patch_two = patch_in_two[21:11];
       end
       3'b010 : begin
            sliced_patch = patch_in[32:22];
            sliced_patch_two = patch_in_two[32:22];
       end   
 
       3'b011 :   begin
            sliced_patch = patch_in[43:33];
            sliced_patch_two = patch_in_two[43:33];
       end    
       3'b100 :  begin
            sliced_patch = patch_in[54:44];
            sliced_patch_two = patch_in_two[54:44];
       end

       default :  begin
            sliced_patch = 11'b0;;
            sliced_patch_two =11'b0;;
       end
       
       
        // sliced_patch = 11'b0;
    endcase 
end


assign comparison = (sliced_patch < median);
assign comparison_two = (sliced_patch_two < median);

assign valid_left = comparison && valid;
assign valid_right = (!comparison) && valid;


assign valid_left_two = comparison_two && valid_two;
assign valid_right_two = (!comparison_two) && valid_two;



// assign patch_out = patch_in; //deprecated

assign rdata = {median, 8'b0, idx}; //fill to 22 in width



endmodule

