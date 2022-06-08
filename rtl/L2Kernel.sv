module L2Kernel (
  input logic clk,
  input logic [5:0] leaf_idx_in,
  input logic signed [4:0] [10:0] p0_data,
  input logic [8:0] p0_idx_in,
  input logic signed [4:0] [10:0] p1_data,
  input logic [8:0] p1_idx_in,
  input logic signed [4:0] [10:0] p2_data,
  input logic [8:0] p2_idx_in,
  input logic signed [4:0] [10:0] p3_data,
  input logic [8:0] p3_idx_in,
  input logic signed [4:0] [10:0] p4_data,
  input logic [8:0] p4_idx_in,
  input logic signed [4:0] [10:0] p5_data,
  input logic [8:0] p5_idx_in,
  input logic signed [4:0] [10:0] p6_data,
  input logic [8:0] p6_idx_in,
  input logic signed [4:0] [10:0] p7_data,
  input logic [8:0] p7_idx_in,
  input logic query_first_in,
  input logic query_last_in,
  input logic signed [4:0] [10:0] query_patch,
  input logic query_valid,
  input logic rst_n,
  output logic dist_valid,
  output logic [5:0] leaf_idx_out,
  output logic [8:0] p0_idx_out,
  output logic [24:0] p0_l2_dist,
  output logic [8:0] p1_idx_out,
  output logic [24:0] p1_l2_dist,
  output logic [8:0] p2_idx_out,
  output logic [24:0] p2_l2_dist,
  output logic [8:0] p3_idx_out,
  output logic [24:0] p3_l2_dist,
  output logic [8:0] p4_idx_out,
  output logic [24:0] p4_l2_dist,
  output logic [8:0] p5_idx_out,
  output logic [24:0] p5_l2_dist,
  output logic [8:0] p6_idx_out,
  output logic [24:0] p6_l2_dist,
  output logic [8:0] p7_idx_out,
  output logic [24:0] p7_l2_dist,
  output logic query_first_out,
  output logic query_last_out
);

