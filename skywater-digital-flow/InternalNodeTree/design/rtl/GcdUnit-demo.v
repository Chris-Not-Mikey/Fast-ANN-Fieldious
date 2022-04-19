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
  input [STORAGE_WIDTH -1 : 0] wdata,
  input [DATA_WIDTH - 1 : 0] patch_in,
  output [DATA_WIDTH - 1 : 0] patch_out, //Same patch, but we will be pipeling so it will be useful to adopt this input/ouput scheme
  output valid_left,
  output valid_right

);


reg [2:0] idx;
reg signed [10: 0] median; 
reg signed [10: 0] sliced_patch;

 
 

wire comparison;

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
       3'b000 :   sliced_patch = patch_in[10:0];
       3'b001 :   sliced_patch = patch_in[21:11];
       3'b010 :   sliced_patch = patch_in[32:22];
       3'b011 :   sliced_patch = patch_in[43:33];
       3'b100 :   sliced_patch = patch_in[54:44];
       default :  sliced_patch = 11'b0;
    endcase 
end


assign comparison = (sliced_patch < median);

assign valid_left = comparison && valid;
assign valid_right = (!comparison) && valid;
assign patch_out = patch_in;



endmodule




/*
 A module for an register based tree of internal node of a KD-Tree
 A set of these nodes will be instantiated together to make an actual tree,
 this is a physical description of the node of the tree. 

  Author: Chris Calloway, cmc2374@stanford.edu
*/


module internal_node_tree
#(
  parameter INTERNAL_WIDTH = 22,
  parameter PATCH_WIDTH = 55,
  parameter ADDRESS_WIDTH = 8
)
(
  input clk,
  input rst_n,
  input fsm_enable, //based on whether we are at the proper I/O portion
  input sender_enable,
  input [INTERNAL_WIDTH - 1 : 0] sender_data,
  input patch_en,
  input [PATCH_WIDTH - 1 : 0] patch_in,
  output logic [ADDRESS_WIDTH - 1 : 0] leaf_index,
  output receiver_en
);
 



reg [5:0] wadr; //Internal state holding current address to be read (2^6 internal nodes)
reg  one_hot_address_en [63:0]; //TODO: Fix width on these
wire [PATCH_WIDTH - 1 : 0] patch_out;

wire wen;
assign wen = fsm_enable && sender_enable;
 

 //Register for keeping track of whether output is valid (keeps track of pipelined inputs as well.
 // This handles the 6 cycle latency of this setup
 reg latency_track_reciever_en [5:0];
 
 always @ (posedge clk) begin
     if (rst_n == 0) begin
      latency_track_reciever_en[0] <= 0;
      latency_track_reciever_en[1] <= 0;
      latency_track_reciever_en[2] <= 0;
      latency_track_reciever_en[3] <= 0;
      latency_track_reciever_en[4] <= 0;
      latency_track_reciever_en[5] <= 0;
    end
    else begin
      latency_track_reciever_en[0] <= patch_en;
      latency_track_reciever_en[1] <= latency_track_reciever_en[0];
      latency_track_reciever_en[2] <= latency_track_reciever_en[1];
      latency_track_reciever_en[3] <= latency_track_reciever_en[2];
      latency_track_reciever_en[4] <= latency_track_reciever_en[3];
      latency_track_reciever_en[5] <= latency_track_reciever_en[4];
    end
  
 end
 
 assign receiver_en = latency_track_reciever_en[5];


//Register for storing and updating address
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

//Create 7:128 Decoder to create address system for writing to internal nodes
//Result is a 1 hot signal, where the index that includes the 1 corresponds to the internal_node that will be written to.
always @(*) begin 

 for (int q = 0; q < 128; q++) begin
        if (q == wadr) begin
            one_hot_address_en[q] = 1'b1; //TODO: Does this synthesize well?
        end
        else begin
             one_hot_address_en[q] = 1'b0;
        end
    end

end




// Generate the internal kd tree

reg [PATCH_WIDTH-1:0] level_patches [7:0]; //For storing patch
wire [PATCH_WIDTH-1:0] level_patches_storage [7:0]; //For storing patch
reg level_valid [63:0][7:0]; //for storing valid signals
wire level_valid_storage [63:0][7:0]; //for storing valid signals

 assign level_patches_storage[0] = patch_in;
 


always @(*) begin
    
    level_valid[0][0] = 255'b1;
    level_patches[0] = patch_in;

end
 
 
 
genvar i, j;

generate 
    
   for (i = 0; i < 6; i = i +1) begin

        // wire [2*(2**i)] valid_output;
        //Fan out like a tree (TODO: Check that 2**i doesn't cause synthesis problems)
      
        for (j =0; j < (2**i); j = j +1 ) begin
         
             

         //((i * (2**i)) + j) i * (number of iterations of j)+ j //Keep track of one_hot_address_en
         
            internal_node
            #(
            .DATA_WIDTH(PATCH_WIDTH),
            .STORAGE_WIDTH(INTERNAL_WIDTH)
            )
            node
            (
            .clk(clk),
            .rst_n(rst_n),
             .wen(wen), //Determined by FSM, reciever enq, and DECODER indexed at i. TODO Check slice
             .valid(1'b0),
            .wdata(sender_data), //writing mechanics are NOT pipelined
             .patch_in(55'b0),
             .patch_out(55'b0), //TODO REMOVE this, we don't need to store this at the internal node level
             .valid_left(1'b0),
             .valid_right(1'b0)
            );

        //  assign valid_output[(j*2)+1:(j*2)] = vl;
        //  assign valid_output[(j*2)+2:(j*2)+1] = vr;
      
            
        end



        
        //Create register per depth that holds current patch and valids

        always @ (posedge clk) begin

            if (rst_n == 0) begin
                level_patches[i+1] <= 0;
                 for (int r = 0; r < 64; r++) begin
                     level_valid[r][i+1] = 1'b0;
                 end
             
            end
            else begin
                level_patches[i+1] <= level_patches_storage[i];
                //level_valid[i+1] <= level_valid[i];
                 for (int r = 0; r < 64; r++) begin
                    level_valid[r][i+1] = level_valid_storage[r][i];
                 end
            end

        end

        
    end


endgenerate


//From the last row, determine the leaf index
//Algo source: https://stackoverflow.com/a/62776453

always @(*) begin

    leaf_index = 0;
     for (int i = 0; i < 64; i++) begin
        if (level_valid[i][6] == 1'b1) begin
          leaf_index = i;
        end
    end


end

endmodule






