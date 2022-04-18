module RunningMin (
  input logic clk,
  input logic [8:0] p0_idx,
  input logic [10:0] p0_l2_dist,
  input logic [8:0] p1_idx,
  input logic [10:0] p1_l2_dist,
  input logic [8:0] p2_idx,
  input logic [10:0] p2_l2_dist,
  input logic [8:0] p3_idx,
  input logic [10:0] p3_l2_dist,
  input logic [8:0] p4_idx,
  input logic [10:0] p4_l2_dist,
  input logic [8:0] p5_idx,
  input logic [10:0] p5_l2_dist,
  input logic [8:0] p6_idx,
  input logic [10:0] p6_l2_dist,
  input logic [8:0] p7_idx,
  input logic [10:0] p7_l2_dist,
  input logic query_last_in,
  input logic restart,
  input logic rst_n,
  input logic valid_in,
  output logic [8:0] p0_idx_min,
  output logic [10:0] p0_l2_dist_min,
  output logic [8:0] p1_idx_min,
  output logic [10:0] p1_l2_dist_min,
  output logic [8:0] p2_idx_min,
  output logic [10:0] p2_l2_dist_min,
  output logic [8:0] p3_idx_min,
  output logic [10:0] p3_l2_dist_min,
  output logic [8:0] p4_idx_min,
  output logic [10:0] p4_l2_dist_min,
  output logic [8:0] p5_idx_min,
  output logic [10:0] p5_l2_dist_min,
  output logic [8:0] p6_idx_min,
  output logic [10:0] p6_l2_dist_min,
  output logic [8:0] p7_idx_min,
  output logic [10:0] p7_l2_dist_min,
  output logic query_last_out,
  output logic valid_out
);

logic query_last_r;

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    valid_out <= 1'h0;
  end
  else valid_out <= valid_in;
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    query_last_r <= 1'h0;
  end
  else query_last_r <= query_last_in;
end
assign query_last_out = query_last_r;

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p0_l2_dist_min <= 11'h0;
    p0_idx_min <= 9'h0;
  end
  else if (valid_in) begin
    if ((p0_l2_dist < p0_l2_dist_min) | restart) begin
      p0_l2_dist_min <= p0_l2_dist;
      p0_idx_min <= p0_idx;
    end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p1_l2_dist_min <= 11'h0;
    p1_idx_min <= 9'h0;
  end
  else if (valid_in) begin
    if ((p1_l2_dist < p1_l2_dist_min) | restart) begin
      p1_l2_dist_min <= p1_l2_dist;
      p1_idx_min <= p1_idx;
    end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p2_l2_dist_min <= 11'h0;
    p2_idx_min <= 9'h0;
  end
  else if (valid_in) begin
    if ((p2_l2_dist < p2_l2_dist_min) | restart) begin
      p2_l2_dist_min <= p2_l2_dist;
      p2_idx_min <= p2_idx;
    end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p3_l2_dist_min <= 11'h0;
    p3_idx_min <= 9'h0;
  end
  else if (valid_in) begin
    if ((p3_l2_dist < p3_l2_dist_min) | restart) begin
      p3_l2_dist_min <= p3_l2_dist;
      p3_idx_min <= p3_idx;
    end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p4_l2_dist_min <= 11'h0;
    p4_idx_min <= 9'h0;
  end
  else if (valid_in) begin
    if ((p4_l2_dist < p4_l2_dist_min) | restart) begin
      p4_l2_dist_min <= p4_l2_dist;
      p4_idx_min <= p4_idx;
    end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p5_l2_dist_min <= 11'h0;
    p5_idx_min <= 9'h0;
  end
  else if (valid_in) begin
    if ((p5_l2_dist < p5_l2_dist_min) | restart) begin
      p5_l2_dist_min <= p5_l2_dist;
      p5_idx_min <= p5_idx;
    end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p6_l2_dist_min <= 11'h0;
    p6_idx_min <= 9'h0;
  end
  else if (valid_in) begin
    if ((p6_l2_dist < p6_l2_dist_min) | restart) begin
      p6_l2_dist_min <= p6_l2_dist;
      p6_idx_min <= p6_idx;
    end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p7_l2_dist_min <= 11'h0;
    p7_idx_min <= 9'h0;
  end
  else if (valid_in) begin
    if ((p7_l2_dist < p7_l2_dist_min) | restart) begin
      p7_l2_dist_min <= p7_l2_dist;
      p7_idx_min <= p7_idx;
    end
  end
end
endmodule   // RunningMin

