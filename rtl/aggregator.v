module aggregator
#(
  parameter DATA_WIDTH = 16,
  parameter FETCH_WIDTH = 40 //40 is the most we will use, so we will use this by default
)
(
  input clk,
  input rst_n,
  input [DATA_WIDTH - 1 : 0] sender_data,
  input sender_empty_n,
  output sender_deq,
  output [FETCH_WIDTH*DATA_WIDTH - 1 : 0] receiver_data, //For Internal Nodes and Query patches this is too large by defualy
  input receiver_full_n,
  output reg receiver_enq,
  input change_fetch_width,
  input [2:0] input_fetch_width
  
);

  localparam COUNTER_WIDTH = $clog2(FETCH_WIDTH);
  reg [COUNTER_WIDTH - 1 : 0] count_r;
  
  reg [DATA_WIDTH - 1 : 0] receiver_data_unpacked [FETCH_WIDTH - 1 : 0]; 
  wire sender_deq_w;

  assign sender_deq_w = rst_n && sender_empty_n && receiver_full_n;
  assign sender_deq = sender_deq_w;

  genvar i;
  generate
    for (i = 0; i < FETCH_WIDTH; i++) begin: unpack
      assign receiver_data[(i + 1)*DATA_WIDTH - 1 : i*DATA_WIDTH] = receiver_data_unpacked[i];
    end
  endgenerate
  
  
  reg [5:0] LOCAL_FETCH_WIDTH;
  always @ (posedge clk) begin
    if (!rst_n) begin
       LOCAL_FETCH_WIDTH <= FETCH_WIDTH;
      count_r <= 0;
    end
    
    else if (change_fetch_width) begin
      LOCAL_FETCH_WIDTH <= {3'b0, input_fetch_width};
    end
    
    else begin
      LOCAL_FETCH_WIDTH <= LOCAL_FETCH_WIDTH;
    end
    
  end

  always @ (posedge clk) begin
    if (rst_n) begin
      if (sender_deq_w) begin
        receiver_data_unpacked[count_r] <= sender_data;
        count_r <= (count_r == LOCAL_FETCH_WIDTH) ? 0 : count_r + 1;
        receiver_enq <= (count_r == LOCAL_FETCH_WIDTH); 
      end else begin
        receiver_enq <= 0;
      end
    end else begin
      receiver_enq <= 0;
      count_r <= 0;
    end
  end
endmodule
