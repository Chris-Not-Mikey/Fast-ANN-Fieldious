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
  input [PATCH_WIDTH - 1 : 0] patch_in,
  output [ADDRESS_WIDTH - 1 : 0] leaf_index
);


reg [6:0] wadr; //Internal state holding current address to be read (2^7 internal nodes)
reg [127:0] one_hot_address_en;
wire [127:0] one_hot_shifter;

assign one_hot_shifter = 128'b1;

wire wen;

assign wen = fsm_enable && sender_enable;


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

    if (wadr == 7'b0000000) begin
        one_hot_address_en = 128'b0;
    end
        
    else begin
        one_hot_address_en = one_hot_shifter << wadr;//shift 0000...001 over by wadr (max 2^7) bits
    end 
    
end




// Generate the internal kd tree



reg [PATCH_WIDTH-1:0] level_patches [7:0]; //For storing patch
reg [255:0] level_valid [7:0]; //for storing valid signals


always @(*) begin
    level_valid[0] = 255'b1;
    level_patches[0] = patch_in;

end
 
genvar i, j;

generate 
    
    for (i = 0; i < 7; i = i +1) begin

        wire [2**(2**i)]valid_output;
        //Fan out like a tree (TODO: Check that 2**i doesn't cause synthesis problems)
        genvar d;
        for (j =0; j < (2**i); j = j +1 ) begin
         
         for (d =j; d < j; d++) begin
         end

            wire vl;
            wire vr;

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
            .wen(wen && one_hot_address_en[((i * (2**i)) + j)+1:((i * (2**i)) + j)]), //Determined by FSM, reciever enq, and DECODER indexed at i. TODO Check slice
            .valid(level_valid[i][j+1:j]),
            .wdata(sender_data), //writing mechanics are NOT pipelined
            .patch_in(level_patches[i]),
            .patch_out(patch_out), //TODO REMOVE this, we don't need to store this at the internal node level
            .valid_left(vl),
            .valid_right(vr)
            );

            assign valid_output[d+1:d] = vl;
            assign valid_output[d+2:d+1] = vr;
         
        
            
        end



        
        //Create register per depth that holds current patch and valids

        always @ (posedge clk) begin

            if (rst_n == 0) begin
                level_patches[i+1] <= 0;
                level_valid[i+1] <= 255'b0;
            end
            else begin
                level_patches[i+1] <= level_patches[i];
                level_valid[i+1] <= valid_output;
            end

        end

        

    end


endgenerate


//From the last row, determine the leaf index
//Algo source: https://stackoverflow.com/a/62776453

always @(*) begin

    out = 0;
    for (int i = 0; i < 256; i++) begin
        if (level_valid[7][i+1:i] == 1'b1) begin
          leaf_index = i;
        end
    end


end

endmodule
