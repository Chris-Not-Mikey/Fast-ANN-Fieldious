module wbsCtrl
#(
    parameter DATA_WIDTH = 11,
    parameter IDX_WIDTH = 9, // index of patch in the original image
    parameter LEAF_SIZE = 8,
    parameter PATCH_SIZE = 5, //excluding the index
    parameter ROW_SIZE = 26,
    parameter COL_SIZE = 19,
    parameter NUM_QUERYS = ROW_SIZE * COL_SIZE,
    parameter K = 4,
    parameter NUM_LEAVES = 64,
    parameter LEAF_ADDRW = $clog2(NUM_LEAVES)
)
(
    input  logic wb_clk_i,
    input  logic wb_rst_n_i,
    input  logic wbs_stb_i,
    input  logic wbs_cyc_i,
    input  logic wbs_we_i,
    input  logic [3:0] wbs_sel_i,
    input  logic [31:0] wbs_dat_i,
    input  logic [31:0] wbs_adr_i,
    output logic wbs_ack_o,
    output logic [31:0] wbs_dat_o,

    output logic wbs_usrclk_sel,
    output logic wbs_mode,
    output logic wbs_debug,
    output logic wbs_done,
    output logic wbs_cfg_done,
    output logic wbs_fsm_start,
    input logic acc_fsm_done,
    input logic acc_load_done,
    input logic acc_send_done,

    output logic                                                    wbs_qp_mem_csb0,
    output logic                                                    wbs_qp_mem_web0,
    output logic [$clog2(NUM_QUERYS)-1:0]                           wbs_qp_mem_addr0,
    output logic [PATCH_SIZE*DATA_WIDTH-1:0]                        wbs_qp_mem_wpatch0,
    input logic [PATCH_SIZE*DATA_WIDTH-1:0]                         wbs_qp_mem_rpatch0,

    output logic [LEAF_SIZE-1:0]                                    wbs_leaf_mem_csb0,
    output logic [LEAF_SIZE-1:0]                                    wbs_leaf_mem_web0,
    output logic [LEAF_ADDRW-1:0]                                   wbs_leaf_mem_addr0,
    output logic [63:0]                                             wbs_leaf_mem_wleaf0,
    input logic [63:0]                                              wbs_leaf_mem_rleaf0 [LEAF_SIZE-1:0],

    output logic                                                    wbs_node_mem_rd,
    output logic                                                    wbs_node_mem_we,
    output logic [5:0]                                              wbs_node_mem_addr,
    output logic [2*DATA_WIDTH-1:0]                                 wbs_node_mem_wdata,
    input logic [2*DATA_WIDTH-1:0]                                  wbs_node_mem_rdata,

    output logic                                                    wbs_best_arr_csb1,
    output logic [7:0]                                              wbs_best_arr_addr1,
    input logic [63:0]                                              wbs_best_arr_rdata1
);

    localparam WBS_ADDR_MASK        = 32'hFFFF_0000;
    localparam WBS_MODE_ADDR        = 32'h3000_0000;
    localparam WBS_DEBUG_ADDR       = 32'h3000_0004;
    localparam WBS_DONE_ADDR        = 32'h3000_0008;
    localparam WBS_FSM_START_ADDR   = 32'h3000_000C;
    localparam WBS_FSM_DONE_ADDR    = 32'h3000_0010;
    localparam WBS_LOAD_DONE_ADDR   = 32'h3000_0014;
    localparam WBS_SEND_DONE_ADDR   = 32'h3000_0018;
    localparam WBS_CFG_DONE_ADDR    = 32'h3000_001C;
    localparam WBS_USRCLK_SEL_ADDR  = 32'h3000_0020;
    localparam WBS_QUERY_ADDR       = 32'h3001_0000;
    localparam WBS_LEAF_ADDR        = 32'h3002_0000;
    localparam WBS_BEST_ADDR        = 32'h3003_0000;
    localparam WBS_NODE_ADDR        = 32'h3004_0000;

    typedef enum {  Idle,
                    ReadMem,
                    RegMemRead,
                    Ack                    
    } stateCoding_t;

    (* fsm_encoding = "one_hot" *) stateCoding_t currState;
    // stateCoding_t currState;
    stateCoding_t nextState;

    logic wbs_input_reg_en;
    logic wbs_valid;
    logic wbs_valid_q;
    logic wbs_we_i_q;
    logic [3:0] wbs_sel_i_q;
    logic [31:0] wbs_dat_i_q;
    logic [31:0] wbs_adr_i_q;
    logic [31:0] wbs_dat_i_lower_q;
    logic wbs_ack_o_q;
    logic wbs_ack_o_d;
    logic [31:0] wbs_dat_o_q;
    logic [31:0] wbs_dat_o_d;
    logic wbs_dat_o_d_valid;
    logic wbs_fsm_done;
    logic wbs_load_done;
    logic wbs_send_done;

    assign wbs_valid = wbs_cyc_i & wbs_stb_i;
    assign wbs_ack_o = wbs_ack_o_q;
    assign wbs_dat_o = wbs_dat_o_q;

    // CONTROLLER

    always_ff @(posedge wb_clk_i or negedge wb_rst_n_i) begin
        if (~wb_rst_n_i) begin
            currState <= Idle;
        end else begin
            currState <= nextState;
        end
    end

    always_comb begin
        nextState = currState;
        wbs_input_reg_en = 1'b0;
        wbs_ack_o_d = 1'b0;
        wbs_dat_o_d = '0;
        wbs_dat_o_d_valid = 1'b0;

        wbs_qp_mem_csb0 = 1'b1;
        wbs_qp_mem_web0 = 1'b1;
        wbs_qp_mem_addr0 = '0;
        wbs_qp_mem_wpatch0 = '0;

        wbs_leaf_mem_csb0 = '1;
        wbs_leaf_mem_web0 = '1;
        wbs_leaf_mem_addr0 = '0;
        wbs_leaf_mem_wleaf0 = '0;

        wbs_best_arr_csb1 = 1'b1;
        wbs_best_arr_addr1 = '0;

        wbs_node_mem_we = 1'b0;
        wbs_node_mem_rd = 1'b0;
        wbs_node_mem_addr = '0;
        wbs_node_mem_wdata = '0;


        unique case (currState)
            Idle: begin
                if (wbs_valid) begin
                    wbs_input_reg_en = 1'b1;
                    if (wbs_we_i) begin
                        nextState = Ack;
                        wbs_ack_o_d = 1'b1;
                    end else begin
                        nextState = ReadMem;
                    end
                end
            end

            ReadMem: begin
                nextState = RegMemRead;
                if ((wbs_adr_i_q & WBS_ADDR_MASK) == WBS_QUERY_ADDR) begin
                    wbs_qp_mem_csb0 = 1'b0;
                    wbs_qp_mem_web0 = 1'b1;
                    // bit 1:0 are ignored as wbs_adr is byte-addressable
                    // bit 2 determines which 32bit it is accessing of the 55 bit query data
                    wbs_qp_mem_addr0 = wbs_adr_i_q[3+:$clog2(NUM_QUERYS)];
                end
                
                else if ((wbs_adr_i_q & WBS_ADDR_MASK) == WBS_LEAF_ADDR) begin
                    // bit 2 determines which 32bit it is accessing of the 64 bit leaf mem data
                    // bit 5:3 is the patch index within a leaf
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
                    // bit 2 determines which 32bit it is accessing of the 64 bit best array data
                    wbs_best_arr_addr1 = wbs_adr_i_q[10:3];
                end
            end

            RegMemRead: begin
                nextState = Ack;
                wbs_ack_o_d = 1'b1;
                wbs_dat_o_d_valid = 1'b1;
                if ((wbs_adr_i_q & WBS_ADDR_MASK) == WBS_QUERY_ADDR)
                    wbs_dat_o_d = wbs_adr_i_q[2] ?{9'b0, wbs_qp_mem_rpatch0[54:32]} :wbs_qp_mem_rpatch0[31:0];
                else if ((wbs_adr_i_q & WBS_ADDR_MASK) == WBS_LEAF_ADDR)
                    wbs_dat_o_d = wbs_adr_i_q[2] ?wbs_leaf_mem_rleaf0[wbs_adr_i_q[5:3]][63:32] :wbs_leaf_mem_rleaf0[wbs_adr_i_q[5:3]][31:0];

                else if ((wbs_adr_i_q & WBS_ADDR_MASK) == WBS_NODE_ADDR)
                    wbs_dat_o_d = {10'd0, wbs_node_mem_rdata};
                else if ((wbs_adr_i_q & WBS_ADDR_MASK) == WBS_BEST_ADDR)
                    wbs_dat_o_d = wbs_adr_i_q[2] ?wbs_best_arr_rdata1[63:32] :wbs_best_arr_rdata1[31:0];
                else if (wbs_adr_i_q == WBS_FSM_DONE_ADDR)
                    wbs_dat_o_d = {31'd0, wbs_fsm_done};
                else if (wbs_adr_i_q == WBS_LOAD_DONE_ADDR)
                    wbs_dat_o_d = {31'd0, wbs_load_done};
                else if (wbs_adr_i_q == WBS_SEND_DONE_ADDR)
                    wbs_dat_o_d = {31'd0, wbs_send_done};
            end

            Ack: begin
                nextState = Idle;
                if (wbs_we_i_q & wbs_adr_i_q[2] & ((wbs_adr_i_q & WBS_ADDR_MASK) == WBS_QUERY_ADDR)) begin
                    wbs_qp_mem_csb0 = 1'b0;
                    wbs_qp_mem_web0 = 1'b0;
                    wbs_qp_mem_addr0 = wbs_adr_i_q[3+:$clog2(NUM_QUERYS)];
                    wbs_qp_mem_wpatch0 = {wbs_dat_i_q, wbs_dat_i_lower_q};
                end
                else if (wbs_we_i_q & wbs_adr_i_q[2] & ((wbs_adr_i_q & WBS_ADDR_MASK) == WBS_LEAF_ADDR)) begin
                    wbs_leaf_mem_csb0[wbs_adr_i_q[5:3]] = 1'b0;
                    wbs_leaf_mem_web0[wbs_adr_i_q[5:3]] = 1'b0;
                    wbs_leaf_mem_addr0 = wbs_adr_i_q[11:6];
                    wbs_leaf_mem_wleaf0 = {wbs_dat_i_q, wbs_dat_i_lower_q};
                end
                else if (wbs_we_i_q & ((wbs_adr_i_q & WBS_ADDR_MASK) == WBS_NODE_ADDR)) begin //remove addr_i_q[2] condition
                    wbs_node_mem_we = 1'b1; //Write enabled
                    wbs_node_mem_addr = wbs_adr_i_q[7:2];
                    wbs_node_mem_wdata = wbs_dat_i_q[21:0];
                end
            end
        endcase
    end


    // input registers
    always_ff @(posedge wb_clk_i, negedge wb_rst_n_i) begin
        if (~wb_rst_n_i) wbs_valid_q <= '0;
        else begin
            wbs_valid_q <= wbs_valid;
        end
    end

    always_ff @(posedge wb_clk_i, negedge wb_rst_n_i) begin
        if (~wb_rst_n_i) begin
            wbs_we_i_q <= '0;
            wbs_sel_i_q <= '0;
            wbs_dat_i_q <= '0;
            wbs_adr_i_q <= '0;
        end else if (wbs_input_reg_en) begin
            wbs_we_i_q <= wbs_we_i;
            wbs_sel_i_q <= wbs_sel_i;
            wbs_dat_i_q <= wbs_dat_i;
            wbs_adr_i_q <= wbs_adr_i;
        end
    end

    always_ff @(posedge wb_clk_i, negedge wb_rst_n_i) begin
        if (~wb_rst_n_i) begin
            wbs_dat_i_lower_q <= '0;
        end else begin
            wbs_dat_i_lower_q <= wbs_dat_i_q;
        end
    end

    // output registers
    always_ff @(posedge wb_clk_i, negedge wb_rst_n_i) begin
        if (~wb_rst_n_i) wbs_ack_o_q <= '0;
        else begin
            wbs_ack_o_q <= wbs_ack_o_d;
        end
    end

    always_ff @(posedge wb_clk_i, negedge wb_rst_n_i) begin
        if (~wb_rst_n_i) wbs_dat_o_q <= '0;
        else if (wbs_dat_o_d_valid) begin
            wbs_dat_o_q <= wbs_dat_o_d;
        end
    end


    // Wishbone mapped accelerator control registers
    
    // if 1, makes the entire chip use the wishbone clock and reset
    always_ff @(posedge wb_clk_i, negedge wb_rst_n_i) begin
        if (~wb_rst_n_i) wbs_mode <= '0;
        else if (wbs_valid_q & wbs_we_i_q & (wbs_adr_i_q == WBS_MODE_ADDR)) begin
            wbs_mode <= wbs_dat_i_q[0];
        end
    end

    // if 1, occupies all memory's control
    always_ff @(posedge wb_clk_i, negedge wb_rst_n_i) begin
        if (~wb_rst_n_i) wbs_debug <= '0;
        else if (wbs_valid_q & wbs_we_i_q & (wbs_adr_i_q == WBS_DEBUG_ADDR)) begin
            wbs_debug <= wbs_dat_i_q[0];
        end
    end

    // caravel debugging only
    // if 1, RISC-V done instructions
    always_ff @(posedge wb_clk_i, negedge wb_rst_n_i) begin
        if (~wb_rst_n_i) wbs_done <= '0;
        else if (wbs_valid_q & wbs_we_i_q & (wbs_adr_i_q == WBS_DONE_ADDR)) begin
            wbs_done <= wbs_dat_i_q[0];
        end
    end

    // if 1, FSM start pulse
    always_ff @(posedge wb_clk_i, negedge wb_rst_n_i) begin
        if (~wb_rst_n_i) wbs_fsm_start <= '0;
        else if (wbs_valid_q & wbs_we_i_q & (wbs_adr_i_q == WBS_FSM_START_ADDR))
            wbs_fsm_start <= 1'b1;
        else
            wbs_fsm_start <= 1'b0;
    end

    // if 1, FSM is done
    always_ff @(posedge wb_clk_i, negedge wb_rst_n_i) begin
        if (~wb_rst_n_i) wbs_fsm_done <= '0;
        else if (wbs_valid_q & wbs_we_i_q & (wbs_adr_i_q == WBS_FSM_DONE_ADDR))
            wbs_fsm_done <= 1'b0;
        else if (acc_fsm_done)
            wbs_fsm_done <= 1'b1;
    end

    // if 1, load data structure is done
    always_ff @(posedge wb_clk_i, negedge wb_rst_n_i) begin
        if (~wb_rst_n_i) wbs_load_done <= '0;
        else if (wbs_valid_q & wbs_we_i_q & (wbs_adr_i_q == WBS_LOAD_DONE_ADDR))
            wbs_load_done <= 1'b0;
        else if (acc_load_done)
            wbs_load_done <= 1'b1;
    end

    // if 1, send best array is done
    always_ff @(posedge wb_clk_i, negedge wb_rst_n_i) begin
        if (~wb_rst_n_i) wbs_send_done <= '0;
        else if (wbs_valid_q & wbs_we_i_q & (wbs_adr_i_q == WBS_SEND_DONE_ADDR))
            wbs_send_done <= 1'b0;
        else if (acc_send_done)
            wbs_send_done <= 1'b1;
    end

    // if 1, IO pad configuration is done
    always_ff @(posedge wb_clk_i, negedge wb_rst_n_i) begin
        if (~wb_rst_n_i) wbs_cfg_done <= '0;
        else if (wbs_valid_q & wbs_we_i_q & (wbs_adr_i_q == WBS_CFG_DONE_ADDR))
            wbs_cfg_done <= wbs_dat_i_q[0];
    end

    // if 1, selects user_clock2, else selects io_clk
    always_ff @(posedge wb_clk_i, negedge wb_rst_n_i) begin
        if (~wb_rst_n_i) wbs_usrclk_sel <= '0;
        else if (wbs_valid_q & wbs_we_i_q & (wbs_adr_i_q == WBS_USRCLK_SEL_ADDR))
            wbs_usrclk_sel <= wbs_dat_i_q[0];
    end

endmodule
