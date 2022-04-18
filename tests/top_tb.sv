`timescale 1 ns / 1 ps
module top_tb();
    parameter DATA_WIDTH = 11;
    parameter LEAF_SIZE = 8;
    parameter PATCH_SIZE = 5;
    parameter NUM_ROWS = 26;
    parameter NUM_COLS = 19;
    parameter NUM_QUERYS = NUM_ROWS * NUM_COLS;
    parameter NUM_LEAVES = 64;
    parameter NUM_NODES = NUM_LEAVES - 1;
    parameter ADDR_WIDTH = $clog2(NUM_LEAVES);

    logic                                   clk;
    logic                                   rst_n;
    logic                                   fsm_start;
    logic                                   load_kdtree;
    logic                                   in_fifo_wclk;
    logic                                   in_fifo_wrst_n;
    logic                                   in_fifo_wenq;
    logic [DATA_WIDTH-1:0]                  in_fifo_wdata;
    logic                                   in_fifo_wfull_n;

    top dut(
        .clk(clk),
        .rst_n(rst_n),

        .load_kdtree(load_kdtree),

        .in_fifo_wclk(in_fifo_wclk),
        .in_fifo_wrst_n(in_fifo_wrst_n),
        .in_fifo_wenq(in_fifo_wenq),
        .in_fifo_wdata(in_fifo_wdata),
        .in_fifo_wfull_n(in_fifo_wfull_n),

        .fsm_start(fsm_start)
    );

    initial begin 
        clk = 0;
        forever begin
            #5 clk = ~clk;
        end 
    end

    initial begin 
        in_fifo_wclk = 0;
        forever begin
            #10 in_fifo_wclk = ~in_fifo_wclk;
        end 
    end

    integer scan_file;
    integer int_nodes_data_file;
    integer leaves_data_file;
    integer query_data_file;

    initial begin

        $readmemh("leaves_mem_dummy0.txt", dut.leaf_mem_inst.loop_ram_patch_gen[0].ram_patch_inst.loop_depth_gen[0].loop_width_gen[0].genblk1.sram_macro.mem);
        $readmemh("leaves_mem_dummy0.txt", dut.leaf_mem_inst.loop_ram_patch_gen[1].ram_patch_inst.loop_depth_gen[0].loop_width_gen[0].genblk1.sram_macro.mem);
        $readmemh("leaves_mem_dummy0.txt", dut.leaf_mem_inst.loop_ram_patch_gen[2].ram_patch_inst.loop_depth_gen[0].loop_width_gen[0].genblk1.sram_macro.mem);
        $readmemh("leaves_mem_dummy0.txt", dut.leaf_mem_inst.loop_ram_patch_gen[3].ram_patch_inst.loop_depth_gen[0].loop_width_gen[0].genblk1.sram_macro.mem);
        $readmemh("leaves_mem_dummy1.txt", dut.leaf_mem_inst.loop_ram_patch_gen[4].ram_patch_inst.loop_depth_gen[0].loop_width_gen[0].genblk1.sram_macro.mem);
        $readmemh("leaves_mem_dummy1.txt", dut.leaf_mem_inst.loop_ram_patch_gen[5].ram_patch_inst.loop_depth_gen[0].loop_width_gen[0].genblk1.sram_macro.mem);
        $readmemh("leaves_mem_dummy1.txt", dut.leaf_mem_inst.loop_ram_patch_gen[6].ram_patch_inst.loop_depth_gen[0].loop_width_gen[0].genblk1.sram_macro.mem);
        $readmemh("leaves_mem_dummy1.txt", dut.leaf_mem_inst.loop_ram_patch_gen[7].ram_patch_inst.loop_depth_gen[0].loop_width_gen[0].genblk1.sram_macro.mem);
        $readmemh("leaves_mem_dummy0.txt", dut.leaf_mem_inst.loop_ram_patch_gen[0].ram_patch_inst.loop_depth_gen[0].loop_width_gen[1].genblk1.sram_macro.mem);
        $readmemh("leaves_mem_dummy0.txt", dut.leaf_mem_inst.loop_ram_patch_gen[1].ram_patch_inst.loop_depth_gen[0].loop_width_gen[1].genblk1.sram_macro.mem);
        $readmemh("leaves_mem_dummy0.txt", dut.leaf_mem_inst.loop_ram_patch_gen[2].ram_patch_inst.loop_depth_gen[0].loop_width_gen[1].genblk1.sram_macro.mem);
        $readmemh("leaves_mem_dummy0.txt", dut.leaf_mem_inst.loop_ram_patch_gen[3].ram_patch_inst.loop_depth_gen[0].loop_width_gen[1].genblk1.sram_macro.mem);
        $readmemh("leaves_mem_dummy1.txt", dut.leaf_mem_inst.loop_ram_patch_gen[4].ram_patch_inst.loop_depth_gen[0].loop_width_gen[1].genblk1.sram_macro.mem);
        $readmemh("leaves_mem_dummy1.txt", dut.leaf_mem_inst.loop_ram_patch_gen[5].ram_patch_inst.loop_depth_gen[0].loop_width_gen[1].genblk1.sram_macro.mem);
        $readmemh("leaves_mem_dummy1.txt", dut.leaf_mem_inst.loop_ram_patch_gen[6].ram_patch_inst.loop_depth_gen[0].loop_width_gen[1].genblk1.sram_macro.mem);
        $readmemh("leaves_mem_dummy1.txt", dut.leaf_mem_inst.loop_ram_patch_gen[7].ram_patch_inst.loop_depth_gen[0].loop_width_gen[1].genblk1.sram_macro.mem);
        
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
        load_kdtree = 0;
        in_fifo_wrst_n = 0;
        in_fifo_wenq = 0;
        in_fifo_wdata = '0;
        #20
        rst_n = 1;
        in_fifo_wrst_n = 1;
        #40;

        // start load kd tree internal nodes and leaves
        @(negedge clk) load_kdtree = 1'b1;
        @(negedge clk) load_kdtree = 1'b0;

        // send internal nodes, 2 lines per node
        // index
        // median
        for(int i=0; i<NUM_NODES*2; i=i+1) begin
            @(negedge in_fifo_wclk)
            in_fifo_wenq = 1'b1;
            scan_file = $fscanf(int_nodes_data_file, "%d\n", in_fifo_wdata[10:0]);
        end
        @(negedge in_fifo_wclk)
        in_fifo_wenq = 0;
        in_fifo_wdata = '0;

        // send leaves, 6*8 lines per leaf
        // 8 patches per leaf
        // each patch has 5 lines of data
        // and 1 line of patch index in the original image (for reconstruction)
        for(int i=0; i<NUM_LEAVES*6*8; i=i+1) begin
            @(negedge in_fifo_wclk)
            in_fifo_wenq = 1'b1;
            scan_file = $fscanf(leaves_data_file, "%d\n", in_fifo_wdata[10:0]);
        end
        @(negedge in_fifo_wclk)
        in_fifo_wenq = 0;
        in_fifo_wdata = '0;
        
        // send query patches, 5 lines per query patch
        // each patch has 5 lines of data
        for(int i=0; i<NUM_QUERYS*5; i=i+1) begin
            @(negedge in_fifo_wclk)
            in_fifo_wenq = 1'b1;
            scan_file = $fscanf(query_data_file, "%d\n", in_fifo_wdata[10:0]);
        end
        @(negedge in_fifo_wclk)
        in_fifo_wenq = 0;
        in_fifo_wdata = '0;

        @(negedge clk) fsm_start = 1'b1;
        @(negedge clk) fsm_start = 1'b0;

        #20000;

    end

endmodule