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
  input sender_enable,
  input [INTERNAL_WIDTH - 1 : 0] sender_data,
  input [5:0] sender_addr,
  input patch_en,
  input patch_two_en, 
  input [PATCH_WIDTH - 1 : 0] patch_in,
  input [PATCH_WIDTH - 1 : 0] patch_in_two,
  output logic [ADDRESS_WIDTH - 1 : 0] leaf_index,
  output logic [ADDRESS_WIDTH - 1 : 0] leaf_index_two,
  output receiver_en,
  output receiver_two_en,
  input wbs_rd_en_i, 
  output logic [21:0] wbs_dat_o


);

wire wen;
assign wen = sender_enable;



reg [INTERNAL_WIDTH-1:0] rdata_storage [63:0]; //For index and median read from tree
reg [INTERNAL_WIDTH - 1 : 0]  write_data;



always @ (posedge clk) begin 
    if (rst_n == 0) begin
        wbs_dat_o <= {INTERNAL_WIDTH{1'b0}};
    end
    else if (wbs_rd_en_i) begin
        wbs_dat_o <= rdata_storage[sender_addr]; //read address is same as write address
    end
end

 



reg [5:0] wadr; //Internal state holding current address to be read (2^6 internal nodes)
reg  one_hot_address_en [63:0]; //TODO: Fix width on these
wire [PATCH_WIDTH - 1 : 0] patch_out;


 

 //Register for keeping track of whether output is valid (keeps track of pipelined inputs as well.
 // This handles the 6 cycle latency of this setup
 reg latency_track_reciever_en [6:0];
 reg latency_track_reciever_two_en [6:0];
 
 always @ (posedge clk) begin
     if (rst_n == 0) begin
      latency_track_reciever_en[0] <= 0;
      latency_track_reciever_en[1] <= 0;
      latency_track_reciever_en[2] <= 0;
      latency_track_reciever_en[3] <= 0;
      latency_track_reciever_en[4] <= 0;
      latency_track_reciever_en[5] <= 0;
      latency_track_reciever_en[6] <= 0;

      latency_track_reciever_two_en[0] <= 0;
      latency_track_reciever_two_en[1] <= 0;
      latency_track_reciever_two_en[2] <= 0;
      latency_track_reciever_two_en[3] <= 0;
      latency_track_reciever_two_en[4] <= 0;
      latency_track_reciever_two_en[5] <= 0;
      latency_track_reciever_two_en[6] <= 0;
 
    end
    else begin
      latency_track_reciever_en[0] <= patch_en;
      latency_track_reciever_en[1] <= latency_track_reciever_en[0];
      latency_track_reciever_en[2] <= latency_track_reciever_en[1];
      latency_track_reciever_en[3] <= latency_track_reciever_en[2];
      latency_track_reciever_en[4] <= latency_track_reciever_en[3];
      latency_track_reciever_en[5] <= latency_track_reciever_en[4];
      latency_track_reciever_en[6] <= latency_track_reciever_en[5];

      latency_track_reciever_two_en[0] <= patch_two_en;
      latency_track_reciever_two_en[1] <= latency_track_reciever_two_en[0];
      latency_track_reciever_two_en[2] <= latency_track_reciever_two_en[1];
      latency_track_reciever_two_en[3] <= latency_track_reciever_two_en[2];
      latency_track_reciever_two_en[4] <= latency_track_reciever_two_en[3];
      latency_track_reciever_two_en[5] <= latency_track_reciever_two_en[4];
      latency_track_reciever_two_en[6] <= latency_track_reciever_two_en[5];
    end
  
 end
 
 assign receiver_en = latency_track_reciever_en[6];
 assign receiver_two_en = latency_track_reciever_two_en[6];



//Create 7:128 Decoder to create address system for writing to internal nodes
//Result is a 1 hot signal, where the index that includes the 1 corresponds to the internal_node that will be written to.
always @(*) begin 

    for (int q = 0; q < 128; q++) begin

        if (q == sender_addr) begin
            one_hot_address_en[q] = 1'b1; //TODO: Does this synthesize well?
        end
        else begin
            one_hot_address_en[q] = 1'b0;
        end
    end
end




// Generate the internal kd tree

reg [PATCH_WIDTH-1:0] level_patches [7:0]; //For storing patch
reg [PATCH_WIDTH-1:0] level_patches_two [7:0]; //For storing patch
reg level_valid [63:0][7:0]; //for storing valid signals
reg level_valid_two [63:0][7:0]; //for storing valid signals
wire level_valid_storage [63:0][7:0]; //for storing valid signals
wire level_valid_storage_two [63:0][7:0]; //for storing valid signals


 
 
 
genvar i, j;

generate 
    
   for (i = 0; i < 6; i = i +1) begin

        // wire [2*(2**i)] valid_output;
        //Fan out like a tree (TODO: Check that 2**i doesn't cause synthesis problems)
    
       //NEW! We do patch pipeling in the outer loop. See the diagram of how the patch is moved through the registers
      // For more clarity
      //level_patches_storage[i] = level_patches[i];
      
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
            .wen(wen && one_hot_address_en[(((2**i)) + j-1)]), //Determined by FSM, reciever enq, and DECODER indexed at i. TODO Check slice
            .valid(level_valid[j][i]),
            .valid_two(level_valid_two[j][i]),
            .wdata(sender_data), //writing mechanics are NOT pipelined
            .patch_in(level_patches[i]),
            .patch_in_two(level_patches_two[i]),
            .valid_left(level_valid_storage[j*2][i]),
            .valid_right(level_valid_storage[(j*2)+1][i]),
            .valid_left_two(level_valid_storage_two[j*2][i]),
            .valid_right_two(level_valid_storage_two[(j*2)+1][i]),
            .rdata(rdata_storage[(((2**i)) + j-1)])
            );

        //  assign valid_output[(j*2)+1:(j*2)] = vl;
        //  assign valid_output[(j*2)+2:(j*2)+1] = vr;
      
            
        end

        
    end

endgenerate


 
 //NEW register input
 always @ (posedge clk) begin

    if (rst_n == 0) begin
     level_patches[0] <= 55'b0;
     level_patches_two[0] <=  55'b0; 

        for (int r = 0; r < 64; r++) begin
         level_valid[r][0] <= 1'b0;
         level_valid_two[r][0] <= 1'b0;
        end
    end

  else if (patch_en && patch_two_en) begin //Only update patch when enabled
     level_patches[0] <= patch_in;
     level_patches_two[0] <= patch_in_two;
     
     level_valid[0][0] <= 1'b1;
     level_valid_two[0][0] <=  1'b1;

        for (int r = 1; r < 64; r++) begin
         level_valid[r][0] <= 1'b0;
         level_valid_two[r][0] <= 1'b0;
        end
    end
  
   else begin
    
     level_patches[0] <= level_patches[0];
     level_patches_two[0] <= level_patches_two[0];
     
     level_valid[0][0] <= 1'b1;
     level_valid_two[0][0] <=  1'b1;

        for (int r = 1; r < 64; r++) begin
         level_valid[r][0] <= 1'b0;
         level_valid_two[r][0] <= 1'b0;
        end
    
   end
  
end
 
 
always @ (posedge clk) begin

    if (rst_n == 0) begin
        level_patches[1] <= 55'b0;
        level_patches_two[1] <=  55'b0; 

        for (int r = 0; r < 64; r++) begin
         level_valid[r][1] <= 1'b0;
         level_valid_two[r][1] <= 1'b0;
        end
    end

    else begin
        level_patches[1] <= level_patches[0];
        level_patches_two[1] <= level_patches_two[0];

          for (int r = 0; r < 64; r++) begin
           level_valid[r][1] <= level_valid_storage[r][0];
           level_valid_two[r][1] <= level_valid_storage_two[r][0];
        end
    end
end


always @ (posedge clk) begin

    if (rst_n == 0) begin
        level_patches[2] <= 55'b0;
        level_patches_two[2] <=  55'b0; 

        for (int r = 0; r < 64; r++) begin
         level_valid[r][2] <= 1'b0;
         level_valid_two[r][2] <= 1'b0;
        end
    end

    else begin
        level_patches[2] <= level_patches[1];
        level_patches_two[2] <= level_patches_two[1];

          for (int r = 0; r < 64; r++) begin
           level_valid[r][2] <= level_valid_storage[r][1];
           level_valid_two[r][2] <= level_valid_storage_two[r][1];
        end
    end
end


always @ (posedge clk) begin

    if (rst_n == 0) begin
        level_patches[3] <= 55'b0;
        level_patches_two[3] <=  55'b0; 

        for (int r = 0; r < 64; r++) begin
         level_valid[r][3] <= 1'b0;
         level_valid_two[r][3] <= 1'b0;
        end
    end

    else begin
        level_patches[3] <= level_patches[1];
        level_patches_two[3] <= level_patches_two[1];

          for (int r = 0; r < 64; r++) begin
           level_valid[r][3] <= level_valid_storage[r][2];
           level_valid_two[r][3] <= level_valid_storage_two[r][2];
        end
    end
end



always @ (posedge clk) begin

    if (rst_n == 0) begin
        level_patches[4] <= 55'b0;
        level_patches_two[4] <=  55'b0; 

        for (int r = 0; r < 64; r++) begin
         level_valid[r][4] <= 1'b0;
         level_valid_two[r][4] <= 1'b0;
        end
    end

    else begin
        level_patches[4] <= level_patches[3];
        level_patches_two[4] <= level_patches_two[3];

          for (int r = 0; r < 64; r++) begin
           level_valid[r][4] <= level_valid_storage[r][3];
           level_valid_two[r][4] <= level_valid_storage_two[r][3];
        end
    end
end


always @ (posedge clk) begin

    if (rst_n == 0) begin
        level_patches[5] <= 55'b0;
        level_patches_two[5] <=  55'b0; 

        for (int r = 0; r < 64; r++) begin
         level_valid[r][5] <= 1'b0;
         level_valid_two[r][5] <= 1'b0;
        end
    end

    else begin
        level_patches[5] <= level_patches[4];
        level_patches_two[5] <= level_patches_two[4];

          for (int r = 0; r < 64; r++) begin
           level_valid[r][5] <= level_valid_storage[r][4];
           level_valid_two[r][5] <= level_valid_storage_two[r][4];
        end
    end
end


always @ (posedge clk) begin

    if (rst_n == 0) begin
        level_patches[6] <= 55'b0;
        level_patches_two[6] <=  55'b0; 

        for (int r = 0; r < 64; r++) begin
         level_valid[r][6] <= 1'b0;
         level_valid_two[r][6] <= 1'b0;
        end
    end

    else begin
        level_patches[6] <= level_patches[5];
        level_patches_two[6] <= level_patches_two[5];

          for (int r = 0; r < 64; r++) begin
           level_valid[r][6] <= level_valid_storage[r][5];
           level_valid_two[r][6] <= level_valid_storage_two[r][5];
        end
    end
end
 
 
 

//From the last row, determine the leaf index
//Algo source: https://stackoverflow.com/a/62776453

always @(*) begin

    leaf_index = 0;
    for (int i = 0; i < 64; i++) begin
        if (level_valid[i][6] == 1'b1) begin
          leaf_index = i;
        end
    end


    leaf_index_two = 0;
    for (int i = 0; i < 64; i++) begin
        if (level_valid_two[i][6] == 1'b1) begin
          leaf_index_two = i;
        end
    end


end

endmodule









