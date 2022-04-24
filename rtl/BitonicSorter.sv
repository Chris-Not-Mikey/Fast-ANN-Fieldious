module BitonicSorter (
  input logic clk,
  input logic [24:0] data_in_0,
  input logic [24:0] data_in_1,
  input logic [24:0] data_in_2,
  input logic [24:0] data_in_3,
  input logic [24:0] data_in_4,
  input logic [24:0] data_in_5,
  input logic [24:0] data_in_6,
  input logic [24:0] data_in_7,
  input logic [14:0] idx_in_0,
  input logic [14:0] idx_in_1,
  input logic [14:0] idx_in_2,
  input logic [14:0] idx_in_3,
  input logic [14:0] idx_in_4,
  input logic [14:0] idx_in_5,
  input logic [14:0] idx_in_6,
  input logic [14:0] idx_in_7,
  input logic rst_n,
  input logic valid_in,
  output logic [24:0] data_out_0,
  output logic [24:0] data_out_1,
  output logic [24:0] data_out_2,
  output logic [24:0] data_out_3,
  output logic [14:0] idx_out_0,
  output logic [14:0] idx_out_1,
  output logic [14:0] idx_out_2,
  output logic [14:0] idx_out_3,
  output logic valid_out
);

logic [24:0] stage0_data [7:0];
logic [14:0] stage0_idx [7:0];
logic stage0_valid;
logic [24:0] stage1_data [7:0];
logic [14:0] stage1_idx [7:0];
logic stage1_valid;
logic [24:0] stage2_data [7:0];
logic [14:0] stage2_idx [7:0];
logic stage2_valid;
logic [24:0] stage3_data [3:0];
logic [14:0] stage3_idx [3:0];
logic stage3_valid;
logic [24:0] stage4_data [3:0];
logic [14:0] stage4_idx [3:0];
logic stage4_valid;
logic [24:0] stage5_data [3:0];
logic [14:0] stage5_idx [3:0];
logic stage5_valid;

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    stage0_valid <= 1'h0;
    for (int unsigned p = 0; p < 8; p += 1) begin
        stage0_data[3'(p)] <= 25'h0;
        stage0_idx[3'(p)] <= 15'h0;
      end
  end
  else begin
    stage0_valid <= valid_in;
    if (valid_in) begin
      stage0_data[0] <= (data_in_0 < data_in_1) ? data_in_0: data_in_1;
      stage0_data[1] <= (data_in_0 < data_in_1) ? data_in_1: data_in_0;
      stage0_data[2] <= (data_in_2 > data_in_3) ? data_in_2: data_in_3;
      stage0_data[3] <= (data_in_2 > data_in_3) ? data_in_3: data_in_2;
      stage0_data[4] <= (data_in_4 < data_in_5) ? data_in_4: data_in_5;
      stage0_data[5] <= (data_in_4 < data_in_5) ? data_in_5: data_in_4;
      stage0_data[6] <= (data_in_6 > data_in_7) ? data_in_6: data_in_7;
      stage0_data[7] <= (data_in_6 > data_in_7) ? data_in_7: data_in_6;
      stage0_idx[0] <= (data_in_0 < data_in_1) ? idx_in_0: idx_in_1;
      stage0_idx[1] <= (data_in_0 < data_in_1) ? idx_in_1: idx_in_0;
      stage0_idx[2] <= (data_in_2 > data_in_3) ? idx_in_2: idx_in_3;
      stage0_idx[3] <= (data_in_2 > data_in_3) ? idx_in_3: idx_in_2;
      stage0_idx[4] <= (data_in_4 < data_in_5) ? idx_in_4: idx_in_5;
      stage0_idx[5] <= (data_in_4 < data_in_5) ? idx_in_5: idx_in_4;
      stage0_idx[6] <= (data_in_6 > data_in_7) ? idx_in_6: idx_in_7;
      stage0_idx[7] <= (data_in_6 > data_in_7) ? idx_in_7: idx_in_6;
    end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    stage1_valid <= 1'h0;
    for (int unsigned p = 0; p < 8; p += 1) begin
        stage1_data[3'(p)] <= 25'h0;
        stage1_idx[3'(p)] <= 15'h0;
      end
  end
  else begin
    stage1_valid <= stage0_valid;
    if (stage0_valid) begin
      stage1_data[0] <= (stage0_data[0] < stage0_data[2]) ? stage0_data[0]: stage0_data[2];
      stage1_data[2] <= (stage0_data[0] < stage0_data[2]) ? stage0_data[2]: stage0_data[0];
      stage1_data[1] <= (stage0_data[1] < stage0_data[3]) ? stage0_data[1]: stage0_data[3];
      stage1_data[3] <= (stage0_data[1] < stage0_data[3]) ? stage0_data[3]: stage0_data[1];
      stage1_data[4] <= (stage0_data[4] > stage0_data[6]) ? stage0_data[4]: stage0_data[6];
      stage1_data[6] <= (stage0_data[4] > stage0_data[6]) ? stage0_data[6]: stage0_data[4];
      stage1_data[5] <= (stage0_data[5] > stage0_data[7]) ? stage0_data[5]: stage0_data[7];
      stage1_data[7] <= (stage0_data[5] > stage0_data[7]) ? stage0_data[7]: stage0_data[5];
      stage1_idx[0] <= (stage0_data[0] < stage0_data[2]) ? stage0_idx[0]: stage0_idx[2];
      stage1_idx[2] <= (stage0_data[0] < stage0_data[2]) ? stage0_idx[2]: stage0_idx[0];
      stage1_idx[1] <= (stage0_data[1] < stage0_data[3]) ? stage0_idx[1]: stage0_idx[3];
      stage1_idx[3] <= (stage0_data[1] < stage0_data[3]) ? stage0_idx[3]: stage0_idx[1];
      stage1_idx[4] <= (stage0_data[4] > stage0_data[6]) ? stage0_idx[4]: stage0_idx[6];
      stage1_idx[6] <= (stage0_data[4] > stage0_data[6]) ? stage0_idx[6]: stage0_idx[4];
      stage1_idx[5] <= (stage0_data[5] > stage0_data[7]) ? stage0_idx[5]: stage0_idx[7];
      stage1_idx[7] <= (stage0_data[5] > stage0_data[7]) ? stage0_idx[7]: stage0_idx[5];
    end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    stage2_valid <= 1'h0;
    for (int unsigned p = 0; p < 8; p += 1) begin
        stage2_data[3'(p)] <= 25'h0;
        stage2_idx[3'(p)] <= 15'h0;
      end
  end
  else begin
    stage2_valid <= stage1_valid;
    if (stage1_valid) begin
      stage2_data[0] <= (stage1_data[0] < stage1_data[1]) ? stage1_data[0]: stage1_data[1];
      stage2_data[1] <= (stage1_data[0] < stage1_data[1]) ? stage1_data[1]: stage1_data[0];
      stage2_data[2] <= (stage1_data[2] < stage1_data[3]) ? stage1_data[2]: stage1_data[3];
      stage2_data[3] <= (stage1_data[2] < stage1_data[3]) ? stage1_data[3]: stage1_data[2];
      stage2_data[4] <= (stage1_data[4] > stage1_data[5]) ? stage1_data[4]: stage1_data[5];
      stage2_data[5] <= (stage1_data[4] > stage1_data[5]) ? stage1_data[5]: stage1_data[4];
      stage2_data[6] <= (stage1_data[6] > stage1_data[7]) ? stage1_data[6]: stage1_data[7];
      stage2_data[7] <= (stage1_data[6] > stage1_data[7]) ? stage1_data[7]: stage1_data[6];
      stage2_idx[0] <= (stage1_data[0] < stage1_data[1]) ? stage1_idx[0]: stage1_idx[1];
      stage2_idx[1] <= (stage1_data[0] < stage1_data[1]) ? stage1_idx[1]: stage1_idx[0];
      stage2_idx[2] <= (stage1_data[2] < stage1_data[3]) ? stage1_idx[2]: stage1_idx[3];
      stage2_idx[3] <= (stage1_data[2] < stage1_data[3]) ? stage1_idx[3]: stage1_idx[2];
      stage2_idx[4] <= (stage1_data[4] > stage1_data[5]) ? stage1_idx[4]: stage1_idx[5];
      stage2_idx[5] <= (stage1_data[4] > stage1_data[5]) ? stage1_idx[5]: stage1_idx[4];
      stage2_idx[6] <= (stage1_data[6] > stage1_data[7]) ? stage1_idx[6]: stage1_idx[7];
      stage2_idx[7] <= (stage1_data[6] > stage1_data[7]) ? stage1_idx[7]: stage1_idx[6];
    end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    stage3_valid <= 1'h0;
    for (int unsigned p = 0; p < 4; p += 1) begin
        stage3_data[2'(p)] <= 25'h0;
        stage3_idx[2'(p)] <= 15'h0;
      end
  end
  else begin
    stage3_valid <= stage2_valid;
    if (stage2_valid) begin
      stage3_data[0] <= (stage2_data[0] < stage2_data[4]) ? stage2_data[0]: stage2_data[4];
      stage3_data[1] <= (stage2_data[1] < stage2_data[5]) ? stage2_data[1]: stage2_data[5];
      stage3_data[2] <= (stage2_data[2] < stage2_data[6]) ? stage2_data[2]: stage2_data[6];
      stage3_data[3] <= (stage2_data[3] < stage2_data[7]) ? stage2_data[3]: stage2_data[7];
      stage3_idx[0] <= (stage2_data[0] < stage2_data[4]) ? stage2_idx[0]: stage2_idx[4];
      stage3_idx[1] <= (stage2_data[1] < stage2_data[5]) ? stage2_idx[1]: stage2_idx[5];
      stage3_idx[2] <= (stage2_data[2] < stage2_data[6]) ? stage2_idx[2]: stage2_idx[6];
      stage3_idx[3] <= (stage2_data[3] < stage2_data[7]) ? stage2_idx[3]: stage2_idx[7];
    end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    stage4_valid <= 1'h0;
    for (int unsigned p = 0; p < 4; p += 1) begin
        stage4_data[2'(p)] <= 25'h0;
        stage4_idx[2'(p)] <= 15'h0;
      end
  end
  else begin
    stage4_valid <= stage3_valid;
    if (stage3_valid) begin
      stage4_data[0] <= (stage3_data[0] < stage3_data[2]) ? stage3_data[0]: stage3_data[2];
      stage4_data[2] <= (stage3_data[0] < stage3_data[2]) ? stage3_data[2]: stage3_data[0];
      stage4_data[1] <= (stage3_data[1] < stage3_data[3]) ? stage3_data[1]: stage3_data[3];
      stage4_data[3] <= (stage3_data[1] < stage3_data[3]) ? stage3_data[3]: stage3_data[1];
      stage4_idx[0] <= (stage3_data[0] < stage3_data[2]) ? stage3_idx[0]: stage3_idx[2];
      stage4_idx[2] <= (stage3_data[0] < stage3_data[2]) ? stage3_idx[2]: stage3_idx[0];
      stage4_idx[1] <= (stage3_data[1] < stage3_data[3]) ? stage3_idx[1]: stage3_idx[3];
      stage4_idx[3] <= (stage3_data[1] < stage3_data[3]) ? stage3_idx[3]: stage3_idx[1];
    end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    stage5_valid <= 1'h0;
    for (int unsigned p = 0; p < 4; p += 1) begin
        stage5_data[2'(p)] <= 25'h0;
        stage5_idx[2'(p)] <= 15'h0;
      end
  end
  else begin
    stage5_valid <= stage4_valid;
    if (stage4_valid) begin
      stage5_data[0] <= (stage4_data[0] < stage4_data[1]) ? stage4_data[0]: stage4_data[1];
      stage5_data[1] <= (stage4_data[0] < stage4_data[1]) ? stage4_data[1]: stage4_data[0];
      stage5_data[2] <= (stage4_data[2] < stage4_data[3]) ? stage4_data[2]: stage4_data[3];
      stage5_data[3] <= (stage4_data[2] < stage4_data[3]) ? stage4_data[3]: stage4_data[2];
      stage5_idx[0] <= (stage4_data[0] < stage4_data[1]) ? stage4_idx[0]: stage4_idx[1];
      stage5_idx[1] <= (stage4_data[0] < stage4_data[1]) ? stage4_idx[1]: stage4_idx[0];
      stage5_idx[2] <= (stage4_data[2] < stage4_data[3]) ? stage4_idx[2]: stage4_idx[3];
      stage5_idx[3] <= (stage4_data[2] < stage4_data[3]) ? stage4_idx[3]: stage4_idx[2];
    end
  end
end
assign valid_out = stage5_valid;
assign data_out_0 = stage5_data[0];
assign idx_out_0 = stage5_idx[0];
assign data_out_1 = stage5_data[1];
assign idx_out_1 = stage5_idx[1];
assign data_out_2 = stage5_data[2];
assign idx_out_2 = stage5_idx[2];
assign data_out_3 = stage5_data[3];
assign idx_out_3 = stage5_idx[3];
endmodule   // BitonicSorter

