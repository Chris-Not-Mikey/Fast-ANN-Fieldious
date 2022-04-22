`timescale 1 ns / 1 ps
module top_tb();
    parameter DATA_WIDTH = 11;
    parameter LEAF_SIZE = 8;
    parameter PATCH_SIZE = 5;
    parameter ROW_SIZE = 26;
    parameter COL_SIZE = 19;
    parameter NUM_QUERYS = ROW_SIZE * COL_SIZE;
    parameter NUM_LEAVES = 64;
    parameter NUM_NODES = NUM_LEAVES - 1;
    parameter BLOCKING = 4;
    parameter ADDR_WIDTH = $clog2(NUM_LEAVES);

    logic                                   clk;
    logic                                   rst_n;
    logic                                   fsm_start;
    logic                                   fsm_done;
    logic                                   send_best_arr;
    logic                                   load_kdtree;
    logic                                   io_clk;
    logic                                   io_rst_n;
    logic                                   in_fifo_wenq;
    logic [DATA_WIDTH-1:0]                  in_fifo_wdata;
    logic                                   in_fifo_wfull_n;
    logic                                   out_fifo_deq;
    logic [DATA_WIDTH-1:0]                  out_fifo_rdata;
    logic                                   out_fifo_rempty_n;

    top dut(
        .clk(clk),
        .rst_n(rst_n),

        .load_kdtree(load_kdtree),
        .fsm_start(fsm_start),
        .fsm_done(fsm_done),
        .send_best_arr(send_best_arr),

        .io_clk(io_clk),
        .io_rst_n(io_rst_n),
        .in_fifo_wenq(in_fifo_wenq),
        .in_fifo_wdata(in_fifo_wdata),
        .in_fifo_wfull_n(in_fifo_wfull_n),
        .out_fifo_deq(out_fifo_deq),
        .out_fifo_rdata(out_fifo_rdata),
        .out_fifo_rempty_n(out_fifo_rempty_n)
    );

    initial begin 
        clk = 0;
        forever begin
            #5 clk = ~clk;
        end 
    end

    initial begin 
        io_clk = 0;
        forever begin
            #10 io_clk = ~io_clk;
        end 
    end

    integer scan_file;
    integer expected_idx_data_file;
    integer int_nodes_data_file;
    integer leaves_data_file;
    integer query_data_file;
    reg [DATA_WIDTH-1:0] received_idx [NUM_QUERYS-1:0];
    reg [DATA_WIDTH-1:0] expected_idx [NUM_QUERYS-1:0];
    integer x;
    integer xi;
    integer y;
    integer addr;

    initial begin

        // $readmemh("leaves_mem_dummy0.txt", dut.leaf_mem_inst.loop_ram_patch_gen[0].ram_patch_inst.loop_depth_gen[0].loop_width_gen[0].genblk1.sram_macro.mem);
        // $readmemh("leaves_mem_dummy0.txt", dut.leaf_mem_inst.loop_ram_patch_gen[1].ram_patch_inst.loop_depth_gen[0].loop_width_gen[0].genblk1.sram_macro.mem);
        // $readmemh("leaves_mem_dummy0.txt", dut.leaf_mem_inst.loop_ram_patch_gen[2].ram_patch_inst.loop_depth_gen[0].loop_width_gen[0].genblk1.sram_macro.mem);
        // $readmemh("leaves_mem_dummy0.txt", dut.leaf_mem_inst.loop_ram_patch_gen[3].ram_patch_inst.loop_depth_gen[0].loop_width_gen[0].genblk1.sram_macro.mem);
        // $readmemh("leaves_mem_dummy1.txt", dut.leaf_mem_inst.loop_ram_patch_gen[4].ram_patch_inst.loop_depth_gen[0].loop_width_gen[0].genblk1.sram_macro.mem);
        // $readmemh("leaves_mem_dummy1.txt", dut.leaf_mem_inst.loop_ram_patch_gen[5].ram_patch_inst.loop_depth_gen[0].loop_width_gen[0].genblk1.sram_macro.mem);
        // $readmemh("leaves_mem_dummy1.txt", dut.leaf_mem_inst.loop_ram_patch_gen[6].ram_patch_inst.loop_depth_gen[0].loop_width_gen[0].genblk1.sram_macro.mem);
        // $readmemh("leaves_mem_dummy1.txt", dut.leaf_mem_inst.loop_ram_patch_gen[7].ram_patch_inst.loop_depth_gen[0].loop_width_gen[0].genblk1.sram_macro.mem);
        // $readmemh("leaves_mem_dummy0.txt", dut.leaf_mem_inst.loop_ram_patch_gen[0].ram_patch_inst.loop_depth_gen[0].loop_width_gen[1].genblk1.sram_macro.mem);
        // $readmemh("leaves_mem_dummy0.txt", dut.leaf_mem_inst.loop_ram_patch_gen[1].ram_patch_inst.loop_depth_gen[0].loop_width_gen[1].genblk1.sram_macro.mem);
        // $readmemh("leaves_mem_dummy0.txt", dut.leaf_mem_inst.loop_ram_patch_gen[2].ram_patch_inst.loop_depth_gen[0].loop_width_gen[1].genblk1.sram_macro.mem);
        // $readmemh("leaves_mem_dummy0.txt", dut.leaf_mem_inst.loop_ram_patch_gen[3].ram_patch_inst.loop_depth_gen[0].loop_width_gen[1].genblk1.sram_macro.mem);
        // $readmemh("leaves_mem_dummy1.txt", dut.leaf_mem_inst.loop_ram_patch_gen[4].ram_patch_inst.loop_depth_gen[0].loop_width_gen[1].genblk1.sram_macro.mem);
        // $readmemh("leaves_mem_dummy1.txt", dut.leaf_mem_inst.loop_ram_patch_gen[5].ram_patch_inst.loop_depth_gen[0].loop_width_gen[1].genblk1.sram_macro.mem);
        // $readmemh("leaves_mem_dummy1.txt", dut.leaf_mem_inst.loop_ram_patch_gen[6].ram_patch_inst.loop_depth_gen[0].loop_width_gen[1].genblk1.sram_macro.mem);
        // $readmemh("leaves_mem_dummy1.txt", dut.leaf_mem_inst.loop_ram_patch_gen[7].ram_patch_inst.loop_depth_gen[0].loop_width_gen[1].genblk1.sram_macro.mem);
        
        expected_idx_data_file = $fopen("expected_idx.txt", "r");
        if (expected_idx_data_file == 0) begin
            $display("expected_idx_data_file handle was NULL");
            $finish;
        end
        for(int i=0; i<NUM_QUERYS; i=i+1) begin
            scan_file = $fscanf(expected_idx_data_file, "%d\n", expected_idx[i]);
        end
        
        int_nodes_data_file = $fopen("internalNodes.txt", "r");
        if (int_nodes_data_file == 0) begin
            $display("int_nodes_data_file handle was NULL");
            $finish;
        end
        
        leaves_data_file = $fopen("leafNodes.txt", "r");
        if (leaves_data_file == 0) begin
            $display("leaves_data_file handle was NULL");
            $finish;
        end
        
        query_data_file = $fopen("patches.txt", "r");
        if (query_data_file == 0) begin
            $display("query_data_file handle was NULL");
            $finish;
        end

        rst_n = 0;
        fsm_start = 0;
        send_best_arr = 0;
        load_kdtree = 0;
        io_rst_n = 0;
        in_fifo_wenq = 0;
        in_fifo_wdata = '0;
        out_fifo_deq = '0;
        #20
        rst_n = 1;
        io_rst_n = 1;
        #40;

        // start load kd tree internal nodes and leaves
        @(negedge io_clk) load_kdtree = 1'b1;
        @(negedge io_clk) load_kdtree = 1'b0;

        // send internal nodes, 2 lines per node
        // index
        // median
        for(int i=0; i<NUM_NODES*2; i=i+1) begin
            @(negedge io_clk)
            in_fifo_wenq = 1'b1;
            scan_file = $fscanf(int_nodes_data_file, "%d\n", in_fifo_wdata[10:0]);
        end
        @(negedge io_clk)
        in_fifo_wenq = 0;
        in_fifo_wdata = '0;

        // send leaves, 6*8 lines per leaf
        // 8 patches per leaf
        // each patch has 5 lines of data
        // and 1 line of patch index in the original image (for reconstruction)
        for(int i=0; i<NUM_LEAVES*6*8; i=i+1) begin
            @(negedge io_clk)
            in_fifo_wenq = 1'b1;
            scan_file = $fscanf(leaves_data_file, "%d\n", in_fifo_wdata[10:0]);
        end
        @(negedge io_clk)
        in_fifo_wenq = 0;
        in_fifo_wdata = '0;
        
        // send query patches, 5 lines per query patch
        // each patch has 5 lines of data
        for(int i=0; i<NUM_QUERYS*5; i=i+1) begin
            @(negedge io_clk)
            in_fifo_wenq = 1'b1;
            scan_file = $fscanf(query_data_file, "%d\n", in_fifo_wdata[10:0]);
        end
        @(negedge io_clk)
        in_fifo_wenq = 0;
        in_fifo_wdata = '0;

        #100;
        @(negedge io_clk) fsm_start = 1'b1;
        @(negedge io_clk) fsm_start = 1'b0;

        wait(fsm_done == 1'b1);
        @(negedge io_clk) send_best_arr = 1'b1;
        @(negedge io_clk) send_best_arr = 1'b0;

        for(x=0; x<7; x=x+1) begin
            for(y=0; y<COL_SIZE; y=y+1) begin
                for(xi=0; xi<BLOCKING; xi=xi+1) begin
                    if ((x != 6) || (xi < 2)) begin
                        wait(out_fifo_rempty_n);
                        @(negedge io_clk)
                        out_fifo_deq = 1'b1;
                        addr = y*ROW_SIZE+x*BLOCKING+xi;
                        received_idx[addr] = out_fifo_rdata;
                    end
                end
            end
        end
        @(negedge io_clk) out_fifo_deq = 1'b0;

        for(int i=0; i<NUM_QUERYS; i=i+1) begin
            if (expected_idx[i] != received_idx[i])
                $display("mismatch %d: expected: %d, received %d", i, expected_idx[i], received_idx[i]);
        end

        #200;
        $finish;

    end

endmodule