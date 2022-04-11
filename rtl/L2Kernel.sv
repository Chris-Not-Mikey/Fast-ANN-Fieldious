module L2Kernel (
  input logic clk,
  input logic [5:0] leaf_idx,
  input logic signed [4:0] [10:0] p0_candidate_leaf,
  input logic signed [4:0] [10:0] p1_candidate_leaf,
  input logic signed [4:0] [10:0] p2_candidate_leaf,
  input logic signed [4:0] [10:0] p3_candidate_leaf,
  input logic signed [4:0] [10:0] p4_candidate_leaf,
  input logic signed [4:0] [10:0] p5_candidate_leaf,
  input logic signed [4:0] [10:0] p6_candidate_leaf,
  input logic signed [4:0] [10:0] p7_candidate_leaf,
  input logic signed [4:0] [10:0] query_patch,
  input logic query_valid,
  input logic rst_n,
  output logic dist_valid,
  output logic [8:0] p0_indices,
  output logic [10:0] p0_l2_dist,
  output logic [8:0] p1_indices,
  output logic [10:0] p1_l2_dist,
  output logic [8:0] p2_indices,
  output logic [10:0] p2_l2_dist,
  output logic [8:0] p3_indices,
  output logic [10:0] p3_l2_dist,
  output logic [8:0] p4_indices,
  output logic [10:0] p4_l2_dist,
  output logic [8:0] p5_indices,
  output logic [10:0] p5_l2_dist,
  output logic [8:0] p6_indices,
  output logic [10:0] p6_l2_dist,
  output logic [8:0] p7_indices,
  output logic [10:0] p7_l2_dist
);

logic [10:0] p0_add_tree0 [2:0];
logic [10:0] p0_add_tree1 [1:0];
logic signed [10:0] p0_diff2 [4:0];
logic [10:0] p0_diff2_unsigned [4:0];
logic [5:0] p0_leaf_idx_r0;
logic [5:0] p0_leaf_idx_r1;
logic [5:0] p0_leaf_idx_r2;
logic [5:0] p0_leaf_idx_r3;
logic signed [10:0] p0_patch_diff [4:0];
logic [10:0] p1_add_tree0 [2:0];
logic [10:0] p1_add_tree1 [1:0];
logic signed [10:0] p1_diff2 [4:0];
logic [10:0] p1_diff2_unsigned [4:0];
logic [5:0] p1_leaf_idx_r0;
logic [5:0] p1_leaf_idx_r1;
logic [5:0] p1_leaf_idx_r2;
logic [5:0] p1_leaf_idx_r3;
logic signed [10:0] p1_patch_diff [4:0];
logic [10:0] p2_add_tree0 [2:0];
logic [10:0] p2_add_tree1 [1:0];
logic signed [10:0] p2_diff2 [4:0];
logic [10:0] p2_diff2_unsigned [4:0];
logic [5:0] p2_leaf_idx_r0;
logic [5:0] p2_leaf_idx_r1;
logic [5:0] p2_leaf_idx_r2;
logic [5:0] p2_leaf_idx_r3;
logic signed [10:0] p2_patch_diff [4:0];
logic [10:0] p3_add_tree0 [2:0];
logic [10:0] p3_add_tree1 [1:0];
logic signed [10:0] p3_diff2 [4:0];
logic [10:0] p3_diff2_unsigned [4:0];
logic [5:0] p3_leaf_idx_r0;
logic [5:0] p3_leaf_idx_r1;
logic [5:0] p3_leaf_idx_r2;
logic [5:0] p3_leaf_idx_r3;
logic signed [10:0] p3_patch_diff [4:0];
logic [10:0] p4_add_tree0 [2:0];
logic [10:0] p4_add_tree1 [1:0];
logic signed [10:0] p4_diff2 [4:0];
logic [10:0] p4_diff2_unsigned [4:0];
logic [5:0] p4_leaf_idx_r0;
logic [5:0] p4_leaf_idx_r1;
logic [5:0] p4_leaf_idx_r2;
logic [5:0] p4_leaf_idx_r3;
logic signed [10:0] p4_patch_diff [4:0];
logic [10:0] p5_add_tree0 [2:0];
logic [10:0] p5_add_tree1 [1:0];
logic signed [10:0] p5_diff2 [4:0];
logic [10:0] p5_diff2_unsigned [4:0];
logic [5:0] p5_leaf_idx_r0;
logic [5:0] p5_leaf_idx_r1;
logic [5:0] p5_leaf_idx_r2;
logic [5:0] p5_leaf_idx_r3;
logic signed [10:0] p5_patch_diff [4:0];
logic [10:0] p6_add_tree0 [2:0];
logic [10:0] p6_add_tree1 [1:0];
logic signed [10:0] p6_diff2 [4:0];
logic [10:0] p6_diff2_unsigned [4:0];
logic [5:0] p6_leaf_idx_r0;
logic [5:0] p6_leaf_idx_r1;
logic [5:0] p6_leaf_idx_r2;
logic [5:0] p6_leaf_idx_r3;
logic signed [10:0] p6_patch_diff [4:0];
logic [10:0] p7_add_tree0 [2:0];
logic [10:0] p7_add_tree1 [1:0];
logic signed [10:0] p7_diff2 [4:0];
logic [10:0] p7_diff2_unsigned [4:0];
logic [5:0] p7_leaf_idx_r0;
logic [5:0] p7_leaf_idx_r1;
logic [5:0] p7_leaf_idx_r2;
logic [5:0] p7_leaf_idx_r3;
logic signed [10:0] p7_patch_diff [4:0];
logic [4:0] valid_shft;

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    valid_shft <= 5'h0;
  end
  else valid_shft <= {valid_shft[3:0], query_valid};
