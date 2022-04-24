module SortedList (
  input logic clk,
  input logic insert,
  input logic [24:0] l2_dist_in,
  input logic last_in,
  input logic [14:0] merged_idx_in,
  input logic restart,
  input logic rst_n,
  output logic [24:0] l2_dist_0,
  output logic [24:0] l2_dist_1,
  output logic [24:0] l2_dist_2,
  output logic [24:0] l2_dist_3,
  output logic [14:0] merged_idx_0,
  output logic [14:0] merged_idx_1,
  output logic [14:0] merged_idx_2,
  output logic [14:0] merged_idx_3,
  output logic valid_out
);

logic [3:0] empty_n;
logic [3:0] same_leafidx;
logic [3:0] smaller;

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    valid_out <= 1'h0;
  end
  else valid_out <= last_in;
end
assign smaller[0] = l2_dist_in <= l2_dist_0;
assign same_leafidx[0] = merged_idx_0[14:9] == merged_idx_in[14:9];
assign smaller[1] = l2_dist_in <= l2_dist_1;
assign same_leafidx[1] = merged_idx_1[14:9] == merged_idx_in[14:9];
assign smaller[2] = l2_dist_in <= l2_dist_2;
assign same_leafidx[2] = merged_idx_2[14:9] == merged_idx_in[14:9];
assign smaller[3] = l2_dist_in <= l2_dist_3;
assign same_leafidx[3] = merged_idx_3[14:9] == merged_idx_in[14:9];

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n) begin
    empty_n <= 4'h0;
    l2_dist_0 <= 25'h0;
    merged_idx_0 <= 15'h0;
    l2_dist_1 <= 25'h0;
    merged_idx_1 <= 15'h0;
    l2_dist_2 <= 25'h0;
    merged_idx_2 <= 15'h0;
    l2_dist_3 <= 25'h0;
    merged_idx_3 <= 15'h0;
  end
  else if (restart) begin
    empty_n <= 4'h0;
    if (insert) begin
      l2_dist_0 <= l2_dist_in;
      merged_idx_0 <= merged_idx_in;
      empty_n[0] <= 1'h1;
    end
  end
  else if (insert) begin
    if (|(same_leafidx & (same_leafidx ^ (~empty_n)))) begin
      if (same_leafidx[0] & smaller[0]) begin
        l2_dist_0 <= l2_dist_in;
      end
      else if (same_leafidx[1] & smaller[1]) begin
        if (smaller[0]) begin
          l2_dist_0 <= l2_dist_in;
          merged_idx_0 <= merged_idx_in;
          l2_dist_1 <= l2_dist_0;
          merged_idx_1 <= merged_idx_0;
        end
        else l2_dist_1 <= l2_dist_in;
      end
      else if (same_leafidx[2] & smaller[2]) begin
        if (smaller[0]) begin
          l2_dist_0 <= l2_dist_in;
          merged_idx_0 <= merged_idx_in;
          l2_dist_1 <= l2_dist_0;
          merged_idx_1 <= merged_idx_0;
          l2_dist_2 <= l2_dist_1;
          merged_idx_2 <= merged_idx_1;
        end
        else if (smaller[1]) begin
          l2_dist_1 <= l2_dist_in;
          merged_idx_1 <= merged_idx_in;
          l2_dist_2 <= l2_dist_1;
          merged_idx_2 <= merged_idx_1;
        end
        else l2_dist_2 <= l2_dist_in;
      end
      else if (same_leafidx[3] & smaller[3]) begin
        if (smaller[0]) begin
          l2_dist_0 <= l2_dist_in;
          merged_idx_0 <= merged_idx_in;
          l2_dist_1 <= l2_dist_0;
          merged_idx_1 <= merged_idx_0;
          l2_dist_2 <= l2_dist_1;
          merged_idx_2 <= merged_idx_1;
          l2_dist_3 <= l2_dist_2;
          merged_idx_3 <= merged_idx_2;
        end
        else if (smaller[1]) begin
          l2_dist_1 <= l2_dist_in;
          merged_idx_1 <= merged_idx_in;
          l2_dist_2 <= l2_dist_1;
          merged_idx_2 <= merged_idx_1;
          l2_dist_3 <= l2_dist_2;
          merged_idx_3 <= merged_idx_2;
        end
        else if (smaller[2]) begin
          l2_dist_2 <= l2_dist_in;
          merged_idx_2 <= merged_idx_in;
          l2_dist_3 <= l2_dist_2;
          merged_idx_3 <= merged_idx_2;
        end
        else l2_dist_3 <= l2_dist_in;
      end
    end
    else begin
      if ((~empty_n[3]) | (smaller[3] & (~same_leafidx[3]))) begin
        l2_dist_3 <= l2_dist_in;
        merged_idx_3 <= merged_idx_in;
        empty_n[3] <= 1'h1;
      end
      if ((~empty_n[2]) | (smaller[2] & (~same_leafidx[2]))) begin
        l2_dist_2 <= l2_dist_in;
        merged_idx_2 <= merged_idx_in;
        empty_n[2] <= 1'h1;
        l2_dist_3 <= l2_dist_2;
        merged_idx_3 <= merged_idx_2;
        empty_n[3] <= empty_n[2];
      end
      if ((~empty_n[1]) | (smaller[1] & (~same_leafidx[1]))) begin
        l2_dist_1 <= l2_dist_in;
        merged_idx_1 <= merged_idx_in;
        empty_n[1] <= 1'h1;
        l2_dist_2 <= l2_dist_1;
        merged_idx_2 <= merged_idx_1;
        empty_n[2] <= empty_n[1];
        l2_dist_3 <= l2_dist_2;
        merged_idx_3 <= merged_idx_2;
        empty_n[3] <= empty_n[2];
      end
      if ((~empty_n[0]) | (smaller[0] & (~same_leafidx[0]))) begin
        l2_dist_0 <= l2_dist_in;
        merged_idx_0 <= merged_idx_in;
        empty_n[0] <= 1'h1;
        l2_dist_1 <= l2_dist_0;
        merged_idx_1 <= merged_idx_0;
        empty_n[1] <= empty_n[0];
        l2_dist_2 <= l2_dist_1;
        merged_idx_2 <= merged_idx_1;
        empty_n[2] <= empty_n[1];
        l2_dist_3 <= l2_dist_2;
        merged_idx_3 <= merged_idx_2;
        empty_n[3] <= empty_n[2];
      end
    end
  end
end
endmodule   // SortedList

