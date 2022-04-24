module MainFSM #(
    parameter DATA_WIDTH = 11,
    parameter LEAF_SIZE = 8,
    parameter PATCH_SIZE = 5,
    parameter ROW_SIZE = 26,
    parameter COL_SIZE = 19,
    parameter NUM_QUERYS = ROW_SIZE * COL_SIZE,
    parameter K = 4,
    parameter NUM_LEAVES = 64,
    parameter NUM_NODES = NUM_LEAVES - 1,
    parameter BLOCKING = 4,
    parameter NUM_OUTER_BLOCK = (ROW_SIZE + BLOCKING - 1) / BLOCKING, // ceiling(ROW_SIZE/BLOCKING)
    parameter LAST_BLOCK_REMAINDER = ROW_SIZE % BLOCKING,
    parameter NUM_LAST_BLOCK = (LAST_BLOCK_REMAINDER==0) ?BLOCKING :LAST_BLOCK_REMAINDER,
    parameter LEAF_ADDRW = $clog2(NUM_LEAVES)
)
(
    input                                                           clk,
    input                                                           rst_n,
    input logic                                                     load_kdtree,
    input logic                                                     fsm_start,
    output logic                                                    fsm_done,
    input logic                                                     send_best_arr,

    input logic                                                     agg_receiver_enq,
    output logic                                                    agg_receiver_full_n,
    output logic                                                    agg_change_fetch_width,
    output logic [2:0]                                              agg_input_fetch_width,

    output logic                                                    int_node_fsm_enable,
    output logic                                                    int_node_patch_en,
    input logic [LEAF_ADDRW-1:0]                                    int_node_leaf_index,

    output logic                                                    qp_mem_csb0,
    output logic                                                    qp_mem_web0,
    output logic [$clog2(NUM_QUERYS)-1:0]                           qp_mem_addr0,
    output logic                                                    qp_mem_csb1,
    output logic [$clog2(NUM_QUERYS)-1:0]                           qp_mem_addr1,
    input logic [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]                   qp_mem_rpatch1,

    output logic [LEAF_SIZE-1:0]                                    leaf_mem_csb0,
    output logic [LEAF_SIZE-1:0]                                    leaf_mem_web0,
    output logic [LEAF_ADDRW-1:0]                                   leaf_mem_addr0,
    output logic                                                    leaf_mem_csb1,
    output logic [LEAF_ADDRW-1:0]                                   leaf_mem_addr1,

    output logic [8:0]                                              best_arr_addr0,
    output logic [K-1:0]                                            best_arr_csb1,
    output logic [8:0]                                              best_arr_addr1,

    output logic                                                    out_fifo_wenq,
    input logic                                                     out_fifo_wfull_n,

    output logic                                                    k0_query_valid,
    output logic                                                    k0_query_first_in,
    output logic                                                    k0_query_last_in,
    output logic signed [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]           k0_query_patch,

    input logic                                                     sl0_valid_out,
    input logic [LEAF_ADDRW-1:0]                                    best_arr_wleaf_idx_0 [K-1:0]
);


    typedef enum {  Idle,
                    LoadInternalNodes,
                    LoadLeaves,
                    LoadQuerys,
                    ExactFstRow,
                    ExactFstRowLast,
                    ExactFstRowDone,
                    SLPR0,
                    SLPR1,
                    SLPR2,
                    SLPR3,
                    SLPR4,
                    SLPR5,
                    SLPR6,
                    SLPR7,
                    SLPR8,
                    SLPR9,
                    SendBestIdx
    } stateCoding_t;

    (* fsm_encoding = "one_hot" *) stateCoding_t currState;
    // stateCoding_t currState;
    stateCoding_t nextState;

    logic [LEAF_SIZE-1:0] leaf_mem_wr_sel;
    logic counter_en;
    logic counter_done;
    logic [15:0] counter_in;
    logic [15:0] counter;
    logic [$clog2(NUM_QUERYS)-1:0] qp_mem_rd_addr;
    logic qp_mem_rd_addr_rst;
    logic qp_mem_rd_addr_set;
    logic qp_mem_rd_addr_incr_col;
    logic qp_mem_rd_addr_incr_row;
    logic qp_mem_rd_addr_incr_row_special;
    logic [8:0] best_arr_addr_r;
    logic best_arr_addr_rst;
    logic signed [PATCH_SIZE-1:0] [DATA_WIDTH-1:0] cur_query_patch;
    logic qp_mem_rvalid1;
    logic [LEAF_ADDRW-1:0] prop_leaf_idx_r [BLOCKING-1:0] [K-1:0];
    logic [1:0] prop_leaf_wr_idx;
    logic prop_leaf_wr_rotate;
    logic [1:0] row_blocking_cnt;
    logic row_blocking_cnt_incr;
    logic [$clog2(NUM_OUTER_BLOCK)-1:0] row_outer_cnt;
    logic row_outer_cnt_incr;
    logic [$clog2(COL_SIZE)-1:0] col_query_cnt;
    logic col_query_cnt_incr;


    // CONTROLLER

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            currState <= Idle;
        end else begin
            currState <= nextState;
        end
    end

    always_comb begin
        nextState = currState;

        fsm_done = '0;

        agg_change_fetch_width = '0;
        agg_input_fetch_width = '0;
        agg_receiver_full_n = '0;
        int_node_fsm_enable = '0;
        int_node_patch_en = '0;
        qp_mem_csb0 = 1'b1;
        qp_mem_web0 = 1'b1;
        qp_mem_addr0 = '0;
        qp_mem_csb1 = 1'b1;
        qp_mem_addr1 = '0;
        leaf_mem_csb0 = '1;
        leaf_mem_web0 = '1;
        leaf_mem_addr0 = '0;
        leaf_mem_csb1 = 1'b1;
        leaf_mem_addr1 = '0;
        k0_query_valid = '0;
        k0_query_first_in = '0;
        k0_query_last_in = '0;
        k0_query_patch = '0;
        best_arr_csb1 = {K{1'b1}};
        best_arr_addr1 = '0;
        
        counter_en = '0;
        counter_in = '0;
        qp_mem_rvalid1 = '0;
        qp_mem_rd_addr_rst = '0;
        qp_mem_rd_addr_set = '0;
        qp_mem_rd_addr_incr_col = '0;
        qp_mem_rd_addr_incr_row = '0;
        qp_mem_rd_addr_incr_row_special = '0;
        best_arr_addr_rst = '0;
        col_query_cnt_incr = '0;
        prop_leaf_wr_rotate = '0;
        row_blocking_cnt_incr = '0;
        row_outer_cnt_incr = '0;

        unique case (currState)
            Idle: begin
                if (load_kdtree) begin
                    nextState = LoadInternalNodes;
                    agg_change_fetch_width = 1'b1;
                    agg_input_fetch_width = 3'd1;
                end
                
                if (fsm_start) begin
                    nextState = ExactFstRow;
                    counter_en = 1'b1;
                    counter_in = NUM_LEAVES - 1;
                    leaf_mem_csb0 = '0;
                    leaf_mem_web0 = '1;
                    leaf_mem_addr0 = counter;
                    qp_mem_csb1 = 1'b0;
                    qp_mem_addr1 = qp_mem_rd_addr;
                    row_outer_cnt_incr = 1'b1;
                end

                if (send_best_arr)
                    nextState = SendBestIdx;
            end

            LoadInternalNodes: begin
                counter_in = NUM_NODES - 1;
                agg_receiver_full_n = 1'b1;
                int_node_fsm_enable = 1'b1;
                if (agg_receiver_enq) begin
                    counter_en = 1'b1;
                    if (counter_done) begin
                        nextState = LoadLeaves;
                        agg_change_fetch_width = 1'b1;
                        agg_input_fetch_width = 3'd5;
                    end
                end
            end

            LoadLeaves: begin
                counter_in = NUM_LEAVES * LEAF_SIZE - 1;
                agg_receiver_full_n = 1'b1;
                if (agg_receiver_enq) begin
                    counter_en = 1'b1;
                    leaf_mem_csb0 = leaf_mem_wr_sel;
                    leaf_mem_web0 = leaf_mem_wr_sel;
                    leaf_mem_addr0 = counter[LEAF_ADDRW+3-1:3];
                    if (counter_done) begin
                        nextState = LoadQuerys;
                        agg_change_fetch_width = 1'b1;
                        agg_input_fetch_width = 3'd4;
                    end
                end
            end

            LoadQuerys: begin
                counter_in = NUM_QUERYS - 1;
                agg_receiver_full_n = 1'b1;
                if (agg_receiver_enq) begin
                    counter_en = 1'b1;
                    qp_mem_csb0 = 1'b0;
                    qp_mem_web0 = 1'b0;
                    qp_mem_addr0 = counter;
                    if (counter_done) begin
                        nextState = Idle;
                    end
                end
            end

            // process 3 queries
            ExactFstRow: begin
                counter_en = 1'b1;
                counter_in = NUM_LEAVES - 1;
                k0_query_valid = 1'b1;
                k0_query_patch = cur_query_patch;
                leaf_mem_csb0 = '0;
                leaf_mem_web0 = '1;
                leaf_mem_addr0 = counter;
                prop_leaf_wr_rotate = 1'b1;

                if (counter_done) begin
                    if ((prop_leaf_wr_idx == BLOCKING - 1) || 
                        ((row_outer_cnt == NUM_OUTER_BLOCK) && (prop_leaf_wr_idx == NUM_LAST_BLOCK - 1)))
                        nextState = ExactFstRowLast;
                end

                if (counter == 1) begin
                    k0_query_first_in = 1'b1;
                    qp_mem_rvalid1 = 1'b1;
                    k0_query_patch = qp_mem_rpatch1;
                end

                if (counter == 0) begin
                    qp_mem_csb1 = 1'b0;
                    qp_mem_addr1 = qp_mem_rd_addr;
                    k0_query_last_in = 1'b1;
                end

                if (counter_done) begin
                    if ((row_outer_cnt == NUM_OUTER_BLOCK) && (prop_leaf_wr_idx == NUM_LAST_BLOCK - 1))
                        qp_mem_rd_addr_incr_row_special = 1'b1;
                    else if (prop_leaf_wr_idx == BLOCKING - 1)
                        qp_mem_rd_addr_incr_row = 1'b1;
                    else
                        qp_mem_rd_addr_incr_col = 1'b1;
                end
            end

            ExactFstRowLast: begin
                nextState = ExactFstRowDone;
                k0_query_valid = 1'b1;
                k0_query_last_in = 1'b1;
                k0_query_patch = cur_query_patch;
            end

            ExactFstRowDone: begin
                prop_leaf_wr_rotate = 1'b1;
                if (sl0_valid_out) begin
                    nextState = SLPR0;
                    col_query_cnt_incr = 1'b1;
                    // read query for the first SearchLeaf
                    qp_mem_csb1 = 1'b0;
                    qp_mem_addr1 = qp_mem_rd_addr;
                end
            end

            SLPR0: begin
                counter_in = 1;
                counter_en = 1'b1;
                
                if (counter == 0) begin
                    int_node_patch_en = 1'b1;
                end

                if (counter_done) begin
                    nextState = SLPR1;
                end
            end
            
            // read prop 0
            // read the next query
            SLPR1: begin
                nextState = SLPR2;
                leaf_mem_csb0 = '0;
                leaf_mem_web0 = '1;
                leaf_mem_addr0 = prop_leaf_idx_r[row_blocking_cnt][0];

                qp_mem_csb1 = 1'b0;
                qp_mem_addr1 = qp_mem_rd_addr;
                qp_mem_rd_addr_incr_col = 1'b1;
            end

            // send prop 0 and query to l2_k0 with query_first
            // read prop 1
            SLPR2: begin
                nextState = SLPR3;

                k0_query_first_in = 1'b1;
                k0_query_valid = 1'b1;
                k0_query_patch = qp_mem_rpatch1;
                
                leaf_mem_csb0 = '0;
                leaf_mem_web0 = '1;
                leaf_mem_addr0 = prop_leaf_idx_r[row_blocking_cnt][1];
                
                // store the query for reuse
                qp_mem_rvalid1 = 1'b1;
            end

            // send prop 1 and query to l2_k0
            // read prop 2
            // read the next query for SearchLeaf
            SLPR3: begin
                nextState = SLPR4;
                k0_query_valid = 1'b1;
                k0_query_patch = cur_query_patch;
                
                leaf_mem_csb0 = '0;
                leaf_mem_web0 = '1;
                leaf_mem_addr0 = prop_leaf_idx_r[row_blocking_cnt][2];

                if (~((row_outer_cnt == NUM_OUTER_BLOCK) && (row_blocking_cnt == NUM_LAST_BLOCK - 1))) begin
                    qp_mem_csb1 = 1'b0;
                    qp_mem_addr1 = qp_mem_rd_addr;
                end
            end

            // send prop 2 and query to l2_k0
            // read prop 3
            // send the next query to SearchLeaf
            SLPR4: begin
                nextState = SLPR5;
                k0_query_valid = 1'b1;
                k0_query_patch = cur_query_patch;
                
                leaf_mem_csb0 = '0;
                leaf_mem_web0 = '1;
                leaf_mem_addr0 = prop_leaf_idx_r[row_blocking_cnt][3];
                
                if (~((row_outer_cnt == NUM_OUTER_BLOCK) && (row_blocking_cnt == NUM_LAST_BLOCK - 1)))
                    int_node_patch_en = 1'b1;
            end

            // send prop 3 and query to l2_k0
            // read SearchLeaf result
            SLPR5: begin
                if ((col_query_cnt == COL_SIZE - 1) && (row_blocking_cnt == BLOCKING - 1))
                    nextState = SLPR7;
                else begin
                    if ((row_outer_cnt == NUM_OUTER_BLOCK) && (row_blocking_cnt == NUM_LAST_BLOCK - 1))
                        nextState = SLPR9;
                    else
                        nextState = SLPR6;
                end
                k0_query_valid = 1'b1;
                k0_query_patch = cur_query_patch;
                
                leaf_mem_csb0 = '0;
                leaf_mem_web0 = '1;
                leaf_mem_addr0 = int_node_leaf_index;
                
                row_blocking_cnt_incr = 1'b1;
                if (row_blocking_cnt == BLOCKING - 1) begin
                    col_query_cnt_incr = 1'b1;
                end
            end

            // send SearchLeaf result and query to l2_k0 with query_last
            // read prop 0
            // read the next query
            SLPR6: begin
                nextState = SLPR2;
                k0_query_last_in = 1'b1;
                k0_query_valid = 1'b1;
                k0_query_patch = cur_query_patch;

                leaf_mem_csb0 = '0;
                leaf_mem_web0 = '1;
                leaf_mem_addr0 = prop_leaf_idx_r[row_blocking_cnt][0];

                qp_mem_csb1 = 1'b0;
                qp_mem_addr1 = qp_mem_rd_addr;
                // the next query can be in the first row or in the next row or at the right 
                if ((col_query_cnt == COL_SIZE - 1) && (row_blocking_cnt == BLOCKING - 1))
                    qp_mem_rd_addr_set = 1'b1;
                if (row_blocking_cnt == BLOCKING - 1)
                    qp_mem_rd_addr_incr_row = 1'b1;
                else
                    qp_mem_rd_addr_incr_col = 1'b1;
            end

            // send SearchLeaf result and query to l2_k0 with query_last
            // finished all rows and incr outer count
            SLPR7: begin
                row_outer_cnt_incr = 1'b1;
                if (row_outer_cnt == NUM_OUTER_BLOCK) begin
                    nextState = SLPR8;
                end
                else begin
                    nextState = ExactFstRow;
                    counter_en = 1'b1;
                    counter_in = NUM_LEAVES - 1;
                    leaf_mem_csb0 = '0;
                    leaf_mem_web0 = '1;
                    leaf_mem_addr0 = counter;
                    qp_mem_csb1 = 1'b0;
                    qp_mem_addr1 = qp_mem_rd_addr;
                end

                k0_query_last_in = 1'b1;
                k0_query_valid = 1'b1;
                k0_query_patch = cur_query_patch;
            end

            // wait 12 more cycles for the pipeline to flush
            // 5 cycles for l2_k0
            // 1 cycles for running min
            // 6 cycles for sorter
            SLPR8: begin
                counter_en = 1'b1;
                counter_in = 11;
                if (counter_done) begin
                    nextState = Idle;
                    fsm_done = 1'b1;
                    qp_mem_rd_addr_rst = 1'b1;
                    best_arr_addr_rst = 1'b1;
                end
            end

            // for the last blocking, we may need to insert dummy cycles
            // if the ROW_SIZE is not multiples of BLOCKING
            SLPR9: begin
                counter_en = 1'b1;
                counter_in = (BLOCKING - NUM_LAST_BLOCK) * 5;

                if (counter == 0) begin
                    k0_query_last_in = 1'b1;
                    k0_query_valid = 1'b1;
                    k0_query_patch = cur_query_patch;
                end

                if (counter < BLOCKING - NUM_LAST_BLOCK) begin
                    row_blocking_cnt_incr = 1'b1;
                end

                if (counter < BLOCKING - NUM_LAST_BLOCK - 1) begin
                    row_blocking_cnt_incr = 1'b1;
                    qp_mem_rd_addr_incr_col = 1'b1;
                end

                if (counter == BLOCKING - NUM_LAST_BLOCK) begin
                    qp_mem_rd_addr_incr_row = 1'b1;
                end

                // read next query for SearchLeaf
                if (counter == (BLOCKING - NUM_LAST_BLOCK) * 5 - 3) begin
                    qp_mem_csb1 = 1'b0;
                    qp_mem_addr1 = qp_mem_rd_addr;
                end

                // send to SearchLeaf
                if (counter == (BLOCKING - NUM_LAST_BLOCK) * 5 - 2) begin
                    int_node_patch_en = 1'b1;
                end

                if (counter_done) begin
                    col_query_cnt_incr = 1'b1;
                    if (col_query_cnt == COL_SIZE - 1) begin
                        nextState = SLPR8;
                        row_outer_cnt_incr = 1'b1;
                    end
                    else begin
                        nextState = SLPR2;
                        leaf_mem_csb0 = '0;
                        leaf_mem_web0 = '1;
                        leaf_mem_addr0 = prop_leaf_idx_r[0][0];

                        qp_mem_csb1 = 1'b0;
                        qp_mem_addr1 = qp_mem_rd_addr;
                        qp_mem_rd_addr_incr_col = 1'b1;
                    end
                end
            end

            // read out the best array
            SendBestIdx: begin
                counter_in = NUM_QUERYS - 1;
                if (~out_fifo_wenq & out_fifo_wfull_n) begin
                    counter_en = 1'b1;
                    // reads only the best
                    best_arr_csb1 = {{(K-1){1'b1}}, 1'b0};
                    best_arr_addr1 = counter;

                    if (counter_done)
                        nextState = Idle;
                end
            end

        endcase
    end



    // DATAPATH

    // binary to one-hot encoder
    always_comb begin
        leaf_mem_wr_sel = '1;
        leaf_mem_wr_sel[counter[2:0]] = 1'b0;
    end

    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n) counter <= '0;
        else if (counter_en) begin
            if (counter == counter_in)
                counter <= '0;
            else
                counter <= counter + 1'b1;
        end
    end
    assign counter_done = counter == counter_in;

    // ExactFstRow and SearchLeaf: used to read from the query patch memory
    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n | qp_mem_rd_addr_rst) qp_mem_rd_addr <= '0;
        else if (qp_mem_rd_addr_set) begin
            qp_mem_rd_addr <= row_outer_cnt * BLOCKING;
        end else if (qp_mem_rd_addr_incr_col) begin
            qp_mem_rd_addr <= qp_mem_rd_addr + 1'b1;
        end else if (qp_mem_rd_addr_incr_row) begin
            // we have gone BLOCKING right before going to the next row
            qp_mem_rd_addr <= qp_mem_rd_addr + ROW_SIZE - (BLOCKING - 1);
        end else if (qp_mem_rd_addr_incr_row_special) begin
            // when blocking is not multiples of 4
            // ExactFstRow needs this special increment
            qp_mem_rd_addr <= qp_mem_rd_addr + ROW_SIZE - (NUM_LAST_BLOCK - 1);
        end
    end

    // stores the next addr of best arrays
    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n | best_arr_addr_rst) best_arr_addr_r <= '0;
        else if (sl0_valid_out) begin
            best_arr_addr_r <= best_arr_addr_r + 1'b1;
        end
    end
    assign best_arr_addr0 = best_arr_addr_r;
    
    // used to store propagated leaves
    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            prop_leaf_wr_idx <= '0;
            for (int i=0; i<BLOCKING; i=i+1) begin
                prop_leaf_idx_r[i][0] <= '0;
                prop_leaf_idx_r[i][1] <= '0;
                prop_leaf_idx_r[i][2] <= '0;
                prop_leaf_idx_r[i][3] <= '0;
            end
        end
        else if (sl0_valid_out) begin
            if (((row_outer_cnt == NUM_OUTER_BLOCK) && (prop_leaf_wr_idx == NUM_LAST_BLOCK - 1))
                    || (prop_leaf_wr_idx == BLOCKING - 1) )
                prop_leaf_wr_idx <= '0;
            else
                prop_leaf_wr_idx <= prop_leaf_wr_idx + 1'b1;
            prop_leaf_idx_r[prop_leaf_wr_idx][0] <= best_arr_wleaf_idx_0[0];
            prop_leaf_idx_r[prop_leaf_wr_idx][1] <= best_arr_wleaf_idx_0[1];
            prop_leaf_idx_r[prop_leaf_wr_idx][2] <= best_arr_wleaf_idx_0[2];
            prop_leaf_idx_r[prop_leaf_wr_idx][3] <= best_arr_wleaf_idx_0[3];
        end
    end
    
    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n) col_query_cnt <= '0;
        else if ( col_query_cnt_incr) begin
            if ( col_query_cnt == COL_SIZE - 1)
                col_query_cnt <= '0;
            else
                col_query_cnt <= col_query_cnt + 1'b1;
        end
    end
    
    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n) row_blocking_cnt <= '0;
        else if (row_blocking_cnt_incr) begin
            if (row_blocking_cnt == BLOCKING - 1)
                row_blocking_cnt <= '0;
            else
                row_blocking_cnt <= row_blocking_cnt + 1'b1;
        end
    end

    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n) row_outer_cnt <= '0;
        else if (row_outer_cnt_incr) begin
            if (row_outer_cnt == NUM_OUTER_BLOCK)
                row_outer_cnt <= '0;
            else
                row_outer_cnt <= row_outer_cnt + 1'b1;
        end
    end
    
    // used to store and reuse the current query patch
    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n) cur_query_patch <= '0;
        else if (qp_mem_rvalid1) begin
            cur_query_patch <= qp_mem_rpatch1;
        end
    end

    // writes to out fifo after reading out from best arrays
    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n) out_fifo_wenq <= '0;
        else begin
            out_fifo_wenq <= ~(&best_arr_csb1);
        end
    end

endmodule