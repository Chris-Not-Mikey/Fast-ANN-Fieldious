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
  parameter ADDRESS_WIDTH = 8,
  parameter WB_ADDRESS_OFFSET = 495
)
(
  input clk,
  input rst_n,
  input fsm_enable, //based on whether we are at the proper I/O portion
  input sender_enable,
  input [INTERNAL_WIDTH - 1 : 0] sender_data,
  input patch_en,
  input patch_two_en, 
  input [PATCH_WIDTH - 1 : 0] patch_in,
  input [PATCH_WIDTH - 1 : 0] patch_in_two,
  output logic [ADDRESS_WIDTH - 1 : 0] leaf_index,
  output logic [ADDRESS_WIDTH - 1 : 0] leaf_index_two,
  output receiver_en,
  output receiver_two_en,
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

wire wen;

assign wen = fsm_enable && sender_enable && (!wb_mode);


//Wishbone interface

reg [INTERNAL_WIDTH-1:0] rdata_storage [63:0]; //For index and median read from tree

reg [INTERNAL_WIDTH - 1 : 0]  write_data;

reg wb_wen;
reg [31:0] wb_out;
reg ack;
wire signed [31:0] wb_addr; //Will only use top 6 bits of this

assign wb_addr = wbs_adr_i - WB_ADDRESS_OFFSET;
 assign wbs_ack_o = ack;
 
 


 assign wbs_dat_o = {21'b0, wb_out[10:0]};


always @(*) begin 

    if (wb_mode) begin


        if (wbs_we_i) begin //active high wen

           if (wbs_dat_i[11] == 1'b0) begin
                write_data[10:0] = wbs_dat_i[10:0]; //if index is 0
                wb_wen = 1'b0;
                ack = 1'b0;

            end
            else begin
                write_data[21:11] = wbs_dat_i[10:0]; //second half
                wb_wen = 1'b1; //written all data so set wen

                ack = 1'b1;
            
            end
        end

        //if not write, then read

        else begin
         
           wb_wen = 1'b0;

           if (wbs_dat_i[11] == 1'b0) begin
 

                wb_out[10:0] = rdata_storage[wb_addr[5:0]][10:0]; //read address is same as write address
                ack = 1'b1;

            end
            else begin
                wb_out[10:0] = rdata_storage[wb_addr[5:0]][21:11]; //read address is same as write address
                ack = 1'b1;
            
            end

        end




    end
    //Normal I/O mode
    else begin 
        write_data = sender_data;
       
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
      //latency_track_reciever_en[6] <= 0;

      latency_track_reciever_two_en[0] <= 0;
      latency_track_reciever_two_en[1] <= 0;
      latency_track_reciever_two_en[2] <= 0;
      latency_track_reciever_two_en[3] <= 0;
      latency_track_reciever_two_en[4] <= 0;
      latency_track_reciever_two_en[5] <= 0;
      //latency_track_reciever_two_en[6] <= 0;
    end
    else begin
      latency_track_reciever_en[0] <= patch_en;
      latency_track_reciever_en[1] <= latency_track_reciever_en[0];
      latency_track_reciever_en[2] <= latency_track_reciever_en[1];
      latency_track_reciever_en[3] <= latency_track_reciever_en[2];
      latency_track_reciever_en[4] <= latency_track_reciever_en[3];
      latency_track_reciever_en[5] <= latency_track_reciever_en[4];
      //latency_track_reciever_en[6] <= latency_track_reciever_en[5];

      latency_track_reciever_two_en[0] <= patch_two_en;
      latency_track_reciever_two_en[1] <= latency_track_reciever_two_en[0];
      latency_track_reciever_two_en[2] <= latency_track_reciever_two_en[1];
      latency_track_reciever_two_en[3] <= latency_track_reciever_two_en[2];
      latency_track_reciever_two_en[4] <= latency_track_reciever_two_en[3];
      latency_track_reciever_two_en[5] <= latency_track_reciever_two_en[4];
      //latency_track_reciever_two_en[6] <= latency_track_reciever_two_en[5];
    end
  
 end
 
 assign receiver_en = latency_track_reciever_en[5];
 assign receiver_two_en = latency_track_reciever_two_en[5];


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

        if (wb_mode) begin  //If in wishbone mode, this will read from the wb_addr
            if (q == wb_addr) begin
                one_hot_address_en[q] = 1'b1; 
            end
            else begin
                one_hot_address_en[q] = 1'b0;
            end

        end
        else begin
            if (q == wadr) begin
                one_hot_address_en[q] = 1'b1; //TODO: Does this synthesize well?
            end
            else begin
                one_hot_address_en[q] = 1'b0;
            end
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

 
 reg [PATCH_WIDTH-1:0] debug_one = level_patches[0];
 reg [PATCH_WIDTH-1:0] debug_two = level_patches[1];
 

 
 always @(*) begin
    level_valid[0][0] = 255'b1;
  level_valid_two[0][0] = 255'b1;

 end
 
 always @(posedge clk) begin
  level_patches[0] <= patch_in;
  level_patches_two[0] <= patch_in_two;
 end


 
 
 
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
            .wen((wen || wb_wen ) && one_hot_address_en[(((2**i)) + j-1)]), //Determined by FSM, reciever enq, and DECODER indexed at i. TODO Check slice
            .valid(level_valid[j][i]),
            .valid_two(level_valid_two[j][i]),
            .wdata(write_data), //writing mechanics are NOT pipelined
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



    //SYNTHESIS CHANGE: The following was not synthesized as intended, so has been broken into individual components as seen below ~Chris
    
        //Create register per depth that holds current patch and valids

//         always @ (posedge clk) begin

//             if (rst_n == 0) begin
//                 level_patches[i+1] <= 0;
//                 level_patches_two[i+1] <= 0 ;
//                  for (int r = 0; r < 64; r++) begin
//                      level_valid[r][i+1] = 1'b0;
//                       level_valid_two[r][i+1] = 1'b0;
//                  end
             
//             end
//             else begin
//                 level_patches[i+1] <= level_patches[i];
//                 level_patches_two[i+1] <= level_patches_two[i];
//                 //level_valid[i+1] <= level_valid[i];
//                  for (int r = 0; r < 64; r++) begin
//                     level_valid[r][i+1] = level_valid_storage[r][i];
//                     level_valid_two[r][i+1] = level_valid_storage_two[r][i];
//                  end
//             end

//         end

        
    end

endgenerate


//Registers for 
 
always @ (posedge clk) begin

    if (rst_n == 0) begin
        level_patches[1] <= 55'b0;
        level_patches_two[1] <=  55'b0; 

        for (int r = 0; r < 64; r++) begin
            level_valid[r][1] = 1'b0;
             level_valid_two[r][1] = 1'b0;
        end
    end

    else begin
        level_patches[1] <= level_patches[0];
        level_patches_two[1] <= level_patches_two[0];

          for (int r = 0; r < 64; r++) begin
           level_valid[r][1] = level_valid_storage[r][0];
           level_valid_two[r][1] = level_valid_storage_two[r][0];
        end
    end
end


always @ (posedge clk) begin

    if (rst_n == 0) begin
        level_patches[2] <= 55'b0;
        level_patches_two[2] <=  55'b0; 

        for (int r = 0; r < 64; r++) begin
         level_valid[r][2] = 1'b0;
         level_valid_two[r][2] = 1'b0;
        end
    end

    else begin
        level_patches[2] <= level_patches[1];
        level_patches_two[2] <= level_patches_two[1];

          for (int r = 0; r < 64; r++) begin
           level_valid[r][2] = level_valid_storage[r][1];
           level_valid_two[r][2] = level_valid_storage_two[r][1];
        end
    end
end


always @ (posedge clk) begin

    if (rst_n == 0) begin
        level_patches[3] <= 55'b0;
        level_patches_two[3] <=  55'b0; 

        for (int r = 0; r < 64; r++) begin
         level_valid[r][3] = 1'b0;
         level_valid_two[r][3] = 1'b0;
        end
    end

    else begin
        level_patches[3] <= level_patches[1];
        level_patches_two[3] <= level_patches_two[1];

          for (int r = 0; r < 64; r++) begin
           level_valid[r][3] = level_valid_storage[r][2];
           level_valid_two[r][3] = level_valid_storage_two[r][2];
        end
    end
end



always @ (posedge clk) begin

    if (rst_n == 0) begin
        level_patches[4] <= 55'b0;
        level_patches_two[4] <=  55'b0; 

        for (int r = 0; r < 64; r++) begin
         level_valid[r][4] = 1'b0;
         level_valid_two[r][4] = 1'b0;
        end
    end

    else begin
        level_patches[4] <= level_patches[3];
        level_patches_two[4] <= level_patches_two[3];

          for (int r = 0; r < 64; r++) begin
           level_valid[r][4] = level_valid_storage[r][3];
           level_valid_two[r][4] = level_valid_storage_two[r][3];
        end
    end
end


always @ (posedge clk) begin

    if (rst_n == 0) begin
        level_patches[5] <= 55'b0;
        level_patches_two[5] <=  55'b0; 

        for (int r = 0; r < 64; r++) begin
         level_valid[r][5] = 1'b0;
         level_valid_two[r][5] = 1'b0;
        end
    end

    else begin
        level_patches[5] <= level_patches[4];
        level_patches_two[5] <= level_patches_two[4];

          for (int r = 0; r < 64; r++) begin
           level_valid[r][5] = level_valid_storage[r][4];
           level_valid_two[r][5] = level_valid_storage_two[r][4];
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