end
assign dist_valid = valid_shft[4];

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p0_leaf_idx_r0 <= 6'h0;
    p0_leaf_idx_r1 <= 6'h0;
    p0_leaf_idx_r2 <= 6'h0;
    p0_leaf_idx_r3 <= 6'h0;
    p0_indices <= 9'h0;
  end
  else begin
    p0_leaf_idx_r0 <= leaf_idx;
    p0_leaf_idx_r1 <= p0_leaf_idx_r0;
    p0_leaf_idx_r2 <= p0_leaf_idx_r1;
    p0_leaf_idx_r3 <= p0_leaf_idx_r2;
    p0_indices <= {p0_leaf_idx_r3, 3'h0};
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p0_patch_diff[3'(p)] <= 11'h0;
      end
  end
  else if (query_valid) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p0_patch_diff[3'(p)] <= query_patch[3'(p)] - p0_candidate_leaf[3'(p)];
      end
  end
end
always_comb begin
  for (int unsigned p = 0; p < 5; p += 1) begin
      p0_diff2[3'(p)] = p0_patch_diff[3'(p)] * p0_patch_diff[3'(p)];
    end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p0_diff2_unsigned[3'(p)] <= 11'h0;
      end
  end
  else if (valid_shft[0]) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p0_diff2_unsigned[3'(p)] <= unsigned'(p0_diff2[3'(p)]);
      end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p0_add_tree0[0] <= 11'h0;
    p0_add_tree0[1] <= 11'h0;
    p0_add_tree0[2] <= 11'h0;
    p0_add_tree1[0] <= 11'h0;
    p0_add_tree1[1] <= 11'h0;
    p0_l2_dist <= 11'h0;
  end
  else begin
    if (valid_shft[1]) begin
      p0_add_tree0[0] <= p0_diff2_unsigned[0] + p0_diff2_unsigned[1];
      p0_add_tree0[1] <= p0_diff2_unsigned[2] + p0_diff2_unsigned[3];
      p0_add_tree0[2] <= p0_diff2_unsigned[4];
    end
    if (valid_shft[2]) begin
      p0_add_tree1[0] <= p0_add_tree0[0] + p0_add_tree0[1];
      p0_add_tree1[1] <= p0_add_tree0[2];
    end
    if (valid_shft[3]) begin
      p0_l2_dist <= p0_add_tree1[0] + p0_add_tree1[1];
    end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p1_leaf_idx_r0 <= 6'h0;
    p1_leaf_idx_r1 <= 6'h0;
    p1_leaf_idx_r2 <= 6'h0;
    p1_leaf_idx_r3 <= 6'h0;
    p1_indices <= 9'h0;
  end
  else begin
    p1_leaf_idx_r0 <= leaf_idx;
    p1_leaf_idx_r1 <= p1_leaf_idx_r0;
    p1_leaf_idx_r2 <= p1_leaf_idx_r1;
    p1_leaf_idx_r3 <= p1_leaf_idx_r2;
    p1_indices <= {p1_leaf_idx_r3, 3'h1};
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p1_patch_diff[3'(p)] <= 11'h0;
      end
  end
  else if (query_valid) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p1_patch_diff[3'(p)] <= query_patch[3'(p)] - p1_candidate_leaf[3'(p)];
      end
  end
end
always_comb begin
  for (int unsigned p = 0; p < 5; p += 1) begin
      p1_diff2[3'(p)] = p1_patch_diff[3'(p)] * p1_patch_diff[3'(p)];
    end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p1_diff2_unsigned[3'(p)] <= 11'h0;
      end
  end
  else if (valid_shft[0]) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p1_diff2_unsigned[3'(p)] <= unsigned'(p1_diff2[3'(p)]);
      end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p1_add_tree0[0] <= 11'h0;
    p1_add_tree0[1] <= 11'h0;
    p1_add_tree0[2] <= 11'h0;
    p1_add_tree1[0] <= 11'h0;
    p1_add_tree1[1] <= 11'h0;
    p1_l2_dist <= 11'h0;
  end
  else begin
    if (valid_shft[1]) begin
      p1_add_tree0[0] <= p1_diff2_unsigned[0] + p1_diff2_unsigned[1];
      p1_add_tree0[1] <= p1_diff2_unsigned[2] + p1_diff2_unsigned[3];
      p1_add_tree0[2] <= p1_diff2_unsigned[4];
    end
    if (valid_shft[2]) begin
      p1_add_tree1[0] <= p1_add_tree0[0] + p1_add_tree0[1];
      p1_add_tree1[1] <= p1_add_tree0[2];
    end
    if (valid_shft[3]) begin
      p1_l2_dist <= p1_add_tree1[0] + p1_add_tree1[1];
    end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p2_leaf_idx_r0 <= 6'h0;
    p2_leaf_idx_r1 <= 6'h0;
    p2_leaf_idx_r2 <= 6'h0;
    p2_leaf_idx_r3 <= 6'h0;
    p2_indices <= 9'h0;
  end
  else begin
    p2_leaf_idx_r0 <= leaf_idx;
    p2_leaf_idx_r1 <= p2_leaf_idx_r0;
    p2_leaf_idx_r2 <= p2_leaf_idx_r1;
    p2_leaf_idx_r3 <= p2_leaf_idx_r2;
    p2_indices <= {p2_leaf_idx_r3, 3'h2};
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p2_patch_diff[3'(p)] <= 11'h0;
      end
  end
  else if (query_valid) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p2_patch_diff[3'(p)] <= query_patch[3'(p)] - p2_candidate_leaf[3'(p)];
      end
  end
end
always_comb begin
  for (int unsigned p = 0; p < 5; p += 1) begin
      p2_diff2[3'(p)] = p2_patch_diff[3'(p)] * p2_patch_diff[3'(p)];
    end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p2_diff2_unsigned[3'(p)] <= 11'h0;
      end
  end
  else if (valid_shft[0]) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p2_diff2_unsigned[3'(p)] <= unsigned'(p2_diff2[3'(p)]);
      end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p2_add_tree0[0] <= 11'h0;
    p2_add_tree0[1] <= 11'h0;
    p2_add_tree0[2] <= 11'h0;
    p2_add_tree1[0] <= 11'h0;
    p2_add_tree1[1] <= 11'h0;
    p2_l2_dist <= 11'h0;
  end
  else begin
    if (valid_shft[1]) begin
      p2_add_tree0[0] <= p2_diff2_unsigned[0] + p2_diff2_unsigned[1];
      p2_add_tree0[1] <= p2_diff2_unsigned[2] + p2_diff2_unsigned[3];
      p2_add_tree0[2] <= p2_diff2_unsigned[4];
    end
    if (valid_shft[2]) begin
      p2_add_tree1[0] <= p2_add_tree0[0] + p2_add_tree0[1];
      p2_add_tree1[1] <= p2_add_tree0[2];
    end
    if (valid_shft[3]) begin
      p2_l2_dist <= p2_add_tree1[0] + p2_add_tree1[1];
    end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p3_leaf_idx_r0 <= 6'h0;
    p3_leaf_idx_r1 <= 6'h0;
    p3_leaf_idx_r2 <= 6'h0;
    p3_leaf_idx_r3 <= 6'h0;
    p3_indices <= 9'h0;
  end
  else begin
    p3_leaf_idx_r0 <= leaf_idx;
    p3_leaf_idx_r1 <= p3_leaf_idx_r0;
    p3_leaf_idx_r2 <= p3_leaf_idx_r1;
    p3_leaf_idx_r3 <= p3_leaf_idx_r2;
    p3_indices <= {p3_leaf_idx_r3, 3'h3};
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p3_patch_diff[3'(p)] <= 11'h0;
      end
  end
  else if (query_valid) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p3_patch_diff[3'(p)] <= query_patch[3'(p)] - p3_candidate_leaf[3'(p)];
      end
  end
end
always_comb begin
  for (int unsigned p = 0; p < 5; p += 1) begin
      p3_diff2[3'(p)] = p3_patch_diff[3'(p)] * p3_patch_diff[3'(p)];
    end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p3_diff2_unsigned[3'(p)] <= 11'h0;
      end
  end
  else if (valid_shft[0]) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p3_diff2_unsigned[3'(p)] <= unsigned'(p3_diff2[3'(p)]);
      end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p3_add_tree0[0] <= 11'h0;
    p3_add_tree0[1] <= 11'h0;
    p3_add_tree0[2] <= 11'h0;
    p3_add_tree1[0] <= 11'h0;
    p3_add_tree1[1] <= 11'h0;
    p3_l2_dist <= 11'h0;
  end
  else begin
    if (valid_shft[1]) begin
      p3_add_tree0[0] <= p3_diff2_unsigned[0] + p3_diff2_unsigned[1];
      p3_add_tree0[1] <= p3_diff2_unsigned[2] + p3_diff2_unsigned[3];
      p3_add_tree0[2] <= p3_diff2_unsigned[4];
    end
    if (valid_shft[2]) begin
      p3_add_tree1[0] <= p3_add_tree0[0] + p3_add_tree0[1];
      p3_add_tree1[1] <= p3_add_tree0[2];
    end
    if (valid_shft[3]) begin
      p3_l2_dist <= p3_add_tree1[0] + p3_add_tree1[1];
    end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p4_leaf_idx_r0 <= 6'h0;
    p4_leaf_idx_r1 <= 6'h0;
    p4_leaf_idx_r2 <= 6'h0;
    p4_leaf_idx_r3 <= 6'h0;
    p4_indices <= 9'h0;
  end
  else begin
    p4_leaf_idx_r0 <= leaf_idx;
    p4_leaf_idx_r1 <= p4_leaf_idx_r0;
    p4_leaf_idx_r2 <= p4_leaf_idx_r1;
    p4_leaf_idx_r3 <= p4_leaf_idx_r2;
    p4_indices <= {p4_leaf_idx_r3, 3'h4};
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p4_patch_diff[3'(p)] <= 11'h0;
      end
  end
  else if (query_valid) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p4_patch_diff[3'(p)] <= query_patch[3'(p)] - p4_candidate_leaf[3'(p)];
      end
  end
end
always_comb begin
  for (int unsigned p = 0; p < 5; p += 1) begin
      p4_diff2[3'(p)] = p4_patch_diff[3'(p)] * p4_patch_diff[3'(p)];
    end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p4_diff2_unsigned[3'(p)] <= 11'h0;
      end
  end
  else if (valid_shft[0]) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p4_diff2_unsigned[3'(p)] <= unsigned'(p4_diff2[3'(p)]);
      end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p4_add_tree0[0] <= 11'h0;
    p4_add_tree0[1] <= 11'h0;
    p4_add_tree0[2] <= 11'h0;
    p4_add_tree1[0] <= 11'h0;
    p4_add_tree1[1] <= 11'h0;
    p4_l2_dist <= 11'h0;
  end
  else begin
    if (valid_shft[1]) begin
      p4_add_tree0[0] <= p4_diff2_unsigned[0] + p4_diff2_unsigned[1];
      p4_add_tree0[1] <= p4_diff2_unsigned[2] + p4_diff2_unsigned[3];
      p4_add_tree0[2] <= p4_diff2_unsigned[4];
    end
    if (valid_shft[2]) begin
      p4_add_tree1[0] <= p4_add_tree0[0] + p4_add_tree0[1];
      p4_add_tree1[1] <= p4_add_tree0[2];
    end
    if (valid_shft[3]) begin
      p4_l2_dist <= p4_add_tree1[0] + p4_add_tree1[1];
    end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p5_leaf_idx_r0 <= 6'h0;
    p5_leaf_idx_r1 <= 6'h0;
    p5_leaf_idx_r2 <= 6'h0;
    p5_leaf_idx_r3 <= 6'h0;
    p5_indices <= 9'h0;
  end
  else begin
    p5_leaf_idx_r0 <= leaf_idx;
    p5_leaf_idx_r1 <= p5_leaf_idx_r0;
    p5_leaf_idx_r2 <= p5_leaf_idx_r1;
    p5_leaf_idx_r3 <= p5_leaf_idx_r2;
    p5_indices <= {p5_leaf_idx_r3, 3'h5};
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p5_patch_diff[3'(p)] <= 11'h0;
      end
  end
  else if (query_valid) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p5_patch_diff[3'(p)] <= query_patch[3'(p)] - p5_candidate_leaf[3'(p)];
      end
  end
end
always_comb begin
  for (int unsigned p = 0; p < 5; p += 1) begin
      p5_diff2[3'(p)] = p5_patch_diff[3'(p)] * p5_patch_diff[3'(p)];
    end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p5_diff2_unsigned[3'(p)] <= 11'h0;
      end
  end
  else if (valid_shft[0]) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p5_diff2_unsigned[3'(p)] <= unsigned'(p5_diff2[3'(p)]);
      end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p5_add_tree0[0] <= 11'h0;
    p5_add_tree0[1] <= 11'h0;
    p5_add_tree0[2] <= 11'h0;
    p5_add_tree1[0] <= 11'h0;
    p5_add_tree1[1] <= 11'h0;
    p5_l2_dist <= 11'h0;
  end
  else begin
    if (valid_shft[1]) begin
      p5_add_tree0[0] <= p5_diff2_unsigned[0] + p5_diff2_unsigned[1];
      p5_add_tree0[1] <= p5_diff2_unsigned[2] + p5_diff2_unsigned[3];
      p5_add_tree0[2] <= p5_diff2_unsigned[4];
    end
    if (valid_shft[2]) begin
      p5_add_tree1[0] <= p5_add_tree0[0] + p5_add_tree0[1];
      p5_add_tree1[1] <= p5_add_tree0[2];
    end
    if (valid_shft[3]) begin
      p5_l2_dist <= p5_add_tree1[0] + p5_add_tree1[1];
    end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p6_leaf_idx_r0 <= 6'h0;
    p6_leaf_idx_r1 <= 6'h0;
    p6_leaf_idx_r2 <= 6'h0;
    p6_leaf_idx_r3 <= 6'h0;
    p6_indices <= 9'h0;
  end
  else begin
    p6_leaf_idx_r0 <= leaf_idx;
    p6_leaf_idx_r1 <= p6_leaf_idx_r0;
    p6_leaf_idx_r2 <= p6_leaf_idx_r1;
    p6_leaf_idx_r3 <= p6_leaf_idx_r2;
    p6_indices <= {p6_leaf_idx_r3, 3'h6};
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p6_patch_diff[3'(p)] <= 11'h0;
      end
  end
  else if (query_valid) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p6_patch_diff[3'(p)] <= query_patch[3'(p)] - p6_candidate_leaf[3'(p)];
      end
  end
end
always_comb begin
  for (int unsigned p = 0; p < 5; p += 1) begin
      p6_diff2[3'(p)] = p6_patch_diff[3'(p)] * p6_patch_diff[3'(p)];
    end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p6_diff2_unsigned[3'(p)] <= 11'h0;
      end
  end
  else if (valid_shft[0]) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p6_diff2_unsigned[3'(p)] <= unsigned'(p6_diff2[3'(p)]);
      end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p6_add_tree0[0] <= 11'h0;
    p6_add_tree0[1] <= 11'h0;
    p6_add_tree0[2] <= 11'h0;
    p6_add_tree1[0] <= 11'h0;
    p6_add_tree1[1] <= 11'h0;
    p6_l2_dist <= 11'h0;
  end
  else begin
    if (valid_shft[1]) begin
      p6_add_tree0[0] <= p6_diff2_unsigned[0] + p6_diff2_unsigned[1];
      p6_add_tree0[1] <= p6_diff2_unsigned[2] + p6_diff2_unsigned[3];
      p6_add_tree0[2] <= p6_diff2_unsigned[4];
    end
    if (valid_shft[2]) begin
      p6_add_tree1[0] <= p6_add_tree0[0] + p6_add_tree0[1];
      p6_add_tree1[1] <= p6_add_tree0[2];
    end
    if (valid_shft[3]) begin
      p6_l2_dist <= p6_add_tree1[0] + p6_add_tree1[1];
    end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p7_leaf_idx_r0 <= 6'h0;
    p7_leaf_idx_r1 <= 6'h0;
    p7_leaf_idx_r2 <= 6'h0;
    p7_leaf_idx_r3 <= 6'h0;
    p7_indices <= 9'h0;
  end
  else begin
    p7_leaf_idx_r0 <= leaf_idx;
    p7_leaf_idx_r1 <= p7_leaf_idx_r0;
    p7_leaf_idx_r2 <= p7_leaf_idx_r1;
    p7_leaf_idx_r3 <= p7_leaf_idx_r2;
    p7_indices <= {p7_leaf_idx_r3, 3'h7};
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p7_patch_diff[3'(p)] <= 11'h0;
      end
  end
  else if (query_valid) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p7_patch_diff[3'(p)] <= query_patch[3'(p)] - p7_candidate_leaf[3'(p)];
      end
  end
end
always_comb begin
  for (int unsigned p = 0; p < 5; p += 1) begin
      p7_diff2[3'(p)] = p7_patch_diff[3'(p)] * p7_patch_diff[3'(p)];
    end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p7_diff2_unsigned[3'(p)] <= 11'h0;
      end
  end
  else if (valid_shft[0]) begin
    for (int unsigned p = 0; p < 5; p += 1) begin
        p7_diff2_unsigned[3'(p)] <= unsigned'(p7_diff2[3'(p)]);
      end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p7_add_tree0[0] <= 11'h0;
    p7_add_tree0[1] <= 11'h0;
    p7_add_tree0[2] <= 11'h0;
    p7_add_tree1[0] <= 11'h0;
    p7_add_tree1[1] <= 11'h0;
    p7_l2_dist <= 11'h0;
  end
  else begin
    if (valid_shft[1]) begin
      p7_add_tree0[0] <= p7_diff2_unsigned[0] + p7_diff2_unsigned[1];
      p7_add_tree0[1] <= p7_diff2_unsigned[2] + p7_diff2_unsigned[3];
      p7_add_tree0[2] <= p7_diff2_unsigned[4];
    end
    if (valid_shft[2]) begin
      p7_add_tree1[0] <= p7_add_tree0[0] + p7_add_tree0[1];
      p7_add_tree1[1] <= p7_add_tree0[2];
    end
    if (valid_shft[3]) begin
      p7_l2_dist <= p7_add_tree1[0] + p7_add_tree1[1];
    end
  end
end
endmodule   // L2Kernel

