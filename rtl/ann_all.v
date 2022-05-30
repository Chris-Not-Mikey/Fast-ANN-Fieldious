module aggregator (
	clk,
	rst_n,
	sender_data,
	sender_empty_n,
	sender_deq,
	receiver_data,
	receiver_full_n,
	receiver_enq,
	change_fetch_width,
	input_fetch_width
);
	parameter DATA_WIDTH = 16;
	parameter FETCH_WIDTH = 40;
	input clk;
	input rst_n;
	input [DATA_WIDTH - 1:0] sender_data;
	input sender_empty_n;
	output wire sender_deq;
	output wire [(FETCH_WIDTH * DATA_WIDTH) - 1:0] receiver_data;
	input receiver_full_n;
	output reg receiver_enq;
	input change_fetch_width;
	input [2:0] input_fetch_width;
	localparam COUNTER_WIDTH = $clog2(FETCH_WIDTH);
	reg [COUNTER_WIDTH - 1:0] count_r;
	reg [DATA_WIDTH - 1:0] receiver_data_unpacked [FETCH_WIDTH - 1:0];
	wire sender_deq_w;
	assign sender_deq_w = (rst_n && sender_empty_n) && receiver_full_n;
	assign sender_deq = sender_deq_w;
	genvar i;
	generate
		for (i = 0; i < FETCH_WIDTH; i = i + 1) begin : unpack
			assign receiver_data[((i + 1) * DATA_WIDTH) - 1:i * DATA_WIDTH] = receiver_data_unpacked[i];
		end
	endgenerate
	reg [5:0] LOCAL_FETCH_WIDTH;
	always @(posedge clk)
		if (!rst_n)
			LOCAL_FETCH_WIDTH <= FETCH_WIDTH;
		else if (change_fetch_width)
			LOCAL_FETCH_WIDTH <= {3'b000, input_fetch_width};
		else
			LOCAL_FETCH_WIDTH <= LOCAL_FETCH_WIDTH;
	always @(posedge clk)
		if (rst_n) begin
			if (sender_deq_w) begin
				receiver_data_unpacked[count_r] <= sender_data;
				count_r <= (count_r == LOCAL_FETCH_WIDTH ? 0 : count_r + 1);
				receiver_enq <= count_r == LOCAL_FETCH_WIDTH;
			end
			else
				receiver_enq <= 0;
		end
		else begin
			receiver_enq <= 0;
			count_r <= 0;
		end
endmodule
module BitonicSorter (
	clk,
	data_in_0,
	data_in_1,
	data_in_2,
	data_in_3,
	data_in_4,
	data_in_5,
	data_in_6,
	data_in_7,
	idx_in_0,
	idx_in_1,
	idx_in_2,
	idx_in_3,
	idx_in_4,
	idx_in_5,
	idx_in_6,
	idx_in_7,
	query_first_in,
	query_last_in,
	rst_n,
	valid_in,
	data_out_0,
	data_out_1,
	data_out_2,
	data_out_3,
	idx_out_0,
	idx_out_1,
	idx_out_2,
	idx_out_3,
	query_first_out,
	query_last_out,
	valid_out
);
	input wire clk;
	input wire [24:0] data_in_0;
	input wire [24:0] data_in_1;
	input wire [24:0] data_in_2;
	input wire [24:0] data_in_3;
	input wire [24:0] data_in_4;
	input wire [24:0] data_in_5;
	input wire [24:0] data_in_6;
	input wire [24:0] data_in_7;
	input wire [14:0] idx_in_0;
	input wire [14:0] idx_in_1;
	input wire [14:0] idx_in_2;
	input wire [14:0] idx_in_3;
	input wire [14:0] idx_in_4;
	input wire [14:0] idx_in_5;
	input wire [14:0] idx_in_6;
	input wire [14:0] idx_in_7;
	input wire query_first_in;
	input wire query_last_in;
	input wire rst_n;
	input wire valid_in;
	output wire [24:0] data_out_0;
	output wire [24:0] data_out_1;
	output wire [24:0] data_out_2;
	output wire [24:0] data_out_3;
	output wire [14:0] idx_out_0;
	output wire [14:0] idx_out_1;
	output wire [14:0] idx_out_2;
	output wire [14:0] idx_out_3;
	output wire query_first_out;
	output wire query_last_out;
	output wire valid_out;
	reg [5:0] query_first_shft;
	reg [5:0] query_last_shft;
	reg [24:0] stage0_data [7:0];
	reg [14:0] stage0_idx [7:0];
	reg stage0_valid;
	reg [24:0] stage1_data [7:0];
	reg [14:0] stage1_idx [7:0];
	reg stage1_valid;
	reg [24:0] stage2_data [7:0];
	reg [14:0] stage2_idx [7:0];
	reg stage2_valid;
	reg [24:0] stage3_data [3:0];
	reg [14:0] stage3_idx [3:0];
	reg stage3_valid;
	reg [24:0] stage4_data [3:0];
	reg [14:0] stage4_idx [3:0];
	reg stage4_valid;
	reg [24:0] stage5_data [3:0];
	reg [14:0] stage5_idx [3:0];
	reg stage5_valid;
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin
			query_first_shft <= 6'h00;
			query_last_shft <= 6'h00;
		end
		else begin
			query_first_shft <= {query_first_shft[4:0], query_first_in};
			query_last_shft <= {query_last_shft[4:0], query_last_in};
		end
	assign query_first_out = query_first_shft[5];
	assign query_last_out = query_last_shft[5];
	function automatic [2:0] sv2v_cast_3;
		input reg [2:0] inp;
		sv2v_cast_3 = inp;
	endfunction
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin
			stage0_valid <= 1'h0;
			begin : sv2v_autoblock_1
				reg [31:0] p;
				for (p = 0; p < 8; p = p + 1)
					begin
						stage0_data[sv2v_cast_3(p)] <= 25'h0000000;
						stage0_idx[sv2v_cast_3(p)] <= 15'h0000;
					end
			end
		end
		else begin
			stage0_valid <= valid_in;
			if (valid_in) begin
				stage0_data[0] <= (data_in_0 < data_in_1 ? data_in_0 : data_in_1);
				stage0_data[1] <= (data_in_0 < data_in_1 ? data_in_1 : data_in_0);
				stage0_data[2] <= (data_in_2 > data_in_3 ? data_in_2 : data_in_3);
				stage0_data[3] <= (data_in_2 > data_in_3 ? data_in_3 : data_in_2);
				stage0_data[4] <= (data_in_4 < data_in_5 ? data_in_4 : data_in_5);
				stage0_data[5] <= (data_in_4 < data_in_5 ? data_in_5 : data_in_4);
				stage0_data[6] <= (data_in_6 > data_in_7 ? data_in_6 : data_in_7);
				stage0_data[7] <= (data_in_6 > data_in_7 ? data_in_7 : data_in_6);
				stage0_idx[0] <= (data_in_0 < data_in_1 ? idx_in_0 : idx_in_1);
				stage0_idx[1] <= (data_in_0 < data_in_1 ? idx_in_1 : idx_in_0);
				stage0_idx[2] <= (data_in_2 > data_in_3 ? idx_in_2 : idx_in_3);
				stage0_idx[3] <= (data_in_2 > data_in_3 ? idx_in_3 : idx_in_2);
				stage0_idx[4] <= (data_in_4 < data_in_5 ? idx_in_4 : idx_in_5);
				stage0_idx[5] <= (data_in_4 < data_in_5 ? idx_in_5 : idx_in_4);
				stage0_idx[6] <= (data_in_6 > data_in_7 ? idx_in_6 : idx_in_7);
				stage0_idx[7] <= (data_in_6 > data_in_7 ? idx_in_7 : idx_in_6);
			end
		end
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin
			stage1_valid <= 1'h0;
			begin : sv2v_autoblock_2
				reg [31:0] p;
				for (p = 0; p < 8; p = p + 1)
					begin
						stage1_data[sv2v_cast_3(p)] <= 25'h0000000;
						stage1_idx[sv2v_cast_3(p)] <= 15'h0000;
					end
			end
		end
		else begin
			stage1_valid <= stage0_valid;
			if (stage0_valid) begin
				stage1_data[0] <= (stage0_data[0] < stage0_data[2] ? stage0_data[0] : stage0_data[2]);
				stage1_data[2] <= (stage0_data[0] < stage0_data[2] ? stage0_data[2] : stage0_data[0]);
				stage1_data[1] <= (stage0_data[1] < stage0_data[3] ? stage0_data[1] : stage0_data[3]);
				stage1_data[3] <= (stage0_data[1] < stage0_data[3] ? stage0_data[3] : stage0_data[1]);
				stage1_data[4] <= (stage0_data[4] > stage0_data[6] ? stage0_data[4] : stage0_data[6]);
				stage1_data[6] <= (stage0_data[4] > stage0_data[6] ? stage0_data[6] : stage0_data[4]);
				stage1_data[5] <= (stage0_data[5] > stage0_data[7] ? stage0_data[5] : stage0_data[7]);
				stage1_data[7] <= (stage0_data[5] > stage0_data[7] ? stage0_data[7] : stage0_data[5]);
				stage1_idx[0] <= (stage0_data[0] < stage0_data[2] ? stage0_idx[0] : stage0_idx[2]);
				stage1_idx[2] <= (stage0_data[0] < stage0_data[2] ? stage0_idx[2] : stage0_idx[0]);
				stage1_idx[1] <= (stage0_data[1] < stage0_data[3] ? stage0_idx[1] : stage0_idx[3]);
				stage1_idx[3] <= (stage0_data[1] < stage0_data[3] ? stage0_idx[3] : stage0_idx[1]);
				stage1_idx[4] <= (stage0_data[4] > stage0_data[6] ? stage0_idx[4] : stage0_idx[6]);
				stage1_idx[6] <= (stage0_data[4] > stage0_data[6] ? stage0_idx[6] : stage0_idx[4]);
				stage1_idx[5] <= (stage0_data[5] > stage0_data[7] ? stage0_idx[5] : stage0_idx[7]);
				stage1_idx[7] <= (stage0_data[5] > stage0_data[7] ? stage0_idx[7] : stage0_idx[5]);
			end
		end
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin
			stage2_valid <= 1'h0;
			begin : sv2v_autoblock_3
				reg [31:0] p;
				for (p = 0; p < 8; p = p + 1)
					begin
						stage2_data[sv2v_cast_3(p)] <= 25'h0000000;
						stage2_idx[sv2v_cast_3(p)] <= 15'h0000;
					end
			end
		end
		else begin
			stage2_valid <= stage1_valid;
			if (stage1_valid) begin
				stage2_data[0] <= (stage1_data[0] < stage1_data[1] ? stage1_data[0] : stage1_data[1]);
				stage2_data[1] <= (stage1_data[0] < stage1_data[1] ? stage1_data[1] : stage1_data[0]);
				stage2_data[2] <= (stage1_data[2] < stage1_data[3] ? stage1_data[2] : stage1_data[3]);
				stage2_data[3] <= (stage1_data[2] < stage1_data[3] ? stage1_data[3] : stage1_data[2]);
				stage2_data[4] <= (stage1_data[4] > stage1_data[5] ? stage1_data[4] : stage1_data[5]);
				stage2_data[5] <= (stage1_data[4] > stage1_data[5] ? stage1_data[5] : stage1_data[4]);
				stage2_data[6] <= (stage1_data[6] > stage1_data[7] ? stage1_data[6] : stage1_data[7]);
				stage2_data[7] <= (stage1_data[6] > stage1_data[7] ? stage1_data[7] : stage1_data[6]);
				stage2_idx[0] <= (stage1_data[0] < stage1_data[1] ? stage1_idx[0] : stage1_idx[1]);
				stage2_idx[1] <= (stage1_data[0] < stage1_data[1] ? stage1_idx[1] : stage1_idx[0]);
				stage2_idx[2] <= (stage1_data[2] < stage1_data[3] ? stage1_idx[2] : stage1_idx[3]);
				stage2_idx[3] <= (stage1_data[2] < stage1_data[3] ? stage1_idx[3] : stage1_idx[2]);
				stage2_idx[4] <= (stage1_data[4] > stage1_data[5] ? stage1_idx[4] : stage1_idx[5]);
				stage2_idx[5] <= (stage1_data[4] > stage1_data[5] ? stage1_idx[5] : stage1_idx[4]);
				stage2_idx[6] <= (stage1_data[6] > stage1_data[7] ? stage1_idx[6] : stage1_idx[7]);
				stage2_idx[7] <= (stage1_data[6] > stage1_data[7] ? stage1_idx[7] : stage1_idx[6]);
			end
		end
	function automatic [1:0] sv2v_cast_2;
		input reg [1:0] inp;
		sv2v_cast_2 = inp;
	endfunction
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin
			stage3_valid <= 1'h0;
			begin : sv2v_autoblock_4
				reg [31:0] p;
				for (p = 0; p < 4; p = p + 1)
					begin
						stage3_data[sv2v_cast_2(p)] <= 25'h0000000;
						stage3_idx[sv2v_cast_2(p)] <= 15'h0000;
					end
			end
		end
		else begin
			stage3_valid <= stage2_valid;
			if (stage2_valid) begin
				stage3_data[0] <= (stage2_data[0] < stage2_data[4] ? stage2_data[0] : stage2_data[4]);
				stage3_data[1] <= (stage2_data[1] < stage2_data[5] ? stage2_data[1] : stage2_data[5]);
				stage3_data[2] <= (stage2_data[2] < stage2_data[6] ? stage2_data[2] : stage2_data[6]);
				stage3_data[3] <= (stage2_data[3] < stage2_data[7] ? stage2_data[3] : stage2_data[7]);
				stage3_idx[0] <= (stage2_data[0] < stage2_data[4] ? stage2_idx[0] : stage2_idx[4]);
				stage3_idx[1] <= (stage2_data[1] < stage2_data[5] ? stage2_idx[1] : stage2_idx[5]);
				stage3_idx[2] <= (stage2_data[2] < stage2_data[6] ? stage2_idx[2] : stage2_idx[6]);
				stage3_idx[3] <= (stage2_data[3] < stage2_data[7] ? stage2_idx[3] : stage2_idx[7]);
			end
		end
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin
			stage4_valid <= 1'h0;
			begin : sv2v_autoblock_5
				reg [31:0] p;
				for (p = 0; p < 4; p = p + 1)
					begin
						stage4_data[sv2v_cast_2(p)] <= 25'h0000000;
						stage4_idx[sv2v_cast_2(p)] <= 15'h0000;
					end
			end
		end
		else begin
			stage4_valid <= stage3_valid;
			if (stage3_valid) begin
				stage4_data[0] <= (stage3_data[0] < stage3_data[2] ? stage3_data[0] : stage3_data[2]);
				stage4_data[2] <= (stage3_data[0] < stage3_data[2] ? stage3_data[2] : stage3_data[0]);
				stage4_data[1] <= (stage3_data[1] < stage3_data[3] ? stage3_data[1] : stage3_data[3]);
				stage4_data[3] <= (stage3_data[1] < stage3_data[3] ? stage3_data[3] : stage3_data[1]);
				stage4_idx[0] <= (stage3_data[0] < stage3_data[2] ? stage3_idx[0] : stage3_idx[2]);
				stage4_idx[2] <= (stage3_data[0] < stage3_data[2] ? stage3_idx[2] : stage3_idx[0]);
				stage4_idx[1] <= (stage3_data[1] < stage3_data[3] ? stage3_idx[1] : stage3_idx[3]);
				stage4_idx[3] <= (stage3_data[1] < stage3_data[3] ? stage3_idx[3] : stage3_idx[1]);
			end
		end
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin
			stage5_valid <= 1'h0;
			begin : sv2v_autoblock_6
				reg [31:0] p;
				for (p = 0; p < 4; p = p + 1)
					begin
						stage5_data[sv2v_cast_2(p)] <= 25'h0000000;
						stage5_idx[sv2v_cast_2(p)] <= 15'h0000;
					end
			end
		end
		else begin
			stage5_valid <= stage4_valid;
			if (stage4_valid) begin
				stage5_data[0] <= (stage4_data[0] < stage4_data[1] ? stage4_data[0] : stage4_data[1]);
				stage5_data[1] <= (stage4_data[0] < stage4_data[1] ? stage4_data[1] : stage4_data[0]);
				stage5_data[2] <= (stage4_data[2] < stage4_data[3] ? stage4_data[2] : stage4_data[3]);
				stage5_data[3] <= (stage4_data[2] < stage4_data[3] ? stage4_data[3] : stage4_data[2]);
				stage5_idx[0] <= (stage4_data[0] < stage4_data[1] ? stage4_idx[0] : stage4_idx[1]);
				stage5_idx[1] <= (stage4_data[0] < stage4_data[1] ? stage4_idx[1] : stage4_idx[0]);
				stage5_idx[2] <= (stage4_data[2] < stage4_data[3] ? stage4_idx[2] : stage4_idx[3]);
				stage5_idx[3] <= (stage4_data[2] < stage4_data[3] ? stage4_idx[3] : stage4_idx[2]);
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
endmodule
module ClockMux (
	select,
	clk0,
	clk1,
	out_clk
);
	input select;
	input clk0;
	input clk1;
	output wire out_clk;
	wire q_t0;
	wire q_t1;
	wire q_b0;
	wire q_b1;
	CW_ff #(.wD(1)) t0(
		.CLK(clk1),
		.D(!q_b1 & select),
		.Q(q_t0)
	);
	CW_ff #(.wD(1)) t1(
		.CLK(!clk1),
		.D(q_t0),
		.Q(q_t1)
	);
	CW_ff #(.wD(1)) b0(
		.CLK(clk0),
		.D(!q_t1 & !select),
		.Q(q_b0)
	);
	CW_ff #(.wD(1)) b1(
		.CLK(!clk0),
		.D(q_b0),
		.Q(q_b1)
	);
	assign out_clk = (clk1 & q_t1) | (clk0 & q_b1);
endmodule
module CW_ff (
	CLK,
	D,
	Q
);
	parameter wD = 1;
	input CLK;
	input [wD - 1:0] D;
	output reg [wD - 1:0] Q;
	wire [wD - 1:0] D2 = D;
	always @(posedge CLK) Q <= D2;
