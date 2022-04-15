module RunningMin (
  input logic clk,
  input logic [8:0] p0_indices,
  input logic [10:0] p0_l2_dist,
  input logic [8:0] p1_indices,
  input logic [10:0] p1_l2_dist,
  input logic [8:0] p2_indices,
  input logic [10:0] p2_l2_dist,
  input logic [8:0] p3_indices,
  input logic [10:0] p3_l2_dist,
  input logic [8:0] p4_indices,
  input logic [10:0] p4_l2_dist,
  input logic [8:0] p5_indices,
  input logic [10:0] p5_l2_dist,
  input logic [8:0] p6_indices,
  input logic [10:0] p6_l2_dist,
  input logic [8:0] p7_indices,
  input logic [10:0] p7_l2_dist,
  input logic query_last_in,
  input logic restart,
  input logic rst_n,
  input logic valid_in,
  output logic [8:0] p0_indices_min,
  output logic [10:0] p0_l2_dist_min,
  output logic [8:0] p1_indices_min,
  output logic [10:0] p1_l2_dist_min,
  output logic [8:0] p2_indices_min,
  output logic [10:0] p2_l2_dist_min,
  output logic [8:0] p3_indices_min,
  output logic [10:0] p3_l2_dist_min,
  output logic [8:0] p4_indices_min,
  output logic [10:0] p4_l2_dist_min,
  output logic [8:0] p5_indices_min,
  output logic [10:0] p5_l2_dist_min,
  output logic [8:0] p6_indices_min,
  output logic [10:0] p6_l2_dist_min,
  output logic [8:0] p7_indices_min,
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
    p0_indices_min <= 9'h0;
  end
  else if (valid_in) begin
    if ((p0_l2_dist < p0_l2_dist_min) | restart) begin
      p0_l2_dist_min <= p0_l2_dist;
      p0_indices_min <= p0_indices;
    end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p1_l2_dist_min <= 11'h0;
    p1_indices_min <= 9'h0;
  end
  else if (valid_in) begin
    if ((p1_l2_dist < p1_l2_dist_min) | restart) begin
      p1_l2_dist_min <= p1_l2_dist;
      p1_indices_min <= p1_indices;
    end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p2_l2_dist_min <= 11'h0;
    p2_indices_min <= 9'h0;
  end
  else if (valid_in) begin
    if ((p2_l2_dist < p2_l2_dist_min) | restart) begin
      p2_l2_dist_min <= p2_l2_dist;
      p2_indices_min <= p2_indices;
    end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p3_l2_dist_min <= 11'h0;
    p3_indices_min <= 9'h0;
  end
  else if (valid_in) begin
    if ((p3_l2_dist < p3_l2_dist_min) | restart) begin
      p3_l2_dist_min <= p3_l2_dist;
      p3_indices_min <= p3_indices;
    end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p4_l2_dist_min <= 11'h0;
    p4_indices_min <= 9'h0;
  end
  else if (valid_in) begin
    if ((p4_l2_dist < p4_l2_dist_min) | restart) begin
      p4_l2_dist_min <= p4_l2_dist;
      p4_indices_min <= p4_indices;
    end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p5_l2_dist_min <= 11'h0;
    p5_indices_min <= 9'h0;
  end
  else if (valid_in) begin
    if ((p5_l2_dist < p5_l2_dist_min) | restart) begin
      p5_l2_dist_min <= p5_l2_dist;
      p5_indices_min <= p5_indices;
    end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p6_l2_dist_min <= 11'h0;
    p6_indices_min <= 9'h0;
  end
  else if (valid_in) begin
    if ((p6_l2_dist < p6_l2_dist_min) | restart) begin
      p6_l2_dist_min <= p6_l2_dist;
      p6_indices_min <= p6_indices;
    end
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    p7_l2_dist_min <= 11'h0;
    p7_indices_min <= 9'h0;
  end
  else if (valid_in) begin
    if ((p7_l2_dist < p7_l2_dist_min) | restart) begin
      p7_l2_dist_min <= p7_l2_dist;
      p7_indices_min <= p7_indices;
    end
  end
end
endmodule   // RunningMin