logic [5:0] leaf_idx_r0;
logic [5:0] leaf_idx_r1;
logic [5:0] leaf_idx_r2;
logic [5:0] leaf_idx_r3;
logic [5:0] leaf_idx_r4;
logic [22:0] p0_add_tree0 [2:0];
logic [23:0] p0_add_tree1 [1:0];
logic [24:0] p0_add_tree2;
logic signed [4:0][10:0] p0_data_in_r;
logic signed [21:0] p0_diff2 [4:0];
logic [21:0] p0_diff2_unsigned [4:0];
logic [8:0] p0_idx_r0;
logic [8:0] p0_idx_r1;
logic [8:0] p0_idx_r2;
logic [8:0] p0_idx_r3;
logic [8:0] p0_idx_r4;
logic signed [10:0] p0_patch_diff [4:0];
logic [22:0] p1_add_tree0 [2:0];
logic [23:0] p1_add_tree1 [1:0];
logic [24:0] p1_add_tree2;
logic signed [4:0][10:0] p1_data_in_r;
logic signed [21:0] p1_diff2 [4:0];
logic [21:0] p1_diff2_unsigned [4:0];
logic [8:0] p1_idx_r0;
logic [8:0] p1_idx_r1;
logic [8:0] p1_idx_r2;
logic [8:0] p1_idx_r3;
logic [8:0] p1_idx_r4;
logic signed [10:0] p1_patch_diff [4:0];
logic [22:0] p2_add_tree0 [2:0];
logic [23:0] p2_add_tree1 [1:0];
logic [24:0] p2_add_tree2;
logic signed [4:0][10:0] p2_data_in_r;
logic signed [21:0] p2_diff2 [4:0];
logic [21:0] p2_diff2_unsigned [4:0];
logic [8:0] p2_idx_r0;
logic [8:0] p2_idx_r1;
logic [8:0] p2_idx_r2;
logic [8:0] p2_idx_r3;
logic [8:0] p2_idx_r4;
logic signed [10:0] p2_patch_diff [4:0];
logic [22:0] p3_add_tree0 [2:0];
logic [23:0] p3_add_tree1 [1:0];
logic [24:0] p3_add_tree2;
logic signed [4:0][10:0] p3_data_in_r;
logic signed [21:0] p3_diff2 [4:0];
logic [21:0] p3_diff2_unsigned [4:0];
logic [8:0] p3_idx_r0;
logic [8:0] p3_idx_r1;
logic [8:0] p3_idx_r2;
logic [8:0] p3_idx_r3;
logic [8:0] p3_idx_r4;
logic signed [10:0] p3_patch_diff [4:0];
logic [22:0] p4_add_tree0 [2:0];
logic [23:0] p4_add_tree1 [1:0];
logic [24:0] p4_add_tree2;
logic signed [4:0][10:0] p4_data_in_r;
logic signed [21:0] p4_diff2 [4:0];
logic [21:0] p4_diff2_unsigned [4:0];
logic [8:0] p4_idx_r0;
logic [8:0] p4_idx_r1;
logic [8:0] p4_idx_r2;
logic [8:0] p4_idx_r3;
logic [8:0] p4_idx_r4;
logic signed [10:0] p4_patch_diff [4:0];
logic [22:0] p5_add_tree0 [2:0];
logic [23:0] p5_add_tree1 [1:0];
logic [24:0] p5_add_tree2;
logic signed [4:0][10:0] p5_data_in_r;
logic signed [21:0] p5_diff2 [4:0];
logic [21:0] p5_diff2_unsigned [4:0];
logic [8:0] p5_idx_r0;
logic [8:0] p5_idx_r1;
logic [8:0] p5_idx_r2;
logic [8:0] p5_idx_r3;
logic [8:0] p5_idx_r4;
logic signed [10:0] p5_patch_diff [4:0];
logic [22:0] p6_add_tree0 [2:0];
logic [23:0] p6_add_tree1 [1:0];
logic [24:0] p6_add_tree2;
logic signed [4:0][10:0] p6_data_in_r;
logic signed [21:0] p6_diff2 [4:0];
logic [21:0] p6_diff2_unsigned [4:0];
logic [8:0] p6_idx_r0;
logic [8:0] p6_idx_r1;
logic [8:0] p6_idx_r2;
logic [8:0] p6_idx_r3;
logic [8:0] p6_idx_r4;
logic signed [10:0] p6_patch_diff [4:0];
logic [22:0] p7_add_tree0 [2:0];
logic [23:0] p7_add_tree1 [1:0];
logic [24:0] p7_add_tree2;
logic signed [4:0][10:0] p7_data_in_r;
logic signed [21:0] p7_diff2 [4:0];
logic [21:0] p7_diff2_unsigned [4:0];
logic [8:0] p7_idx_r0;
logic [8:0] p7_idx_r1;
logic [8:0] p7_idx_r2;
logic [8:0] p7_idx_r3;
logic [8:0] p7_idx_r4;
logic signed [10:0] p7_patch_diff [4:0];
logic [5:0] query_first_shft;
logic [5:0] query_last_shft;
logic signed [4:0][10:0] query_patch_in_r;
logic [5:0] valid_shft;

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    query_first_shft <= 6'h0;
    query_last_shft <= 6'h0;
    valid_shft <= 6'h0;
  end
  else begin
    query_first_shft <= {query_first_shft[4:0], query_first_in};
    query_last_shft <= {query_last_shft[4:0], query_last_in};
    valid_shft <= {valid_shft[4:0], query_valid};
  end
