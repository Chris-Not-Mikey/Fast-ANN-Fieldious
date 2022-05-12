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
    input  logic wb_rst_i,
    input  logic wbs_stb_i,
    input  logic wbs_cyc_i,
    input  logic wbs_we_i,
    input  logic [3:0] wbs_sel_i,
    input  logic [31:0] wbs_dat_i,
    input  logic [31:0] wbs_adr_i,
    output logic wbs_ack_o,
    output logic [31:0] wbs_dat_o,

    output logic wbs_mode,
    output logic wbs_debug,

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

    output logic                                                    wbs_node_mem_web,
    output logic [31:0]                                             wbs_node_mem_addr,
    output logic [31:0]                                             wbs_node_mem_wdata,
    input logic [31:0]                                              wbs_node_mem_rdata 


    


);

    localparam WBS_ADDR_MASK        = 32'hFF00_0000;
    localparam WBS_MODE_ADDR        = 32'h3000_0000;
    localparam WBS_DEBUG_ADDR       = 32'h3000_0001;
    localparam WBS_QUERY_ADDR       = 32'h3100_0000;
    localparam WBS_LEAF_ADDR        = 32'h3200_0000;
    localparam WBS_BEST_ADDR        = 32'h3300_0000;
    localparam WBS_NODE_ADDR        = 32'h3400_0000;

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

    assign wbs_valid = wbs_cyc_i & wbs_stb_i;
    assign wbs_ack_o = wbs_ack_o_q;
    assign wbs_dat_o = wbs_dat_o_q;

    // CONTROLLER

    always_ff @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
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


        wbs_node_mem_web = 1'b0;
        wbs_node_mem_addr = '0;
        wbs_node_mem_wdata = '0;
       // wbs_node_mem_rdata = '0;


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
                    // the last bit determines which 32bit it is accessing of the 55 bit query data
                    wbs_qp_mem_addr0 = wbs_adr_i_q[$clog2(NUM_QUERYS):1];
                end
                
                else if ((wbs_adr_i_q & WBS_ADDR_MASK) == WBS_LEAF_ADDR) begin
                    // bit 0 is because each patch is 64 bit
                    // bit 3:1 is the patch index within a leaf
                    wbs_leaf_mem_csb0[wbs_adr_i_q[3:1]] = 1'b0;
                    wbs_leaf_mem_web0[wbs_adr_i_q[3:1]] = 1'b1;
                    wbs_leaf_mem_addr0 = wbs_adr_i_q[9:4];
                end

                else if ((wbs_adr_i_q & WBS_ADDR_MASK) == WBS_NODE_ADDR) begin
                    wbs_node_mem_web = 1'b0; //Write disable, hence read enabled
                    wbs_node_mem_addr = wbs_adr_i_q;
                    
                end
            end

            RegMemRead: begin
                nextState = Ack;
                wbs_ack_o_d = 1'b1;
                wbs_dat_o_d_valid = 1'b1;
                if ((wbs_adr_i_q & WBS_ADDR_MASK) == WBS_QUERY_ADDR)
                    wbs_dat_o_d = wbs_adr_i_q[0] ?{9'b0, wbs_qp_mem_rpatch0[54:32]} :wbs_qp_mem_rpatch0[31:0];
                else if ((wbs_adr_i_q & WBS_ADDR_MASK) == WBS_LEAF_ADDR)
                    wbs_dat_o_d = wbs_adr_i_q[0] ?wbs_leaf_mem_rleaf0[wbs_adr_i_q[3:1]][63:32] :wbs_leaf_mem_rleaf0[wbs_adr_i_q[3:1]][31:0];

                else if ((wbs_adr_i_q & WBS_ADDR_MASK) == WBS_NODE_ADDR)
                    wbs_dat_o_d = wbs_node_mem_rdata;
                 
            end

            Ack: begin
                nextState = Idle;
                if (wbs_we_i_q & wbs_adr_i_q[0] & ((wbs_adr_i_q & WBS_ADDR_MASK) == WBS_QUERY_ADDR)) begin
                    wbs_qp_mem_csb0 = 1'b0;
                    wbs_qp_mem_web0 = 1'b0;
                    wbs_qp_mem_addr0 = wbs_adr_i_q[$clog2(NUM_QUERYS):1];
                    wbs_qp_mem_wpatch0 = {wbs_dat_i_q, wbs_dat_i_lower_q};
                end
                else if (wbs_we_i_q & wbs_adr_i_q[0] & ((wbs_adr_i_q & WBS_ADDR_MASK) == WBS_LEAF_ADDR)) begin
                    wbs_leaf_mem_csb0[wbs_adr_i_q[3:1]] = 1'b0;
                    wbs_leaf_mem_web0[wbs_adr_i_q[3:1]] = 1'b0;
                    wbs_leaf_mem_addr0 = wbs_adr_i_q[9:4];
                    wbs_leaf_mem_wleaf0 = {wbs_dat_i_q, wbs_dat_i_lower_q};
                end
                else if (wbs_we_i_q & wbs_adr_i_q[0] & ((wbs_adr_i_q & WBS_ADDR_MASK) == WBS_NODE_ADDR)) begin
                    wbs_node_mem_web = 1'b1; //Write enabled
                    wbs_node_mem_wdata = wbs_dat_i_q;


                    
                end
            end
        endcase
    end


    // input registers
    always_ff @(posedge wb_clk_i, posedge wb_rst_i) begin
        if (wb_rst_i) wbs_valid_q <= '0;
        else begin
            wbs_valid_q <= wbs_valid;
        end
    end

    always_ff @(posedge wb_clk_i, posedge wb_rst_i) begin
        if (wb_rst_i) begin
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

    always_ff @(posedge wb_clk_i, posedge wb_rst_i) begin
        if (wb_rst_i) begin
            wbs_dat_i_lower_q <= '0;
        end else begin
            wbs_dat_i_lower_q <= wbs_dat_i_q;
        end
    end

    // output registers
    always_ff @(posedge wb_clk_i, posedge wb_rst_i) begin
        if (wb_rst_i) wbs_ack_o_q <= '0;
        else begin
            wbs_ack_o_q <= wbs_ack_o_d;
        end
    end

    always_ff @(posedge wb_clk_i, posedge wb_rst_i) begin
        if (wb_rst_i) wbs_dat_o_q <= '0;
        else if (wbs_dat_o_d_valid) begin
            wbs_dat_o_q <= wbs_dat_o_d;
        end
    end


    // Wishbone mapped accelerator control registers
    
    // if 1, makes the entire chip use the wishbone clock and reset
    always_ff @(posedge wb_clk_i, posedge wb_rst_i) begin
        if (wb_rst_i) wbs_mode <= '0;
        else if (wbs_valid_q & wbs_we_i_q & (wbs_adr_i_q == WBS_MODE_ADDR)) begin
            wbs_mode <= wbs_dat_i_q[0];
        end
    end

    // if 1, occupies all memory's control
    always_ff @(posedge wb_clk_i, posedge wb_rst_i) begin
        if (wb_rst_i) wbs_debug <= '0;
        else if (wbs_valid_q & wbs_we_i_q & (wbs_adr_i_q == WBS_DEBUG_ADDR)) begin
            wbs_debug <= wbs_dat_i_q[0];
        end
    end


endmodule
