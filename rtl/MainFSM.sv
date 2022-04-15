module MainFSM #(
    parameter DATA_WIDTH = 11,
    parameter LEAF_SIZE = 8,
    parameter PATCH_SIZE = 5,
    parameter ROW_SIZE = 26,
    parameter K = 4,
    parameter NUM_LEAVES = 64,
    parameter ADDR_WIDTH = $clog2(NUM_LEAVES)
)
(
    input                                               clk,
    input                                               rst_n,
    input                                               fsm_start,

    output logic                                        leaf_mem_csb0,
    output logic                                        leaf_mem_web0,
    output logic [ADDR_WIDTH-1:0]                       leaf_mem_addr0,
    output logic [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]      leaf_mem_wleaf0 [LEAF_SIZE-1:0],
    output logic                                        leaf_mem_csb1,
    output logic [ADDR_WIDTH-1:0]                       leaf_mem_addr1,

    output logic [7:0]                                  best_arr_addr0,
    output logic                                        best_arr_csb1,
    output logic [7:0]                                  best_arr_addr1,
    output logic [8:0]                                  best_arr_rindices_1 [K-1:0],

    output logic                                        k0_query_valid,
    output logic                                        k0_query_first_in,
    output logic                                        k0_query_last_in,
    input logic                                         s0_valid_out
);


    typedef enum {  Idle,
                    ExactFstRow,
                    ExactFstRowLast,
                    SearchLeaf,
                    ProcessRowsInit,
                    ProcessRowsSearchLeaf,
                    ProcessRowsPropag1,
                    ProcessRowsPropag2,
                    ProcessRowsLast,
                    TBD
    } stateCoding_t;

    (* fsm_encoding = "one_hot" *) stateCoding_t currState;
    // stateCoding_t currState;
    stateCoding_t nextState;

    logic counter_en;
    logic counter_done;
    logic [15:0] counter_in;
    logic [15:0] counter;
    logic [6:0] query_cnt_write;
    logic [6:0] query_cnt_read;
    logic donefirstquery;
    logic donefirstquery_next;
    logic best_arr_cur_row;
    logic switch_bank;
    logic query_cnt_read_done;


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

        leaf_mem_csb0 = 1'b1;
        leaf_mem_web0 = 1'b1;
        leaf_mem_addr0 = '0;
        leaf_mem_csb1 = 1'b1;
        leaf_mem_addr1 = '0;
        for (int i=0; i<LEAF_SIZE; i=i+1) begin
            leaf_mem_wleaf0[i] = '0;
        end
        best_arr_csb1 = 1'b1;
        best_arr_addr1 = '0;
        k0_query_valid = '0;
        k0_query_first_in = '0;
        k0_query_last_in = '0;
        
        counter_en = '0;
        counter_in = '0;
        donefirstquery_next = '0;
        switch_bank = '0;
        query_cnt_read_done = '0;

        unique case (currState)
            Idle: begin
                if (fsm_start) begin 
                    nextState = ExactFstRow;
                    counter_en = 1'b1;
                    counter_in = NUM_LEAVES - 1;
                    leaf_mem_csb0 = 1'b0;
                    leaf_mem_web0 = 1'b1;
                    leaf_mem_addr0 = counter;
                end
            end

            // per 1 query
            ExactFstRow: begin
                counter_en = 1'b1;
                counter_in = NUM_LEAVES - 1;
                k0_query_valid = 1'b1;
                leaf_mem_csb0 = 1'b0;
                leaf_mem_web0 = 1'b1;
                leaf_mem_addr0 = counter;

                if ((query_cnt_write == ROW_SIZE - 1) && (counter_done)) begin
                    nextState = ExactFstRowLast;
                end

                if (counter_done) begin
                    donefirstquery_next = 1'b1;
                end

                if (counter == 1) begin
                    k0_query_first_in = 1'b1;
                end

                if ((counter == 0) && donefirstquery) begin
                    k0_query_last_in = 1'b1;
                end
            end

            ExactFstRowLast: begin
                nextState = ProcessRowsInit;
                k0_query_valid = 1'b1;
                k0_query_last_in = 1'b1;
            end

            ProcessRowsInit: begin
                if (s0_valid_out) begin
                    nextState = ProcessRowsPropag1;
                    // read SearchLeaf results
                    best_arr_csb1 = 1'b0;
                    best_arr_addr1 = {best_arr_cur_row, query_cnt_read};
                    // switch_bank = 1'b1;
                end
            end

            ProcessRowsPropag1: begin
                counter_en = 1'b1;
                counter_in = K - 1;
                if (counter_done) begin
                    if (query_cnt_read == ROW_SIZE - 1) begin
                        nextState = ProcessRowsLast;
                    end
                    else begin
                        nextState = ProcessRowsSearchLeaf;
                        query_cnt_read_done = 1'b1;
                    end
                end

                leaf_mem_csb0 = 1'b0;
                leaf_mem_web0 = 1'b1;
                // assumes the searchleaf stores leaf index here
                leaf_mem_addr0 = best_arr_rindices_1[0][ADDR_WIDTH+3-1:3];
                
                // read Propagation results
                best_arr_csb1 = 1'b0;
                // best_arr_addr1 = {best_arr_cur_row, query_cnt_read}; //testing only
                best_arr_addr1 = {~best_arr_cur_row, query_cnt_read};

                if (counter == 1) begin
                    k0_query_first_in = 1'b1;
                end
                if (counter >= 1) begin
                    k0_query_valid = 1'b1;
                end
            end

            ProcessRowsSearchLeaf: begin
                nextState = ProcessRowsPropag2;
                k0_query_valid = 1'b1;
                // read SearchLeaf results of the current query
                best_arr_csb1 = 1'b0;
                best_arr_addr1 = {best_arr_cur_row, query_cnt_read};
                
                // read the last propagated leaf of the previous query
                leaf_mem_csb0 = 1'b0;
                leaf_mem_web0 = 1'b1;
                // assumes the searchleaf stores leaf index here
                leaf_mem_addr0 = best_arr_rindices_1[0][ADDR_WIDTH+3-1:3];
            end

            ProcessRowsPropag2: begin
                counter_en = 1'b1;
                counter_in = K - 1;
                nextState = ProcessRowsPropag1;
                // read Propagation results
                best_arr_csb1 = 1'b0;
                // best_arr_addr1 = {best_arr_cur_row, query_cnt_read}; //testing only
                best_arr_addr1 = {~best_arr_cur_row, query_cnt_read};

                leaf_mem_csb0 = 1'b0;
                leaf_mem_web0 = 1'b1;
                // assumes the searchleaf stores leaf index here
                leaf_mem_addr0 = best_arr_rindices_1[0][ADDR_WIDTH+3-1:3];

                k0_query_last_in = 1'b1;
                k0_query_valid = 1'b1;
            end

            ProcessRowsLast: begin
                counter_en = 1'b1;
                counter_in = 'd1;
                if (counter_done) begin
                    nextState = Idle;
                    k0_query_last_in = 1'b1;
                end
                else begin
                    // read the last propagated leaf of the previous query
                    leaf_mem_csb0 = 1'b0;
                    leaf_mem_web0 = 1'b1;
                    // assumes the searchleaf stores leaf index here
                    leaf_mem_addr0 = best_arr_rindices_1[0][ADDR_WIDTH+3-1:3];
                end
                
                k0_query_valid = 1'b1;
            end

        endcase
    end



    // DATAPATH

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

    // used to store the sorted dist and indices in best arrays
    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n) query_cnt_write <= '0;
        else if (s0_valid_out) begin
            if (query_cnt_write == ROW_SIZE - 1)
                query_cnt_write <= '0;
            else
                query_cnt_write <= query_cnt_write + 1'b1;
        end
    end
    assign best_arr_addr0 = {best_arr_cur_row, query_cnt_write};
    
    // used to read the indices from the best arrays
    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n) query_cnt_read <= '0;
        else if (query_cnt_read_done) begin
            if (query_cnt_read == ROW_SIZE - 1)
                query_cnt_read <= '0;
            else
                query_cnt_read <= query_cnt_read + 1'b1;
        end
    end
    
    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n) donefirstquery <= '0;
        else if (donefirstquery_next) begin
            donefirstquery <= 1'b1;
        end
    end
    
    // used to select from the best arrays double buffer
    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n) best_arr_cur_row <= '0;
        else if (switch_bank) begin
            best_arr_cur_row <= ~best_arr_cur_row;
        end
    end

endmodule