end
assign query_first_out = query_first_shft[5];
assign query_last_out = query_last_shft[5];
assign dist_valid = valid_shft[5];

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    leaf_idx_r0 <= 6'h0;
    leaf_idx_r1 <= 6'h0;
    leaf_idx_r2 <= 6'h0;
    leaf_idx_r3 <= 6'h0;
    leaf_idx_r4 <= 6'h0;
    leaf_idx_out <= 6'h0;
  end
  else begin
    if (query_valid) begin
      leaf_idx_r0 <= leaf_idx_in;
    end
    if (valid_shft[0]) begin
      leaf_idx_r1 <= leaf_idx_r0;
    end
    if (valid_shft[1]) begin
      leaf_idx_r2 <= leaf_idx_r1;
    end
    if (valid_shft[2]) begin
      leaf_idx_r3 <= leaf_idx_r2;
    end
    if (valid_shft[3]) begin
      leaf_idx_r4 <= leaf_idx_r3;
    end
    if (valid_shft[4]) begin
      leaf_idx_out <= leaf_idx_r4;
    end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    query_patch_in_r <= 55'h0;
  end
  else if (query_valid) begin
    query_patch_in_r <= query_patch;
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p0_idx_r0 <= 9'h0;
    p0_idx_r1 <= 9'h0;
    p0_idx_r2 <= 9'h0;
    p0_idx_r3 <= 9'h0;
    p0_idx_r4 <= 9'h0;
    p0_idx_out <= 9'h0;
  end
  else begin
    if (query_valid) begin
      p0_idx_r0 <= p0_idx_in;
    end
    if (valid_shft[0]) begin
      p0_idx_r1 <= p0_idx_r0;
    end
    if (valid_shft[1]) begin
      p0_idx_r2 <= p0_idx_r1;
    end
    if (valid_shft[2]) begin
      p0_idx_r3 <= p0_idx_r2;
    end
    if (valid_shft[3]) begin
      p0_idx_r4 <= p0_idx_r3;
    end
    if (valid_shft[4]) begin
      p0_idx_out <= p0_idx_r4;
    end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p0_data_in_r <= 55'h0;
  end
  else if (query_valid) begin
    p0_data_in_r <= p0_data;
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p0_patch_diff[3'(p)] <= 11'h0;
      end
  end
  else if (valid_shft[0]) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p0_patch_diff[3'(p)] <= signed'(query_patch_in_r[3'(p)]) - signed'(p0_data_in_r[3'(p)]);
      end
  end
end
always_comb begin
  for (int unsigned p = 0; p < 5; p += 1) begin
      p0_diff2[3'(p)] = 22'(signed'(p0_patch_diff[3'(p)])) * 22'(signed'(p0_patch_diff[3'(p)]));
    end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p0_diff2_unsigned[3'(p)] <= 22'h0;
      end
  end
  else if (valid_shft[1]) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p0_diff2_unsigned[3'(p)] <= unsigned'(p0_diff2[3'(p)]);
      end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p0_add_tree0[0] <= 23'h0;
    p0_add_tree0[1] <= 23'h0;
    p0_add_tree0[2] <= 23'h0;
    p0_add_tree1[0] <= 24'h0;
    p0_add_tree1[1] <= 24'h0;
    p0_add_tree2 <= 25'h0;
  end
  else begin
    if (valid_shft[2]) begin
      p0_add_tree0[0] <= 23'(p0_diff2_unsigned[0]) + 23'(p0_diff2_unsigned[1]);
      p0_add_tree0[1] <= 23'(p0_diff2_unsigned[2]) + 23'(p0_diff2_unsigned[3]);
      p0_add_tree0[2] <= 23'(p0_diff2_unsigned[4]);
    end
    if (valid_shft[3]) begin
      p0_add_tree1[0] <= 24'(p0_add_tree0[0]) + 24'(p0_add_tree0[1]);
      p0_add_tree1[1] <= 24'(p0_add_tree0[2]);
    end
    if (valid_shft[4]) begin
      p0_add_tree2 <= 25'(p0_add_tree1[0]) + 25'(p0_add_tree1[1]);
    end
  end
end
assign p0_l2_dist = p0_add_tree2;

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p1_idx_r0 <= 9'h0;
    p1_idx_r1 <= 9'h0;
    p1_idx_r2 <= 9'h0;
    p1_idx_r3 <= 9'h0;
    p1_idx_r4 <= 9'h0;
    p1_idx_out <= 9'h0;
  end
  else begin
    if (query_valid) begin
      p1_idx_r0 <= p1_idx_in;
    end
    if (valid_shft[0]) begin
      p1_idx_r1 <= p1_idx_r0;
    end
    if (valid_shft[1]) begin
      p1_idx_r2 <= p1_idx_r1;
    end
    if (valid_shft[2]) begin
      p1_idx_r3 <= p1_idx_r2;
    end
    if (valid_shft[3]) begin
      p1_idx_r4 <= p1_idx_r3;
    end
    if (valid_shft[4]) begin
      p1_idx_out <= p1_idx_r4;
    end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p1_data_in_r <= 55'h0;
  end
  else if (query_valid) begin
    p1_data_in_r <= p1_data;
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p1_patch_diff[3'(p)] <= 11'h0;
      end
  end
  else if (valid_shft[0]) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p1_patch_diff[3'(p)] <= signed'(query_patch_in_r[3'(p)]) - signed'(p1_data_in_r[3'(p)]);
      end
  end
end
always_comb begin
  for (int unsigned p = 0; p < 5; p += 1) begin
      p1_diff2[3'(p)] = 22'(signed'(p1_patch_diff[3'(p)])) * 22'(signed'(p1_patch_diff[3'(p)]));
    end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p1_diff2_unsigned[3'(p)] <= 22'h0;
      end
  end
  else if (valid_shft[1]) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p1_diff2_unsigned[3'(p)] <= unsigned'(p1_diff2[3'(p)]);
      end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p1_add_tree0[0] <= 23'h0;
    p1_add_tree0[1] <= 23'h0;
    p1_add_tree0[2] <= 23'h0;
    p1_add_tree1[0] <= 24'h0;
    p1_add_tree1[1] <= 24'h0;
    p1_add_tree2 <= 25'h0;
  end
  else begin
    if (valid_shft[2]) begin
      p1_add_tree0[0] <= 23'(p1_diff2_unsigned[0]) + 23'(p1_diff2_unsigned[1]);
      p1_add_tree0[1] <= 23'(p1_diff2_unsigned[2]) + 23'(p1_diff2_unsigned[3]);
      p1_add_tree0[2] <= 23'(p1_diff2_unsigned[4]);
    end
    if (valid_shft[3]) begin
      p1_add_tree1[0] <= 24'(p1_add_tree0[0]) + 24'(p1_add_tree0[1]);
      p1_add_tree1[1] <= 24'(p1_add_tree0[2]);
    end
    if (valid_shft[4]) begin
      p1_add_tree2 <= 25'(p1_add_tree1[0]) + 25'(p1_add_tree1[1]);
    end
  end
end
assign p1_l2_dist = p1_add_tree2;

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p2_idx_r0 <= 9'h0;
    p2_idx_r1 <= 9'h0;
    p2_idx_r2 <= 9'h0;
    p2_idx_r3 <= 9'h0;
    p2_idx_r4 <= 9'h0;
    p2_idx_out <= 9'h0;
  end
  else begin
    if (query_valid) begin
      p2_idx_r0 <= p2_idx_in;
    end
    if (valid_shft[0]) begin
      p2_idx_r1 <= p2_idx_r0;
    end
    if (valid_shft[1]) begin
      p2_idx_r2 <= p2_idx_r1;
    end
    if (valid_shft[2]) begin
      p2_idx_r3 <= p2_idx_r2;
    end
    if (valid_shft[3]) begin
      p2_idx_r4 <= p2_idx_r3;
    end
    if (valid_shft[4]) begin
      p2_idx_out <= p2_idx_r4;
    end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p2_data_in_r <= 55'h0;
  end
  else if (query_valid) begin
    p2_data_in_r <= p2_data;
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p2_patch_diff[3'(p)] <= 11'h0;
      end
  end
  else if (valid_shft[0]) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p2_patch_diff[3'(p)] <= signed'(query_patch_in_r[3'(p)]) - signed'(p2_data_in_r[3'(p)]);
      end
  end
end
always_comb begin
  for (int unsigned p = 0; p < 5; p += 1) begin
      p2_diff2[3'(p)] = 22'(signed'(p2_patch_diff[3'(p)])) * 22'(signed'(p2_patch_diff[3'(p)]));
    end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p2_diff2_unsigned[3'(p)] <= 22'h0;
      end
  end
  else if (valid_shft[1]) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p2_diff2_unsigned[3'(p)] <= unsigned'(p2_diff2[3'(p)]);
      end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p2_add_tree0[0] <= 23'h0;
    p2_add_tree0[1] <= 23'h0;
    p2_add_tree0[2] <= 23'h0;
    p2_add_tree1[0] <= 24'h0;
    p2_add_tree1[1] <= 24'h0;
    p2_add_tree2 <= 25'h0;
  end
  else begin
    if (valid_shft[2]) begin
      p2_add_tree0[0] <= 23'(p2_diff2_unsigned[0]) + 23'(p2_diff2_unsigned[1]);
      p2_add_tree0[1] <= 23'(p2_diff2_unsigned[2]) + 23'(p2_diff2_unsigned[3]);
      p2_add_tree0[2] <= 23'(p2_diff2_unsigned[4]);
    end
    if (valid_shft[3]) begin
      p2_add_tree1[0] <= 24'(p2_add_tree0[0]) + 24'(p2_add_tree0[1]);
      p2_add_tree1[1] <= 24'(p2_add_tree0[2]);
    end
    if (valid_shft[4]) begin
      p2_add_tree2 <= 25'(p2_add_tree1[0]) + 25'(p2_add_tree1[1]);
    end
  end
end
assign p2_l2_dist = p2_add_tree2;

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p3_idx_r0 <= 9'h0;
    p3_idx_r1 <= 9'h0;
    p3_idx_r2 <= 9'h0;
    p3_idx_r3 <= 9'h0;
    p3_idx_r4 <= 9'h0;
    p3_idx_out <= 9'h0;
  end
  else begin
    if (query_valid) begin
      p3_idx_r0 <= p3_idx_in;
    end
    if (valid_shft[0]) begin
      p3_idx_r1 <= p3_idx_r0;
    end
    if (valid_shft[1]) begin
      p3_idx_r2 <= p3_idx_r1;
    end
    if (valid_shft[2]) begin
      p3_idx_r3 <= p3_idx_r2;
    end
    if (valid_shft[3]) begin
      p3_idx_r4 <= p3_idx_r3;
    end
    if (valid_shft[4]) begin
      p3_idx_out <= p3_idx_r4;
    end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p3_data_in_r <= 55'h0;
  end
  else if (query_valid) begin
    p3_data_in_r <= p3_data;
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p3_patch_diff[3'(p)] <= 11'h0;
      end
  end
  else if (valid_shft[0]) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p3_patch_diff[3'(p)] <= signed'(query_patch_in_r[3'(p)]) - signed'(p3_data_in_r[3'(p)]);
      end
  end
end
always_comb begin
  for (int unsigned p = 0; p < 5; p += 1) begin
      p3_diff2[3'(p)] = 22'(signed'(p3_patch_diff[3'(p)])) * 22'(signed'(p3_patch_diff[3'(p)]));
    end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p3_diff2_unsigned[3'(p)] <= 22'h0;
      end
  end
  else if (valid_shft[1]) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p3_diff2_unsigned[3'(p)] <= unsigned'(p3_diff2[3'(p)]);
      end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p3_add_tree0[0] <= 23'h0;
    p3_add_tree0[1] <= 23'h0;
    p3_add_tree0[2] <= 23'h0;
    p3_add_tree1[0] <= 24'h0;
    p3_add_tree1[1] <= 24'h0;
    p3_add_tree2 <= 25'h0;
  end
  else begin
    if (valid_shft[2]) begin
      p3_add_tree0[0] <= 23'(p3_diff2_unsigned[0]) + 23'(p3_diff2_unsigned[1]);
      p3_add_tree0[1] <= 23'(p3_diff2_unsigned[2]) + 23'(p3_diff2_unsigned[3]);
      p3_add_tree0[2] <= 23'(p3_diff2_unsigned[4]);
    end
    if (valid_shft[3]) begin
      p3_add_tree1[0] <= 24'(p3_add_tree0[0]) + 24'(p3_add_tree0[1]);
      p3_add_tree1[1] <= 24'(p3_add_tree0[2]);
    end
    if (valid_shft[4]) begin
      p3_add_tree2 <= 25'(p3_add_tree1[0]) + 25'(p3_add_tree1[1]);
    end
  end
end
assign p3_l2_dist = p3_add_tree2;

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p4_idx_r0 <= 9'h0;
    p4_idx_r1 <= 9'h0;
    p4_idx_r2 <= 9'h0;
    p4_idx_r3 <= 9'h0;
    p4_idx_r4 <= 9'h0;
    p4_idx_out <= 9'h0;
  end
  else begin
    if (query_valid) begin
      p4_idx_r0 <= p4_idx_in;
    end
    if (valid_shft[0]) begin
      p4_idx_r1 <= p4_idx_r0;
    end
    if (valid_shft[1]) begin
      p4_idx_r2 <= p4_idx_r1;
    end
    if (valid_shft[2]) begin
      p4_idx_r3 <= p4_idx_r2;
    end
    if (valid_shft[3]) begin
      p4_idx_r4 <= p4_idx_r3;
    end
    if (valid_shft[4]) begin
      p4_idx_out <= p4_idx_r4;
    end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p4_data_in_r <= 55'h0;
  end
  else if (query_valid) begin
    p4_data_in_r <= p4_data;
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p4_patch_diff[3'(p)] <= 11'h0;
      end
  end
  else if (valid_shft[0]) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p4_patch_diff[3'(p)] <= signed'(query_patch_in_r[3'(p)]) - signed'(p4_data_in_r[3'(p)]);
      end
  end
end
always_comb begin
  for (int unsigned p = 0; p < 5; p += 1) begin
      p4_diff2[3'(p)] = 22'(signed'(p4_patch_diff[3'(p)])) * 22'(signed'(p4_patch_diff[3'(p)]));
    end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p4_diff2_unsigned[3'(p)] <= 22'h0;
      end
  end
  else if (valid_shft[1]) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p4_diff2_unsigned[3'(p)] <= unsigned'(p4_diff2[3'(p)]);
      end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p4_add_tree0[0] <= 23'h0;
    p4_add_tree0[1] <= 23'h0;
    p4_add_tree0[2] <= 23'h0;
    p4_add_tree1[0] <= 24'h0;
    p4_add_tree1[1] <= 24'h0;
    p4_add_tree2 <= 25'h0;
  end
  else begin
    if (valid_shft[2]) begin
      p4_add_tree0[0] <= 23'(p4_diff2_unsigned[0]) + 23'(p4_diff2_unsigned[1]);
      p4_add_tree0[1] <= 23'(p4_diff2_unsigned[2]) + 23'(p4_diff2_unsigned[3]);
      p4_add_tree0[2] <= 23'(p4_diff2_unsigned[4]);
    end
    if (valid_shft[3]) begin
      p4_add_tree1[0] <= 24'(p4_add_tree0[0]) + 24'(p4_add_tree0[1]);
      p4_add_tree1[1] <= 24'(p4_add_tree0[2]);
    end
    if (valid_shft[4]) begin
      p4_add_tree2 <= 25'(p4_add_tree1[0]) + 25'(p4_add_tree1[1]);
    end
  end
end
assign p4_l2_dist = p4_add_tree2;

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p5_idx_r0 <= 9'h0;
    p5_idx_r1 <= 9'h0;
    p5_idx_r2 <= 9'h0;
    p5_idx_r3 <= 9'h0;
    p5_idx_r4 <= 9'h0;
    p5_idx_out <= 9'h0;
  end
  else begin
    if (query_valid) begin
      p5_idx_r0 <= p5_idx_in;
    end
    if (valid_shft[0]) begin
      p5_idx_r1 <= p5_idx_r0;
    end
    if (valid_shft[1]) begin
      p5_idx_r2 <= p5_idx_r1;
    end
    if (valid_shft[2]) begin
      p5_idx_r3 <= p5_idx_r2;
    end
    if (valid_shft[3]) begin
      p5_idx_r4 <= p5_idx_r3;
    end
    if (valid_shft[4]) begin
      p5_idx_out <= p5_idx_r4;
    end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p5_data_in_r <= 55'h0;
  end
  else if (query_valid) begin
    p5_data_in_r <= p5_data;
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p5_patch_diff[3'(p)] <= 11'h0;
      end
  end
  else if (valid_shft[0]) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p5_patch_diff[3'(p)] <= signed'(query_patch_in_r[3'(p)]) - signed'(p5_data_in_r[3'(p)]);
      end
  end
end
always_comb begin
  for (int unsigned p = 0; p < 5; p += 1) begin
      p5_diff2[3'(p)] = 22'(signed'(p5_patch_diff[3'(p)])) * 22'(signed'(p5_patch_diff[3'(p)]));
    end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p5_diff2_unsigned[3'(p)] <= 22'h0;
      end
  end
  else if (valid_shft[1]) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p5_diff2_unsigned[3'(p)] <= unsigned'(p5_diff2[3'(p)]);
      end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p5_add_tree0[0] <= 23'h0;
    p5_add_tree0[1] <= 23'h0;
    p5_add_tree0[2] <= 23'h0;
    p5_add_tree1[0] <= 24'h0;
    p5_add_tree1[1] <= 24'h0;
    p5_add_tree2 <= 25'h0;
  end
  else begin
    if (valid_shft[2]) begin
      p5_add_tree0[0] <= 23'(p5_diff2_unsigned[0]) + 23'(p5_diff2_unsigned[1]);
      p5_add_tree0[1] <= 23'(p5_diff2_unsigned[2]) + 23'(p5_diff2_unsigned[3]);
      p5_add_tree0[2] <= 23'(p5_diff2_unsigned[4]);
    end
    if (valid_shft[3]) begin
      p5_add_tree1[0] <= 24'(p5_add_tree0[0]) + 24'(p5_add_tree0[1]);
      p5_add_tree1[1] <= 24'(p5_add_tree0[2]);
    end
    if (valid_shft[4]) begin
      p5_add_tree2 <= 25'(p5_add_tree1[0]) + 25'(p5_add_tree1[1]);
    end
  end
end
assign p5_l2_dist = p5_add_tree2;

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p6_idx_r0 <= 9'h0;
    p6_idx_r1 <= 9'h0;
    p6_idx_r2 <= 9'h0;
    p6_idx_r3 <= 9'h0;
    p6_idx_r4 <= 9'h0;
    p6_idx_out <= 9'h0;
  end
  else begin
    if (query_valid) begin
      p6_idx_r0 <= p6_idx_in;
    end
    if (valid_shft[0]) begin
      p6_idx_r1 <= p6_idx_r0;
    end
    if (valid_shft[1]) begin
      p6_idx_r2 <= p6_idx_r1;
    end
    if (valid_shft[2]) begin
      p6_idx_r3 <= p6_idx_r2;
    end
    if (valid_shft[3]) begin
      p6_idx_r4 <= p6_idx_r3;
    end
    if (valid_shft[4]) begin
      p6_idx_out <= p6_idx_r4;
    end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p6_data_in_r <= 55'h0;
  end
  else if (query_valid) begin
    p6_data_in_r <= p6_data;
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p6_patch_diff[3'(p)] <= 11'h0;
      end
  end
  else if (valid_shft[0]) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p6_patch_diff[3'(p)] <= signed'(query_patch_in_r[3'(p)]) - signed'(p6_data_in_r[3'(p)]);
      end
  end
end
always_comb begin
  for (int unsigned p = 0; p < 5; p += 1) begin
      p6_diff2[3'(p)] = 22'(signed'(p6_patch_diff[3'(p)])) * 22'(signed'(p6_patch_diff[3'(p)]));
    end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p6_diff2_unsigned[3'(p)] <= 22'h0;
      end
  end
  else if (valid_shft[1]) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p6_diff2_unsigned[3'(p)] <= unsigned'(p6_diff2[3'(p)]);
      end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p6_add_tree0[0] <= 23'h0;
    p6_add_tree0[1] <= 23'h0;
    p6_add_tree0[2] <= 23'h0;
    p6_add_tree1[0] <= 24'h0;
    p6_add_tree1[1] <= 24'h0;
    p6_add_tree2 <= 25'h0;
  end
  else begin
    if (valid_shft[2]) begin
      p6_add_tree0[0] <= 23'(p6_diff2_unsigned[0]) + 23'(p6_diff2_unsigned[1]);
      p6_add_tree0[1] <= 23'(p6_diff2_unsigned[2]) + 23'(p6_diff2_unsigned[3]);
      p6_add_tree0[2] <= 23'(p6_diff2_unsigned[4]);
    end
    if (valid_shft[3]) begin
      p6_add_tree1[0] <= 24'(p6_add_tree0[0]) + 24'(p6_add_tree0[1]);
      p6_add_tree1[1] <= 24'(p6_add_tree0[2]);
    end
    if (valid_shft[4]) begin
      p6_add_tree2 <= 25'(p6_add_tree1[0]) + 25'(p6_add_tree1[1]);
    end
  end
end
assign p6_l2_dist = p6_add_tree2;

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p7_idx_r0 <= 9'h0;
    p7_idx_r1 <= 9'h0;
    p7_idx_r2 <= 9'h0;
    p7_idx_r3 <= 9'h0;
    p7_idx_r4 <= 9'h0;
    p7_idx_out <= 9'h0;
  end
  else begin
    if (query_valid) begin
      p7_idx_r0 <= p7_idx_in;
    end
    if (valid_shft[0]) begin
      p7_idx_r1 <= p7_idx_r0;
    end
    if (valid_shft[1]) begin
      p7_idx_r2 <= p7_idx_r1;
    end
    if (valid_shft[2]) begin
      p7_idx_r3 <= p7_idx_r2;
    end
    if (valid_shft[3]) begin
      p7_idx_r4 <= p7_idx_r3;
    end
    if (valid_shft[4]) begin
      p7_idx_out <= p7_idx_r4;
    end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p7_data_in_r <= 55'h0;
  end
  else if (query_valid) begin
    p7_data_in_r <= p7_data;
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p7_patch_diff[3'(p)] <= 11'h0;
      end
  end
  else if (valid_shft[0]) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p7_patch_diff[3'(p)] <= signed'(query_patch_in_r[3'(p)]) - signed'(p7_data_in_r[3'(p)]);
      end
  end
end
always_comb begin
  for (int unsigned p = 0; p < 5; p += 1) begin
      p7_diff2[3'(p)] = 22'(signed'(p7_patch_diff[3'(p)])) * 22'(signed'(p7_patch_diff[3'(p)]));
    end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p7_diff2_unsigned[3'(p)] <= 22'h0;
      end
  end
  else if (valid_shft[1]) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p7_diff2_unsigned[3'(p)] <= unsigned'(p7_diff2[3'(p)]);
      end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p7_add_tree0[0] <= 23'h0;
    p7_add_tree0[1] <= 23'h0;
    p7_add_tree0[2] <= 23'h0;
    p7_add_tree1[0] <= 24'h0;
    p7_add_tree1[1] <= 24'h0;
    p7_add_tree2 <= 25'h0;
  end
  else begin
    if (valid_shft[2]) begin
      p7_add_tree0[0] <= 23'(p7_diff2_unsigned[0]) + 23'(p7_diff2_unsigned[1]);
      p7_add_tree0[1] <= 23'(p7_diff2_unsigned[2]) + 23'(p7_diff2_unsigned[3]);
      p7_add_tree0[2] <= 23'(p7_diff2_unsigned[4]);
    end
    if (valid_shft[3]) begin
      p7_add_tree1[0] <= 24'(p7_add_tree0[0]) + 24'(p7_add_tree0[1]);
      p7_add_tree1[1] <= 24'(p7_add_tree0[2]);
    end
    if (valid_shft[4]) begin
      p7_add_tree2 <= 25'(p7_add_tree1[0]) + 25'(p7_add_tree1[1]);
    end
  end
end
assign p7_l2_dist = p7_add_tree2;
endmodule   // L2Kernel