endmodule
module internal_node (
	clk,
	rst_n,
	wen,
	valid,
	valid_two,
	wdata,
	patch_in,
	patch_in_two,
	patch_out,
	valid_left,
	valid_right,
	valid_left_two,
	valid_right_two,
	rdata
);
	parameter DATA_WIDTH = 55;
	parameter STORAGE_WIDTH = 22;
	input clk;
	input rst_n;
	input wen;
	input valid;
	input valid_two;
	input [STORAGE_WIDTH - 1:0] wdata;
	input [DATA_WIDTH - 1:0] patch_in;
	input [DATA_WIDTH - 1:0] patch_in_two;
	output wire [DATA_WIDTH - 1:0] patch_out;
	output wire valid_left;
	output wire valid_right;
	output wire valid_left_two;
	output wire valid_right_two;
	output wire [STORAGE_WIDTH - 1:0] rdata;
	reg [2:0] idx;
	reg signed [10:0] median;
	reg signed [10:0] sliced_patch;
	reg signed [10:0] sliced_patch_two;
	wire comparison;
	wire comparison_two;
	always @(clk)
		if (rst_n == 0)
			idx <= 3'b111;
		else if (wen)
			idx <= wdata[2:0];
		else
			idx <= idx;
	always @(clk)
		if (rst_n == 0)
			median <= 0;
		else if (wen)
			median <= wdata[21:11];
		else
			median <= median;
	always @(*)
		case (idx)
			3'b000: begin
				sliced_patch = patch_in[10:0];
				sliced_patch_two = patch_in_two[10:0];
			end
			3'b001: begin
				sliced_patch = patch_in[21:11];
				sliced_patch_two = patch_in_two[21:11];
			end
			3'b010: begin
				sliced_patch = patch_in[32:22];
				sliced_patch_two = patch_in_two[32:22];
			end
			3'b011: begin
				sliced_patch = patch_in[43:33];
				sliced_patch_two = patch_in_two[43:33];
			end
			3'b100: begin
				sliced_patch = patch_in[54:44];
				sliced_patch_two = patch_in_two[54:44];
			end
			default: begin
				sliced_patch = 11'b00000000000;
				sliced_patch_two = 11'b00000000000;
			end
		endcase
	assign comparison = sliced_patch < median;
	assign comparison_two = sliced_patch_two < median;
	assign valid_left = comparison && valid;
	assign valid_right = !comparison && valid;
	assign valid_left_two = comparison_two && valid_two;
	assign valid_right_two = !comparison_two && valid_two;
	assign patch_out = patch_in;
	assign rdata = {median, 8'b00000000, idx};
endmodule
module internal_node_tree (
	clk,
	rst_n,
	sender_enable,
	sender_data,
	sender_addr,
	patch_en,
	patch_two_en,
	patch_in,
	patch_in_two,
	leaf_index,
	leaf_index_two,
	receiver_en,
	receiver_two_en,
	wbs_rd_en_i,
	wbs_dat_o
);
	parameter INTERNAL_WIDTH = 22;
	parameter PATCH_WIDTH = 55;
	parameter ADDRESS_WIDTH = 8;
	input clk;
	input rst_n;
	input sender_enable;
	input [INTERNAL_WIDTH - 1:0] sender_data;
	input [5:0] sender_addr;
	input patch_en;
	input patch_two_en;
	input [PATCH_WIDTH - 1:0] patch_in;
	input [PATCH_WIDTH - 1:0] patch_in_two;
	output reg [ADDRESS_WIDTH - 1:0] leaf_index;
	output reg [ADDRESS_WIDTH - 1:0] leaf_index_two;
	output wire receiver_en;
	output wire receiver_two_en;
	input wbs_rd_en_i;
	output reg [21:0] wbs_dat_o;
	wire wen;
	assign wen = sender_enable;
	reg [INTERNAL_WIDTH - 1:0] rdata_storage [63:0];
	reg [INTERNAL_WIDTH - 1:0] write_data;
	always @(posedge clk)
		if (rst_n == 0)
			wbs_dat_o <= {INTERNAL_WIDTH {1'b0}};
		else if (wbs_rd_en_i)
			wbs_dat_o <= rdata_storage[sender_addr];
	reg [5:0] wadr;
	reg one_hot_address_en [63:0];
	wire [PATCH_WIDTH - 1:0] patch_out;
	reg latency_track_reciever_en [6:0];
	reg latency_track_reciever_two_en [6:0];
	always @(posedge clk)
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
	assign receiver_en = latency_track_reciever_en[6];
	assign receiver_two_en = latency_track_reciever_two_en[6];
	always @(*) begin : sv2v_autoblock_1
		reg signed [31:0] q;
		for (q = 0; q < 128; q = q + 1)
			if (q == sender_addr)
				one_hot_address_en[q] = 1'b1;
			else
				one_hot_address_en[q] = 1'b0;
	end
	reg [PATCH_WIDTH - 1:0] level_patches [7:0];
	reg [PATCH_WIDTH - 1:0] level_patches_two [7:0];
	reg level_valid [63:0][7:0];
	reg level_valid_two [63:0][7:0];
	wire level_valid_storage [63:0][7:0];
	wire level_valid_storage_two [63:0][7:0];
	genvar i;
	genvar j;
	generate
		for (i = 0; i < 6; i = i + 1) begin : genblk1
			for (j = 0; j < (2 ** i); j = j + 1) begin : genblk1
				wire [INTERNAL_WIDTH:1] sv2v_tmp_node_rdata;
				always @(*) rdata_storage[((2 ** i) + j) - 1] = sv2v_tmp_node_rdata;
				internal_node #(
					.DATA_WIDTH(PATCH_WIDTH),
					.STORAGE_WIDTH(INTERNAL_WIDTH)
				) node(
					.clk(clk),
					.rst_n(rst_n),
					.wen(wen && one_hot_address_en[((2 ** i) + j) - 1]),
					.valid(level_valid[j][i]),
					.valid_two(level_valid_two[j][i]),
					.wdata(sender_data),
					.patch_in(level_patches[i]),
					.patch_in_two(level_patches_two[i]),
					.valid_left(level_valid_storage[j * 2][i]),
					.valid_right(level_valid_storage[(j * 2) + 1][i]),
					.valid_left_two(level_valid_storage_two[j * 2][i]),
					.valid_right_two(level_valid_storage_two[(j * 2) + 1][i]),
					.rdata(sv2v_tmp_node_rdata)
				);
			end
		end
	endgenerate
	always @(posedge clk)
		if (rst_n == 0) begin
			level_patches[0] <= 55'b0000000000000000000000000000000000000000000000000000000;
			level_patches_two[0] <= 55'b0000000000000000000000000000000000000000000000000000000;
			begin : sv2v_autoblock_2
				reg signed [31:0] r;
				for (r = 0; r < 64; r = r + 1)
					begin
						level_valid[r][0] <= 1'b0;
						level_valid_two[r][0] <= 1'b0;
					end
			end
		end
		else if (patch_en && patch_two_en) begin
			level_patches[0] <= patch_in;
			level_patches_two[0] <= patch_in_two;
			level_valid[0][0] <= 1'b1;
			level_valid_two[0][0] <= 1'b1;
			begin : sv2v_autoblock_3
				reg signed [31:0] r;
				for (r = 1; r < 64; r = r + 1)
					begin
						level_valid[r][0] <= 1'b0;
						level_valid_two[r][0] <= 1'b0;
					end
			end
		end
		else begin
			level_patches[0] <= level_patches[0];
			level_patches_two[0] <= level_patches_two[0];
			level_valid[0][0] <= 1'b1;
			level_valid_two[0][0] <= 1'b1;
			begin : sv2v_autoblock_4
				reg signed [31:0] r;
				for (r = 1; r < 64; r = r + 1)
					begin
						level_valid[r][0] <= 1'b0;
						level_valid_two[r][0] <= 1'b0;
					end
			end
		end
	always @(posedge clk)
		if (rst_n == 0) begin
			level_patches[1] <= 55'b0000000000000000000000000000000000000000000000000000000;
			level_patches_two[1] <= 55'b0000000000000000000000000000000000000000000000000000000;
			begin : sv2v_autoblock_5
				reg signed [31:0] r;
				for (r = 0; r < 64; r = r + 1)
					begin
						level_valid[r][1] <= 1'b0;
						level_valid_two[r][1] <= 1'b0;
					end
			end
		end
		else begin
			level_patches[1] <= level_patches[0];
			level_patches_two[1] <= level_patches_two[0];
			begin : sv2v_autoblock_6
				reg signed [31:0] r;
				for (r = 0; r < 64; r = r + 1)
					begin
						level_valid[r][1] <= level_valid_storage[r][0];
						level_valid_two[r][1] <= level_valid_storage_two[r][0];
					end
			end
		end
	always @(posedge clk)
		if (rst_n == 0) begin
			level_patches[2] <= 55'b0000000000000000000000000000000000000000000000000000000;
			level_patches_two[2] <= 55'b0000000000000000000000000000000000000000000000000000000;
			begin : sv2v_autoblock_7
				reg signed [31:0] r;
				for (r = 0; r < 64; r = r + 1)
					begin
						level_valid[r][2] <= 1'b0;
						level_valid_two[r][2] <= 1'b0;
					end
			end
		end
		else begin
			level_patches[2] <= level_patches[1];
			level_patches_two[2] <= level_patches_two[1];
			begin : sv2v_autoblock_8
				reg signed [31:0] r;
				for (r = 0; r < 64; r = r + 1)
					begin
						level_valid[r][2] <= level_valid_storage[r][1];
						level_valid_two[r][2] <= level_valid_storage_two[r][1];
					end
			end
		end
	always @(posedge clk)
		if (rst_n == 0) begin
			level_patches[3] <= 55'b0000000000000000000000000000000000000000000000000000000;
			level_patches_two[3] <= 55'b0000000000000000000000000000000000000000000000000000000;
			begin : sv2v_autoblock_9
				reg signed [31:0] r;
				for (r = 0; r < 64; r = r + 1)
					begin
						level_valid[r][3] <= 1'b0;
						level_valid_two[r][3] <= 1'b0;
					end
			end
		end
		else begin
			level_patches[3] <= level_patches[1];
			level_patches_two[3] <= level_patches_two[1];
			begin : sv2v_autoblock_10
				reg signed [31:0] r;
				for (r = 0; r < 64; r = r + 1)
					begin
						level_valid[r][3] <= level_valid_storage[r][2];
						level_valid_two[r][3] <= level_valid_storage_two[r][2];
					end
			end
		end
	always @(posedge clk)
		if (rst_n == 0) begin
			level_patches[4] <= 55'b0000000000000000000000000000000000000000000000000000000;
			level_patches_two[4] <= 55'b0000000000000000000000000000000000000000000000000000000;
			begin : sv2v_autoblock_11
				reg signed [31:0] r;
				for (r = 0; r < 64; r = r + 1)
					begin
						level_valid[r][4] <= 1'b0;
						level_valid_two[r][4] <= 1'b0;
					end
			end
		end
		else begin
			level_patches[4] <= level_patches[3];
			level_patches_two[4] <= level_patches_two[3];
			begin : sv2v_autoblock_12
				reg signed [31:0] r;
				for (r = 0; r < 64; r = r + 1)
					begin
						level_valid[r][4] <= level_valid_storage[r][3];
						level_valid_two[r][4] <= level_valid_storage_two[r][3];
					end
			end
		end
	always @(posedge clk)
		if (rst_n == 0) begin
			level_patches[5] <= 55'b0000000000000000000000000000000000000000000000000000000;
			level_patches_two[5] <= 55'b0000000000000000000000000000000000000000000000000000000;
			begin : sv2v_autoblock_13
				reg signed [31:0] r;
				for (r = 0; r < 64; r = r + 1)
					begin
						level_valid[r][5] <= 1'b0;
						level_valid_two[r][5] <= 1'b0;
					end
			end
		end
		else begin
			level_patches[5] <= level_patches[4];
			level_patches_two[5] <= level_patches_two[4];
			begin : sv2v_autoblock_14
				reg signed [31:0] r;
				for (r = 0; r < 64; r = r + 1)
					begin
						level_valid[r][5] <= level_valid_storage[r][4];
						level_valid_two[r][5] <= level_valid_storage_two[r][4];
					end
			end
		end
	always @(posedge clk)
		if (rst_n == 0) begin
			level_patches[6] <= 55'b0000000000000000000000000000000000000000000000000000000;
			level_patches_two[6] <= 55'b0000000000000000000000000000000000000000000000000000000;
			begin : sv2v_autoblock_15
				reg signed [31:0] r;
				for (r = 0; r < 64; r = r + 1)
					begin
						level_valid[r][6] <= 1'b0;
						level_valid_two[r][6] <= 1'b0;
					end
			end
		end
		else begin
			level_patches[6] <= level_patches[5];
			level_patches_two[6] <= level_patches_two[5];
			begin : sv2v_autoblock_16
				reg signed [31:0] r;
				for (r = 0; r < 64; r = r + 1)
					begin
						level_valid[r][6] <= level_valid_storage[r][5];
						level_valid_two[r][6] <= level_valid_storage_two[r][5];
					end
			end
		end
	always @(*) begin
		leaf_index = 0;
		begin : sv2v_autoblock_17
			reg signed [31:0] i;
			for (i = 0; i < 64; i = i + 1)
				if (level_valid[i][6] == 1'b1)
					leaf_index = i;
		end
		leaf_index_two = 0;
		begin : sv2v_autoblock_18
			reg signed [31:0] i;
			for (i = 0; i < 64; i = i + 1)
				if (level_valid_two[i][6] == 1'b1)
					leaf_index_two = i;
		end
	end
endmodule
module kBestArrays (
	clk,
	csb0,
	web0,
	addr0,
	wdata0,
	rdata0,
	csb1,
	addr1,
	rdata1
);
	parameter DATA_WIDTH = 32;
	parameter IDX_WIDTH = 9;
	parameter K = 4;
	parameter NUM_LEAVES = 64;
	parameter LEAF_ADDRW = $clog2(NUM_LEAVES);
	input clk;
	input wire csb0;
	input wire web0;
	input wire [7:0] addr0;
	input wire [(K * DATA_WIDTH) - 1:0] wdata0;
	output wire [(K * DATA_WIDTH) - 1:0] rdata0;
	input wire [K - 1:0] csb1;
	input wire [7:0] addr1;
	output wire [(K * DATA_WIDTH) - 1:0] rdata1;
	wire [DATA_WIDTH - 1:0] dout0 [K - 1:0];
	wire [DATA_WIDTH - 1:0] dout1 [K - 1:0];
	genvar i;
	generate
		for (i = 0; i < K; i = i + 1) begin : loop_best_array_gen
			sram_1kbyte_1rw1r #(
				.DATA_WIDTH(DATA_WIDTH),
				.ADDR_WIDTH(8),
				.RAM_DEPTH(256)
			) best_dist_array_inst(
				.clk0(clk),
				.csb0(csb0),
				.web0(web0),
				.addr0(addr0),
				.din0(wdata0[i * DATA_WIDTH+:DATA_WIDTH]),
				.dout0(dout0[i]),
				.clk1(clk),
				.csb1(csb1[i]),
				.addr1(addr1),
				.dout1(dout1[i])
			);
			assign rdata0[i * DATA_WIDTH+:DATA_WIDTH] = dout0[i];
			assign rdata1[i * DATA_WIDTH+:DATA_WIDTH] = dout1[i];
		end
	endgenerate
endmodule
module L2Kernel (
	clk,
	leaf_idx_in,
	p0_data,
	p0_idx_in,
	p1_data,
	p1_idx_in,
	p2_data,
	p2_idx_in,
	p3_data,
	p3_idx_in,
	p4_data,
	p4_idx_in,
	p5_data,
	p5_idx_in,
	p6_data,
	p6_idx_in,
	p7_data,
	p7_idx_in,
	query_first_in,
	query_last_in,
	query_patch,
	query_valid,
	rst_n,
	dist_valid,
	leaf_idx_out,
	p0_idx_out,
	p0_l2_dist,
	p1_idx_out,
	p1_l2_dist,
	p2_idx_out,
	p2_l2_dist,
	p3_idx_out,
	p3_l2_dist,
	p4_idx_out,
	p4_l2_dist,
	p5_idx_out,
	p5_l2_dist,
	p6_idx_out,
	p6_l2_dist,
	p7_idx_out,
	p7_l2_dist,
	query_first_out,
	query_last_out
);
	input wire clk;
	input wire [5:0] leaf_idx_in;
	input wire signed [54:0] p0_data;
	input wire [8:0] p0_idx_in;
	input wire signed [54:0] p1_data;
	input wire [8:0] p1_idx_in;
	input wire signed [54:0] p2_data;
	input wire [8:0] p2_idx_in;
	input wire signed [54:0] p3_data;
	input wire [8:0] p3_idx_in;
	input wire signed [54:0] p4_data;
	input wire [8:0] p4_idx_in;
	input wire signed [54:0] p5_data;
	input wire [8:0] p5_idx_in;
	input wire signed [54:0] p6_data;
	input wire [8:0] p6_idx_in;
	input wire signed [54:0] p7_data;
	input wire [8:0] p7_idx_in;
	input wire query_first_in;
	input wire query_last_in;
	input wire signed [54:0] query_patch;
	input wire query_valid;
	input wire rst_n;
	output wire dist_valid;
	output reg [5:0] leaf_idx_out;
	output reg [8:0] p0_idx_out;
	output wire [24:0] p0_l2_dist;
	output reg [8:0] p1_idx_out;
	output wire [24:0] p1_l2_dist;
	output reg [8:0] p2_idx_out;
	output wire [24:0] p2_l2_dist;
	output reg [8:0] p3_idx_out;
	output wire [24:0] p3_l2_dist;
	output reg [8:0] p4_idx_out;
	output wire [24:0] p4_l2_dist;
	output reg [8:0] p5_idx_out;
	output wire [24:0] p5_l2_dist;
	output reg [8:0] p6_idx_out;
	output wire [24:0] p6_l2_dist;
	output reg [8:0] p7_idx_out;
	output wire [24:0] p7_l2_dist;
	output wire query_first_out;
	output wire query_last_out;
	reg [5:0] leaf_idx_r0;
	reg [5:0] leaf_idx_r1;
	reg [5:0] leaf_idx_r2;
	reg [5:0] leaf_idx_r3;
	reg [22:0] p0_add_tree0 [2:0];
	reg [23:0] p0_add_tree1 [1:0];
	reg [24:0] p0_add_tree2;
	reg signed [21:0] p0_diff2 [4:0];
	reg [21:0] p0_diff2_unsigned [4:0];
	reg [8:0] p0_idx_r0;
	reg [8:0] p0_idx_r1;
	reg [8:0] p0_idx_r2;
	reg [8:0] p0_idx_r3;
	reg signed [10:0] p0_patch_diff [4:0];
	reg [22:0] p1_add_tree0 [2:0];
	reg [23:0] p1_add_tree1 [1:0];
	reg [24:0] p1_add_tree2;
	reg signed [21:0] p1_diff2 [4:0];
	reg [21:0] p1_diff2_unsigned [4:0];
	reg [8:0] p1_idx_r0;
	reg [8:0] p1_idx_r1;
	reg [8:0] p1_idx_r2;
	reg [8:0] p1_idx_r3;
	reg signed [10:0] p1_patch_diff [4:0];
	reg [22:0] p2_add_tree0 [2:0];
	reg [23:0] p2_add_tree1 [1:0];
	reg [24:0] p2_add_tree2;
	reg signed [21:0] p2_diff2 [4:0];
	reg [21:0] p2_diff2_unsigned [4:0];
	reg [8:0] p2_idx_r0;
	reg [8:0] p2_idx_r1;
	reg [8:0] p2_idx_r2;
	reg [8:0] p2_idx_r3;
	reg signed [10:0] p2_patch_diff [4:0];
	reg [22:0] p3_add_tree0 [2:0];
	reg [23:0] p3_add_tree1 [1:0];
	reg [24:0] p3_add_tree2;
	reg signed [21:0] p3_diff2 [4:0];
	reg [21:0] p3_diff2_unsigned [4:0];
	reg [8:0] p3_idx_r0;
	reg [8:0] p3_idx_r1;
	reg [8:0] p3_idx_r2;
	reg [8:0] p3_idx_r3;
	reg signed [10:0] p3_patch_diff [4:0];
	reg [22:0] p4_add_tree0 [2:0];
	reg [23:0] p4_add_tree1 [1:0];
	reg [24:0] p4_add_tree2;
	reg signed [21:0] p4_diff2 [4:0];
	reg [21:0] p4_diff2_unsigned [4:0];
	reg [8:0] p4_idx_r0;
	reg [8:0] p4_idx_r1;
	reg [8:0] p4_idx_r2;
	reg [8:0] p4_idx_r3;
	reg signed [10:0] p4_patch_diff [4:0];
	reg [22:0] p5_add_tree0 [2:0];
	reg [23:0] p5_add_tree1 [1:0];
	reg [24:0] p5_add_tree2;
	reg signed [21:0] p5_diff2 [4:0];
	reg [21:0] p5_diff2_unsigned [4:0];
	reg [8:0] p5_idx_r0;
	reg [8:0] p5_idx_r1;
	reg [8:0] p5_idx_r2;
	reg [8:0] p5_idx_r3;
	reg signed [10:0] p5_patch_diff [4:0];
	reg [22:0] p6_add_tree0 [2:0];
	reg [23:0] p6_add_tree1 [1:0];
	reg [24:0] p6_add_tree2;
	reg signed [21:0] p6_diff2 [4:0];
	reg [21:0] p6_diff2_unsigned [4:0];
	reg [8:0] p6_idx_r0;
	reg [8:0] p6_idx_r1;
	reg [8:0] p6_idx_r2;
	reg [8:0] p6_idx_r3;
	reg signed [10:0] p6_patch_diff [4:0];
	reg [22:0] p7_add_tree0 [2:0];
	reg [23:0] p7_add_tree1 [1:0];
	reg [24:0] p7_add_tree2;
	reg signed [21:0] p7_diff2 [4:0];
	reg [21:0] p7_diff2_unsigned [4:0];
	reg [8:0] p7_idx_r0;
	reg [8:0] p7_idx_r1;
	reg [8:0] p7_idx_r2;
	reg [8:0] p7_idx_r3;
	reg signed [10:0] p7_patch_diff [4:0];
	reg [4:0] query_first_shft;
	reg [4:0] query_last_shft;
	reg [4:0] valid_shft;
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin
			query_first_shft <= 5'h00;
			query_last_shft <= 5'h00;
			valid_shft <= 5'h00;
		end
		else begin
			query_first_shft <= {query_first_shft[3:0], query_first_in};
			query_last_shft <= {query_last_shft[3:0], query_last_in};
			valid_shft <= {valid_shft[3:0], query_valid};
		end
	assign query_first_out = query_first_shft[4];
	assign query_last_out = query_last_shft[4];
	assign dist_valid = valid_shft[4];
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin
			leaf_idx_r0 <= 6'h00;
			leaf_idx_r1 <= 6'h00;
			leaf_idx_r2 <= 6'h00;
			leaf_idx_r3 <= 6'h00;
			leaf_idx_out <= 6'h00;
		end
		else begin
			if (query_valid)
				leaf_idx_r0 <= leaf_idx_in;
			if (valid_shft[0])
				leaf_idx_r1 <= leaf_idx_r0;
			if (valid_shft[1])
				leaf_idx_r2 <= leaf_idx_r1;
			if (valid_shft[2])
				leaf_idx_r3 <= leaf_idx_r2;
			if (valid_shft[3])
				leaf_idx_out <= leaf_idx_r3;
		end
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin
			p0_idx_r0 <= 9'h000;
			p0_idx_r1 <= 9'h000;
			p0_idx_r2 <= 9'h000;
			p0_idx_r3 <= 9'h000;
			p0_idx_out <= 9'h000;
		end
		else begin
			if (query_valid)
				p0_idx_r0 <= p0_idx_in;
			if (valid_shft[0])
				p0_idx_r1 <= p0_idx_r0;
			if (valid_shft[1])
				p0_idx_r2 <= p0_idx_r1;
			if (valid_shft[2])
				p0_idx_r3 <= p0_idx_r2;
			if (valid_shft[3])
				p0_idx_out <= p0_idx_r3;
		end
	function automatic [2:0] sv2v_cast_3;
		input reg [2:0] inp;
		sv2v_cast_3 = inp;
	endfunction
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin : sv2v_autoblock_1
			reg [31:0] p;
			for (p = 0; p < 5; p = p + 1)
				p0_patch_diff[sv2v_cast_3(p)] <= 11'h000;
		end
		else if (query_valid) begin : sv2v_autoblock_2
			reg [31:0] p;
			for (p = 0; p < 5; p = p + 1)
				p0_patch_diff[sv2v_cast_3(p)] <= query_patch[sv2v_cast_3(p) * 11+:11] - p0_data[sv2v_cast_3(p) * 11+:11];
		end
	function automatic [21:0] sv2v_cast_22;
		input reg [21:0] inp;
		sv2v_cast_22 = inp;
	endfunction
	always @(*) begin : sv2v_autoblock_3
		reg [31:0] p;
		for (p = 0; p < 5; p = p + 1)
			p0_diff2[sv2v_cast_3(p)] = sv2v_cast_22(p0_patch_diff[sv2v_cast_3(p)]) * sv2v_cast_22(p0_patch_diff[sv2v_cast_3(p)]);
	end
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin : sv2v_autoblock_4
			reg [31:0] p;
			for (p = 0; p < 5; p = p + 1)
				p0_diff2_unsigned[sv2v_cast_3(p)] <= 22'h000000;
		end
		else if (valid_shft[0]) begin : sv2v_autoblock_5
			reg [31:0] p;
			for (p = 0; p < 5; p = p + 1)
				p0_diff2_unsigned[sv2v_cast_3(p)] <= $unsigned(p0_diff2[sv2v_cast_3(p)]);
		end
	function automatic [22:0] sv2v_cast_23;
		input reg [22:0] inp;
		sv2v_cast_23 = inp;
	endfunction
	function automatic [23:0] sv2v_cast_24;
		input reg [23:0] inp;
		sv2v_cast_24 = inp;
	endfunction
	function automatic [24:0] sv2v_cast_25;
		input reg [24:0] inp;
		sv2v_cast_25 = inp;
	endfunction
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin
			p0_add_tree0[0] <= 23'h000000;
			p0_add_tree0[1] <= 23'h000000;
			p0_add_tree0[2] <= 23'h000000;
			p0_add_tree1[0] <= 24'h000000;
			p0_add_tree1[1] <= 24'h000000;
			p0_add_tree2 <= 25'h0000000;
		end
		else begin
			if (valid_shft[1]) begin
				p0_add_tree0[0] <= sv2v_cast_23(p0_diff2_unsigned[0]) + sv2v_cast_23(p0_diff2_unsigned[1]);
				p0_add_tree0[1] <= sv2v_cast_23(p0_diff2_unsigned[2]) + sv2v_cast_23(p0_diff2_unsigned[3]);
				p0_add_tree0[2] <= sv2v_cast_23(p0_diff2_unsigned[4]);
			end
			if (valid_shft[2]) begin
				p0_add_tree1[0] <= sv2v_cast_24(p0_add_tree0[0]) + sv2v_cast_24(p0_add_tree0[1]);
				p0_add_tree1[1] <= sv2v_cast_24(p0_add_tree0[2]);
			end
			if (valid_shft[3])
				p0_add_tree2 <= sv2v_cast_25(p0_add_tree1[0]) + sv2v_cast_25(p0_add_tree1[1]);
		end
	assign p0_l2_dist = p0_add_tree2;
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin
			p1_idx_r0 <= 9'h000;
			p1_idx_r1 <= 9'h000;
			p1_idx_r2 <= 9'h000;
			p1_idx_r3 <= 9'h000;
			p1_idx_out <= 9'h000;
		end
		else begin
			if (query_valid)
				p1_idx_r0 <= p1_idx_in;
			if (valid_shft[0])
				p1_idx_r1 <= p1_idx_r0;
			if (valid_shft[1])
				p1_idx_r2 <= p1_idx_r1;
			if (valid_shft[2])
				p1_idx_r3 <= p1_idx_r2;
			if (valid_shft[3])
				p1_idx_out <= p1_idx_r3;
		end
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin : sv2v_autoblock_6
			reg [31:0] p;
			for (p = 0; p < 5; p = p + 1)
				p1_patch_diff[sv2v_cast_3(p)] <= 11'h000;
		end
		else if (query_valid) begin : sv2v_autoblock_7
			reg [31:0] p;
			for (p = 0; p < 5; p = p + 1)
				p1_patch_diff[sv2v_cast_3(p)] <= query_patch[sv2v_cast_3(p) * 11+:11] - p1_data[sv2v_cast_3(p) * 11+:11];
		end
	always @(*) begin : sv2v_autoblock_8
		reg [31:0] p;
		for (p = 0; p < 5; p = p + 1)
			p1_diff2[sv2v_cast_3(p)] = sv2v_cast_22(p1_patch_diff[sv2v_cast_3(p)]) * sv2v_cast_22(p1_patch_diff[sv2v_cast_3(p)]);
	end
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin : sv2v_autoblock_9
			reg [31:0] p;
			for (p = 0; p < 5; p = p + 1)
				p1_diff2_unsigned[sv2v_cast_3(p)] <= 22'h000000;
		end
		else if (valid_shft[0]) begin : sv2v_autoblock_10
			reg [31:0] p;
			for (p = 0; p < 5; p = p + 1)
				p1_diff2_unsigned[sv2v_cast_3(p)] <= $unsigned(p1_diff2[sv2v_cast_3(p)]);
		end
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin
			p1_add_tree0[0] <= 23'h000000;
			p1_add_tree0[1] <= 23'h000000;
			p1_add_tree0[2] <= 23'h000000;
			p1_add_tree1[0] <= 24'h000000;
			p1_add_tree1[1] <= 24'h000000;
			p1_add_tree2 <= 25'h0000000;
		end
		else begin
			if (valid_shft[1]) begin
				p1_add_tree0[0] <= sv2v_cast_23(p1_diff2_unsigned[0]) + sv2v_cast_23(p1_diff2_unsigned[1]);
				p1_add_tree0[1] <= sv2v_cast_23(p1_diff2_unsigned[2]) + sv2v_cast_23(p1_diff2_unsigned[3]);
				p1_add_tree0[2] <= sv2v_cast_23(p1_diff2_unsigned[4]);
			end
			if (valid_shft[2]) begin
				p1_add_tree1[0] <= sv2v_cast_24(p1_add_tree0[0]) + sv2v_cast_24(p1_add_tree0[1]);
				p1_add_tree1[1] <= sv2v_cast_24(p1_add_tree0[2]);
			end
			if (valid_shft[3])
				p1_add_tree2 <= sv2v_cast_25(p1_add_tree1[0]) + sv2v_cast_25(p1_add_tree1[1]);
		end
	assign p1_l2_dist = p1_add_tree2;
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin
			p2_idx_r0 <= 9'h000;
			p2_idx_r1 <= 9'h000;
			p2_idx_r2 <= 9'h000;
			p2_idx_r3 <= 9'h000;
			p2_idx_out <= 9'h000;
		end
		else begin
			if (query_valid)
				p2_idx_r0 <= p2_idx_in;
			if (valid_shft[0])
				p2_idx_r1 <= p2_idx_r0;
			if (valid_shft[1])
				p2_idx_r2 <= p2_idx_r1;
			if (valid_shft[2])
				p2_idx_r3 <= p2_idx_r2;
			if (valid_shft[3])
				p2_idx_out <= p2_idx_r3;
		end
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin : sv2v_autoblock_11
			reg [31:0] p;
			for (p = 0; p < 5; p = p + 1)
				p2_patch_diff[sv2v_cast_3(p)] <= 11'h000;
		end
		else if (query_valid) begin : sv2v_autoblock_12
			reg [31:0] p;
			for (p = 0; p < 5; p = p + 1)
				p2_patch_diff[sv2v_cast_3(p)] <= query_patch[sv2v_cast_3(p) * 11+:11] - p2_data[sv2v_cast_3(p) * 11+:11];
		end
	always @(*) begin : sv2v_autoblock_13
		reg [31:0] p;
		for (p = 0; p < 5; p = p + 1)
			p2_diff2[sv2v_cast_3(p)] = sv2v_cast_22(p2_patch_diff[sv2v_cast_3(p)]) * sv2v_cast_22(p2_patch_diff[sv2v_cast_3(p)]);
	end
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin : sv2v_autoblock_14
			reg [31:0] p;
			for (p = 0; p < 5; p = p + 1)
				p2_diff2_unsigned[sv2v_cast_3(p)] <= 22'h000000;
		end
		else if (valid_shft[0]) begin : sv2v_autoblock_15
			reg [31:0] p;
			for (p = 0; p < 5; p = p + 1)
				p2_diff2_unsigned[sv2v_cast_3(p)] <= $unsigned(p2_diff2[sv2v_cast_3(p)]);
		end
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin
			p2_add_tree0[0] <= 23'h000000;
			p2_add_tree0[1] <= 23'h000000;
			p2_add_tree0[2] <= 23'h000000;
			p2_add_tree1[0] <= 24'h000000;
			p2_add_tree1[1] <= 24'h000000;
			p2_add_tree2 <= 25'h0000000;
		end
		else begin
			if (valid_shft[1]) begin
				p2_add_tree0[0] <= sv2v_cast_23(p2_diff2_unsigned[0]) + sv2v_cast_23(p2_diff2_unsigned[1]);
				p2_add_tree0[1] <= sv2v_cast_23(p2_diff2_unsigned[2]) + sv2v_cast_23(p2_diff2_unsigned[3]);
				p2_add_tree0[2] <= sv2v_cast_23(p2_diff2_unsigned[4]);
			end
			if (valid_shft[2]) begin
				p2_add_tree1[0] <= sv2v_cast_24(p2_add_tree0[0]) + sv2v_cast_24(p2_add_tree0[1]);
				p2_add_tree1[1] <= sv2v_cast_24(p2_add_tree0[2]);
			end
			if (valid_shft[3])
				p2_add_tree2 <= sv2v_cast_25(p2_add_tree1[0]) + sv2v_cast_25(p2_add_tree1[1]);
		end
	assign p2_l2_dist = p2_add_tree2;
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin
			p3_idx_r0 <= 9'h000;
			p3_idx_r1 <= 9'h000;
			p3_idx_r2 <= 9'h000;
			p3_idx_r3 <= 9'h000;
			p3_idx_out <= 9'h000;
		end
		else begin
			if (query_valid)
				p3_idx_r0 <= p3_idx_in;
			if (valid_shft[0])
				p3_idx_r1 <= p3_idx_r0;
			if (valid_shft[1])
				p3_idx_r2 <= p3_idx_r1;
			if (valid_shft[2])
				p3_idx_r3 <= p3_idx_r2;
			if (valid_shft[3])
				p3_idx_out <= p3_idx_r3;
		end
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin : sv2v_autoblock_16
			reg [31:0] p;
			for (p = 0; p < 5; p = p + 1)
				p3_patch_diff[sv2v_cast_3(p)] <= 11'h000;
		end
		else if (query_valid) begin : sv2v_autoblock_17
			reg [31:0] p;
			for (p = 0; p < 5; p = p + 1)
				p3_patch_diff[sv2v_cast_3(p)] <= query_patch[sv2v_cast_3(p) * 11+:11] - p3_data[sv2v_cast_3(p) * 11+:11];
		end
	always @(*) begin : sv2v_autoblock_18
		reg [31:0] p;
		for (p = 0; p < 5; p = p + 1)
			p3_diff2[sv2v_cast_3(p)] = sv2v_cast_22(p3_patch_diff[sv2v_cast_3(p)]) * sv2v_cast_22(p3_patch_diff[sv2v_cast_3(p)]);
	end
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin : sv2v_autoblock_19
			reg [31:0] p;
			for (p = 0; p < 5; p = p + 1)
				p3_diff2_unsigned[sv2v_cast_3(p)] <= 22'h000000;
		end
		else if (valid_shft[0]) begin : sv2v_autoblock_20
			reg [31:0] p;
			for (p = 0; p < 5; p = p + 1)
				p3_diff2_unsigned[sv2v_cast_3(p)] <= $unsigned(p3_diff2[sv2v_cast_3(p)]);
		end
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin
			p3_add_tree0[0] <= 23'h000000;
			p3_add_tree0[1] <= 23'h000000;
			p3_add_tree0[2] <= 23'h000000;
			p3_add_tree1[0] <= 24'h000000;
			p3_add_tree1[1] <= 24'h000000;
			p3_add_tree2 <= 25'h0000000;
		end
		else begin
			if (valid_shft[1]) begin
				p3_add_tree0[0] <= sv2v_cast_23(p3_diff2_unsigned[0]) + sv2v_cast_23(p3_diff2_unsigned[1]);
				p3_add_tree0[1] <= sv2v_cast_23(p3_diff2_unsigned[2]) + sv2v_cast_23(p3_diff2_unsigned[3]);
				p3_add_tree0[2] <= sv2v_cast_23(p3_diff2_unsigned[4]);
			end
			if (valid_shft[2]) begin
				p3_add_tree1[0] <= sv2v_cast_24(p3_add_tree0[0]) + sv2v_cast_24(p3_add_tree0[1]);
				p3_add_tree1[1] <= sv2v_cast_24(p3_add_tree0[2]);
			end
			if (valid_shft[3])
				p3_add_tree2 <= sv2v_cast_25(p3_add_tree1[0]) + sv2v_cast_25(p3_add_tree1[1]);
		end
	assign p3_l2_dist = p3_add_tree2;
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin
			p4_idx_r0 <= 9'h000;
			p4_idx_r1 <= 9'h000;
			p4_idx_r2 <= 9'h000;
			p4_idx_r3 <= 9'h000;
			p4_idx_out <= 9'h000;
		end
		else begin
			if (query_valid)
				p4_idx_r0 <= p4_idx_in;
			if (valid_shft[0])
				p4_idx_r1 <= p4_idx_r0;
			if (valid_shft[1])
				p4_idx_r2 <= p4_idx_r1;
			if (valid_shft[2])
				p4_idx_r3 <= p4_idx_r2;
			if (valid_shft[3])
				p4_idx_out <= p4_idx_r3;
		end
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin : sv2v_autoblock_21
			reg [31:0] p;
			for (p = 0; p < 5; p = p + 1)
				p4_patch_diff[sv2v_cast_3(p)] <= 11'h000;
		end
		else if (query_valid) begin : sv2v_autoblock_22
			reg [31:0] p;
			for (p = 0; p < 5; p = p + 1)
				p4_patch_diff[sv2v_cast_3(p)] <= query_patch[sv2v_cast_3(p) * 11+:11] - p4_data[sv2v_cast_3(p) * 11+:11];
		end
	always @(*) begin : sv2v_autoblock_23
		reg [31:0] p;
		for (p = 0; p < 5; p = p + 1)
			p4_diff2[sv2v_cast_3(p)] = sv2v_cast_22(p4_patch_diff[sv2v_cast_3(p)]) * sv2v_cast_22(p4_patch_diff[sv2v_cast_3(p)]);
	end
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin : sv2v_autoblock_24
			reg [31:0] p;
			for (p = 0; p < 5; p = p + 1)
				p4_diff2_unsigned[sv2v_cast_3(p)] <= 22'h000000;
		end
		else if (valid_shft[0]) begin : sv2v_autoblock_25
			reg [31:0] p;
			for (p = 0; p < 5; p = p + 1)
				p4_diff2_unsigned[sv2v_cast_3(p)] <= $unsigned(p4_diff2[sv2v_cast_3(p)]);
		end
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin
			p4_add_tree0[0] <= 23'h000000;
			p4_add_tree0[1] <= 23'h000000;
			p4_add_tree0[2] <= 23'h000000;
			p4_add_tree1[0] <= 24'h000000;
			p4_add_tree1[1] <= 24'h000000;
			p4_add_tree2 <= 25'h0000000;
		end
		else begin
			if (valid_shft[1]) begin
				p4_add_tree0[0] <= sv2v_cast_23(p4_diff2_unsigned[0]) + sv2v_cast_23(p4_diff2_unsigned[1]);
				p4_add_tree0[1] <= sv2v_cast_23(p4_diff2_unsigned[2]) + sv2v_cast_23(p4_diff2_unsigned[3]);
				p4_add_tree0[2] <= sv2v_cast_23(p4_diff2_unsigned[4]);
			end
			if (valid_shft[2]) begin
				p4_add_tree1[0] <= sv2v_cast_24(p4_add_tree0[0]) + sv2v_cast_24(p4_add_tree0[1]);
				p4_add_tree1[1] <= sv2v_cast_24(p4_add_tree0[2]);
			end
			if (valid_shft[3])
				p4_add_tree2 <= sv2v_cast_25(p4_add_tree1[0]) + sv2v_cast_25(p4_add_tree1[1]);
		end
	assign p4_l2_dist = p4_add_tree2;
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin
			p5_idx_r0 <= 9'h000;
			p5_idx_r1 <= 9'h000;
			p5_idx_r2 <= 9'h000;
			p5_idx_r3 <= 9'h000;
			p5_idx_out <= 9'h000;
		end
		else begin
			if (query_valid)
				p5_idx_r0 <= p5_idx_in;
			if (valid_shft[0])
				p5_idx_r1 <= p5_idx_r0;
			if (valid_shft[1])
				p5_idx_r2 <= p5_idx_r1;
			if (valid_shft[2])
				p5_idx_r3 <= p5_idx_r2;
			if (valid_shft[3])
				p5_idx_out <= p5_idx_r3;
		end
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin : sv2v_autoblock_26
			reg [31:0] p;
			for (p = 0; p < 5; p = p + 1)
				p5_patch_diff[sv2v_cast_3(p)] <= 11'h000;
		end
		else if (query_valid) begin : sv2v_autoblock_27
			reg [31:0] p;
			for (p = 0; p < 5; p = p + 1)
				p5_patch_diff[sv2v_cast_3(p)] <= query_patch[sv2v_cast_3(p) * 11+:11] - p5_data[sv2v_cast_3(p) * 11+:11];
		end
	always @(*) begin : sv2v_autoblock_28
		reg [31:0] p;
		for (p = 0; p < 5; p = p + 1)
			p5_diff2[sv2v_cast_3(p)] = sv2v_cast_22(p5_patch_diff[sv2v_cast_3(p)]) * sv2v_cast_22(p5_patch_diff[sv2v_cast_3(p)]);
	end
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin : sv2v_autoblock_29
			reg [31:0] p;
			for (p = 0; p < 5; p = p + 1)
				p5_diff2_unsigned[sv2v_cast_3(p)] <= 22'h000000;
		end
		else if (valid_shft[0]) begin : sv2v_autoblock_30
			reg [31:0] p;
			for (p = 0; p < 5; p = p + 1)
				p5_diff2_unsigned[sv2v_cast_3(p)] <= $unsigned(p5_diff2[sv2v_cast_3(p)]);
		end
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin
			p5_add_tree0[0] <= 23'h000000;
			p5_add_tree0[1] <= 23'h000000;
			p5_add_tree0[2] <= 23'h000000;
			p5_add_tree1[0] <= 24'h000000;
			p5_add_tree1[1] <= 24'h000000;
			p5_add_tree2 <= 25'h0000000;
		end
		else begin
			if (valid_shft[1]) begin
				p5_add_tree0[0] <= sv2v_cast_23(p5_diff2_unsigned[0]) + sv2v_cast_23(p5_diff2_unsigned[1]);
				p5_add_tree0[1] <= sv2v_cast_23(p5_diff2_unsigned[2]) + sv2v_cast_23(p5_diff2_unsigned[3]);
				p5_add_tree0[2] <= sv2v_cast_23(p5_diff2_unsigned[4]);
			end
			if (valid_shft[2]) begin
				p5_add_tree1[0] <= sv2v_cast_24(p5_add_tree0[0]) + sv2v_cast_24(p5_add_tree0[1]);
				p5_add_tree1[1] <= sv2v_cast_24(p5_add_tree0[2]);
			end
			if (valid_shft[3])
				p5_add_tree2 <= sv2v_cast_25(p5_add_tree1[0]) + sv2v_cast_25(p5_add_tree1[1]);
		end
	assign p5_l2_dist = p5_add_tree2;
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin
			p6_idx_r0 <= 9'h000;
			p6_idx_r1 <= 9'h000;
			p6_idx_r2 <= 9'h000;
			p6_idx_r3 <= 9'h000;
			p6_idx_out <= 9'h000;
		end
		else begin
			if (query_valid)
				p6_idx_r0 <= p6_idx_in;
			if (valid_shft[0])
				p6_idx_r1 <= p6_idx_r0;
			if (valid_shft[1])
				p6_idx_r2 <= p6_idx_r1;
			if (valid_shft[2])
				p6_idx_r3 <= p6_idx_r2;
			if (valid_shft[3])
				p6_idx_out <= p6_idx_r3;
		end
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin : sv2v_autoblock_31
			reg [31:0] p;
			for (p = 0; p < 5; p = p + 1)
				p6_patch_diff[sv2v_cast_3(p)] <= 11'h000;
		end
		else if (query_valid) begin : sv2v_autoblock_32
			reg [31:0] p;
			for (p = 0; p < 5; p = p + 1)
				p6_patch_diff[sv2v_cast_3(p)] <= query_patch[sv2v_cast_3(p) * 11+:11] - p6_data[sv2v_cast_3(p) * 11+:11];
		end
	always @(*) begin : sv2v_autoblock_33
		reg [31:0] p;
		for (p = 0; p < 5; p = p + 1)
			p6_diff2[sv2v_cast_3(p)] = sv2v_cast_22(p6_patch_diff[sv2v_cast_3(p)]) * sv2v_cast_22(p6_patch_diff[sv2v_cast_3(p)]);
	end
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin : sv2v_autoblock_34
			reg [31:0] p;
			for (p = 0; p < 5; p = p + 1)
				p6_diff2_unsigned[sv2v_cast_3(p)] <= 22'h000000;
		end
		else if (valid_shft[0]) begin : sv2v_autoblock_35
			reg [31:0] p;
			for (p = 0; p < 5; p = p + 1)
				p6_diff2_unsigned[sv2v_cast_3(p)] <= $unsigned(p6_diff2[sv2v_cast_3(p)]);
		end
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin
			p6_add_tree0[0] <= 23'h000000;
			p6_add_tree0[1] <= 23'h000000;
			p6_add_tree0[2] <= 23'h000000;
			p6_add_tree1[0] <= 24'h000000;
			p6_add_tree1[1] <= 24'h000000;
			p6_add_tree2 <= 25'h0000000;
		end
		else begin
			if (valid_shft[1]) begin
				p6_add_tree0[0] <= sv2v_cast_23(p6_diff2_unsigned[0]) + sv2v_cast_23(p6_diff2_unsigned[1]);
				p6_add_tree0[1] <= sv2v_cast_23(p6_diff2_unsigned[2]) + sv2v_cast_23(p6_diff2_unsigned[3]);
				p6_add_tree0[2] <= sv2v_cast_23(p6_diff2_unsigned[4]);
			end
			if (valid_shft[2]) begin
				p6_add_tree1[0] <= sv2v_cast_24(p6_add_tree0[0]) + sv2v_cast_24(p6_add_tree0[1]);
				p6_add_tree1[1] <= sv2v_cast_24(p6_add_tree0[2]);
			end
			if (valid_shft[3])
				p6_add_tree2 <= sv2v_cast_25(p6_add_tree1[0]) + sv2v_cast_25(p6_add_tree1[1]);
		end
	assign p6_l2_dist = p6_add_tree2;
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin
			p7_idx_r0 <= 9'h000;
			p7_idx_r1 <= 9'h000;
			p7_idx_r2 <= 9'h000;
			p7_idx_r3 <= 9'h000;
			p7_idx_out <= 9'h000;
		end
		else begin
			if (query_valid)
				p7_idx_r0 <= p7_idx_in;
			if (valid_shft[0])
				p7_idx_r1 <= p7_idx_r0;
			if (valid_shft[1])
				p7_idx_r2 <= p7_idx_r1;
			if (valid_shft[2])
				p7_idx_r3 <= p7_idx_r2;
			if (valid_shft[3])
				p7_idx_out <= p7_idx_r3;
		end
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin : sv2v_autoblock_36
			reg [31:0] p;
			for (p = 0; p < 5; p = p + 1)
				p7_patch_diff[sv2v_cast_3(p)] <= 11'h000;
		end
		else if (query_valid) begin : sv2v_autoblock_37
			reg [31:0] p;
			for (p = 0; p < 5; p = p + 1)
				p7_patch_diff[sv2v_cast_3(p)] <= query_patch[sv2v_cast_3(p) * 11+:11] - p7_data[sv2v_cast_3(p) * 11+:11];
		end
	always @(*) begin : sv2v_autoblock_38
		reg [31:0] p;
		for (p = 0; p < 5; p = p + 1)
			p7_diff2[sv2v_cast_3(p)] = sv2v_cast_22(p7_patch_diff[sv2v_cast_3(p)]) * sv2v_cast_22(p7_patch_diff[sv2v_cast_3(p)]);
	end
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin : sv2v_autoblock_39
			reg [31:0] p;
			for (p = 0; p < 5; p = p + 1)
				p7_diff2_unsigned[sv2v_cast_3(p)] <= 22'h000000;
		end
		else if (valid_shft[0]) begin : sv2v_autoblock_40
			reg [31:0] p;
			for (p = 0; p < 5; p = p + 1)
				p7_diff2_unsigned[sv2v_cast_3(p)] <= $unsigned(p7_diff2[sv2v_cast_3(p)]);
		end
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin
			p7_add_tree0[0] <= 23'h000000;
			p7_add_tree0[1] <= 23'h000000;
			p7_add_tree0[2] <= 23'h000000;
			p7_add_tree1[0] <= 24'h000000;
			p7_add_tree1[1] <= 24'h000000;
			p7_add_tree2 <= 25'h0000000;
		end
		else begin
			if (valid_shft[1]) begin
				p7_add_tree0[0] <= sv2v_cast_23(p7_diff2_unsigned[0]) + sv2v_cast_23(p7_diff2_unsigned[1]);
				p7_add_tree0[1] <= sv2v_cast_23(p7_diff2_unsigned[2]) + sv2v_cast_23(p7_diff2_unsigned[3]);
				p7_add_tree0[2] <= sv2v_cast_23(p7_diff2_unsigned[4]);
			end
			if (valid_shft[2]) begin
				p7_add_tree1[0] <= sv2v_cast_24(p7_add_tree0[0]) + sv2v_cast_24(p7_add_tree0[1]);
				p7_add_tree1[1] <= sv2v_cast_24(p7_add_tree0[2]);
			end
			if (valid_shft[3])
				p7_add_tree2 <= sv2v_cast_25(p7_add_tree1[0]) + sv2v_cast_25(p7_add_tree1[1]);
		end
	assign p7_l2_dist = p7_add_tree2;
endmodule
module LeavesMem (
	clk,
	csb0,
	web0,
	addr0,
	wleaf0,
	rleaf0,
	rpatch_data0,
	rpatch_idx0,
	csb1,
	addr1,
	rpatch_data1,
	rpatch_idx1
);
	parameter DATA_WIDTH = 11;
	parameter IDX_WIDTH = 9;
	parameter LEAF_SIZE = 8;
	parameter PATCH_SIZE = 5;
	parameter NUM_LEAVES = 64;
	parameter LEAF_ADDRW = $clog2(NUM_LEAVES);
	input wire clk;
	input wire [LEAF_SIZE - 1:0] csb0;
	input wire [LEAF_SIZE - 1:0] web0;
	input wire [LEAF_ADDRW - 1:0] addr0;
	input wire [((PATCH_SIZE * DATA_WIDTH) + IDX_WIDTH) - 1:0] wleaf0;
	output wire [(LEAF_SIZE * 64) - 1:0] rleaf0;
	output wire [((LEAF_SIZE * PATCH_SIZE) * DATA_WIDTH) - 1:0] rpatch_data0;
	output wire [(LEAF_SIZE * IDX_WIDTH) - 1:0] rpatch_idx0;
	input wire csb1;
	input wire [LEAF_ADDRW - 1:0] addr1;
	output wire [((LEAF_SIZE * PATCH_SIZE) * DATA_WIDTH) - 1:0] rpatch_data1;
	output wire [(LEAF_SIZE * IDX_WIDTH) - 1:0] rpatch_idx1;
	wire [7:0] ram_addr0;
	wire [7:0] ram_addr1;
	wire [63:0] rdata0 [LEAF_SIZE - 1:0];
	wire [63:0] rdata1 [LEAF_SIZE - 1:0];
	assign ram_addr0 = {1'sb0, addr0};
	assign ram_addr1 = {1'sb0, addr1};
	genvar i;
	generate
		for (i = 0; i < LEAF_SIZE; i = i + 1) begin : loop_ram_patch_gen
			sram_1kbyte_1rw1r #(
				.DATA_WIDTH(64),
				.ADDR_WIDTH(8),
				.RAM_DEPTH(256)
			) ram_patch_inst(
				.clk0(clk),
				.csb0(csb0[i]),
				.web0(web0[i]),
				.addr0(ram_addr0),
				.din0(wleaf0),
				.dout0(rdata0[i]),
				.clk1(clk),
				.csb1(csb1),
				.addr1(ram_addr1),
				.dout1(rdata1[i])
			);
			assign rpatch_data0[DATA_WIDTH * (i * PATCH_SIZE)+:DATA_WIDTH * PATCH_SIZE] = rdata0[i][(PATCH_SIZE * DATA_WIDTH) - 1:0];
			assign rpatch_idx0[i * IDX_WIDTH+:IDX_WIDTH] = rdata0[i][63:PATCH_SIZE * DATA_WIDTH];
			assign rpatch_data1[DATA_WIDTH * (i * PATCH_SIZE)+:DATA_WIDTH * PATCH_SIZE] = rdata1[i][(PATCH_SIZE * DATA_WIDTH) - 1:0];
			assign rpatch_idx1[i * IDX_WIDTH+:IDX_WIDTH] = rdata1[i][63:PATCH_SIZE * DATA_WIDTH];
			assign rleaf0[i * 64+:64] = rdata0[i];
		end
	endgenerate
endmodule
module MainFSM (
	clk,
	rst_n,
	load_kdtree,
	load_done,
	fsm_start,
	fsm_done,
	send_best_arr,
	send_done,
	agg_receiver_enq,
	agg_receiver_full_n,
	agg_change_fetch_width,
	agg_input_fetch_width,
	int_node_sender_enable,
	int_node_sender_addr,
	int_node_patch_en,
	int_node_leaf_index,
	int_node_patch_en2,
	int_node_leaf_index2,
	qp_mem_csb0,
	qp_mem_web0,
	qp_mem_addr0,
	qp_mem_rpatch0,
	qp_mem_csb1,
	qp_mem_addr1,
	qp_mem_rpatch1,
	leaf_mem_csb0,
	leaf_mem_web0,
	leaf_mem_addr0,
	leaf_mem_csb1,
	leaf_mem_addr1,
	best_arr_addr0,
	best_arr_csb1,
	best_arr_addr1,
	out_fifo_wdata_sel,
	out_fifo_wenq,
	out_fifo_wfull_n,
	k0_query_valid,
	k0_query_first_in,
	k0_query_last_in,
	k0_query_patch,
	sl0_valid_out,
	computes0_leaf_idx,
	k1_exactfstrow,
	k1_query_valid,
	k1_query_first_in,
	k1_query_last_in,
	k1_query_patch,
	sl1_valid_out,
	computes1_leaf_idx
);
	parameter DATA_WIDTH = 11;
	parameter LEAF_SIZE = 8;
	parameter PATCH_SIZE = 5;
	parameter ROW_SIZE = 26;
	parameter COL_SIZE = 19;
	parameter NUM_QUERYS = ROW_SIZE * COL_SIZE;
	parameter K = 4;
	parameter NUM_LEAVES = 64;
	parameter NUM_NODES = NUM_LEAVES - 1;
	parameter BLOCKING = 4;
	parameter NUM_OUTER_BLOCK = (((ROW_SIZE / 2) + BLOCKING) - 1) / BLOCKING;
	parameter LAST_BLOCK_REMAINDER = (ROW_SIZE / 2) % BLOCKING;
	parameter NUM_LAST_BLOCK = (LAST_BLOCK_REMAINDER == 0 ? BLOCKING : LAST_BLOCK_REMAINDER);
	parameter LEAF_ADDRW = $clog2(NUM_LEAVES);
	input clk;
	input rst_n;
	input wire load_kdtree;
	output reg load_done;
	input wire fsm_start;
	output reg fsm_done;
	input wire send_best_arr;
	output reg send_done;
	input wire agg_receiver_enq;
	output reg agg_receiver_full_n;
	output reg agg_change_fetch_width;
	output reg [2:0] agg_input_fetch_width;
	output reg int_node_sender_enable;
	output reg [5:0] int_node_sender_addr;
	output reg int_node_patch_en;
	input wire [LEAF_ADDRW - 1:0] int_node_leaf_index;
	output reg int_node_patch_en2;
	input wire [LEAF_ADDRW - 1:0] int_node_leaf_index2;
	output reg qp_mem_csb0;
	output reg qp_mem_web0;
	output reg [$clog2(NUM_QUERYS) - 1:0] qp_mem_addr0;
	input wire [(PATCH_SIZE * DATA_WIDTH) - 1:0] qp_mem_rpatch0;
	output reg qp_mem_csb1;
	output reg [$clog2(NUM_QUERYS) - 1:0] qp_mem_addr1;
	input wire [(PATCH_SIZE * DATA_WIDTH) - 1:0] qp_mem_rpatch1;
	output reg [LEAF_SIZE - 1:0] leaf_mem_csb0;
	output reg [LEAF_SIZE - 1:0] leaf_mem_web0;
	output reg [LEAF_ADDRW - 1:0] leaf_mem_addr0;
	output reg leaf_mem_csb1;
	output reg [LEAF_ADDRW - 1:0] leaf_mem_addr1;
	output wire [7:0] best_arr_addr0;
	output reg [0:0] best_arr_csb1;
	output reg [7:0] best_arr_addr1;
	output reg [2:0] out_fifo_wdata_sel;
	output reg out_fifo_wenq;
	input wire out_fifo_wfull_n;
	output reg k0_query_valid;
	output reg k0_query_first_in;
	output reg k0_query_last_in;
	output reg signed [(PATCH_SIZE * DATA_WIDTH) - 1:0] k0_query_patch;
	input wire sl0_valid_out;
	input wire [(K * LEAF_ADDRW) - 1:0] computes0_leaf_idx;
	output reg k1_exactfstrow;
	output reg k1_query_valid;
	output reg k1_query_first_in;
	output reg k1_query_last_in;
	output reg signed [(PATCH_SIZE * DATA_WIDTH) - 1:0] k1_query_patch;
	input wire sl1_valid_out;
	input wire [(K * LEAF_ADDRW) - 1:0] computes1_leaf_idx;
	(* fsm_encoding = "one_hot" *) reg [31:0] currState;
	reg [31:0] nextState;
	reg [LEAF_SIZE - 1:0] leaf_mem_wr_sel;
	reg counter_en;
	wire counter_done;
	reg [15:0] counter_in;
	reg [15:0] counter;
	reg [$clog2(NUM_QUERYS) - 1:0] qp_mem_rd_addr;
	reg [$clog2(NUM_QUERYS) - 1:0] qp_mem_rd_addr2;
	reg qp_mem_rd_addr_rst;
	reg qp_mem_rd_addr_set;
	reg qp_mem_rd_addr_incr_col;
	reg qp_mem_rd_addr_incr_row;
	reg qp_mem_rd_addr_incr_row_special;
	reg [8:0] best_arr_addr_r;
	reg best_arr_addr_rst;
	reg signed [(PATCH_SIZE * DATA_WIDTH) - 1:0] cur_query_patch0;
	reg signed [(PATCH_SIZE * DATA_WIDTH) - 1:0] cur_query_patch1;
	reg qp_mem_rvalid0;
	reg qp_mem_rvalid1;
	reg [LEAF_ADDRW - 1:0] prop_leaf_idx_r0 [BLOCKING - 1:0][K - 1:0];
	reg [LEAF_ADDRW - 1:0] prop_leaf_idx_r1 [BLOCKING - 1:0][K - 1:0];
	reg [1:0] prop_leaf_wr_idx;
	reg [1:0] row_blocking_cnt;
	reg row_blocking_cnt_incr;
	reg [$clog2(NUM_OUTER_BLOCK + 1) - 1:0] row_outer_cnt;
	reg row_outer_cnt_incr;
	reg [$clog2(COL_SIZE) - 1:0] col_query_cnt;
	reg col_query_cnt_incr;
	reg [2:0] out_fifo_wdata_sel_d;
	reg send_dist;
	always @(posedge clk or negedge rst_n)
		if (~rst_n)
			currState <= 32'd0;
		else
			currState <= nextState;
	always @(*) begin
		nextState = currState;
		load_done = 1'sb0;
		fsm_done = 1'sb0;
		send_done = 1'sb0;
		agg_change_fetch_width = 1'sb0;
		agg_input_fetch_width = 1'sb0;
		agg_receiver_full_n = 1'sb0;
		int_node_sender_enable = 1'sb0;
		int_node_sender_addr = 1'sb0;
		int_node_patch_en = 1'sb0;
		int_node_patch_en2 = 1'sb0;
		qp_mem_csb0 = 1'b1;
		qp_mem_web0 = 1'b1;
		qp_mem_addr0 = 1'sb0;
		qp_mem_csb1 = 1'b1;
		qp_mem_addr1 = 1'sb0;
		leaf_mem_csb0 = 1'sb1;
		leaf_mem_web0 = 1'sb1;
		leaf_mem_addr0 = 1'sb0;
		leaf_mem_csb1 = 1'b1;
		leaf_mem_addr1 = 1'sb0;
		k0_query_valid = 1'sb0;
		k0_query_first_in = 1'sb0;
		k0_query_last_in = 1'sb0;
		k0_query_patch = 1'sb0;
		k1_exactfstrow = 1'sb0;
		k1_query_valid = 1'sb0;
		k1_query_first_in = 1'sb0;
		k1_query_last_in = 1'sb0;
		k1_query_patch = 1'sb0;
		best_arr_csb1 = 1'b1;
		best_arr_addr1 = 1'sb0;
		out_fifo_wdata_sel_d = 1'sb0;
		counter_en = 1'sb0;
		counter_in = 1'sb0;
		qp_mem_rvalid0 = 1'sb0;
		qp_mem_rvalid1 = 1'sb0;
		qp_mem_rd_addr_rst = 1'sb0;
		qp_mem_rd_addr_set = 1'sb0;
		qp_mem_rd_addr_incr_col = 1'sb0;
		qp_mem_rd_addr_incr_row = 1'sb0;
		qp_mem_rd_addr_incr_row_special = 1'sb0;
		best_arr_addr_rst = 1'sb0;
		col_query_cnt_incr = 1'sb0;
		row_blocking_cnt_incr = 1'sb0;
		row_outer_cnt_incr = 1'sb0;
		send_dist = 1'sb0;
		case (currState)
			32'd0: begin
				qp_mem_rd_addr_set = 1'b1;
				if (load_kdtree) begin
					nextState = 32'd1;
					agg_change_fetch_width = 1'b1;
					agg_input_fetch_width = 3'd1;
				end
				if (fsm_start) begin
					nextState = 32'd4;
					counter_en = 1'b1;
					counter_in = NUM_LEAVES - 1;
					leaf_mem_csb0 = 1'sb0;
					leaf_mem_web0 = 1'sb1;
					leaf_mem_addr0 = counter;
					qp_mem_csb0 = 1'b0;
					qp_mem_web0 = 1'b1;
					qp_mem_addr0 = qp_mem_rd_addr;
					qp_mem_csb1 = 1'b0;
					qp_mem_addr1 = qp_mem_rd_addr2;
					row_outer_cnt_incr = 1'b1;
				end
				if (send_best_arr)
					nextState = 32'd17;
			end
			32'd1: begin
				counter_in = NUM_NODES - 1;
				agg_receiver_full_n = 1'b1;
				int_node_sender_addr = counter;
				if (agg_receiver_enq) begin
					int_node_sender_enable = 1'b1;
					counter_en = 1'b1;
					if (counter_done) begin
						nextState = 32'd2;
						agg_change_fetch_width = 1'b1;
						agg_input_fetch_width = 3'd5;
					end
				end
			end
			32'd2: begin
				counter_in = (NUM_LEAVES * LEAF_SIZE) - 1;
				agg_receiver_full_n = 1'b1;
				if (agg_receiver_enq) begin
					counter_en = 1'b1;
					leaf_mem_csb0 = leaf_mem_wr_sel;
					leaf_mem_web0 = leaf_mem_wr_sel;
					leaf_mem_addr0 = counter[LEAF_ADDRW + 2:3];
					if (counter_done) begin
						nextState = 32'd3;
						agg_change_fetch_width = 1'b1;
						agg_input_fetch_width = 3'd4;
					end
				end
			end
			32'd3: begin
				counter_in = NUM_QUERYS - 1;
				agg_receiver_full_n = 1'b1;
				if (agg_receiver_enq) begin
					counter_en = 1'b1;
					qp_mem_csb0 = 1'b0;
					qp_mem_web0 = 1'b0;
					qp_mem_addr0 = counter;
					if (counter_done) begin
						nextState = 32'd0;
						load_done = 1'b1;
					end
				end
			end
			32'd4: begin
				counter_en = 1'b1;
				counter_in = NUM_LEAVES - 1;
				leaf_mem_csb0 = 1'sb0;
				leaf_mem_web0 = 1'sb1;
				leaf_mem_addr0 = counter;
				k0_query_valid = 1'b1;
				k0_query_patch = cur_query_patch0;
				k1_exactfstrow = 1'b1;
				k1_query_valid = 1'b1;
				k1_query_patch = cur_query_patch1;
				if (counter_done)
					if ((prop_leaf_wr_idx == (BLOCKING - 1)) || ((row_outer_cnt == NUM_OUTER_BLOCK) && (prop_leaf_wr_idx == (NUM_LAST_BLOCK - 1))))
						nextState = 32'd5;
				if (counter == 1) begin
					k0_query_first_in = 1'b1;
					qp_mem_rvalid0 = 1'b1;
					k0_query_patch = qp_mem_rpatch0;
					k1_query_first_in = 1'b1;
					qp_mem_rvalid1 = 1'b1;
					k1_query_patch = qp_mem_rpatch1;
				end
				if (counter == 0) begin
					qp_mem_csb0 = 1'b0;
					qp_mem_web0 = 1'b1;
					qp_mem_addr0 = qp_mem_rd_addr;
					k0_query_last_in = 1'b1;
					qp_mem_csb1 = 1'b0;
					qp_mem_addr1 = qp_mem_rd_addr2;
					k1_query_last_in = 1'b1;
				end
				if (counter_done)
					if ((row_outer_cnt == NUM_OUTER_BLOCK) && (prop_leaf_wr_idx == (NUM_LAST_BLOCK - 1)))
						qp_mem_rd_addr_incr_row_special = 1'b1;
					else if (prop_leaf_wr_idx == (BLOCKING - 1))
						qp_mem_rd_addr_incr_row = 1'b1;
					else
						qp_mem_rd_addr_incr_col = 1'b1;
			end
			32'd5: begin
				if ((row_outer_cnt == NUM_OUTER_BLOCK) && (NUM_LAST_BLOCK <= 2))
					nextState = 32'd6;
				else begin
					nextState = 32'd7;
					col_query_cnt_incr = 1'b1;
					qp_mem_csb0 = 1'b0;
					qp_mem_web0 = 1'b1;
					qp_mem_addr0 = qp_mem_rd_addr;
					qp_mem_csb1 = 1'b0;
					qp_mem_addr1 = qp_mem_rd_addr2;
				end
				k0_query_valid = 1'b1;
				k0_query_last_in = 1'b1;
				k0_query_patch = cur_query_patch0;
				k1_query_valid = 1'b1;
				k1_query_last_in = 1'b1;
				k1_query_patch = cur_query_patch1;
			end
			32'd6:
				if (sl0_valid_out) begin
					nextState = 32'd7;
					col_query_cnt_incr = 1'b1;
					qp_mem_csb0 = 1'b0;
					qp_mem_web0 = 1'b1;
					qp_mem_addr0 = qp_mem_rd_addr;
					qp_mem_csb1 = 1'b0;
					qp_mem_addr1 = qp_mem_rd_addr2;
				end
			32'd7: begin
				counter_in = 2;
				counter_en = 1'b1;
				if (counter == 0) begin
					int_node_patch_en = 1'b1;
					int_node_patch_en2 = 1'b1;
				end
				if (counter_done)
					nextState = 32'd8;
			end
			32'd8: begin
				nextState = 32'd9;
				leaf_mem_csb0 = 1'sb0;
				leaf_mem_web0 = 1'sb1;
				leaf_mem_addr0 = prop_leaf_idx_r0[row_blocking_cnt][0];
				leaf_mem_csb1 = 1'sb0;
				leaf_mem_addr1 = prop_leaf_idx_r1[row_blocking_cnt][0];
				qp_mem_csb0 = 1'b0;
				qp_mem_web0 = 1'b1;
				qp_mem_addr0 = qp_mem_rd_addr;
				qp_mem_csb1 = 1'b0;
				qp_mem_addr1 = qp_mem_rd_addr2;
				qp_mem_rd_addr_incr_col = 1'b1;
			end
			32'd9: begin
				nextState = 32'd10;
				k0_query_first_in = 1'b1;
				k0_query_valid = 1'b1;
				k0_query_patch = qp_mem_rpatch0;
				k1_query_first_in = 1'b1;
				k1_query_valid = 1'b1;
				k1_query_patch = qp_mem_rpatch1;
				leaf_mem_csb0 = 1'sb0;
				leaf_mem_web0 = 1'sb1;
				leaf_mem_addr0 = prop_leaf_idx_r0[row_blocking_cnt][1];
				leaf_mem_csb1 = 1'sb0;
				leaf_mem_addr1 = prop_leaf_idx_r1[row_blocking_cnt][1];
				qp_mem_rvalid0 = 1'b1;
				qp_mem_rvalid1 = 1'b1;
				if (~(((row_outer_cnt == NUM_OUTER_BLOCK) && (row_blocking_cnt == (NUM_LAST_BLOCK - 1))) && (NUM_LAST_BLOCK != BLOCKING))) begin
					qp_mem_csb0 = 1'b0;
					qp_mem_web0 = 1'b1;
					qp_mem_addr0 = qp_mem_rd_addr;
					qp_mem_csb1 = 1'b0;
					qp_mem_addr1 = qp_mem_rd_addr2;
				end
			end
			32'd10: begin
				nextState = 32'd11;
				k0_query_valid = 1'b1;
				k0_query_patch = cur_query_patch0;
				k1_query_valid = 1'b1;
				k1_query_patch = cur_query_patch1;
				leaf_mem_csb0 = 1'sb0;
				leaf_mem_web0 = 1'sb1;
				leaf_mem_addr0 = prop_leaf_idx_r0[row_blocking_cnt][2];
				leaf_mem_csb1 = 1'sb0;
				leaf_mem_addr1 = prop_leaf_idx_r1[row_blocking_cnt][2];
				if (~(((row_outer_cnt == NUM_OUTER_BLOCK) && (row_blocking_cnt == (NUM_LAST_BLOCK - 1))) && (NUM_LAST_BLOCK != BLOCKING))) begin
					int_node_patch_en = 1'b1;
					int_node_patch_en2 = 1'b1;
				end
			end
			32'd11: begin
				nextState = 32'd12;
				k0_query_valid = 1'b1;
				k0_query_patch = cur_query_patch0;
				k1_query_valid = 1'b1;
				k1_query_patch = cur_query_patch1;
				leaf_mem_csb0 = 1'sb0;
				leaf_mem_web0 = 1'sb1;
				leaf_mem_addr0 = prop_leaf_idx_r0[row_blocking_cnt][3];
				leaf_mem_csb1 = 1'sb0;
				leaf_mem_addr1 = prop_leaf_idx_r1[row_blocking_cnt][3];
			end
			32'd12: begin
				if ((col_query_cnt == (COL_SIZE - 1)) && (row_blocking_cnt == (BLOCKING - 1)))
					nextState = 32'd14;
				else if (((row_outer_cnt == NUM_OUTER_BLOCK) && (row_blocking_cnt == (NUM_LAST_BLOCK - 1))) && (NUM_LAST_BLOCK != BLOCKING))
					nextState = 32'd16;
				else
					nextState = 32'd13;
				k0_query_valid = 1'b1;
				k0_query_patch = cur_query_patch0;
				k1_query_valid = 1'b1;
				k1_query_patch = cur_query_patch1;
				leaf_mem_csb0 = 1'sb0;
				leaf_mem_web0 = 1'sb1;
				leaf_mem_addr0 = int_node_leaf_index;
				leaf_mem_csb1 = 1'sb0;
				leaf_mem_addr1 = int_node_leaf_index2;
				row_blocking_cnt_incr = 1'b1;
				if (row_blocking_cnt == (BLOCKING - 1))
					col_query_cnt_incr = 1'b1;
			end
			32'd13: begin
				nextState = 32'd9;
				k0_query_last_in = 1'b1;
				k0_query_valid = 1'b1;
				k0_query_patch = cur_query_patch0;
				k1_query_last_in = 1'b1;
				k1_query_valid = 1'b1;
				k1_query_patch = cur_query_patch1;
				leaf_mem_csb0 = 1'sb0;
				leaf_mem_web0 = 1'sb1;
				leaf_mem_addr0 = prop_leaf_idx_r0[row_blocking_cnt][0];
				leaf_mem_csb1 = 1'sb0;
				leaf_mem_addr1 = prop_leaf_idx_r1[row_blocking_cnt][0];
				qp_mem_csb0 = 1'b0;
				qp_mem_web0 = 1'b1;
				qp_mem_addr0 = qp_mem_rd_addr;
				qp_mem_csb1 = 1'b0;
				qp_mem_addr1 = qp_mem_rd_addr2;
				if ((col_query_cnt == (COL_SIZE - 1)) && (row_blocking_cnt == (BLOCKING - 1)))
					qp_mem_rd_addr_set = 1'b1;
				if (row_blocking_cnt == (BLOCKING - 1))
					qp_mem_rd_addr_incr_row = 1'b1;
				else
					qp_mem_rd_addr_incr_col = 1'b1;
			end
			32'd14: begin
				row_outer_cnt_incr = 1'b1;
				if (row_outer_cnt == NUM_OUTER_BLOCK)
					nextState = 32'd15;
				else begin
					nextState = 32'd4;
					counter_en = 1'b1;
					counter_in = NUM_LEAVES - 1;
					leaf_mem_csb0 = 1'sb0;
					leaf_mem_web0 = 1'sb1;
					leaf_mem_addr0 = counter;
					qp_mem_csb0 = 1'b0;
					qp_mem_web0 = 1'b1;
					qp_mem_addr0 = qp_mem_rd_addr;
					qp_mem_csb1 = 1'b0;
					qp_mem_addr1 = qp_mem_rd_addr2;
				end
				k0_query_last_in = 1'b1;
				k0_query_valid = 1'b1;
				k0_query_patch = cur_query_patch0;
				k1_query_last_in = 1'b1;
				k1_query_valid = 1'b1;
				k1_query_patch = cur_query_patch1;
			end
			32'd15: begin
				counter_en = 1'b1;
				counter_in = 11;
				if (counter_done) begin
					nextState = 32'd0;
					fsm_done = 1'b1;
					qp_mem_rd_addr_rst = 1'b1;
					best_arr_addr_rst = 1'b1;
				end
			end
			32'd16: begin
				counter_en = 1'b1;
				counter_in = (BLOCKING - NUM_LAST_BLOCK) * 5;
				if (counter == 0) begin
					k0_query_last_in = 1'b1;
					k0_query_valid = 1'b1;
					k0_query_patch = cur_query_patch0;
					k1_query_last_in = 1'b1;
					k1_query_valid = 1'b1;
					k1_query_patch = cur_query_patch1;
				end
				if (counter < (BLOCKING - NUM_LAST_BLOCK))
					row_blocking_cnt_incr = 1'b1;
				if (counter < ((BLOCKING - NUM_LAST_BLOCK) - 1)) begin
					row_blocking_cnt_incr = 1'b1;
					qp_mem_rd_addr_incr_col = 1'b1;
				end
				if (counter == (BLOCKING - NUM_LAST_BLOCK))
					qp_mem_rd_addr_incr_row = 1'b1;
				if (counter == (((BLOCKING - NUM_LAST_BLOCK) * 5) - 4)) begin
					qp_mem_csb0 = 1'b0;
					qp_mem_web0 = 1'b1;
					qp_mem_addr0 = qp_mem_rd_addr;
					qp_mem_csb1 = 1'b0;
					qp_mem_addr1 = qp_mem_rd_addr2;
				end
				if (counter == (((BLOCKING - NUM_LAST_BLOCK) * 5) - 3)) begin
					int_node_patch_en = 1'b1;
					int_node_patch_en2 = 1'b1;
				end
				if (counter_done) begin
					col_query_cnt_incr = 1'b1;
					if (col_query_cnt == (COL_SIZE - 1)) begin
						nextState = 32'd15;
						row_outer_cnt_incr = 1'b1;
					end
					else begin
						nextState = 32'd9;
						leaf_mem_csb0 = 1'sb0;
						leaf_mem_web0 = 1'sb1;
						leaf_mem_addr0 = prop_leaf_idx_r0[0][0];
						leaf_mem_csb1 = 1'sb0;
						leaf_mem_addr1 = prop_leaf_idx_r1[0][0];
						qp_mem_csb0 = 1'b0;
						qp_mem_web0 = 1'b1;
						qp_mem_addr0 = qp_mem_rd_addr;
						qp_mem_csb1 = 1'b0;
						qp_mem_addr1 = qp_mem_rd_addr2;
						qp_mem_rd_addr_incr_col = 1'b1;
					end
				end
			end
			32'd17: begin
				counter_in = (NUM_QUERYS / 2) - 1;
				out_fifo_wdata_sel_d = 2'd0;
				if (~out_fifo_wenq & out_fifo_wfull_n) begin
					best_arr_csb1 = 1'b0;
					best_arr_addr1 = counter;
				end
				if (out_fifo_wenq) begin
					counter_en = 1'b1;
					if (counter_done)
						nextState = 32'd18;
				end
			end
			32'd18: begin
				counter_in = (NUM_QUERYS / 2) - 1;
				out_fifo_wdata_sel_d = 2'd1;
				if (~out_fifo_wenq & out_fifo_wfull_n) begin
					best_arr_csb1 = 1'b0;
					best_arr_addr1 = counter;
				end
				if (out_fifo_wenq) begin
					counter_en = 1'b1;
					if (counter_done)
						nextState = 32'd19;
				end
			end
			32'd19: begin
				counter_in = NUM_QUERYS - 1;
				out_fifo_wdata_sel_d = 3'd4;
				if ((~out_fifo_wenq & out_fifo_wfull_n) & ~counter[0]) begin
					out_fifo_wdata_sel_d = 2'd2;
					best_arr_csb1 = 1'b0;
					best_arr_addr1 = counter[8:1];
				end
				else if ((~out_fifo_wenq & out_fifo_wfull_n) & counter[0]) begin
					out_fifo_wdata_sel_d = 3'd4;
					send_dist = 1'b1;
				end
				if (out_fifo_wenq) begin
					counter_en = 1'b1;
					if (counter_done)
						nextState = 32'd20;
				end
			end
			32'd20: begin
				counter_in = NUM_QUERYS - 1;
				out_fifo_wdata_sel_d = 3'd4;
				if ((~out_fifo_wenq & out_fifo_wfull_n) & ~counter[0]) begin
					out_fifo_wdata_sel_d = 2'd3;
					best_arr_csb1 = 1'b0;
					best_arr_addr1 = counter[8:1];
				end
				else if ((~out_fifo_wenq & out_fifo_wfull_n) & counter[0]) begin
					out_fifo_wdata_sel_d = 3'd4;
					send_dist = 1'b1;
				end
				if (out_fifo_wenq) begin
					counter_en = 1'b1;
					if (counter_done) begin
						nextState = 32'd0;
						send_done = 1'b1;
					end
				end
			end
		endcase
	end
	always @(*) begin
		leaf_mem_wr_sel = 1'sb1;
		leaf_mem_wr_sel[counter[2:0]] = 1'b0;
	end
	always @(posedge clk or negedge rst_n)
		if (~rst_n)
			counter <= 1'sb0;
		else if (counter_en)
			if (counter == counter_in)
				counter <= 1'sb0;
			else
				counter <= counter + 1'b1;
	assign counter_done = counter == counter_in;
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin
			qp_mem_rd_addr <= 1'sb0;
			qp_mem_rd_addr2 <= 1'sb0;
		end
		else if (qp_mem_rd_addr_rst) begin
			qp_mem_rd_addr <= 1'sb0;
			qp_mem_rd_addr2 <= 1'sb0;
		end
		else if (qp_mem_rd_addr_set) begin
			qp_mem_rd_addr <= row_outer_cnt * BLOCKING;
			qp_mem_rd_addr2 <= (row_outer_cnt * BLOCKING) + (ROW_SIZE / 2);
		end
		else if (qp_mem_rd_addr_incr_col) begin
			qp_mem_rd_addr <= qp_mem_rd_addr + 1'b1;
			qp_mem_rd_addr2 <= qp_mem_rd_addr2 + 1'b1;
		end
		else if (qp_mem_rd_addr_incr_row) begin
			qp_mem_rd_addr <= (qp_mem_rd_addr + ROW_SIZE) - (BLOCKING - 1);
			qp_mem_rd_addr2 <= (qp_mem_rd_addr2 + ROW_SIZE) - (BLOCKING - 1);
		end
		else if (qp_mem_rd_addr_incr_row_special) begin
			qp_mem_rd_addr <= (qp_mem_rd_addr + ROW_SIZE) - (NUM_LAST_BLOCK - 1);
			qp_mem_rd_addr2 <= (qp_mem_rd_addr2 + ROW_SIZE) - (NUM_LAST_BLOCK - 1);
		end
	always @(posedge clk or negedge rst_n)
		if (~rst_n)
			best_arr_addr_r <= 1'sb0;
		else if (best_arr_addr_rst)
			best_arr_addr_r <= 1'sb0;
		else if (sl0_valid_out)
			best_arr_addr_r <= best_arr_addr_r + 1'b1;
	assign best_arr_addr0 = best_arr_addr_r;
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin
			prop_leaf_wr_idx <= 1'sb0;
			begin : sv2v_autoblock_1
				reg signed [31:0] i;
				for (i = 0; i < BLOCKING; i = i + 1)
					begin
						prop_leaf_idx_r0[i][0] <= 1'sb0;
						prop_leaf_idx_r0[i][1] <= 1'sb0;
						prop_leaf_idx_r0[i][2] <= 1'sb0;
						prop_leaf_idx_r0[i][3] <= 1'sb0;
						prop_leaf_idx_r1[i][0] <= 1'sb0;
						prop_leaf_idx_r1[i][1] <= 1'sb0;
						prop_leaf_idx_r1[i][2] <= 1'sb0;
						prop_leaf_idx_r1[i][3] <= 1'sb0;
					end
			end
		end
		else if (sl0_valid_out) begin
			if (((row_outer_cnt == NUM_OUTER_BLOCK) && (prop_leaf_wr_idx == (NUM_LAST_BLOCK - 1))) || (prop_leaf_wr_idx == (BLOCKING - 1)))
				prop_leaf_wr_idx <= 1'sb0;
			else
				prop_leaf_wr_idx <= prop_leaf_wr_idx + 1'b1;
			prop_leaf_idx_r0[prop_leaf_wr_idx][0] <= computes0_leaf_idx[0+:LEAF_ADDRW];
			prop_leaf_idx_r0[prop_leaf_wr_idx][1] <= computes0_leaf_idx[LEAF_ADDRW+:LEAF_ADDRW];
			prop_leaf_idx_r0[prop_leaf_wr_idx][2] <= computes0_leaf_idx[2 * LEAF_ADDRW+:LEAF_ADDRW];
			prop_leaf_idx_r0[prop_leaf_wr_idx][3] <= computes0_leaf_idx[3 * LEAF_ADDRW+:LEAF_ADDRW];
			prop_leaf_idx_r1[prop_leaf_wr_idx][0] <= computes1_leaf_idx[0+:LEAF_ADDRW];
			prop_leaf_idx_r1[prop_leaf_wr_idx][1] <= computes1_leaf_idx[LEAF_ADDRW+:LEAF_ADDRW];
			prop_leaf_idx_r1[prop_leaf_wr_idx][2] <= computes1_leaf_idx[2 * LEAF_ADDRW+:LEAF_ADDRW];
			prop_leaf_idx_r1[prop_leaf_wr_idx][3] <= computes1_leaf_idx[3 * LEAF_ADDRW+:LEAF_ADDRW];
		end
	always @(posedge clk or negedge rst_n)
		if (~rst_n)
			col_query_cnt <= 1'sb0;
		else if (col_query_cnt_incr)
			if (col_query_cnt == (COL_SIZE - 1))
				col_query_cnt <= 1'sb0;
			else
				col_query_cnt <= col_query_cnt + 1'b1;
	always @(posedge clk or negedge rst_n)
		if (~rst_n)
			row_blocking_cnt <= 1'sb0;
		else if (row_blocking_cnt_incr)
			if (row_blocking_cnt == (BLOCKING - 1))
				row_blocking_cnt <= 1'sb0;
			else
				row_blocking_cnt <= row_blocking_cnt + 1'b1;
	always @(posedge clk or negedge rst_n)
		if (~rst_n)
			row_outer_cnt <= 1'sb0;
		else if (row_outer_cnt_incr)
			if (row_outer_cnt == NUM_OUTER_BLOCK)
				row_outer_cnt <= 1'sb0;
			else
				row_outer_cnt <= row_outer_cnt + 1'b1;
	always @(posedge clk or negedge rst_n)
		if (~rst_n)
			cur_query_patch0 <= 1'sb0;
		else if (qp_mem_rvalid0)
			cur_query_patch0 <= qp_mem_rpatch0;
	always @(posedge clk or negedge rst_n)
		if (~rst_n)
			cur_query_patch1 <= 1'sb0;
		else if (qp_mem_rvalid1)
			cur_query_patch1 <= qp_mem_rpatch1;
	always @(posedge clk or negedge rst_n)
		if (~rst_n)
			out_fifo_wenq <= 1'sb0;
		else
			out_fifo_wenq <= ~best_arr_csb1 | send_dist;
	always @(posedge clk or negedge rst_n)
		if (~rst_n)
			out_fifo_wdata_sel <= 1'sb0;
		else
			out_fifo_wdata_sel <= out_fifo_wdata_sel_d;
endmodule
module QueryPatchMem2 (
	clk,
	csb0,
	web0,
	addr0,
	wpatch0,
	rpatch0,
	csb1,
	addr1,
	rpatch1
);
	parameter DATA_WIDTH = 11;
	parameter PATCH_SIZE = 5;
	parameter ADDR_WIDTH = 9;
	parameter DEPTH = 512;
	input wire clk;
	input wire csb0;
	input wire web0;
	input wire [ADDR_WIDTH - 1:0] addr0;
	input wire [(DATA_WIDTH * PATCH_SIZE) - 1:0] wpatch0;
	output wire [(DATA_WIDTH * PATCH_SIZE) - 1:0] rpatch0;
	input wire csb1;
	input wire [ADDR_WIDTH - 1:0] addr1;
	output wire [(DATA_WIDTH * PATCH_SIZE) - 1:0] rpatch1;
	wire [63:0] wdata0;
	wire [63:0] rdata0;
	wire [63:0] rdata1;
	assign wdata0 = {1'sb0, wpatch0};
	assign rpatch0 = rdata0[(PATCH_SIZE * DATA_WIDTH) - 1:0];
	assign rpatch1 = rdata1[(PATCH_SIZE * DATA_WIDTH) - 1:0];
	sram_1kbyte_1rw1r #(
		.DATA_WIDTH(64),
		.ADDR_WIDTH(ADDR_WIDTH),
		.RAM_DEPTH(DEPTH)
	) ram_patch_inst(
		.clk0(clk),
		.csb0(csb0),
		.web0(web0),
		.addr0(addr0),
		.din0(wdata0),
		.dout0(rdata0),
		.clk1(clk),
		.csb1(csb1),
		.addr1(addr1),
		.dout1(rdata1)
	);
endmodule
module QueryPatchMem (
	clk,
	csb0,
	web0,
	addr0,
	wpatch0,
	rpatch0,
	csb1,
	addr1,
	rpatch1
);
	parameter DATA_WIDTH = 11;
	parameter PATCH_SIZE = 5;
	parameter ADDR_WIDTH = 9;
	parameter DEPTH = 512;
	input wire clk;
	input wire csb0;
	input wire web0;
	input wire [ADDR_WIDTH - 1:0] addr0;
	input wire [(DATA_WIDTH * PATCH_SIZE) - 1:0] wpatch0;
	output reg [(DATA_WIDTH * PATCH_SIZE) - 1:0] rpatch0;
	input wire csb1;
	input wire [ADDR_WIDTH - 1:0] addr1;
	output reg [(DATA_WIDTH * PATCH_SIZE) - 1:0] rpatch1;
	reg macro_select_0;
	reg macro_select_1;
	wire [63:0] rpatch0_0;
	wire [63:0] rpatch0_1;
	wire [63:0] rpatch1_0;
	wire [63:0] rpatch1_1;
	wire [10:0] debug;
	wire [10:0] debug_write;
	always @(*)
		case (addr0[8])
			1'b0: begin
				macro_select_0 = 0;
				macro_select_1 = 1;
			end
			1'b1: begin
				macro_select_0 = 1;
				macro_select_1 = 0;
			end
			default: begin
				macro_select_0 = 0;
				macro_select_1 = 1;
			end
		endcase
	assign debug_write = wpatch0[10:0];
	assign debug = rpatch0_1[10:0];
	always @(posedge clk)
		if (!macro_select_0) begin
			rpatch0 <= rpatch0_0[54:0];
			rpatch1 <= rpatch1_0[54:0];
		end
		else begin
			rpatch0 <= rpatch0_1[54:0];
			rpatch1 <= rpatch1_1[54:0];
		end
	sky130_sram_1kbyte_1rw1r_32x256_8 #(
		.DATA_WIDTH(32),
		.ADDR_WIDTH(8),
		.RAM_DEPTH(256)
	) ram_patch_inst_0_0(
		.clk0(clk),
		.csb0(csb0 || macro_select_0),
		.web0(web0 || macro_select_0),
		.wmask0(4'hf),
		.addr0(addr0[7:0]),
		.din0(wpatch0[31:0]),
		.dout0(rpatch0_0[31:0]),
		.clk1(clk),
		.csb1(csb1 || macro_select_0),
		.addr1(addr1[7:0]),
		.dout1(rpatch1_0[31:0])
	);
	sky130_sram_1kbyte_1rw1r_32x256_8 #(
		.DATA_WIDTH(32),
		.ADDR_WIDTH(8),
		.RAM_DEPTH(256)
	) ram_patch_inst_0_1(
		.clk0(clk),
		.csb0(csb0 || macro_select_0),
		.web0(web0 || macro_select_0),
		.wmask0(4'hf),
		.addr0(addr0[7:0]),
		.din0({9'b000000000, wpatch0[54:32]}),
		.dout0(rpatch0_0[63:32]),
		.clk1(clk),
		.csb1(csb1 || macro_select_0),
		.addr1(addr1[7:0]),
		.dout1(rpatch1_0[63:32])
	);
	sky130_sram_1kbyte_1rw1r_32x256_8 #(
		.DATA_WIDTH(32),
		.ADDR_WIDTH(8),
		.RAM_DEPTH(256)
	) ram_patch_inst_1_0(
		.clk0(clk),
		.csb0(csb0 || macro_select_1),
		.web0(web0 || macro_select_1),
		.wmask0(4'hf),
		.addr0(addr0[7:0]),
		.din0(wpatch0[31:0]),
		.dout0(rpatch0_1[31:0]),
		.clk1(clk),
		.csb1(csb1 || macro_select_1),
		.addr1(addr1[7:0]),
		.dout1(rpatch1_1[31:0])
	);
	sky130_sram_1kbyte_1rw1r_32x256_8 #(
		.DATA_WIDTH(32),
		.ADDR_WIDTH(8),
		.RAM_DEPTH(256)
	) ram_patch_inst_1_1(
		.clk0(clk),
		.csb0(csb0 || macro_select_1),
		.web0(web0 || macro_select_1),
		.wmask0(4'hf),
		.addr0(addr0[7:0]),
		.din0({9'b000000000, wpatch0[54:32]}),
		.dout0(rpatch0_1[63:32]),
		.clk1(clk),
		.csb1(csb1 || macro_select_1),
		.addr1(addr1[7:0]),
		.dout1(rpatch1_1[63:32])
	);
endmodule
module ResetMux (
	select,
	rst0,
	rst1,
	out_rst
);
	input select;
	input rst0;
	input rst1;
	output wire out_rst;
	assign out_rst = (select ? rst1 : rst0);
endmodule
module RunningMin (
	clk,
	leaf_idx_in,
	p0_idx,
	p0_l2_dist,
	p1_idx,
	p1_l2_dist,
	p2_idx,
	p2_l2_dist,
	p3_idx,
	p3_l2_dist,
	p4_idx,
	p4_l2_dist,
	p5_idx,
	p5_l2_dist,
	p6_idx,
	p6_l2_dist,
	p7_idx,
	p7_l2_dist,
	query_last_in,
	restart,
	rst_n,
	valid_in,
	p0_idx_min,
	p0_l2_dist_min,
	p1_idx_min,
	p1_l2_dist_min,
	p2_idx_min,
	p2_l2_dist_min,
	p3_idx_min,
	p3_l2_dist_min,
	p4_idx_min,
	p4_l2_dist_min,
	p5_idx_min,
	p5_l2_dist_min,
	p6_idx_min,
	p6_l2_dist_min,
	p7_idx_min,
	p7_l2_dist_min,
	query_last_out,
	valid_out
);
	input wire clk;
	input wire [5:0] leaf_idx_in;
	input wire [8:0] p0_idx;
	input wire [10:0] p0_l2_dist;
	input wire [8:0] p1_idx;
	input wire [10:0] p1_l2_dist;
	input wire [8:0] p2_idx;
	input wire [10:0] p2_l2_dist;
	input wire [8:0] p3_idx;
	input wire [10:0] p3_l2_dist;
	input wire [8:0] p4_idx;
	input wire [10:0] p4_l2_dist;
	input wire [8:0] p5_idx;
	input wire [10:0] p5_l2_dist;
	input wire [8:0] p6_idx;
	input wire [10:0] p6_l2_dist;
	input wire [8:0] p7_idx;
	input wire [10:0] p7_l2_dist;
	input wire query_last_in;
	input wire restart;
	input wire rst_n;
	input wire valid_in;
	output reg [14:0] p0_idx_min;
	output reg [10:0] p0_l2_dist_min;
	output reg [14:0] p1_idx_min;
	output reg [10:0] p1_l2_dist_min;
	output reg [14:0] p2_idx_min;
	output reg [10:0] p2_l2_dist_min;
	output reg [14:0] p3_idx_min;
	output reg [10:0] p3_l2_dist_min;
	output reg [14:0] p4_idx_min;
	output reg [10:0] p4_l2_dist_min;
	output reg [14:0] p5_idx_min;
	output reg [10:0] p5_l2_dist_min;
	output reg [14:0] p6_idx_min;
	output reg [10:0] p6_l2_dist_min;
	output reg [14:0] p7_idx_min;
	output reg [10:0] p7_l2_dist_min;
	output wire query_last_out;
	output reg valid_out;
	reg query_last_r;
	always @(posedge clk or negedge rst_n)
		if (~rst_n)
			valid_out <= 1'h0;
		else
			valid_out <= valid_in;
	always @(posedge clk or negedge rst_n)
		if (~rst_n)
			query_last_r <= 1'h0;
		else
			query_last_r <= query_last_in;
	assign query_last_out = query_last_r;
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin
			p0_l2_dist_min <= 11'h000;
			p0_idx_min <= 15'h0000;
		end
		else if (valid_in)
			if ((p0_l2_dist < p0_l2_dist_min) | restart) begin
				p0_l2_dist_min <= p0_l2_dist;
				p0_idx_min <= {leaf_idx_in, p0_idx};
			end
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin
			p1_l2_dist_min <= 11'h000;
			p1_idx_min <= 15'h0000;
		end
		else if (valid_in)
			if ((p1_l2_dist < p1_l2_dist_min) | restart) begin
				p1_l2_dist_min <= p1_l2_dist;
				p1_idx_min <= {leaf_idx_in, p1_idx};
			end
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin
			p2_l2_dist_min <= 11'h000;
			p2_idx_min <= 15'h0000;
		end
		else if (valid_in)
			if ((p2_l2_dist < p2_l2_dist_min) | restart) begin
				p2_l2_dist_min <= p2_l2_dist;
				p2_idx_min <= {leaf_idx_in, p2_idx};
			end
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin
			p3_l2_dist_min <= 11'h000;
			p3_idx_min <= 15'h0000;
		end
		else if (valid_in)
			if ((p3_l2_dist < p3_l2_dist_min) | restart) begin
				p3_l2_dist_min <= p3_l2_dist;
				p3_idx_min <= {leaf_idx_in, p3_idx};
			end
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin
			p4_l2_dist_min <= 11'h000;
			p4_idx_min <= 15'h0000;
		end
		else if (valid_in)
			if ((p4_l2_dist < p4_l2_dist_min) | restart) begin
				p4_l2_dist_min <= p4_l2_dist;
				p4_idx_min <= {leaf_idx_in, p4_idx};
			end
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin
			p5_l2_dist_min <= 11'h000;
			p5_idx_min <= 15'h0000;
		end
		else if (valid_in)
			if ((p5_l2_dist < p5_l2_dist_min) | restart) begin
				p5_l2_dist_min <= p5_l2_dist;
				p5_idx_min <= {leaf_idx_in, p5_idx};
			end
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin
			p6_l2_dist_min <= 11'h000;
			p6_idx_min <= 15'h0000;
		end
		else if (valid_in)
			if ((p6_l2_dist < p6_l2_dist_min) | restart) begin
				p6_l2_dist_min <= p6_l2_dist;
				p6_idx_min <= {leaf_idx_in, p6_idx};
			end
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin
			p7_l2_dist_min <= 11'h000;
			p7_idx_min <= 15'h0000;
		end
		else if (valid_in)
			if ((p7_l2_dist < p7_l2_dist_min) | restart) begin
				p7_l2_dist_min <= p7_l2_dist;
				p7_idx_min <= {leaf_idx_in, p7_idx};
			end
endmodule
module sky130_sram_1kbyte_1rw1r_32x256_8 (
	clk0,
	csb0,
	web0,
	wmask0,
	addr0,
	din0,
	dout0,
	clk1,
	csb1,
	addr1,
	dout1
);
	parameter NUM_WMASKS = 4;
	parameter DATA_WIDTH = 32;
	parameter ADDR_WIDTH = 8;
	parameter RAM_DEPTH = 1 << ADDR_WIDTH;
	parameter DELAY = 3;
	parameter VERBOSE = 0;
	parameter T_HOLD = 1;
	input clk0;
	input csb0;
	input web0;
	input [NUM_WMASKS - 1:0] wmask0;
	input [ADDR_WIDTH - 1:0] addr0;
	input [DATA_WIDTH - 1:0] din0;
	output reg [DATA_WIDTH - 1:0] dout0;
	input clk1;
	input csb1;
	input [ADDR_WIDTH - 1:0] addr1;
	output reg [DATA_WIDTH - 1:0] dout1;
	reg csb0_reg;
	reg web0_reg;
	reg [NUM_WMASKS - 1:0] wmask0_reg;
	reg [ADDR_WIDTH - 1:0] addr0_reg;
	reg [DATA_WIDTH - 1:0] din0_reg;
	reg [DATA_WIDTH - 1:0] mem [0:RAM_DEPTH - 1];
	always @(posedge clk0) begin
		csb0_reg = csb0;
		web0_reg = web0;
		wmask0_reg = wmask0;
		addr0_reg = addr0;
		din0_reg = din0;
		#(T_HOLD) dout0 = 32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
		if ((!csb0_reg && web0_reg) && VERBOSE)
			$display($time, " Reading %m addr0=%b dout0=%b", addr0_reg, mem[addr0_reg]);
		if ((!csb0_reg && !web0_reg) && VERBOSE)
			$display($time, " Writing %m addr0=%b din0=%b wmask0=%b", addr0_reg, din0_reg, wmask0_reg);
	end
	reg csb1_reg;
	reg [ADDR_WIDTH - 1:0] addr1_reg;
	always @(posedge clk1) begin
		csb1_reg = csb1;
		addr1_reg = addr1;
		if (((!csb0 && !web0) && !csb1) && (addr0 == addr1))
			$display($time, " WARNING: Writing and reading addr0=%b and addr1=%b simultaneously!", addr0, addr1);
		#(T_HOLD) dout1 = 32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
		if (!csb1_reg && VERBOSE)
			$display($time, " Reading %m addr1=%b dout1=%b", addr1_reg, mem[addr1_reg]);
	end
	always @(negedge clk0) begin : MEM_WRITE0
		if (!csb0_reg && !web0_reg) begin
			if (wmask0_reg[0])
				mem[addr0_reg][7:0] = din0_reg[7:0];
			if (wmask0_reg[1])
				mem[addr0_reg][15:8] = din0_reg[15:8];
			if (wmask0_reg[2])
				mem[addr0_reg][23:16] = din0_reg[23:16];
			if (wmask0_reg[3])
				mem[addr0_reg][31:24] = din0_reg[31:24];
		end
	end
	always @(negedge clk0) begin : MEM_READ0
		if (!csb0_reg && web0_reg)
			dout0 <= #(DELAY) mem[addr0_reg];
	end
	always @(negedge clk1) begin : MEM_READ1
		if (!csb1_reg)
			dout1 <= #(DELAY) mem[addr1_reg];
	end
endmodule
module SortedList (
	clk,
	insert,
	l2_dist_in,
	last_in,
	merged_idx_in,
	restart,
	rst_n,
	l2_dist_0,
	l2_dist_1,
	l2_dist_2,
	l2_dist_3,
	merged_idx_0,
	merged_idx_1,
	merged_idx_2,
	merged_idx_3,
	valid_out
);
	input wire clk;
	input wire insert;
	input wire [24:0] l2_dist_in;
	input wire last_in;
	input wire [14:0] merged_idx_in;
	input wire restart;
	input wire rst_n;
	output reg [24:0] l2_dist_0;
	output reg [24:0] l2_dist_1;
	output reg [24:0] l2_dist_2;
	output reg [24:0] l2_dist_3;
	output reg [14:0] merged_idx_0;
	output reg [14:0] merged_idx_1;
	output reg [14:0] merged_idx_2;
	output reg [14:0] merged_idx_3;
	output reg valid_out;
	reg [3:0] empty_n;
	wire [3:0] same_leafidx;
	wire [3:0] smaller;
	always @(posedge clk or negedge rst_n)
		if (~rst_n)
			valid_out <= 1'h0;
		else
			valid_out <= last_in;
	assign smaller[0] = l2_dist_in <= l2_dist_0;
	assign same_leafidx[0] = merged_idx_0[14:9] == merged_idx_in[14:9];
	assign smaller[1] = l2_dist_in <= l2_dist_1;
	assign same_leafidx[1] = merged_idx_1[14:9] == merged_idx_in[14:9];
	assign smaller[2] = l2_dist_in <= l2_dist_2;
	assign same_leafidx[2] = merged_idx_2[14:9] == merged_idx_in[14:9];
	assign smaller[3] = l2_dist_in <= l2_dist_3;
	assign same_leafidx[3] = merged_idx_3[14:9] == merged_idx_in[14:9];
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin
			empty_n <= 4'h0;
			l2_dist_0 <= 25'h0000000;
			merged_idx_0 <= 15'h0000;
			l2_dist_1 <= 25'h0000000;
			merged_idx_1 <= 15'h0000;
			l2_dist_2 <= 25'h0000000;
			merged_idx_2 <= 15'h0000;
			l2_dist_3 <= 25'h0000000;
			merged_idx_3 <= 15'h0000;
		end
		else if (restart) begin
			empty_n <= 4'h0;
			if (insert) begin
				l2_dist_0 <= l2_dist_in;
				merged_idx_0 <= merged_idx_in;
				empty_n[0] <= 1'h1;
			end
		end
		else if (insert)
			if (|(same_leafidx & (same_leafidx ^ ~empty_n))) begin
				if (same_leafidx[0] & smaller[0])
					l2_dist_0 <= l2_dist_in;
				else if (same_leafidx[1] & smaller[1]) begin
					if (smaller[0]) begin
						l2_dist_0 <= l2_dist_in;
						merged_idx_0 <= merged_idx_in;
						l2_dist_1 <= l2_dist_0;
						merged_idx_1 <= merged_idx_0;
					end
					else
						l2_dist_1 <= l2_dist_in;
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
					else
						l2_dist_2 <= l2_dist_in;
				end
				else if (same_leafidx[3] & smaller[3])
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
					else
						l2_dist_3 <= l2_dist_in;
			end
			else begin
				if (~empty_n[3] | (smaller[3] & ~same_leafidx[3])) begin
					l2_dist_3 <= l2_dist_in;
					merged_idx_3 <= merged_idx_in;
					empty_n[3] <= 1'h1;
				end
				if (~empty_n[2] | (smaller[2] & ~same_leafidx[2])) begin
					l2_dist_2 <= l2_dist_in;
					merged_idx_2 <= merged_idx_in;
					empty_n[2] <= 1'h1;
					l2_dist_3 <= l2_dist_2;
					merged_idx_3 <= merged_idx_2;
					empty_n[3] <= empty_n[2];
				end
				if (~empty_n[1] | (smaller[1] & ~same_leafidx[1])) begin
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
				if (~empty_n[0] | (smaller[0] & ~same_leafidx[0])) begin
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
endmodule
module sram_1kbyte_1rw1r (
	clk0,
	csb0,
	web0,
	addr0,
	din0,
	dout0,
	clk1,
	csb1,
	addr1,
	dout1
);
	parameter NUM_WMASKS = 4;
	parameter DATA_WIDTH = 32;
	parameter ADDR_WIDTH = 8;
	parameter RAM_DEPTH = 256;
	parameter DELAY = 1;
	input clk0;
	input csb0;
	input web0;
	input [ADDR_WIDTH - 1:0] addr0;
	input [DATA_WIDTH - 1:0] din0;
	output wire [DATA_WIDTH - 1:0] dout0;
	input clk1;
	input csb1;
	input [ADDR_WIDTH - 1:0] addr1;
	output wire [DATA_WIDTH - 1:0] dout1;
	reg [ADDR_WIDTH - 1:0] addr0_r;
	reg [ADDR_WIDTH - 1:0] addr1_r;
	always @(posedge clk1) begin
		addr0_r <= addr0;
		addr1_r <= addr1;
	end
	wire [DATA_WIDTH - 1:0] dout0_w [(RAM_DEPTH / 256) - 1:0];
	wire [DATA_WIDTH - 1:0] dout1_w [(RAM_DEPTH / 256) - 1:0];
	genvar i;
	genvar j;
	generate
		for (i = 0; i < (RAM_DEPTH / 256); i = i + 1) begin : loop_depth_gen
			for (j = 0; j < (DATA_WIDTH / 32); j = j + 1) begin : loop_width_gen
				if (ADDR_WIDTH == 8) begin : genblk1
					sky130_sram_1kbyte_1rw1r_32x256_8 #(.DELAY(DELAY)) sram_macro(
						.clk0(clk0),
						.csb0(csb0),
						.web0(web0),
						.wmask0(4'hf),
						.addr0(addr0[7:0]),
						.din0(din0[j * 32+:32]),
						.dout0(dout0_w[i][j * 32+:32]),
						.clk1(clk1),
						.csb1(csb1),
						.addr1(addr1[7:0]),
						.dout1(dout1_w[i][j * 32+:32])
					);
				end
				else begin : genblk1
					sky130_sram_1kbyte_1rw1r_32x256_8 #(.DELAY(DELAY)) sram_macro(
						.clk0(clk0),
						.csb0((addr0[ADDR_WIDTH - 1:8] == i ? csb0 : 1'b1)),
						.web0(web0),
						.wmask0(4'hf),
						.addr0(addr0[7:0]),
						.din0(din0[j * 32+:32]),
						.dout0(dout0_w[i][j * 32+:32]),
						.clk1(clk1),
						.csb1((addr1[ADDR_WIDTH - 1:8] == i ? csb1 : 1'b1)),
						.addr1(addr1[7:0]),
						.dout1(dout1_w[i][j * 32+:32])
					);
				end
			end
		end
		if (ADDR_WIDTH == 8) begin : genblk2
			assign dout0 = dout0_w[0];
		end
		else begin : genblk2
			assign dout0 = dout0_w[addr0_r[ADDR_WIDTH - 1:8]];
		end
		if (ADDR_WIDTH == 8) begin : genblk3
			assign dout1 = dout1_w[0];
		end
		else begin : genblk3
			assign dout1 = dout1_w[addr1_r[ADDR_WIDTH - 1:8]];
		end
	endgenerate
endmodule
module SyncBit (
	sCLK,
	sRST,
	dCLK,
	sEN,
	sD_IN,
	dD_OUT
);
	parameter init = 1'b0;
	input sCLK;
	input sRST;
	input sEN;
	input sD_IN;
	input dCLK;
	output wire dD_OUT;
	reg sSyncReg;
	reg dSyncReg1;
	reg dSyncReg2;
	assign dD_OUT = dSyncReg2;
	always @(posedge sCLK or negedge sRST)
		if (sRST == 1'b0)
			sSyncReg <= init;
		else if (sEN)
			sSyncReg <= (sD_IN == 1'b1 ? 1'b1 : 1'b0);
	always @(posedge dCLK or negedge sRST)
		if (sRST == 1'b0) begin
			dSyncReg1 <= init;
			dSyncReg2 <= init;
		end
		else begin
			dSyncReg1 <= sSyncReg;
			dSyncReg2 <= dSyncReg1;
		end
	initial begin
		sSyncReg = init;
		dSyncReg1 = init;
		dSyncReg2 = init;
	end
endmodule
module SyncFIFO (
	sCLK,
	sRST,
	dCLK,
	sENQ,
	sD_IN,
	sFULL_N,
	dDEQ,
	dD_OUT,
	dEMPTY_N
);
	parameter dataWidth = 1;
	parameter depth = 2;
	parameter indxWidth = 1;
	input sCLK;
	input sRST;
	input sENQ;
	input [dataWidth - 1:0] sD_IN;
	output wire sFULL_N;
	input dCLK;
	input dDEQ;
	output wire dEMPTY_N;
	output wire [dataWidth - 1:0] dD_OUT;
	wire [indxWidth:0] msbset = ~({indxWidth + 1 {1'b1}} >> 1);
	wire [indxWidth - 1:0] msb2set = ~({indxWidth {1'b1}} >> 1);
	wire [indxWidth:0] msb12set = msbset | {1'b0, msb2set};
	reg [dataWidth - 1:0] fifoMem [0:depth - 1];
	reg [dataWidth - 1:0] dDoutReg;
	reg [indxWidth + 1:0] sGEnqPtr;
	reg [indxWidth + 1:0] sGEnqPtr1;
	reg sNotFullReg;
	wire sNextNotFull;
	wire sFutureNotFull;
	reg [indxWidth + 1:0] dGDeqPtr;
	reg [indxWidth + 1:0] dGDeqPtr1;
	reg dNotEmptyReg;
	wire dNextNotEmpty;
	wire dRST;
	reg [indxWidth:0] dSyncReg1;
	reg [indxWidth:0] dEnqPtr;
	reg [indxWidth:0] sSyncReg1;
	reg [indxWidth:0] sDeqPtr;
	wire [indxWidth - 1:0] sEnqPtrIndx;
	wire [indxWidth - 1:0] dDeqPtrIndx;
	assign dRST = sRST;
	assign dD_OUT = dDoutReg;
	assign dEMPTY_N = dNotEmptyReg;
	assign sFULL_N = sNotFullReg;
	assign sEnqPtrIndx = sGEnqPtr[indxWidth - 1:0];
	assign dDeqPtrIndx = dGDeqPtr[indxWidth - 1:0];
	always @(posedge sCLK)
		if (sENQ)
			fifoMem[sEnqPtrIndx] <= sD_IN;
	assign sNextNotFull = (sGEnqPtr[indxWidth + 1:1] ^ msb12set) != sDeqPtr;
	assign sFutureNotFull = (sGEnqPtr1[indxWidth + 1:1] ^ msb12set) != sDeqPtr;
	function [indxWidth:0] incrGray;
		input [indxWidth:0] grayin;
		input parity;
		begin : incrGrayBlock
			integer i;
			reg [indxWidth:0] tempshift;
			reg [indxWidth:0] flips;
			flips[0] = !parity;
			for (i = 1; i < indxWidth; i = i + 1)
				begin
					tempshift = grayin << ((2 + indxWidth) - i);
					flips[i] = (parity & grayin[i - 1]) & ~(|tempshift);
				end
			tempshift = grayin << 2;
			flips[indxWidth] = parity & ~(|tempshift);
			incrGray = flips ^ grayin;
		end
	endfunction
	function [indxWidth + 1:0] incrGrayP;
		input [indxWidth + 1:0] grayPin;
		begin : incrGrayPBlock
			reg [indxWidth:0] g;
			reg p;
			reg [indxWidth:0] i;
			g = grayPin[indxWidth + 1:1];
			p = grayPin[0];
			i = incrGray(g, p);
			incrGrayP = {i, ~p};
		end
	endfunction
	always @(posedge sCLK or negedge sRST)
		if (sRST == 1'b0) begin
			sGEnqPtr <= {indxWidth + 2 {1'b0}};
			sGEnqPtr1 <= {{indxWidth {1'b0}}, 2'b11};
			sNotFullReg <= 1'b0;
		end
		else if (sENQ) begin
			sGEnqPtr1 <= incrGrayP(sGEnqPtr1);
			sGEnqPtr <= sGEnqPtr1;
			sNotFullReg <= sFutureNotFull;
		end
		else
			sNotFullReg <= sNextNotFull;
	always @(posedge dCLK or negedge dRST)
		if (dRST == 1'b0) begin
			dSyncReg1 <= {indxWidth + 1 {1'b0}};
			dEnqPtr <= {indxWidth + 1 {1'b0}};
		end
		else begin
			dSyncReg1 <= sGEnqPtr[indxWidth + 1:1];
			dEnqPtr <= dSyncReg1;
		end
	assign dNextNotEmpty = dGDeqPtr[indxWidth + 1:1] != dEnqPtr;
	always @(posedge dCLK or negedge dRST)
		if (dRST == 1'b0) begin
			dGDeqPtr <= {indxWidth + 2 {1'b0}};
			dGDeqPtr1 <= {{indxWidth {1'b0}}, 2'b11};
			dNotEmptyReg <= 1'b0;
		end
		else if ((!dNotEmptyReg || dDEQ) && dNextNotEmpty) begin
			dGDeqPtr <= dGDeqPtr1;
			dGDeqPtr1 <= incrGrayP(dGDeqPtr1);
			dNotEmptyReg <= 1'b1;
		end
		else if (dDEQ && !dNextNotEmpty)
			dNotEmptyReg <= 1'b0;
	always @(posedge dCLK)
		if ((!dNotEmptyReg || dDEQ) && dNextNotEmpty)
			dDoutReg <= fifoMem[dDeqPtrIndx];
	always @(posedge sCLK or negedge sRST)
		if (sRST == 1'b0) begin
			sSyncReg1 <= {indxWidth + 1 {1'b0}};
			sDeqPtr <= {indxWidth + 1 {1'b0}};
		end
		else begin
			sSyncReg1 <= dGDeqPtr[indxWidth + 1:1];
			sDeqPtr <= sSyncReg1;
		end
	initial begin : initBlock
		integer i;
		for (i = 0; i < depth; i = i + 1)
			fifoMem[i] = {(dataWidth + 1) / 2 {2'b10}};
		dDoutReg = {(dataWidth + 1) / 2 {2'b10}};
		sGEnqPtr = {(indxWidth + 2) / 2 {2'b10}};
		sGEnqPtr1 = sGEnqPtr;
		sNotFullReg = 1'b0;
		dGDeqPtr = sGEnqPtr;
		dGDeqPtr1 = sGEnqPtr;
		dNotEmptyReg = 1'b0;
		sSyncReg1 = sGEnqPtr;
		sDeqPtr = sGEnqPtr;
		dSyncReg1 = sGEnqPtr;
		dEnqPtr = sGEnqPtr;
	end
	initial begin : parameter_assertions
		integer ok;
		integer i;
		integer expDepth;
		ok = 1;
		expDepth = 1;
		for (i = 0; i < indxWidth; i = i + 1)
			expDepth = expDepth * 2;
		if (expDepth != depth) begin
			ok = 0;
			$display("ERROR SyncFiFO.v: index size and depth do not match;");
			$display("\tdepth must equal 2 ** index size. expected %0d", expDepth);
		end
		#(0)
			if (ok == 0)
				$finish;
	end
endmodule
module SyncPulse (
	sCLK,
	sRST,
	dCLK,
	sEN,
	dPulse
);
	input sCLK;
	input sRST;
	input sEN;
	input dCLK;
	output wire dPulse;
	reg sSyncReg;
	reg dSyncReg1;
	reg dSyncReg2;
	reg dSyncPulse;
	assign dPulse = dSyncReg2 != dSyncPulse;
	always @(posedge sCLK or negedge sRST)
		if (sRST == 1'b0)
			sSyncReg <= 1'b0;
		else if (sEN)
			sSyncReg <= !sSyncReg;
	always @(posedge dCLK or negedge sRST)
		if (sRST == 1'b0) begin
			dSyncReg1 <= 1'b0;
			dSyncReg2 <= 1'b0;
			dSyncPulse <= 1'b0;
		end
		else begin
			dSyncReg1 <= sSyncReg;
			dSyncReg2 <= dSyncReg1;
			dSyncPulse <= dSyncReg2;
		end
	initial begin
		sSyncReg = 1'b0;
		dSyncReg1 = 1'b0;
		dSyncReg2 = 1'b0;
		dSyncPulse = 1'b0;
	end
endmodule
module SyncResetA (
	IN_RST,
	CLK,
	OUT_RST
);
	parameter RSTDELAY = 1;
	input CLK;
	input IN_RST;
	output wire OUT_RST;
	reg [RSTDELAY:0] reset_hold;
	wire [RSTDELAY + 1:0] next_reset = {reset_hold, ~1'b0};
	assign OUT_RST = reset_hold[RSTDELAY];
	always @(posedge CLK or negedge IN_RST)
		if (IN_RST == 1'b0)
			reset_hold <= {RSTDELAY + 1 {1'b0}};
		else
			reset_hold <= next_reset[RSTDELAY:0];
	initial begin
		#(0)
			;
		reset_hold = {RSTDELAY + 1 {~1'b0}};
	end
endmodule
module top (
	clk,
	rst_n,
	load_kdtree,
	load_done,
	fsm_start,
	fsm_done,
	send_best_arr,
	send_done,
	io_clk,
	io_rst_n,
	in_fifo_wenq,
	in_fifo_wdata,
	in_fifo_wfull_n,
	out_fifo_deq,
	out_fifo_rdata,
	out_fifo_rempty_n,
	wbs_debug,
	wbs_qp_mem_csb0,
	wbs_qp_mem_web0,
	wbs_qp_mem_addr0,
	wbs_qp_mem_wpatch0,
	wbs_qp_mem_rpatch0,
	wbs_leaf_mem_csb0,
	wbs_leaf_mem_web0,
	wbs_leaf_mem_addr0,
	wbs_leaf_mem_wleaf0,
	wbs_leaf_mem_rleaf0,
	wbs_best_arr_csb1,
	wbs_best_arr_addr1,
	wbs_best_arr_rdata1,
	wbs_node_mem_we,
	wbs_node_mem_rd,
	wbs_node_mem_addr,
	wbs_node_mem_wdata,
	wbs_node_mem_rdata
);
	parameter DATA_WIDTH = 11;
	parameter DIST_WIDTH = 25;
	parameter IDX_WIDTH = 9;
	parameter LEAF_SIZE = 8;
	parameter PATCH_SIZE = 5;
	parameter ROW_SIZE = 26;
	parameter COL_SIZE = 19;
	parameter NUM_QUERYS = ROW_SIZE * COL_SIZE;
	parameter K = 4;
	parameter BEST_ARRAY_K = 1;
	parameter NUM_LEAVES = 64;
	parameter BLOCKING = 4;
	parameter LEAF_ADDRW = $clog2(NUM_LEAVES);
	input wire clk;
	input wire rst_n;
	input wire load_kdtree;
	output reg load_done;
	input wire fsm_start;
	output reg fsm_done;
	input wire send_best_arr;
	output reg send_done;
	input wire io_clk;
	input wire io_rst_n;
	input wire in_fifo_wenq;
	input wire [DATA_WIDTH - 1:0] in_fifo_wdata;
	output wire in_fifo_wfull_n;
	input wire out_fifo_deq;
	output wire [DATA_WIDTH - 1:0] out_fifo_rdata;
	output wire out_fifo_rempty_n;
	input wire wbs_debug;
	input wire wbs_qp_mem_csb0;
	input wire wbs_qp_mem_web0;
	input wire [$clog2(NUM_QUERYS) - 1:0] wbs_qp_mem_addr0;
	input wire [(PATCH_SIZE * DATA_WIDTH) - 1:0] wbs_qp_mem_wpatch0;
	output wire [(PATCH_SIZE * DATA_WIDTH) - 1:0] wbs_qp_mem_rpatch0;
	input wire [LEAF_SIZE - 1:0] wbs_leaf_mem_csb0;
	input wire [LEAF_SIZE - 1:0] wbs_leaf_mem_web0;
	input wire [LEAF_ADDRW - 1:0] wbs_leaf_mem_addr0;
	input wire [63:0] wbs_leaf_mem_wleaf0;
	output wire [(LEAF_SIZE * 64) - 1:0] wbs_leaf_mem_rleaf0;
	input wire wbs_best_arr_csb1;
	input wire [7:0] wbs_best_arr_addr1;
	output wire [63:0] wbs_best_arr_rdata1;
	input wire wbs_node_mem_we;
	input wire wbs_node_mem_rd;
	input wire [5:0] wbs_node_mem_addr;
	input wire [(2 * DATA_WIDTH) - 1:0] wbs_node_mem_wdata;
	output wire [(2 * DATA_WIDTH) - 1:0] wbs_node_mem_rdata;
	reg load_kdtree_r;
	wire load_done_w;
	reg fsm_start_r;
	wire fsm_done_w;
	reg send_best_arr_r;
	wire send_done_w;
	wire in_fifo_deq;
	wire [DATA_WIDTH - 1:0] in_fifo_rdata;
	wire in_fifo_rempty_n;
	wire [2:0] out_fifo_wdata_sel;
	reg [DATA_WIDTH - 1:0] out_fifo_wdata_n11;
	wire out_fifo_wenq;
	reg [DATA_WIDTH - 1:0] out_fifo_wdata;
	wire out_fifo_wfull_n;
	wire [DATA_WIDTH - 1:0] agg_sender_data;
	wire agg_sender_empty_n;
	wire agg_sender_deq;
	wire [(6 * DATA_WIDTH) - 1:0] agg_receiver_data;
	wire agg_receiver_full_n;
	wire agg_receiver_enq;
	wire agg_change_fetch_width;
	wire [2:0] agg_input_fetch_width;
	wire int_node_sender_enable;
	wire [(2 * DATA_WIDTH) - 1:0] int_node_sender_data;
	wire [5:0] int_node_sender_addr;
	wire int_node_patch_en;
	wire [(PATCH_SIZE * DATA_WIDTH) - 1:0] int_node_patch_in;
	wire [LEAF_ADDRW - 1:0] int_node_leaf_index;
	wire int_node_leaf_valid;
	wire int_node_patch_en2;
	wire [(PATCH_SIZE * DATA_WIDTH) - 1:0] int_node_patch_in2;
	wire [LEAF_ADDRW - 1:0] int_node_leaf_index2;
	wire int_node_leaf_valid2;
	wire [LEAF_SIZE - 1:0] leaf_mem_csb0;
	wire [LEAF_SIZE - 1:0] leaf_mem_web0;
	wire [LEAF_ADDRW - 1:0] leaf_mem_addr0;
	wire [((PATCH_SIZE * DATA_WIDTH) + IDX_WIDTH) - 1:0] leaf_mem_wleaf0;
	wire [((LEAF_SIZE * PATCH_SIZE) * DATA_WIDTH) - 1:0] leaf_mem_rpatch_data0;
	wire [(LEAF_SIZE * IDX_WIDTH) - 1:0] leaf_mem_rpatch_idx0;
	wire leaf_mem_csb1;
	wire [LEAF_ADDRW - 1:0] leaf_mem_addr1;
	wire [((LEAF_SIZE * PATCH_SIZE) * DATA_WIDTH) - 1:0] leaf_mem_rpatch_data1;
	wire [(LEAF_SIZE * IDX_WIDTH) - 1:0] leaf_mem_rpatch_idx1;
	wire qp_mem_csb0;
	wire qp_mem_web0;
	wire [$clog2(NUM_QUERYS) - 1:0] qp_mem_addr0;
	wire [(PATCH_SIZE * DATA_WIDTH) - 1:0] qp_mem_wpatch0;
	wire [(PATCH_SIZE * DATA_WIDTH) - 1:0] qp_mem_rpatch0;
	wire qp_mem_csb1;
	wire [$clog2(NUM_QUERYS) - 1:0] qp_mem_addr1;
	wire [(PATCH_SIZE * DATA_WIDTH) - 1:0] qp_mem_rpatch1;
	wire best_arr_csb0;
	wire best_arr_web0;
	wire [7:0] best_arr_addr0;
	wire [(BEST_ARRAY_K * 64) - 1:0] best_arr_wdata0;
	wire [(BEST_ARRAY_K * 64) - 1:0] best_arr_rdata0;
	wire [BEST_ARRAY_K - 1:0] best_arr_csb1;
	wire [7:0] best_arr_addr1;
	wire [(BEST_ARRAY_K * 64) - 1:0] best_arr_rdata1;
	wire k0_query_first_in;
	wire k0_query_first_out;
	wire k0_query_last_in;
	wire k0_query_last_out;
	wire k0_query_valid;
	wire signed [(PATCH_SIZE * DATA_WIDTH) - 1:0] k0_query_patch;
	wire k0_dist_valid;
	reg [LEAF_ADDRW - 1:0] k0_leaf_idx_in;
	wire [LEAF_ADDRW - 1:0] k0_leaf_idx_out;
	wire signed [(PATCH_SIZE * DATA_WIDTH) - 1:0] k0_p0_data;
	wire signed [(PATCH_SIZE * DATA_WIDTH) - 1:0] k0_p1_data;
	wire signed [(PATCH_SIZE * DATA_WIDTH) - 1:0] k0_p2_data;
	wire signed [(PATCH_SIZE * DATA_WIDTH) - 1:0] k0_p3_data;
	wire signed [(PATCH_SIZE * DATA_WIDTH) - 1:0] k0_p4_data;
	wire signed [(PATCH_SIZE * DATA_WIDTH) - 1:0] k0_p5_data;
	wire signed [(PATCH_SIZE * DATA_WIDTH) - 1:0] k0_p6_data;
	wire signed [(PATCH_SIZE * DATA_WIDTH) - 1:0] k0_p7_data;
	wire [IDX_WIDTH - 1:0] k0_p0_idx_in;
	wire [IDX_WIDTH - 1:0] k0_p1_idx_in;
	wire [IDX_WIDTH - 1:0] k0_p2_idx_in;
	wire [IDX_WIDTH - 1:0] k0_p3_idx_in;
	wire [IDX_WIDTH - 1:0] k0_p4_idx_in;
	wire [IDX_WIDTH - 1:0] k0_p5_idx_in;
	wire [IDX_WIDTH - 1:0] k0_p6_idx_in;
	wire [IDX_WIDTH - 1:0] k0_p7_idx_in;
	wire [DIST_WIDTH - 1:0] k0_p0_l2_dist;
	wire [DIST_WIDTH - 1:0] k0_p1_l2_dist;
	wire [DIST_WIDTH - 1:0] k0_p2_l2_dist;
	wire [DIST_WIDTH - 1:0] k0_p3_l2_dist;
	wire [DIST_WIDTH - 1:0] k0_p4_l2_dist;
	wire [DIST_WIDTH - 1:0] k0_p5_l2_dist;
	wire [DIST_WIDTH - 1:0] k0_p6_l2_dist;
	wire [DIST_WIDTH - 1:0] k0_p7_l2_dist;
	wire [IDX_WIDTH - 1:0] k0_p0_idx_out;
	wire [IDX_WIDTH - 1:0] k0_p1_idx_out;
	wire [IDX_WIDTH - 1:0] k0_p2_idx_out;
	wire [IDX_WIDTH - 1:0] k0_p3_idx_out;
	wire [IDX_WIDTH - 1:0] k0_p4_idx_out;
	wire [IDX_WIDTH - 1:0] k0_p5_idx_out;
	wire [IDX_WIDTH - 1:0] k0_p6_idx_out;
	wire [IDX_WIDTH - 1:0] k0_p7_idx_out;
	wire s0_query_first_in;
	wire s0_query_first_out;
	wire s0_query_last_in;
	wire s0_query_last_out;
	wire s0_valid_in;
	wire s0_valid_out;
	wire [DIST_WIDTH - 1:0] s0_data_in_0;
	wire [DIST_WIDTH - 1:0] s0_data_in_1;
	wire [DIST_WIDTH - 1:0] s0_data_in_2;
	wire [DIST_WIDTH - 1:0] s0_data_in_3;
	wire [DIST_WIDTH - 1:0] s0_data_in_4;
	wire [DIST_WIDTH - 1:0] s0_data_in_5;
	wire [DIST_WIDTH - 1:0] s0_data_in_6;
	wire [DIST_WIDTH - 1:0] s0_data_in_7;
	wire [(LEAF_ADDRW + IDX_WIDTH) - 1:0] s0_idx_in_0;
	wire [(LEAF_ADDRW + IDX_WIDTH) - 1:0] s0_idx_in_1;
	wire [(LEAF_ADDRW + IDX_WIDTH) - 1:0] s0_idx_in_2;
	wire [(LEAF_ADDRW + IDX_WIDTH) - 1:0] s0_idx_in_3;
	wire [(LEAF_ADDRW + IDX_WIDTH) - 1:0] s0_idx_in_4;
	wire [(LEAF_ADDRW + IDX_WIDTH) - 1:0] s0_idx_in_5;
	wire [(LEAF_ADDRW + IDX_WIDTH) - 1:0] s0_idx_in_6;
	wire [(LEAF_ADDRW + IDX_WIDTH) - 1:0] s0_idx_in_7;
	wire [DIST_WIDTH - 1:0] s0_data_out_0;
	wire [DIST_WIDTH - 1:0] s0_data_out_1;
	wire [DIST_WIDTH - 1:0] s0_data_out_2;
	wire [DIST_WIDTH - 1:0] s0_data_out_3;
	wire [(LEAF_ADDRW + IDX_WIDTH) - 1:0] s0_idx_out_0;
	wire [(LEAF_ADDRW + IDX_WIDTH) - 1:0] s0_idx_out_1;
	wire [(LEAF_ADDRW + IDX_WIDTH) - 1:0] s0_idx_out_2;
	wire [(LEAF_ADDRW + IDX_WIDTH) - 1:0] s0_idx_out_3;
	wire sl0_restart;
	wire sl0_insert;
	wire sl0_last_in;
	wire [DIST_WIDTH - 1:0] sl0_l2_dist_in;
	wire [(LEAF_ADDRW + IDX_WIDTH) - 1:0] sl0_merged_idx_in;
	wire sl0_valid_out;
	wire [DIST_WIDTH - 1:0] sl0_l2_dist_0;
	wire [DIST_WIDTH - 1:0] sl0_l2_dist_1;
	wire [DIST_WIDTH - 1:0] sl0_l2_dist_2;
	wire [DIST_WIDTH - 1:0] sl0_l2_dist_3;
	wire [(LEAF_ADDRW + IDX_WIDTH) - 1:0] sl0_merged_idx_0;
	wire [(LEAF_ADDRW + IDX_WIDTH) - 1:0] sl0_merged_idx_1;
	wire [(LEAF_ADDRW + IDX_WIDTH) - 1:0] sl0_merged_idx_2;
	wire [(LEAF_ADDRW + IDX_WIDTH) - 1:0] sl0_merged_idx_3;
	wire [(K * LEAF_ADDRW) - 1:0] computes0_leaf_idx;
	wire k1_exactfstrow;
	wire k1_query_first_in;
	wire k1_query_first_out;
	wire k1_query_last_in;
	wire k1_query_last_out;
	wire k1_query_valid;
	wire signed [(PATCH_SIZE * DATA_WIDTH) - 1:0] k1_query_patch;
	wire k1_dist_valid;
	reg [LEAF_ADDRW - 1:0] k1_leaf_idx_in;
	wire [LEAF_ADDRW - 1:0] k1_leaf_idx_out;
	wire signed [(PATCH_SIZE * DATA_WIDTH) - 1:0] k1_p0_data;
	wire signed [(PATCH_SIZE * DATA_WIDTH) - 1:0] k1_p1_data;
	wire signed [(PATCH_SIZE * DATA_WIDTH) - 1:0] k1_p2_data;
	wire signed [(PATCH_SIZE * DATA_WIDTH) - 1:0] k1_p3_data;
	wire signed [(PATCH_SIZE * DATA_WIDTH) - 1:0] k1_p4_data;
	wire signed [(PATCH_SIZE * DATA_WIDTH) - 1:0] k1_p5_data;
	wire signed [(PATCH_SIZE * DATA_WIDTH) - 1:0] k1_p6_data;
	wire signed [(PATCH_SIZE * DATA_WIDTH) - 1:0] k1_p7_data;
	wire [IDX_WIDTH - 1:0] k1_p0_idx_in;
	wire [IDX_WIDTH - 1:0] k1_p1_idx_in;
	wire [IDX_WIDTH - 1:0] k1_p2_idx_in;
	wire [IDX_WIDTH - 1:0] k1_p3_idx_in;
	wire [IDX_WIDTH - 1:0] k1_p4_idx_in;
	wire [IDX_WIDTH - 1:0] k1_p5_idx_in;
	wire [IDX_WIDTH - 1:0] k1_p6_idx_in;
	wire [IDX_WIDTH - 1:0] k1_p7_idx_in;
	wire [DIST_WIDTH - 1:0] k1_p0_l2_dist;
	wire [DIST_WIDTH - 1:0] k1_p1_l2_dist;
	wire [DIST_WIDTH - 1:0] k1_p2_l2_dist;
	wire [DIST_WIDTH - 1:0] k1_p3_l2_dist;
	wire [DIST_WIDTH - 1:0] k1_p4_l2_dist;
	wire [DIST_WIDTH - 1:0] k1_p5_l2_dist;
	wire [DIST_WIDTH - 1:0] k1_p6_l2_dist;
	wire [DIST_WIDTH - 1:0] k1_p7_l2_dist;
	wire [IDX_WIDTH - 1:0] k1_p0_idx_out;
	wire [IDX_WIDTH - 1:0] k1_p1_idx_out;
	wire [IDX_WIDTH - 1:0] k1_p2_idx_out;
	wire [IDX_WIDTH - 1:0] k1_p3_idx_out;
	wire [IDX_WIDTH - 1:0] k1_p4_idx_out;
	wire [IDX_WIDTH - 1:0] k1_p5_idx_out;
	wire [IDX_WIDTH - 1:0] k1_p6_idx_out;
	wire [IDX_WIDTH - 1:0] k1_p7_idx_out;
	wire s1_query_first_in;
	wire s1_query_first_out;
	wire s1_query_last_in;
	wire s1_query_last_out;
	wire s1_valid_in;
	wire s1_valid_out;
	wire [DIST_WIDTH - 1:0] s1_data_in_0;
	wire [DIST_WIDTH - 1:0] s1_data_in_1;
	wire [DIST_WIDTH - 1:0] s1_data_in_2;
	wire [DIST_WIDTH - 1:0] s1_data_in_3;
	wire [DIST_WIDTH - 1:0] s1_data_in_4;
	wire [DIST_WIDTH - 1:0] s1_data_in_5;
	wire [DIST_WIDTH - 1:0] s1_data_in_6;
	wire [DIST_WIDTH - 1:0] s1_data_in_7;
	wire [(LEAF_ADDRW + IDX_WIDTH) - 1:0] s1_idx_in_0;
	wire [(LEAF_ADDRW + IDX_WIDTH) - 1:0] s1_idx_in_1;
	wire [(LEAF_ADDRW + IDX_WIDTH) - 1:0] s1_idx_in_2;
	wire [(LEAF_ADDRW + IDX_WIDTH) - 1:0] s1_idx_in_3;
	wire [(LEAF_ADDRW + IDX_WIDTH) - 1:0] s1_idx_in_4;
	wire [(LEAF_ADDRW + IDX_WIDTH) - 1:0] s1_idx_in_5;
	wire [(LEAF_ADDRW + IDX_WIDTH) - 1:0] s1_idx_in_6;
	wire [(LEAF_ADDRW + IDX_WIDTH) - 1:0] s1_idx_in_7;
	wire [DIST_WIDTH - 1:0] s1_data_out_0;
	wire [DIST_WIDTH - 1:0] s1_data_out_1;
	wire [DIST_WIDTH - 1:0] s1_data_out_2;
	wire [DIST_WIDTH - 1:0] s1_data_out_3;
	wire [(LEAF_ADDRW + IDX_WIDTH) - 1:0] s1_idx_out_0;
	wire [(LEAF_ADDRW + IDX_WIDTH) - 1:0] s1_idx_out_1;
	wire [(LEAF_ADDRW + IDX_WIDTH) - 1:0] s1_idx_out_2;
	wire [(LEAF_ADDRW + IDX_WIDTH) - 1:0] s1_idx_out_3;
	wire sl1_restart;
	wire sl1_insert;
	wire sl1_last_in;
	wire [DIST_WIDTH - 1:0] sl1_l2_dist_in;
	wire [(LEAF_ADDRW + IDX_WIDTH) - 1:0] sl1_merged_idx_in;
	wire sl1_valid_out;
	wire [DIST_WIDTH - 1:0] sl1_l2_dist_0;
	wire [DIST_WIDTH - 1:0] sl1_l2_dist_1;
	wire [DIST_WIDTH - 1:0] sl1_l2_dist_2;
	wire [DIST_WIDTH - 1:0] sl1_l2_dist_3;
	wire [(LEAF_ADDRW + IDX_WIDTH) - 1:0] sl1_merged_idx_0;
	wire [(LEAF_ADDRW + IDX_WIDTH) - 1:0] sl1_merged_idx_1;
	wire [(LEAF_ADDRW + IDX_WIDTH) - 1:0] sl1_merged_idx_2;
	wire [(LEAF_ADDRW + IDX_WIDTH) - 1:0] sl1_merged_idx_3;
	wire [(K * LEAF_ADDRW) - 1:0] computes1_leaf_idx;
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin
			load_kdtree_r <= 1'sb0;
			fsm_start_r <= 1'sb0;
			send_best_arr_r <= 1'sb0;
			load_done <= 1'sb0;
			fsm_done <= 1'sb0;
			send_done <= 1'sb0;
		end
		else begin
			load_kdtree_r <= load_kdtree;
			fsm_start_r <= fsm_start;
			send_best_arr_r <= send_best_arr;
			load_done <= load_done_w;
			fsm_done <= fsm_done_w;
			send_done <= send_done_w;
		end
	MainFSM #(
		.DATA_WIDTH(DATA_WIDTH),
		.LEAF_SIZE(LEAF_SIZE),
		.PATCH_SIZE(PATCH_SIZE),
		.ROW_SIZE(ROW_SIZE),
		.COL_SIZE(COL_SIZE),
		.K(K),
		.NUM_LEAVES(NUM_LEAVES),
		.BLOCKING(BLOCKING)
	) main_fsm_inst(
		.clk(clk),
		.rst_n(rst_n),
		.load_kdtree(load_kdtree_r),
		.load_done(load_done_w),
		.fsm_start(fsm_start_r),
		.fsm_done(fsm_done_w),
		.send_done(send_done_w),
		.send_best_arr(send_best_arr_r),
		.agg_receiver_enq(agg_receiver_enq),
		.agg_receiver_full_n(agg_receiver_full_n),
		.agg_change_fetch_width(agg_change_fetch_width),
		.agg_input_fetch_width(agg_input_fetch_width),
		.int_node_sender_enable(int_node_sender_enable),
		.int_node_sender_addr(int_node_sender_addr),
		.int_node_patch_en(int_node_patch_en),
		.int_node_leaf_index(int_node_leaf_index),
		.int_node_patch_en2(int_node_patch_en2),
		.int_node_leaf_index2(int_node_leaf_index2),
		.qp_mem_csb0(qp_mem_csb0),
		.qp_mem_web0(qp_mem_web0),
		.qp_mem_addr0(qp_mem_addr0),
		.qp_mem_rpatch0(qp_mem_rpatch0),
		.qp_mem_csb1(qp_mem_csb1),
		.qp_mem_addr1(qp_mem_addr1),
		.qp_mem_rpatch1(qp_mem_rpatch1),
		.leaf_mem_csb0(leaf_mem_csb0),
		.leaf_mem_web0(leaf_mem_web0),
		.leaf_mem_addr0(leaf_mem_addr0),
		.leaf_mem_csb1(leaf_mem_csb1),
		.leaf_mem_addr1(leaf_mem_addr1),
		.best_arr_addr0(best_arr_addr0),
		.best_arr_csb1(best_arr_csb1),
		.best_arr_addr1(best_arr_addr1),
		.out_fifo_wdata_sel(out_fifo_wdata_sel),
		.out_fifo_wenq(out_fifo_wenq),
		.out_fifo_wfull_n(out_fifo_wfull_n),
		.k0_query_valid(k0_query_valid),
		.k0_query_first_in(k0_query_first_in),
		.k0_query_last_in(k0_query_last_in),
		.k0_query_patch(k0_query_patch),
		.sl0_valid_out(sl0_valid_out),
		.computes0_leaf_idx(computes0_leaf_idx),
		.k1_exactfstrow(k1_exactfstrow),
		.k1_query_valid(k1_query_valid),
		.k1_query_first_in(k1_query_first_in),
		.k1_query_last_in(k1_query_last_in),
		.k1_query_patch(k1_query_patch),
		.sl1_valid_out(sl1_valid_out),
		.computes1_leaf_idx(computes1_leaf_idx)
	);
	assign computes0_leaf_idx = {sl0_merged_idx_3[(LEAF_ADDRW + IDX_WIDTH) - 1:IDX_WIDTH], sl0_merged_idx_2[(LEAF_ADDRW + IDX_WIDTH) - 1:IDX_WIDTH], sl0_merged_idx_1[(LEAF_ADDRW + IDX_WIDTH) - 1:IDX_WIDTH], sl0_merged_idx_0[(LEAF_ADDRW + IDX_WIDTH) - 1:IDX_WIDTH]};
	assign computes1_leaf_idx = {sl1_merged_idx_3[(LEAF_ADDRW + IDX_WIDTH) - 1:IDX_WIDTH], sl1_merged_idx_2[(LEAF_ADDRW + IDX_WIDTH) - 1:IDX_WIDTH], sl1_merged_idx_1[(LEAF_ADDRW + IDX_WIDTH) - 1:IDX_WIDTH], sl1_merged_idx_0[(LEAF_ADDRW + IDX_WIDTH) - 1:IDX_WIDTH]};
	SyncFIFO #(
		.dataWidth(DATA_WIDTH),
		.depth(16),
		.indxWidth(4)
	) input_fifo_inst(
		.sCLK(io_clk),
		.sRST(io_rst_n),
		.sENQ(in_fifo_wenq),
		.sD_IN(in_fifo_wdata),
		.sFULL_N(in_fifo_wfull_n),
		.dCLK(clk),
		.dDEQ(in_fifo_deq),
		.dD_OUT(in_fifo_rdata),
		.dEMPTY_N(in_fifo_rempty_n)
	);
	assign in_fifo_deq = agg_sender_deq;
	aggregator #(
		.DATA_WIDTH(DATA_WIDTH),
		.FETCH_WIDTH(6)
	) in_fifo_aggregator_inst(
		.clk(clk),
		.rst_n(rst_n),
		.sender_data(agg_sender_data),
		.sender_empty_n(agg_sender_empty_n),
		.sender_deq(agg_sender_deq),
		.receiver_data(agg_receiver_data),
		.receiver_full_n(agg_receiver_full_n),
		.receiver_enq(agg_receiver_enq),
		.change_fetch_width(agg_change_fetch_width),
		.input_fetch_width(agg_input_fetch_width)
	);
	assign agg_sender_data = in_fifo_rdata;
	assign agg_sender_empty_n = in_fifo_rempty_n;
	always @(posedge clk or negedge rst_n)
		if (~rst_n)
			out_fifo_wdata_n11 <= 1'sb0;
		else if (out_fifo_wdata_sel[1])
			out_fifo_wdata_n11 <= (out_fifo_wdata_sel[0] ? best_arr_rdata1[62-:11] : best_arr_rdata1[30-:11]);
	SyncFIFO #(
		.dataWidth(DATA_WIDTH),
		.depth(16),
		.indxWidth(4)
	) output_fifo_inst(
		.sCLK(clk),
		.sRST(rst_n),
		.sENQ(out_fifo_wenq),
		.sD_IN(out_fifo_wdata),
		.sFULL_N(out_fifo_wfull_n),
		.dCLK(io_clk),
		.dDEQ(out_fifo_deq),
		.dD_OUT(out_fifo_rdata),
		.dEMPTY_N(out_fifo_rempty_n)
	);
	always @(*)
		case (out_fifo_wdata_sel)
			3'd0: out_fifo_wdata = {2'b00, best_arr_rdata1[IDX_WIDTH - 1-:IDX_WIDTH]};
			3'd1: out_fifo_wdata = {2'b00, best_arr_rdata1[(((32 + IDX_WIDTH) - 1) >= 32 ? (32 + IDX_WIDTH) - 1 : (((32 + IDX_WIDTH) - 1) + (((32 + IDX_WIDTH) - 1) >= 32 ? (32 + IDX_WIDTH) - 32 : 34 - (32 + IDX_WIDTH))) - 1)-:(((32 + IDX_WIDTH) - 1) >= 32 ? (32 + IDX_WIDTH) - 32 : 34 - (32 + IDX_WIDTH))]};
			3'd2: out_fifo_wdata = best_arr_rdata1[19-:11];
			3'd3: out_fifo_wdata = best_arr_rdata1[51-:11];
			3'd4: out_fifo_wdata = out_fifo_wdata_n11;
			default: out_fifo_wdata = {2'b00, best_arr_rdata1[IDX_WIDTH - 1-:IDX_WIDTH]};
		endcase
	internal_node_tree #(
		.INTERNAL_WIDTH(2 * DATA_WIDTH),
		.PATCH_WIDTH(PATCH_SIZE * DATA_WIDTH),
		.ADDRESS_WIDTH(LEAF_ADDRW)
	) internal_node_inst(
		.clk(clk),
		.rst_n(rst_n),
		.sender_enable((wbs_debug ? wbs_node_mem_we : int_node_sender_enable)),
		.sender_data((wbs_debug ? wbs_node_mem_wdata : int_node_sender_data)),
		.sender_addr((wbs_debug ? wbs_node_mem_addr : int_node_sender_addr)),
		.patch_en(int_node_patch_en),
		.patch_in(int_node_patch_in),
		.leaf_index(int_node_leaf_index),
		.receiver_en(int_node_leaf_valid),
		.patch_two_en(int_node_patch_en2),
		.patch_in_two(int_node_patch_in2),
		.leaf_index_two(int_node_leaf_index2),
		.receiver_two_en(int_node_leaf_valid2),
		.wbs_rd_en_i((wbs_debug ? wbs_node_mem_rd : 1'b0)),
		.wbs_dat_o(wbs_node_mem_rdata)
	);
	assign int_node_sender_data = agg_receiver_data[(2 * DATA_WIDTH) - 1:0];
	assign int_node_patch_in = qp_mem_rpatch0;
	assign int_node_patch_in2 = qp_mem_rpatch1;
	LeavesMem #(
		.DATA_WIDTH(DATA_WIDTH),
		.IDX_WIDTH(IDX_WIDTH),
		.LEAF_SIZE(LEAF_SIZE),
		.PATCH_SIZE(PATCH_SIZE),
		.NUM_LEAVES(NUM_LEAVES)
	) leaf_mem_inst(
		.clk(clk),
		.csb0((wbs_debug ? wbs_leaf_mem_csb0 : leaf_mem_csb0)),
		.web0((wbs_debug ? wbs_leaf_mem_web0 : leaf_mem_web0)),
		.addr0((wbs_debug ? wbs_leaf_mem_addr0 : leaf_mem_addr0)),
		.wleaf0((wbs_debug ? wbs_leaf_mem_wleaf0 : leaf_mem_wleaf0)),
		.rleaf0(wbs_leaf_mem_rleaf0),
		.rpatch_data0(leaf_mem_rpatch_data0),
		.rpatch_idx0(leaf_mem_rpatch_idx0),
		.csb1(leaf_mem_csb1),
		.addr1(leaf_mem_addr1),
		.rpatch_data1(leaf_mem_rpatch_data1),
		.rpatch_idx1(leaf_mem_rpatch_idx1)
	);
	assign leaf_mem_wleaf0 = agg_receiver_data[((PATCH_SIZE * DATA_WIDTH) + IDX_WIDTH) - 1:0];
	QueryPatchMem2 #(
		.DATA_WIDTH(DATA_WIDTH),
		.PATCH_SIZE(PATCH_SIZE),
		.ADDR_WIDTH(9),
		.DEPTH(512)
	) qp_mem_inst(
		.clk(clk),
		.csb0((wbs_debug ? wbs_qp_mem_csb0 : qp_mem_csb0)),
		.web0((wbs_debug ? wbs_qp_mem_web0 : qp_mem_web0)),
		.addr0((wbs_debug ? wbs_qp_mem_addr0 : qp_mem_addr0)),
		.wpatch0((wbs_debug ? wbs_qp_mem_wpatch0 : qp_mem_wpatch0)),
		.rpatch0(qp_mem_rpatch0),
		.csb1(qp_mem_csb1),
		.addr1(qp_mem_addr1),
		.rpatch1(qp_mem_rpatch1)
	);
	assign wbs_qp_mem_rpatch0 = qp_mem_rpatch0;
	assign qp_mem_wpatch0 = agg_receiver_data;
	kBestArrays #(
		.DATA_WIDTH(64),
		.IDX_WIDTH(IDX_WIDTH),
		.K(BEST_ARRAY_K),
		.NUM_LEAVES(NUM_LEAVES)
	) k_best_array_inst(
		.clk(clk),
		.csb0(best_arr_csb0),
		.web0(best_arr_web0),
		.addr0(best_arr_addr0),
		.wdata0(best_arr_wdata0),
		.rdata0(best_arr_rdata0),
		.csb1((wbs_debug ? wbs_best_arr_csb1 : best_arr_csb1)),
		.addr1((wbs_debug ? wbs_best_arr_addr1 : best_arr_addr1)),
		.rdata1(best_arr_rdata1)
	);
	assign wbs_best_arr_rdata1 = best_arr_rdata1[0+:64];
	assign best_arr_csb0 = ~sl0_valid_out;
	assign best_arr_web0 = 1'b0;
	wire [22:0] sl0_l2_dist_capped;
	wire [22:0] sl1_l2_dist_capped;
	assign sl0_l2_dist_capped = (|sl0_l2_dist_0[DIST_WIDTH - 1:23] ? 23'h7fffff : sl0_l2_dist_0[22:0]);
	assign sl1_l2_dist_capped = (|sl1_l2_dist_0[DIST_WIDTH - 1:23] ? 23'h7fffff : sl1_l2_dist_0[22:0]);
	assign best_arr_wdata0[31-:32] = {sl0_l2_dist_capped, sl0_merged_idx_0[IDX_WIDTH - 1:0]};
	assign best_arr_wdata0[63-:32] = {sl1_l2_dist_capped, sl1_merged_idx_0[IDX_WIDTH - 1:0]};
	L2Kernel l2_k0_inst(
		.clk(clk),
		.rst_n(rst_n),
		.query_first_in(k0_query_first_in),
		.query_first_out(k0_query_first_out),
		.query_last_in(k0_query_last_in),
		.query_last_out(k0_query_last_out),
		.query_valid(k0_query_valid),
		.query_patch(k0_query_patch),
		.dist_valid(k0_dist_valid),
		.leaf_idx_in(k0_leaf_idx_in),
		.leaf_idx_out(k0_leaf_idx_out),
		.p0_data(k0_p0_data),
		.p1_data(k0_p1_data),
		.p2_data(k0_p2_data),
		.p3_data(k0_p3_data),
		.p4_data(k0_p4_data),
		.p5_data(k0_p5_data),
		.p6_data(k0_p6_data),
		.p7_data(k0_p7_data),
		.p0_idx_in(k0_p0_idx_in),
		.p1_idx_in(k0_p1_idx_in),
		.p2_idx_in(k0_p2_idx_in),
		.p3_idx_in(k0_p3_idx_in),
		.p4_idx_in(k0_p4_idx_in),
		.p5_idx_in(k0_p5_idx_in),
		.p6_idx_in(k0_p6_idx_in),
		.p7_idx_in(k0_p7_idx_in),
		.p0_l2_dist(k0_p0_l2_dist),
		.p1_l2_dist(k0_p1_l2_dist),
		.p2_l2_dist(k0_p2_l2_dist),
		.p3_l2_dist(k0_p3_l2_dist),
		.p4_l2_dist(k0_p4_l2_dist),
		.p5_l2_dist(k0_p5_l2_dist),
		.p6_l2_dist(k0_p6_l2_dist),
		.p7_l2_dist(k0_p7_l2_dist),
		.p0_idx_out(k0_p0_idx_out),
		.p1_idx_out(k0_p1_idx_out),
		.p2_idx_out(k0_p2_idx_out),
		.p3_idx_out(k0_p3_idx_out),
		.p4_idx_out(k0_p4_idx_out),
		.p5_idx_out(k0_p5_idx_out),
		.p6_idx_out(k0_p6_idx_out),
		.p7_idx_out(k0_p7_idx_out)
	);
	assign k0_p0_data = leaf_mem_rpatch_data0[0+:DATA_WIDTH * PATCH_SIZE];
	assign k0_p1_data = leaf_mem_rpatch_data0[DATA_WIDTH * PATCH_SIZE+:DATA_WIDTH * PATCH_SIZE];
	assign k0_p2_data = leaf_mem_rpatch_data0[DATA_WIDTH * (2 * PATCH_SIZE)+:DATA_WIDTH * PATCH_SIZE];
	assign k0_p3_data = leaf_mem_rpatch_data0[DATA_WIDTH * (3 * PATCH_SIZE)+:DATA_WIDTH * PATCH_SIZE];
	assign k0_p4_data = leaf_mem_rpatch_data0[DATA_WIDTH * (4 * PATCH_SIZE)+:DATA_WIDTH * PATCH_SIZE];
	assign k0_p5_data = leaf_mem_rpatch_data0[DATA_WIDTH * (5 * PATCH_SIZE)+:DATA_WIDTH * PATCH_SIZE];
	assign k0_p6_data = leaf_mem_rpatch_data0[DATA_WIDTH * (6 * PATCH_SIZE)+:DATA_WIDTH * PATCH_SIZE];
	assign k0_p7_data = leaf_mem_rpatch_data0[DATA_WIDTH * (7 * PATCH_SIZE)+:DATA_WIDTH * PATCH_SIZE];
	assign k0_p0_idx_in = leaf_mem_rpatch_idx0[0+:IDX_WIDTH];
	assign k0_p1_idx_in = leaf_mem_rpatch_idx0[IDX_WIDTH+:IDX_WIDTH];
	assign k0_p2_idx_in = leaf_mem_rpatch_idx0[2 * IDX_WIDTH+:IDX_WIDTH];
	assign k0_p3_idx_in = leaf_mem_rpatch_idx0[3 * IDX_WIDTH+:IDX_WIDTH];
	assign k0_p4_idx_in = leaf_mem_rpatch_idx0[4 * IDX_WIDTH+:IDX_WIDTH];
	assign k0_p5_idx_in = leaf_mem_rpatch_idx0[5 * IDX_WIDTH+:IDX_WIDTH];
	assign k0_p6_idx_in = leaf_mem_rpatch_idx0[6 * IDX_WIDTH+:IDX_WIDTH];
	assign k0_p7_idx_in = leaf_mem_rpatch_idx0[7 * IDX_WIDTH+:IDX_WIDTH];
	always @(posedge clk or negedge rst_n)
		if (~rst_n)
			k0_leaf_idx_in <= 1'sb0;
		else if (~leaf_mem_csb0 & leaf_mem_web0)
			k0_leaf_idx_in <= leaf_mem_addr0;
	BitonicSorter sorter0_inst(
		.clk(clk),
		.rst_n(rst_n),
		.query_first_in(s0_query_first_in),
		.query_first_out(s0_query_first_out),
		.query_last_in(s0_query_last_in),
		.query_last_out(s0_query_last_out),
		.valid_in(s0_valid_in),
		.valid_out(s0_valid_out),
		.data_in_0(s0_data_in_0),
		.data_in_1(s0_data_in_1),
		.data_in_2(s0_data_in_2),
		.data_in_3(s0_data_in_3),
		.data_in_4(s0_data_in_4),
		.data_in_5(s0_data_in_5),
		.data_in_6(s0_data_in_6),
		.data_in_7(s0_data_in_7),
		.idx_in_0(s0_idx_in_0),
		.idx_in_1(s0_idx_in_1),
		.idx_in_2(s0_idx_in_2),
		.idx_in_3(s0_idx_in_3),
		.idx_in_4(s0_idx_in_4),
		.idx_in_5(s0_idx_in_5),
		.idx_in_6(s0_idx_in_6),
		.idx_in_7(s0_idx_in_7),
		.data_out_0(s0_data_out_0),
		.data_out_1(s0_data_out_1),
		.data_out_2(s0_data_out_2),
		.data_out_3(s0_data_out_3),
		.idx_out_0(s0_idx_out_0),
		.idx_out_1(s0_idx_out_1),
		.idx_out_2(s0_idx_out_2),
		.idx_out_3(s0_idx_out_3)
	);
	assign s0_query_first_in = k0_query_first_out;
	assign s0_query_last_in = k0_query_last_out;
	assign s0_valid_in = {k0_leaf_idx_out, k0_dist_valid};
	assign s0_data_in_0 = {k0_leaf_idx_out, k0_p0_l2_dist};
	assign s0_data_in_1 = {k0_leaf_idx_out, k0_p1_l2_dist};
	assign s0_data_in_2 = {k0_leaf_idx_out, k0_p2_l2_dist};
	assign s0_data_in_3 = {k0_leaf_idx_out, k0_p3_l2_dist};
	assign s0_data_in_4 = {k0_leaf_idx_out, k0_p4_l2_dist};
	assign s0_data_in_5 = {k0_leaf_idx_out, k0_p5_l2_dist};
	assign s0_data_in_6 = {k0_leaf_idx_out, k0_p6_l2_dist};
	assign s0_data_in_7 = {k0_leaf_idx_out, k0_p7_l2_dist};
	assign s0_idx_in_0 = {k0_leaf_idx_out, k0_p0_idx_out};
	assign s0_idx_in_1 = {k0_leaf_idx_out, k0_p1_idx_out};
	assign s0_idx_in_2 = {k0_leaf_idx_out, k0_p2_idx_out};
	assign s0_idx_in_3 = {k0_leaf_idx_out, k0_p3_idx_out};
	assign s0_idx_in_4 = {k0_leaf_idx_out, k0_p4_idx_out};
	assign s0_idx_in_5 = {k0_leaf_idx_out, k0_p5_idx_out};
	assign s0_idx_in_6 = {k0_leaf_idx_out, k0_p6_idx_out};
	assign s0_idx_in_7 = {k0_leaf_idx_out, k0_p7_idx_out};
	SortedList sl0(
		.clk(clk),
		.rst_n(rst_n),
		.restart(sl0_restart),
		.insert(sl0_insert),
		.last_in(sl0_last_in),
		.l2_dist_in(sl0_l2_dist_in),
		.merged_idx_in(sl0_merged_idx_in),
		.valid_out(sl0_valid_out),
		.l2_dist_0(sl0_l2_dist_0),
		.l2_dist_1(sl0_l2_dist_1),
		.l2_dist_2(sl0_l2_dist_2),
		.l2_dist_3(sl0_l2_dist_3),
		.merged_idx_0(sl0_merged_idx_0),
		.merged_idx_1(sl0_merged_idx_1),
		.merged_idx_2(sl0_merged_idx_2),
		.merged_idx_3(sl0_merged_idx_3)
	);
	assign sl0_restart = s0_query_first_out;
	assign sl0_insert = s0_valid_out;
	assign sl0_last_in = s0_query_last_out;
	assign sl0_l2_dist_in = s0_data_out_0;
	assign sl0_merged_idx_in = s0_idx_out_0;
	L2Kernel l2_k1_inst(
		.clk(clk),
		.rst_n(rst_n),
		.query_first_in(k1_query_first_in),
		.query_first_out(k1_query_first_out),
		.query_last_in(k1_query_last_in),
		.query_last_out(k1_query_last_out),
		.query_valid(k1_query_valid),
		.query_patch(k1_query_patch),
		.dist_valid(k1_dist_valid),
		.leaf_idx_in(k1_leaf_idx_in),
		.leaf_idx_out(k1_leaf_idx_out),
		.p0_data(k1_p0_data),
		.p1_data(k1_p1_data),
		.p2_data(k1_p2_data),
		.p3_data(k1_p3_data),
		.p4_data(k1_p4_data),
		.p5_data(k1_p5_data),
		.p6_data(k1_p6_data),
		.p7_data(k1_p7_data),
		.p0_idx_in(k1_p0_idx_in),
		.p1_idx_in(k1_p1_idx_in),
		.p2_idx_in(k1_p2_idx_in),
		.p3_idx_in(k1_p3_idx_in),
		.p4_idx_in(k1_p4_idx_in),
		.p5_idx_in(k1_p5_idx_in),
		.p6_idx_in(k1_p6_idx_in),
		.p7_idx_in(k1_p7_idx_in),
		.p0_l2_dist(k1_p0_l2_dist),
		.p1_l2_dist(k1_p1_l2_dist),
		.p2_l2_dist(k1_p2_l2_dist),
		.p3_l2_dist(k1_p3_l2_dist),
		.p4_l2_dist(k1_p4_l2_dist),
		.p5_l2_dist(k1_p5_l2_dist),
		.p6_l2_dist(k1_p6_l2_dist),
		.p7_l2_dist(k1_p7_l2_dist),
		.p0_idx_out(k1_p0_idx_out),
		.p1_idx_out(k1_p1_idx_out),
		.p2_idx_out(k1_p2_idx_out),
		.p3_idx_out(k1_p3_idx_out),
		.p4_idx_out(k1_p4_idx_out),
		.p5_idx_out(k1_p5_idx_out),
		.p6_idx_out(k1_p6_idx_out),
		.p7_idx_out(k1_p7_idx_out)
	);
	assign k1_p0_data = (k1_exactfstrow ? leaf_mem_rpatch_data0[0+:DATA_WIDTH * PATCH_SIZE] : leaf_mem_rpatch_data1[0+:DATA_WIDTH * PATCH_SIZE]);
	assign k1_p1_data = (k1_exactfstrow ? leaf_mem_rpatch_data0[DATA_WIDTH * PATCH_SIZE+:DATA_WIDTH * PATCH_SIZE] : leaf_mem_rpatch_data1[DATA_WIDTH * PATCH_SIZE+:DATA_WIDTH * PATCH_SIZE]);
	assign k1_p2_data = (k1_exactfstrow ? leaf_mem_rpatch_data0[DATA_WIDTH * (2 * PATCH_SIZE)+:DATA_WIDTH * PATCH_SIZE] : leaf_mem_rpatch_data1[DATA_WIDTH * (2 * PATCH_SIZE)+:DATA_WIDTH * PATCH_SIZE]);
	assign k1_p3_data = (k1_exactfstrow ? leaf_mem_rpatch_data0[DATA_WIDTH * (3 * PATCH_SIZE)+:DATA_WIDTH * PATCH_SIZE] : leaf_mem_rpatch_data1[DATA_WIDTH * (3 * PATCH_SIZE)+:DATA_WIDTH * PATCH_SIZE]);
	assign k1_p4_data = (k1_exactfstrow ? leaf_mem_rpatch_data0[DATA_WIDTH * (4 * PATCH_SIZE)+:DATA_WIDTH * PATCH_SIZE] : leaf_mem_rpatch_data1[DATA_WIDTH * (4 * PATCH_SIZE)+:DATA_WIDTH * PATCH_SIZE]);
	assign k1_p5_data = (k1_exactfstrow ? leaf_mem_rpatch_data0[DATA_WIDTH * (5 * PATCH_SIZE)+:DATA_WIDTH * PATCH_SIZE] : leaf_mem_rpatch_data1[DATA_WIDTH * (5 * PATCH_SIZE)+:DATA_WIDTH * PATCH_SIZE]);
	assign k1_p6_data = (k1_exactfstrow ? leaf_mem_rpatch_data0[DATA_WIDTH * (6 * PATCH_SIZE)+:DATA_WIDTH * PATCH_SIZE] : leaf_mem_rpatch_data1[DATA_WIDTH * (6 * PATCH_SIZE)+:DATA_WIDTH * PATCH_SIZE]);
	assign k1_p7_data = (k1_exactfstrow ? leaf_mem_rpatch_data0[DATA_WIDTH * (7 * PATCH_SIZE)+:DATA_WIDTH * PATCH_SIZE] : leaf_mem_rpatch_data1[DATA_WIDTH * (7 * PATCH_SIZE)+:DATA_WIDTH * PATCH_SIZE]);
	assign k1_p0_idx_in = (k1_exactfstrow ? leaf_mem_rpatch_idx0[0+:IDX_WIDTH] : leaf_mem_rpatch_idx1[0+:IDX_WIDTH]);
	assign k1_p1_idx_in = (k1_exactfstrow ? leaf_mem_rpatch_idx0[IDX_WIDTH+:IDX_WIDTH] : leaf_mem_rpatch_idx1[IDX_WIDTH+:IDX_WIDTH]);
	assign k1_p2_idx_in = (k1_exactfstrow ? leaf_mem_rpatch_idx0[2 * IDX_WIDTH+:IDX_WIDTH] : leaf_mem_rpatch_idx1[2 * IDX_WIDTH+:IDX_WIDTH]);
	assign k1_p3_idx_in = (k1_exactfstrow ? leaf_mem_rpatch_idx0[3 * IDX_WIDTH+:IDX_WIDTH] : leaf_mem_rpatch_idx1[3 * IDX_WIDTH+:IDX_WIDTH]);
	assign k1_p4_idx_in = (k1_exactfstrow ? leaf_mem_rpatch_idx0[4 * IDX_WIDTH+:IDX_WIDTH] : leaf_mem_rpatch_idx1[4 * IDX_WIDTH+:IDX_WIDTH]);
	assign k1_p5_idx_in = (k1_exactfstrow ? leaf_mem_rpatch_idx0[5 * IDX_WIDTH+:IDX_WIDTH] : leaf_mem_rpatch_idx1[5 * IDX_WIDTH+:IDX_WIDTH]);
	assign k1_p6_idx_in = (k1_exactfstrow ? leaf_mem_rpatch_idx0[6 * IDX_WIDTH+:IDX_WIDTH] : leaf_mem_rpatch_idx1[6 * IDX_WIDTH+:IDX_WIDTH]);
	assign k1_p7_idx_in = (k1_exactfstrow ? leaf_mem_rpatch_idx0[7 * IDX_WIDTH+:IDX_WIDTH] : leaf_mem_rpatch_idx1[7 * IDX_WIDTH+:IDX_WIDTH]);
	always @(posedge clk or negedge rst_n)
		if (~rst_n)
			k1_leaf_idx_in <= 1'sb0;
		else if ((k1_exactfstrow & ~leaf_mem_csb0) & leaf_mem_web0)
			k1_leaf_idx_in <= leaf_mem_addr0;
		else if (~k1_exactfstrow & ~leaf_mem_csb1)
			k1_leaf_idx_in <= leaf_mem_addr1;
	BitonicSorter sorter1_inst(
		.clk(clk),
		.rst_n(rst_n),
		.query_first_in(s1_query_first_in),
		.query_first_out(s1_query_first_out),
		.query_last_in(s1_query_last_in),
		.query_last_out(s1_query_last_out),
		.valid_in(s1_valid_in),
		.valid_out(s1_valid_out),
		.data_in_0(s1_data_in_0),
		.data_in_1(s1_data_in_1),
		.data_in_2(s1_data_in_2),
		.data_in_3(s1_data_in_3),
		.data_in_4(s1_data_in_4),
		.data_in_5(s1_data_in_5),
		.data_in_6(s1_data_in_6),
		.data_in_7(s1_data_in_7),
		.idx_in_0(s1_idx_in_0),
		.idx_in_1(s1_idx_in_1),
		.idx_in_2(s1_idx_in_2),
		.idx_in_3(s1_idx_in_3),
		.idx_in_4(s1_idx_in_4),
		.idx_in_5(s1_idx_in_5),
		.idx_in_6(s1_idx_in_6),
		.idx_in_7(s1_idx_in_7),
		.data_out_0(s1_data_out_0),
		.data_out_1(s1_data_out_1),
		.data_out_2(s1_data_out_2),
		.data_out_3(s1_data_out_3),
		.idx_out_0(s1_idx_out_0),
		.idx_out_1(s1_idx_out_1),
		.idx_out_2(s1_idx_out_2),
		.idx_out_3(s1_idx_out_3)
	);
	assign s1_query_first_in = k1_query_first_out;
	assign s1_query_last_in = k1_query_last_out;
	assign s1_valid_in = {k1_leaf_idx_out, k1_dist_valid};
	assign s1_data_in_0 = {k1_leaf_idx_out, k1_p0_l2_dist};
	assign s1_data_in_1 = {k1_leaf_idx_out, k1_p1_l2_dist};
	assign s1_data_in_2 = {k1_leaf_idx_out, k1_p2_l2_dist};
	assign s1_data_in_3 = {k1_leaf_idx_out, k1_p3_l2_dist};
	assign s1_data_in_4 = {k1_leaf_idx_out, k1_p4_l2_dist};
	assign s1_data_in_5 = {k1_leaf_idx_out, k1_p5_l2_dist};
	assign s1_data_in_6 = {k1_leaf_idx_out, k1_p6_l2_dist};
	assign s1_data_in_7 = {k1_leaf_idx_out, k1_p7_l2_dist};
	assign s1_idx_in_0 = {k1_leaf_idx_out, k1_p0_idx_out};
	assign s1_idx_in_1 = {k1_leaf_idx_out, k1_p1_idx_out};
	assign s1_idx_in_2 = {k1_leaf_idx_out, k1_p2_idx_out};
	assign s1_idx_in_3 = {k1_leaf_idx_out, k1_p3_idx_out};
	assign s1_idx_in_4 = {k1_leaf_idx_out, k1_p4_idx_out};
	assign s1_idx_in_5 = {k1_leaf_idx_out, k1_p5_idx_out};
	assign s1_idx_in_6 = {k1_leaf_idx_out, k1_p6_idx_out};
	assign s1_idx_in_7 = {k1_leaf_idx_out, k1_p7_idx_out};
	SortedList sl1(
		.clk(clk),
		.rst_n(rst_n),
		.restart(sl1_restart),
		.insert(sl1_insert),
		.last_in(sl1_last_in),
		.l2_dist_in(sl1_l2_dist_in),
		.merged_idx_in(sl1_merged_idx_in),
		.valid_out(sl1_valid_out),
		.l2_dist_0(sl1_l2_dist_0),
		.l2_dist_1(sl1_l2_dist_1),
		.l2_dist_2(sl1_l2_dist_2),
		.l2_dist_3(sl1_l2_dist_3),
		.merged_idx_0(sl1_merged_idx_0),
		.merged_idx_1(sl1_merged_idx_1),
		.merged_idx_2(sl1_merged_idx_2),
		.merged_idx_3(sl1_merged_idx_3)
	);
	assign sl1_restart = s1_query_first_out;
	assign sl1_insert = s1_valid_out;
	assign sl1_last_in = s1_query_last_out;
	assign sl1_l2_dist_in = s1_data_out_0;
	assign sl1_merged_idx_in = s1_idx_out_0;
endmodule
module wbsCtrl (
	wb_clk_i,
	wb_rst_n_i,
	wbs_stb_i,
	wbs_cyc_i,
	wbs_we_i,
	wbs_sel_i,
	wbs_dat_i,
	wbs_adr_i,
	wbs_ack_o,
	wbs_dat_o,
	wbs_usrclk_sel,
	wbs_mode,
	wbs_debug,
	wbs_done,
	wbs_cfg_done,
	wbs_fsm_start,
	acc_fsm_done,
	acc_load_done,
	acc_send_done,
	wbs_qp_mem_csb0,
	wbs_qp_mem_web0,
	wbs_qp_mem_addr0,
	wbs_qp_mem_wpatch0,
	wbs_qp_mem_rpatch0,
	wbs_leaf_mem_csb0,
	wbs_leaf_mem_web0,
	wbs_leaf_mem_addr0,
	wbs_leaf_mem_wleaf0,
	wbs_leaf_mem_rleaf0,
	wbs_node_mem_rd,
	wbs_node_mem_we,
	wbs_node_mem_addr,
	wbs_node_mem_wdata,
	wbs_node_mem_rdata,
	wbs_best_arr_csb1,
	wbs_best_arr_addr1,
	wbs_best_arr_rdata1
);
	parameter DATA_WIDTH = 11;
	parameter IDX_WIDTH = 9;
	parameter LEAF_SIZE = 8;
	parameter PATCH_SIZE = 5;
	parameter ROW_SIZE = 26;
	parameter COL_SIZE = 19;
	parameter NUM_QUERYS = ROW_SIZE * COL_SIZE;
	parameter K = 4;
	parameter NUM_LEAVES = 64;
	parameter LEAF_ADDRW = $clog2(NUM_LEAVES);
	input wire wb_clk_i;
	input wire wb_rst_n_i;
	input wire wbs_stb_i;
	input wire wbs_cyc_i;
	input wire wbs_we_i;
	input wire [3:0] wbs_sel_i;
	input wire [31:0] wbs_dat_i;
	input wire [31:0] wbs_adr_i;
	output wire wbs_ack_o;
	output wire [31:0] wbs_dat_o;
	output reg wbs_usrclk_sel;
	output reg wbs_mode;
	output reg wbs_debug;
	output reg wbs_done;
	output reg wbs_cfg_done;
	output reg wbs_fsm_start;
	input wire acc_fsm_done;
	input wire acc_load_done;
	input wire acc_send_done;
	output reg wbs_qp_mem_csb0;
	output reg wbs_qp_mem_web0;
	output reg [$clog2(NUM_QUERYS) - 1:0] wbs_qp_mem_addr0;
	output reg [(PATCH_SIZE * DATA_WIDTH) - 1:0] wbs_qp_mem_wpatch0;
	input wire [(PATCH_SIZE * DATA_WIDTH) - 1:0] wbs_qp_mem_rpatch0;
	output reg [LEAF_SIZE - 1:0] wbs_leaf_mem_csb0;
	output reg [LEAF_SIZE - 1:0] wbs_leaf_mem_web0;
	output reg [LEAF_ADDRW - 1:0] wbs_leaf_mem_addr0;
	output reg [63:0] wbs_leaf_mem_wleaf0;
	input wire [(LEAF_SIZE * 64) - 1:0] wbs_leaf_mem_rleaf0;
	output reg wbs_node_mem_rd;
	output reg wbs_node_mem_we;
	output reg [5:0] wbs_node_mem_addr;
	output reg [(2 * DATA_WIDTH) - 1:0] wbs_node_mem_wdata;
	input wire [(2 * DATA_WIDTH) - 1:0] wbs_node_mem_rdata;
	output reg wbs_best_arr_csb1;
	output reg [7:0] wbs_best_arr_addr1;
	input wire [63:0] wbs_best_arr_rdata1;
	localparam WBS_ADDR_MASK = 32'hffff0000;
	localparam WBS_MODE_ADDR = 32'h30000000;
	localparam WBS_DEBUG_ADDR = 32'h30000004;
	localparam WBS_DONE_ADDR = 32'h30000008;
	localparam WBS_FSM_START_ADDR = 32'h3000000c;
	localparam WBS_FSM_DONE_ADDR = 32'h30000010;
	localparam WBS_LOAD_DONE_ADDR = 32'h30000014;
	localparam WBS_SEND_DONE_ADDR = 32'h30000018;
	localparam WBS_CFG_DONE_ADDR = 32'h3000001c;
	localparam WBS_USRCLK_SEL_ADDR = 32'h30000020;
	localparam WBS_QUERY_ADDR = 32'h30010000;
	localparam WBS_LEAF_ADDR = 32'h30020000;
	localparam WBS_BEST_ADDR = 32'h30030000;
	localparam WBS_NODE_ADDR = 32'h30040000;
	(* fsm_encoding = "one_hot" *) reg [31:0] currState;
	reg [31:0] nextState;
	reg wbs_input_reg_en;
	wire wbs_valid;
	reg wbs_valid_q;
	reg wbs_we_i_q;
	reg [3:0] wbs_sel_i_q;
	reg [31:0] wbs_dat_i_q;
	reg [31:0] wbs_adr_i_q;
	reg [31:0] wbs_dat_i_lower_q;
	reg wbs_ack_o_q;
	reg wbs_ack_o_d;
	reg [31:0] wbs_dat_o_q;
	reg [31:0] wbs_dat_o_d;
	reg wbs_dat_o_d_valid;
	reg wbs_fsm_done;
	reg wbs_load_done;
	reg wbs_send_done;
	assign wbs_valid = wbs_cyc_i & wbs_stb_i;
	assign wbs_ack_o = wbs_ack_o_q;
	assign wbs_dat_o = wbs_dat_o_q;
	always @(posedge wb_clk_i or negedge wb_rst_n_i)
		if (~wb_rst_n_i)
			currState <= 32'd0;
		else
			currState <= nextState;
	always @(*) begin
		nextState = currState;
		wbs_input_reg_en = 1'b0;
		wbs_ack_o_d = 1'b0;
		wbs_dat_o_d = 1'sb0;
		wbs_dat_o_d_valid = 1'b0;
		wbs_qp_mem_csb0 = 1'b1;
		wbs_qp_mem_web0 = 1'b1;
		wbs_qp_mem_addr0 = 1'sb0;
		wbs_qp_mem_wpatch0 = 1'sb0;
		wbs_leaf_mem_csb0 = 1'sb1;
		wbs_leaf_mem_web0 = 1'sb1;
		wbs_leaf_mem_addr0 = 1'sb0;
		wbs_leaf_mem_wleaf0 = 1'sb0;
		wbs_best_arr_csb1 = 1'b1;
		wbs_best_arr_addr1 = 1'sb0;
		wbs_node_mem_we = 1'b0;
		wbs_node_mem_rd = 1'b0;
		wbs_node_mem_addr = 1'sb0;
		wbs_node_mem_wdata = 1'sb0;
		case (currState)
			32'd0:
				if (wbs_valid) begin
					wbs_input_reg_en = 1'b1;
					if (wbs_we_i) begin
						nextState = 32'd3;
						wbs_ack_o_d = 1'b1;
					end
					else
						nextState = 32'd1;
				end
			32'd1: begin
				nextState = 32'd2;
				if ((wbs_adr_i_q & WBS_ADDR_MASK) == WBS_QUERY_ADDR) begin
					wbs_qp_mem_csb0 = 1'b0;
					wbs_qp_mem_web0 = 1'b1;
					wbs_qp_mem_addr0 = wbs_adr_i_q[3+:$clog2(NUM_QUERYS)];
				end
				else if ((wbs_adr_i_q & WBS_ADDR_MASK) == WBS_LEAF_ADDR) begin
					wbs_leaf_mem_csb0[wbs_adr_i_q[5:3]] = 1'b0;
					wbs_leaf_mem_web0[wbs_adr_i_q[5:3]] = 1'b1;
					wbs_leaf_mem_addr0 = wbs_adr_i_q[11:6];
				end
				else if ((wbs_adr_i_q & WBS_ADDR_MASK) == WBS_NODE_ADDR) begin
					wbs_node_mem_rd = 1'b1;
					wbs_node_mem_addr = wbs_adr_i_q[7:2];
				end
				else if ((wbs_adr_i_q & WBS_ADDR_MASK) == WBS_BEST_ADDR) begin
					wbs_best_arr_csb1 = 1'b0;
					wbs_best_arr_addr1 = wbs_adr_i_q[10:3];
				end
			end
			32'd2: begin
				nextState = 32'd3;
				wbs_ack_o_d = 1'b1;
				wbs_dat_o_d_valid = 1'b1;
				if ((wbs_adr_i_q & WBS_ADDR_MASK) == WBS_QUERY_ADDR)
					wbs_dat_o_d = (wbs_adr_i_q[2] ? {9'b000000000, wbs_qp_mem_rpatch0[54:32]} : wbs_qp_mem_rpatch0[31:0]);
				else if ((wbs_adr_i_q & WBS_ADDR_MASK) == WBS_LEAF_ADDR)
					wbs_dat_o_d = (wbs_adr_i_q[2] ? wbs_leaf_mem_rleaf0[(wbs_adr_i_q[5:3] * 64) + 63-:32] : wbs_leaf_mem_rleaf0[(wbs_adr_i_q[5:3] * 64) + 31-:32]);
				else if ((wbs_adr_i_q & WBS_ADDR_MASK) == WBS_NODE_ADDR)
					wbs_dat_o_d = {10'd0, wbs_node_mem_rdata};
				else if ((wbs_adr_i_q & WBS_ADDR_MASK) == WBS_BEST_ADDR)
					wbs_dat_o_d = (wbs_adr_i_q[2] ? wbs_best_arr_rdata1[63:32] : wbs_best_arr_rdata1[31:0]);
				else if (wbs_adr_i_q == WBS_FSM_DONE_ADDR)
					wbs_dat_o_d = {31'd0, wbs_fsm_done};
				else if (wbs_adr_i_q == WBS_LOAD_DONE_ADDR)
					wbs_dat_o_d = {31'd0, wbs_load_done};
				else if (wbs_adr_i_q == WBS_SEND_DONE_ADDR)
					wbs_dat_o_d = {31'd0, wbs_send_done};
			end
			32'd3: begin
				nextState = 32'd0;
				if ((wbs_we_i_q & wbs_adr_i_q[2]) & ((wbs_adr_i_q & WBS_ADDR_MASK) == WBS_QUERY_ADDR)) begin
					wbs_qp_mem_csb0 = 1'b0;
					wbs_qp_mem_web0 = 1'b0;
					wbs_qp_mem_addr0 = wbs_adr_i_q[3+:$clog2(NUM_QUERYS)];
					wbs_qp_mem_wpatch0 = {wbs_dat_i_q, wbs_dat_i_lower_q};
				end
				else if ((wbs_we_i_q & wbs_adr_i_q[2]) & ((wbs_adr_i_q & WBS_ADDR_MASK) == WBS_LEAF_ADDR)) begin
					wbs_leaf_mem_csb0[wbs_adr_i_q[5:3]] = 1'b0;
					wbs_leaf_mem_web0[wbs_adr_i_q[5:3]] = 1'b0;
					wbs_leaf_mem_addr0 = wbs_adr_i_q[11:6];
					wbs_leaf_mem_wleaf0 = {wbs_dat_i_q, wbs_dat_i_lower_q};
				end
				else if (wbs_we_i_q & ((wbs_adr_i_q & WBS_ADDR_MASK) == WBS_NODE_ADDR)) begin
					wbs_node_mem_we = 1'b1;
					wbs_node_mem_addr = wbs_adr_i_q[7:2];
					wbs_node_mem_wdata = wbs_dat_i_q[21:0];
				end
			end
		endcase
	end
	always @(posedge wb_clk_i or negedge wb_rst_n_i)
		if (~wb_rst_n_i)
			wbs_valid_q <= 1'sb0;
		else
			wbs_valid_q <= wbs_valid;
	always @(posedge wb_clk_i or negedge wb_rst_n_i)
		if (~wb_rst_n_i) begin
			wbs_we_i_q <= 1'sb0;
			wbs_sel_i_q <= 1'sb0;
			wbs_dat_i_q <= 1'sb0;
			wbs_adr_i_q <= 1'sb0;
		end
		else if (wbs_input_reg_en) begin
			wbs_we_i_q <= wbs_we_i;
			wbs_sel_i_q <= wbs_sel_i;
			wbs_dat_i_q <= wbs_dat_i;
			wbs_adr_i_q <= wbs_adr_i;
		end
	always @(posedge wb_clk_i or negedge wb_rst_n_i)
		if (~wb_rst_n_i)
			wbs_dat_i_lower_q <= 1'sb0;
		else
			wbs_dat_i_lower_q <= wbs_dat_i_q;
	always @(posedge wb_clk_i or negedge wb_rst_n_i)
		if (~wb_rst_n_i)
			wbs_ack_o_q <= 1'sb0;
		else
			wbs_ack_o_q <= wbs_ack_o_d;
	always @(posedge wb_clk_i or negedge wb_rst_n_i)
		if (~wb_rst_n_i)
			wbs_dat_o_q <= 1'sb0;
		else if (wbs_dat_o_d_valid)
			wbs_dat_o_q <= wbs_dat_o_d;
	always @(posedge wb_clk_i or negedge wb_rst_n_i)
		if (~wb_rst_n_i)
			wbs_mode <= 1'sb0;
		else if ((wbs_valid_q & wbs_we_i_q) & (wbs_adr_i_q == WBS_MODE_ADDR))
			wbs_mode <= wbs_dat_i_q[0];
	always @(posedge wb_clk_i or negedge wb_rst_n_i)
		if (~wb_rst_n_i)
			wbs_debug <= 1'sb0;
		else if ((wbs_valid_q & wbs_we_i_q) & (wbs_adr_i_q == WBS_DEBUG_ADDR))
			wbs_debug <= wbs_dat_i_q[0];
	always @(posedge wb_clk_i or negedge wb_rst_n_i)
		if (~wb_rst_n_i)
			wbs_done <= 1'sb0;
		else if ((wbs_valid_q & wbs_we_i_q) & (wbs_adr_i_q == WBS_DONE_ADDR))
			wbs_done <= wbs_dat_i_q[0];
	always @(posedge wb_clk_i or negedge wb_rst_n_i)
		if (~wb_rst_n_i)
			wbs_fsm_start <= 1'sb0;
		else if ((wbs_valid_q & wbs_we_i_q) & (wbs_adr_i_q == WBS_FSM_START_ADDR))
			wbs_fsm_start <= 1'b1;
		else
			wbs_fsm_start <= 1'b0;
	always @(posedge wb_clk_i or negedge wb_rst_n_i)
		if (~wb_rst_n_i)
			wbs_fsm_done <= 1'sb0;
		else if ((wbs_valid_q & wbs_we_i_q) & (wbs_adr_i_q == WBS_FSM_DONE_ADDR))
			wbs_fsm_done <= 1'b0;
		else if (acc_fsm_done)
			wbs_fsm_done <= 1'b1;
	always @(posedge wb_clk_i or negedge wb_rst_n_i)
		if (~wb_rst_n_i)
			wbs_load_done <= 1'sb0;
		else if ((wbs_valid_q & wbs_we_i_q) & (wbs_adr_i_q == WBS_LOAD_DONE_ADDR))
			wbs_load_done <= 1'b0;
		else if (acc_load_done)
			wbs_load_done <= 1'b1;
	always @(posedge wb_clk_i or negedge wb_rst_n_i)
		if (~wb_rst_n_i)
			wbs_send_done <= 1'sb0;
		else if ((wbs_valid_q & wbs_we_i_q) & (wbs_adr_i_q == WBS_SEND_DONE_ADDR))
			wbs_send_done <= 1'b0;
		else if (acc_send_done)
			wbs_send_done <= 1'b1;
	always @(posedge wb_clk_i or negedge wb_rst_n_i)
		if (~wb_rst_n_i)
			wbs_cfg_done <= 1'sb0;
		else if ((wbs_valid_q & wbs_we_i_q) & (wbs_adr_i_q == WBS_CFG_DONE_ADDR))
			wbs_cfg_done <= wbs_dat_i_q[0];
	always @(posedge wb_clk_i or negedge wb_rst_n_i)
		if (~wb_rst_n_i)
			wbs_usrclk_sel <= 1'sb0;
		else if ((wbs_valid_q & wbs_we_i_q) & (wbs_adr_i_q == WBS_USRCLK_SEL_ADDR))
			wbs_usrclk_sel <= wbs_dat_i_q[0];
endmodule
