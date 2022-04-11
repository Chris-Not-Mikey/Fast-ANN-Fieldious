module MainFSM #(
    parameter DATA_WIDTH = 11,
    parameter LEAF_SIZE = 8,
    parameter PATCH_SIZE = 5,
    parameter NUM_LEAVES = 64,
    parameter ADDR_WIDTH = $clog2(NUM_LEAVES)
)
(
    input                                               clk,
    input                                               rst_n,
    input                                               fsm_start,

    output logic                                        leaf_mem_wen,
    output logic [ADDR_WIDTH-1:0]                       leaf_mem_wadr,
    output logic [PATCH_SIZE-1:0] [DATA_WIDTH-1:0]      leaf_mem_wdata [LEAF_SIZE-1:0],
    output logic                                        leaf_mem_ren,
    output logic [ADDR_WIDTH-1:0]                       leaf_mem_radr,
    output logic                                        k0_query_valid,
    output logic                                        rm_restart,
    output logic                                        s0_valid_in,
    input logic                                         s0_valid_out
);


    typedef enum {  Idle,
            ExactFstRow,
            ExactFstRowWait,
            SearchLeaf,
            ProcessRows
    } stateCoding_t;

    (* fsm_encoding = "one_hot" *) stateCoding_t currState;
    // stateCoding_t currState;
    stateCoding_t nextState;

    logic counter_en;
    logic counter_done;
    logic [15:0] counter_in;
    logic [15:0] counter;


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

        leaf_mem_wen = '0;
        leaf_mem_wadr = '0;
        for (int i=0; i<LEAF_SIZE; i=i+1) begin
            leaf_mem_wdata[i] = '0;
        end
        leaf_mem_ren = '0;
        leaf_mem_radr = '0;
        k0_query_valid = '0;
        rm_restart = '0;
        s0_valid_in = '0;
        
        counter_en = '0;
        counter_in = '0;

        unique case (currState)
            Idle: begin
                if (fsm_start) begin 
                    nextState = ExactFstRow;
                    counter_en = 1'b1;
                    counter_in = NUM_LEAVES - 1;
                    leaf_mem_ren = 1'b1;
                    leaf_mem_radr = counter;
                end
            end

            // per 1 query
            ExactFstRow: begin
                counter_en = 1'b1;
                counter_in = NUM_LEAVES;
                k0_query_valid = 1'b1;
                if (counter_done) begin
                    nextState = ExactFstRowWait;
                end
                else begin
                    leaf_mem_ren = 1'b1;
                    leaf_mem_radr = counter;
                end

                // latency of L2Kernel
                if (counter == 6) begin
                    rm_restart = 1'b1;
                end
            end

            ExactFstRowWait: begin
                counter_en = 1'b1;
                counter_in = 5; // latency of L2Kernel + RunningMin
                if (counter_done) begin
                    nextState = Idle;
                    s0_valid_in = 1'b1;
                end
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

endmodule