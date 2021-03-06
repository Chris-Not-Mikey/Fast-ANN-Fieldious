`timescale 1 ns / 1 ps

`ifndef MPRJ_IO_PADS
    `define MPRJ_IO_PADS 38
`endif

module top_wrapper_tb();
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
    
    
    parameter WBS_ADDR_MASK        = 32'hFFFF_0000;
    parameter WBS_MODE_ADDR        = 32'h3000_0000;
    parameter WBS_DEBUG_ADDR       = 32'h3000_0004;
    parameter WBS_DONE_ADDR        = 32'h3000_0008;
    parameter WBS_FSM_START_ADDR   = 32'h3000_000C;
    parameter WBS_FSM_BUSY_ADDR    = 32'h3000_0010;
    parameter WBS_QUERY_ADDR       = 32'h3001_0000;
    parameter WBS_LEAF_ADDR        = 32'h3002_0000;
    parameter WBS_BEST_ADDR        = 32'h3003_0000;
    parameter WBS_NODE_ADDR        = 32'h3004_0000;

    // logic                                   clk;
    // logic                                   rst_n;
    // logic                                   fsm_start;
    // logic                                   fsm_done;
    // logic                                   send_best_arr;
    // logic                                   load_kdtree;
    // logic                                   io_clk;
    // logic                                   io_rst_n;
    // logic                                   in_fifo_wenq;
    // logic [DATA_WIDTH-1:0]                  in_fifo_wdata;
    // logic                                   in_fifo_wfull_n;
    // logic                                   out_fifo_deq;
    // logic [DATA_WIDTH-1:0]                  out_fifo_rdata;
    // logic                                   out_fifo_rempty_n;


    logic user_clock2;
    logic rst_n;
    logic wb_clk_i;
    logic wb_rst_i;
    logic wbs_stb_i;
    logic wbs_cyc_i;
    logic wbs_we_i;
    logic [3:0] wbs_sel_i;
    logic [31:0] wbs_dat_i;
    logic [31:0] wbs_adr_i;
    logic wbs_ack_o;
    logic [31:0] wbs_dat_o;

    // Logic Analyzer Signals
    logic  [127:0] la_data_in;
    logic [127:0] la_data_out;
    logic  [127:0] la_oenb;

    // IOs
    logic  [`MPRJ_IO_PADS-1:0] io_in;
    logic [`MPRJ_IO_PADS-1:0] io_out;
    logic [`MPRJ_IO_PADS-1:0] io_oeb;

    // IRQ
    logic [2:0] irq;
    
        //Node variables
    logic [6:0] counter;
    
    //Leaf variables
    
    logic [11:0] leafCounter;
    logic [63:0] leafReadHold;




    supply0 vssd1;
    supply1 vccd1;


    user_proj_example  #(
        
        .BITS(32)
       
      ) dut(
        `ifdef USE_POWER_PINS
        .vccd1(vccd1),	// User area 1 1.8V supply
        .vssd1(vssd1),	// User area 1 digital ground
        `endif

        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i), //Check this
        .wbs_stb_i(wbs_stb_i),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_we_i(wbs_we_i), 
        .wbs_sel_i(wbs_sel_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_ack_o(wbs_ack_o),
        .wbs_dat_o(wbs_dat_o),
        .la_data_in(la_data_in),
        .la_data_out(la_data_out),
        .la_oenb(la_oenb),
        .io_in(io_in),
        .io_out(io_out),
        .io_oeb(io_oeb),
        .irq(irq),
        .user_clock2(user_clock2)

       
     
    );

    initial begin 
        user_clock2 = 0;
        forever begin
            #5 user_clock2 = ~user_clock2;
        end 
    end

    initial begin 
        wb_clk_i = 0;
        forever begin
            #12.5 wb_clk_i = ~wb_clk_i;
        end 
    end

    initial begin 
        io_in[0] = 0; //Our clock is IO pin1
        forever begin
            #10 io_in[0] = ~io_in[0];
        end 
    end

    integer scan_file;
    integer expected_idx_data_file;
    integer received_idx_data_file;
    integer received_dist_data_file;
    integer int_nodes_data_file;
    integer leaves_data_file;
    integer query_data_file;
    reg [DATA_WIDTH-1:0] received_idx [NUM_QUERYS-1:0];
    reg [DATA_WIDTH-1:0] received_dist [NUM_QUERYS-1:0];
    reg [DATA_WIDTH-1:0] expected_idx [NUM_QUERYS-1:0];
    integer x;
    integer xi;
    integer y;
    integer addr;
    real simtime;
    real kdtreetime;
    real querytime;
    real fsmtime;
    real outputtime;

    initial begin
        $timeformat(-9, 2, "ns", 20);

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
        
        for (int q=0; q<2; q=q+1) begin
            expected_idx_data_file = $fopen("./data/IO_data/expectedIndex.txt", "r");
            // expected_idx_data_file = $fopen("data/IO_data/topToBottomLeafIndex.txt", "r");
            if (expected_idx_data_file == 0) begin
                $display("expected_idx_data_file handle was NULL");
                $finish;
            end
            for(int i=0; i<NUM_QUERYS; i=i+1) begin
                scan_file = $fscanf(expected_idx_data_file, "%d\n", expected_idx[i]);
            end
            
            int_nodes_data_file = $fopen("./data/IO_data/internalNodes.txt", "r");
            if (int_nodes_data_file == 0) begin
                $display("int_nodes_data_file handle was NULL");
                $finish;
            end
            
            leaves_data_file = $fopen("./data/IO_data/leafNodes.txt", "r");
            if (leaves_data_file == 0) begin
                $display("leaves_data_file handle was NULL");
                $finish;
            end
            
            query_data_file = $fopen("./data/IO_data/patches.txt", "r");
            if (query_data_file == 0) begin
                $display("query_data_file handle was NULL");
                $finish;
            end
            
            received_idx_data_file = $fopen("received_idx.txt", "w");
            received_dist_data_file = $fopen("received_dist.txt", "w");
        
            $display("Starting new image");

            wb_rst_i = 1;
            rst_n = 0;
            io_in[15] = 0;
            io_in[16] = 0;
            io_in[17] = 0;
            io_in[1] = 0;
            io_in[2] = 0;
            io_in[13:3] = '0;
            io_in[14] = '0;
            
            #20
            wb_rst_i = 0;      
            rst_n = 1;
            io_in[1] = 1;
            #40;

            // start load kd tree internal nodes and leaves
            @(negedge io_in[0]) io_in[17] = 1'b1;
            simtime = $realtime;
            $display("[T=%0t] Start sending KD tree internal nodes and leaves", $realtime);
            @(negedge io_in[0]) io_in[17] = 1'b0;

            // send internal nodes, 2 lines per node
            // index
            // median
            for(int i=0; i<NUM_NODES*2; i=i+1) begin
                @(negedge io_in[0])
                io_in[2] = 1'b1;
                scan_file = $fscanf(int_nodes_data_file, "%d\n", io_in[13:3]);
            end
            @(negedge io_in[0])
            io_in[2] = 0;
            io_in[13:3] = '0;

            // send leaves, 6*8 lines per leaf
            // 8 patches per leaf
            // each patch has 5 lines of data
            // and 1 line of patch index in the original image (for reconstruction)
            for(int i=0; i<NUM_LEAVES*6*8; i=i+1) begin
                @(negedge io_in[0])
                io_in[2] = 1'b1;
                scan_file = $fscanf(leaves_data_file, "%d\n", io_in[13:3]);
            end
            @(negedge io_in[0])
            io_in[2] = 0;
            io_in[13:3] = '0;
            $display("[T=%0t] Finished sending KD tree internal nodes and leaves", $realtime);
            kdtreetime = $realtime - simtime;
            
            $display("[T=%0t] Start sending queries", $realtime);
            simtime = $realtime;
            // send query patches, 5 lines per query patch
            // each patch has 5 lines of data
            for(int i=0; i<NUM_QUERYS*5; i=i+1) begin
                @(negedge io_in[0])
                io_in[2] = 1'b1;
                scan_file = $fscanf(query_data_file, "%d\n", io_in[13:3]);
            end
            @(negedge io_in[0])
            io_in[2] = 0;
            io_in[13:3] = '0;
            $display("[T=%0t] Finished sending queries", $realtime);
            querytime = $realtime - simtime;
            

            #100;
            @(negedge io_in[0]) io_in[15] = 1'b1;
            $display("[T=%0t] Start algorithm (ExactFstRow, SearchLeaf and ProcessRows)", $realtime);
            simtime = $realtime;
            @(negedge io_in[0]) io_in[15] = 1'b0;

            wait(io_out[31] == 1'b1);
            $display("[T=%0t] Finished algorithm (ExactFstRow, SearchLeaf and ProcessRows)", $realtime);
            fsmtime = $realtime - simtime;

            @(negedge io_in[0]) io_in[16] = 1'b1;
            $display("[T=%0t] Start receiving outputs", $realtime);
            simtime = $realtime;
            @(negedge io_in[0]) io_in[16] = 1'b0;

            for(int px=0; px<2; px=px+1) begin
                for(x=0; x<4; x=x+1) begin
                    // for(x=0; x<(ROW_SIZE/2/BLOCKING); x=x+1) begin  // for row_size = 26
                    for(y=0; y<COL_SIZE; y=y+1) begin
                        for(xi=0; xi<BLOCKING; xi=xi+1) begin
                            if ((x != 3) || (xi < 1)) begin  // for row_size = 26
                                wait(io_out[30]);
                                @(negedge io_in[0])
                                io_in[14] = 1'b1;
                                addr = px*ROW_SIZE/2 + y*ROW_SIZE + x*BLOCKING + xi;
                                received_idx[addr] = io_out[29:19];
                                @(posedge io_in[0]); #1;
                            end
                        end
                    end
                end
            end

            // need this else the fsm state and output fifo is messed up
            for(int px=0; px<2; px=px+1) begin
                for(x=0; x<4; x=x+1) begin
                    // for(x=0; x<(ROW_SIZE/2/BLOCKING); x=x+1) begin  // for row_size = 24
                    for(y=0; y<COL_SIZE; y=y+1) begin
                        for(xi=0; xi<BLOCKING; xi=xi+1) begin
                            for(int agg=0; agg<=1; agg=agg+1) begin  // most significant first
                                if ((x != 3) || (xi < 1)) begin  // for row_size = 26
                                    wait(io_out[30]);
                                    @(negedge io_in[0])
                                    io_in[14] = 1'b1;
                                    addr = px*ROW_SIZE/2 + y*ROW_SIZE + x*BLOCKING + xi;
                                    received_dist[addr][agg*DATA_WIDTH+:DATA_WIDTH] = io_out[29:19];
                                    @(posedge io_in[0]); #1;
                                end
                            end
                        end
                    end
                end
            end

            @(negedge io_in[0]) io_in[14] = 1'b0;
            $display("[T=%0t] Finished receiving outputs", $realtime);
            outputtime = $realtime - simtime;

            
            for(int i=0; i<NUM_QUERYS; i=i+1) begin
                $fwrite(received_idx_data_file, "%d\n", received_idx[i]);
                if (expected_idx[i] != received_idx[i])
                    $display("mismatch %d: expected: %d, received %d", i, expected_idx[i], received_idx[i]);
                // else
                //     $display("match %d: expected: %d, received %d", i, expected_idx[i], received_idx[i]);
            end
                
            
            for(int i=0; i<NUM_QUERYS; i=i+1) begin
                $fwrite(received_dist_data_file, "%d\n", received_dist[i]);
                // if (expected_idx[i] != received_dist[i])
                //     $display("mismatch %d: expected: %d, received %d", i, expected_idx[i], received_dist[i]);
                // else
                //     $display("match %d: expected: %d, received %d", i, expected_idx[i], received_dist[i]);
            end

            $display("===============Runtime Summary===============");
            $display("KD tree: %t", kdtreetime);
            $display("Query patches: %t", querytime);
            $display("Main Algorithm: %t", fsmtime);
            $display("Outputs: %t", outputtime);
            
            #200;
        end //end of inner loop per image pair


        
//         //*********************************************************WISHBONE SECTION***********************************************************
//         //start wishbone test
        
//         for (int q=0; q<2; q=q+1) begin
//             $display("Starting new image");
            
            
//          wb_rst_i = 1'b1;
//         wbs_stb_i = 1'b0;
//         wbs_cyc_i = 1'b0;
//         wbs_we_i = 1'b0;
//         wbs_sel_i = '1;
//         wbs_dat_i = '0;
//         wbs_adr_i = '0;
        
        
//         rst_n = 0;
//         io_in[15] = 0;
//         io_in[16] = 0;
//         io_in[17] = 0;
//         io_in[1] = 0;
//         io_in[2] = 0;
//         io_in[13:3] = '0;
//         io_in[14] = '0;
//         wbs_adr_i = WBS_DEBUG_ADDR;
        
//         #20
//         wb_rst_i = 0;      
//         rst_n = 1;
//         io_in[1] = 1;
//         #40;
        
//         wbs_cyc_i = 1'b1;
//         wbs_stb_i = 1'b1;
//         wbs_we_i = 1'b1;
//         wbs_dat_i = 32'b1;
//         wbs_adr_i = WBS_DEBUG_ADDR;
        
//         #100
        
//         wbs_adr_i = WBS_MODE_ADDR;
//         #100
//         wbs_cyc_i = 1'b0;
//         wbs_stb_i = 1'b0;
//         wbs_we_i = 1'b0;
       
        
      
        
        
//          #20


//         // // start load kd tree internal nodes and leaves
//         // for (int node_num = 0; node_num < 63; node_num++) begin

         
//         // end

        

//         // send internal nodes, 2 lines per node
//         // index
//         // median
     
//         counter = 7'b1;
//         simtime = $realtime;
//         $display("[T=%0t] Start sending KD tree internal nodes and leaves", $realtime);
//         for(int i=0; i<NUM_NODES; i=i+1) begin
//             @(posedge wb_clk_i)
//             io_in[2] = 1'b1; //fifo wenq (TODO: Change to wbs)
//             scan_file = $fscanf(int_nodes_data_file, "%d\n", wbs_dat_i[10:0]);
//             scan_file = $fscanf(int_nodes_data_file, "%d\n", wbs_dat_i[21:11]);
//             wbs_dat_i[31:22] = 10'b0;
//             wbs_cyc_i = 1'b1;
//             wbs_stb_i = 1'b1;
//             wbs_we_i = 1'b1;
//             wbs_sel_i = '1;
//             //wbs_dat_i = {10'b0, 11'd55, 11'd1}; //10 0's, median of 55, and index of 1 
//             wbs_adr_i = WBS_NODE_ADDR + (i<<2); // addr 1
        
//             @(posedge wb_clk_i);
//             wbs_cyc_i = 1'b1;
//             wbs_stb_i = 1'b1;
//             wbs_we_i = 1'b1;
//             //wbs_dat_i = '0;
           
    

//             @(negedge wb_clk_i);
//             wbs_cyc_i = 1'b0;
//             wbs_stb_i = 1'b0;
//             wbs_we_i = 1'b0;
//             wbs_dat_i = '0;
            
//             @(negedge wbs_ack_o);
//             counter = counter + 1'b1;
//         end


//         @(negedge wb_clk_i)
//         io_in[2] = 0;
//         io_in[13:3] = '0;

//         // send leaves, 6*8 lines per leaf
//         // 8 patches per leaf
//         // each patch has 5 lines of data
//         // and 1 line of patch index in the original image (for reconstruction)
//         for(int i=0; i<NUM_LEAVES*6; i=i+1) begin
            
//             for (int j=0; j < 8; j=j+1) begin
                

//                 // mem write

//                 @(posedge wb_clk_i);


//                 scan_file = $fscanf(leaves_data_file, "%d\n", leafReadHold[10:0]);
//                 scan_file = $fscanf(leaves_data_file, "%d\n", leafReadHold[21:11]);
//                 scan_file = $fscanf(leaves_data_file, "%d\n", leafReadHold[32:22]);

//                 scan_file = $fscanf(leaves_data_file, "%d\n", leafReadHold[43:33]);
//                 scan_file = $fscanf(leaves_data_file, "%d\n", leafReadHold[54:44]);
//                 scan_file = $fscanf(leaves_data_file, "%d\n", leafReadHold[63:55]); //smaller because idx 9 bits



//                 wbs_cyc_i = 1'b1;
//                 wbs_stb_i = 1'b1;
//                 wbs_we_i = 1'b1;
//                 wbs_sel_i = '1;
//                 wbs_dat_i = leafReadHold[31:0];
//                 wbs_adr_i = WBS_LEAF_ADDR + (j<<3) + (0<<2) + (i<<5);  // addr 2, lower

//                 @(negedge wbs_ack_o);
//                 wbs_cyc_i = 1'b1;
//                 wbs_stb_i = 1'b1;
//                 wbs_we_i = 1'b1;
//                 wbs_sel_i = '1;
//                 wbs_dat_i = leafReadHold[63:32];
//                 wbs_adr_i = WBS_LEAF_ADDR + (j<<3) + (1<<2) + (i<<5);  // addr 2, upper

//                 @(negedge wbs_ack_o);
//                 wbs_cyc_i = 1'b0;
//                 wbs_stb_i = 1'b0;
//                 wbs_we_i = 1'b0;
//                 wbs_dat_i = '0;
//                 wbs_adr_i = '0;


                
//             end

            
            
//         end
//         @(negedge wb_clk_i)
//         io_in[2] = 0;
//         io_in[13:3] = '0;
//         $display("[T=%0t] Finished sending KD tree internal nodes and leaves", $realtime);
//         kdtreetime = $realtime - simtime;
        
       
        
//         $display("[T=%0t] Start sending queries", $realtime);
//         simtime = $realtime;
//         // send query patches, 5 lines per query patch
//         // each patch has 5 lines of data
//         for(int i=0; i<NUM_QUERYS; i=i+1) begin
// //             @(negedge wb_clk_i)
// //             io_in[2] = 1'b1;
// //             scan_file = $fscanf(query_data_file, "%d\n", io_in[13:3]);
            
//              @(posedge wb_clk_i);
             
     
//             scan_file = $fscanf(query_data_file, "%d\n", leafReadHold[10:0]);
//             scan_file = $fscanf(query_data_file, "%d\n", leafReadHold[21:11]);
//             scan_file = $fscanf(query_data_file, "%d\n", leafReadHold[32:22]);
            
//             scan_file = $fscanf(query_data_file, "%d\n", leafReadHold[43:33]);
//             scan_file = $fscanf(query_data_file, "%d\n", leafReadHold[54:44]);
//             leafReadHold[63:55] = 9'b0;
//             //  scan_file = $fscanf(leaves_data_file, "%d\n", leafReadHold[63:55]); //Empty bc 55 bits
            
            
            
//             wbs_cyc_i = 1'b1;
//             wbs_stb_i = 1'b1;
//             wbs_we_i = 1'b1;
//             wbs_sel_i = '1;
//             wbs_dat_i = leafReadHold[31:0];
//             wbs_adr_i = WBS_QUERY_ADDR + (i<<3) + (0<<2);  // addr 2, lower

//             @(negedge wbs_ack_o);
//             wbs_cyc_i = 1'b1;
//             wbs_stb_i = 1'b1;
//             wbs_we_i = 1'b1;
//             wbs_sel_i = '1;
//             wbs_dat_i = leafReadHold[63:32];
//             wbs_adr_i = WBS_QUERY_ADDR + (i<<3) + (1<<2);  // addr 2, upper

//             @(negedge wbs_ack_o);
//             wbs_cyc_i = 1'b0;
//             wbs_stb_i = 1'b0;
//             wbs_we_i = 1'b0;
//             wbs_dat_i = '0;
//             wbs_adr_i = '0;
            
            
            
//         end
//         @(negedge wb_clk_i)
// //         io_in[2] = 0;
// //         io_in[13:3] = '0;
//         $display("[T=%0t] Finished sending queries", $realtime);
//         querytime = $realtime - simtime;
        
    

//         #100;
//         @(negedge wb_clk_i) io_in[15] = 1'b1; //wbs_adr_i = WBS_FSM_START_ADDR;
//         wbs_we_i = 1'b1;
//         wbs_cyc_i = 1'b1;
//         wbs_stb_i = 1'b1;
//         wbs_we_i = 1'b1;
//         wbs_sel_i = '1;
        
//         $display("[T=%0t] Start algorithm (ExactFstRow, SearchLeaf and ProcessRows)", $realtime);
//         simtime = $realtime;
//         @(negedge wb_clk_i) io_in[15] = 1'b0; // wbs_we_i = 1'b0;
//         wbs_cyc_i = 1'b0;
//         wbs_stb_i = 1'b0;
//         wbs_we_i = 1'b0;
//         wbs_dat_i = '0;
//         wbs_adr_i = '0;

        
       
        

//         wait(io_out[31] == 1'b1); //TODO: Replace with WSB
//         $display("[T=%0t] Finished algorithm (ExactFstRow, SearchLeaf and ProcessRows)", $realtime);
//         fsmtime = $realtime - simtime;

//         @(negedge wb_clk_i) wbs_adr_i = WBS_BEST_ADDR;
//         $display("[T=%0t] Start receiving outputs", $realtime);
//         simtime = $realtime;
//         @(negedge wb_clk_i);

//         for(int px=0; px<2; px=px+1) begin
//             for(x=0; x<4; x=x+1) begin
//                 // for(x=0; x<(ROW_SIZE/2/BLOCKING); x=x+1) begin  // for row_size = 26
//                 for(y=0; y<COL_SIZE; y=y+1) begin
//                     for(xi=0; xi<BLOCKING; xi=xi+1) begin
//                         if ((x != 3) || (xi < 1)) begin  // for row_size = 26
//                             //wait(io_out[30]);
                            
//                                addr = px*ROW_SIZE/2 + y*ROW_SIZE + x*BLOCKING + xi;
//                                @(posedge wb_clk_i);
//                                 wbs_cyc_i = 1'b1;
//                                 wbs_stb_i = 1'b1;
//                                 wbs_we_i = 1'b0;
//                                 wbs_sel_i = '1;
//                             wbs_adr_i = WBS_BEST_ADDR + (addr<<3) + (0<<2); // addr 7, lower

//                              @(negedge (wbs_ack_o));
                            
//                              @(posedge wb_clk_i);
//                             wbs_cyc_i = 1'b1;
//                             wbs_stb_i = 1'b1;
//                             wbs_we_i = 1'b0;
//                             wbs_sel_i = '1;
//                             wbs_adr_i = WBS_BEST_ADDR + (addr<<3) + (1<<2); // addr 7, upper
                            
                            
//                             @(negedge (wbs_ack_o));
//                              wbs_cyc_i = 1'b0;
//                             wbs_stb_i = 1'b0;
//                             wbs_we_i = 1'b0;
//                             wbs_sel_i = '0;
//                             received_idx[addr] = wbs_dat_o[10:0];
// //                             @(posedge wb_clk_i); #1;
                            
// //                                @(negedge wbs_ack_o);
// //                                 wbs_cyc_i = 1'b1;
// //                                 wbs_stb_i = 1'b1;
// //                                 wbs_we_i = 1'b0;
// //                                 wbs_sel_i = '1;
// //                                 wbs_adr_i = WBS_BEST_ADDR + (addr<<3) + (1<<2);  // addr 7, upper

// //                                 @(negedge (~wbs_best_arr_csb1));
                            
// //                             @(negedge wb_clk_i)
// //                             io_in[14] = 1'b1;
// //                             addr = px*ROW_SIZE/2 + y*ROW_SIZE + x*BLOCKING + xi;
// //                             received_idx[addr] = io_out[29:19];
// //                             @(posedge wb_clk_i); #1;
//                         end
//                     end
//                 end
//             end
//         end
//         @(negedge wb_clk_i) io_in[14] = 1'b0;
//         $display("[T=%0t] Finished receiving outputs", $realtime);
//         outputtime = $realtime - simtime;

      
//         for(int i=0; i<NUM_QUERYS; i=i+1) begin
//             $fwrite(received_idx_data_file, "%d\n", received_idx[i]);
//             if (expected_idx[i] != received_idx[i])
//                 $display("mismatch %d: expected: %d, received %d", i, expected_idx[i], received_idx[i]);
//             else
//                 $display("match %d: expected: %d, received %d", i, expected_idx[i], received_idx[i]);
//         end

//         $display("===============Runtime Summary===============");
//         $display("KD tree: %t", kdtreetime);
//         $display("Query patches: %t", querytime);
//         $display("Main Algorithm: %t", fsmtime);
//         $display("Outputs: %t", outputtime);
        
      
            
//         end //end of wishbone pair inner loop
        
//         //****************************************FINAL IO TEST AFTER WISHBONE***********************
//         #200
        
//         for (int q=0; q<1; q=q+1) begin
//             $display("Starting new image");

//         wb_rst_i = 1;
//         wbs_stb_i = 1'b0;
//         wbs_cyc_i = 1'b0;
//         wbs_we_i = 1'b0;
//         wbs_sel_i = '0;
//         wbs_dat_i = '0;
//         wbs_adr_i = '0;
            
            
//         rst_n = 0;
//         io_in[15] = 0;
//         io_in[16] = 0;
//         io_in[17] = 0;
//         io_in[1] = 0;
//         io_in[2] = 0;
//         io_in[13:3] = '0;
//         io_in[14] = '0;
        
//         #20
//         wb_rst_i = 0;      
//         rst_n = 1;
//         io_in[1] = 1;
//         #40;

//         // start load kd tree internal nodes and leaves
//         @(negedge io_in[0]) io_in[17] = 1'b1;
//         simtime = $realtime;
//         $display("[T=%0t] Start sending KD tree internal nodes and leaves", $realtime);
//         @(negedge io_in[0]) io_in[17] = 1'b0;

//         // send internal nodes, 2 lines per node
//         // index
//         // median
//         for(int i=0; i<NUM_NODES*2; i=i+1) begin
//             @(negedge io_in[0])
//             io_in[2] = 1'b1;
//             scan_file = $fscanf(int_nodes_data_file, "%d\n", io_in[13:3]);
//         end
//         @(negedge io_in[0])
//         io_in[2] = 0;
//         io_in[13:3] = '0;

//         // send leaves, 6*8 lines per leaf
//         // 8 patches per leaf
//         // each patch has 5 lines of data
//         // and 1 line of patch index in the original image (for reconstruction)
//         for(int i=0; i<NUM_LEAVES*6*8; i=i+1) begin
//             @(negedge io_in[0])
//             io_in[2] = 1'b1;
//             scan_file = $fscanf(leaves_data_file, "%d\n", io_in[13:3]);
//         end
//         @(negedge io_in[0])
//         io_in[2] = 0;
//         io_in[13:3] = '0;
//         $display("[T=%0t] Finished sending KD tree internal nodes and leaves", $realtime);
//         kdtreetime = $realtime - simtime;
        
//         $display("[T=%0t] Start sending queries", $realtime);
//         simtime = $realtime;
//         // send query patches, 5 lines per query patch
//         // each patch has 5 lines of data
//         for(int i=0; i<NUM_QUERYS*5; i=i+1) begin
//             @(negedge io_in[0])
//             io_in[2] = 1'b1;
//             scan_file = $fscanf(query_data_file, "%d\n", io_in[13:3]);
//         end
//         @(negedge io_in[0])
//         io_in[2] = 0;
//         io_in[13:3] = '0;
//         $display("[T=%0t] Finished sending queries", $realtime);
//         querytime = $realtime - simtime;
        

//         #100;
//         @(negedge io_in[0]) io_in[15] = 1'b1;
//         $display("[T=%0t] Start algorithm (ExactFstRow, SearchLeaf and ProcessRows)", $realtime);
//         simtime = $realtime;
//         @(negedge io_in[0]) io_in[15] = 1'b0;

//         wait(io_out[31] == 1'b1);
//         $display("[T=%0t] Finished algorithm (ExactFstRow, SearchLeaf and ProcessRows)", $realtime);
//         fsmtime = $realtime - simtime;

//         @(negedge io_in[0]) io_in[16] = 1'b1;
//         $display("[T=%0t] Start receiving outputs", $realtime);
//         simtime = $realtime;
//         @(negedge io_in[0]) io_in[16] = 1'b0;

//         for(int px=0; px<2; px=px+1) begin
//             for(x=0; x<4; x=x+1) begin
//                 // for(x=0; x<(ROW_SIZE/2/BLOCKING); x=x+1) begin  // for row_size = 26
//                 for(y=0; y<COL_SIZE; y=y+1) begin
//                     for(xi=0; xi<BLOCKING; xi=xi+1) begin
//                         if ((x != 3) || (xi < 1)) begin  // for row_size = 26
//                             wait(io_out[30]);
//                             @(negedge io_in[0])
//                             io_in[14] = 1'b1;
//                             addr = px*ROW_SIZE/2 + y*ROW_SIZE + x*BLOCKING + xi;
//                             received_idx[addr] = io_out[29:19];
//                             @(posedge io_in[0]); #1;
//                         end
//                     end
//                 end
//             end
//         end
//         @(negedge io_in[0]) io_in[14] = 1'b0;
//         $display("[T=%0t] Finished receiving outputs", $realtime);
//         outputtime = $realtime - simtime;

        
//         for(int i=0; i<NUM_QUERYS; i=i+1) begin
//             $fwrite(received_idx_data_file, "%d\n", received_idx[i]);
//             if (expected_idx[i] != received_idx[i])
//                 $display("mismatch %d: expected: %d, received %d", i, expected_idx[i], received_idx[i]);
//             // else
//             //     $display("match %d: expected: %d, received %d", i, expected_idx[i], received_idx[i]);
//         end
            
        
//         for(int i=0; i<NUM_QUERYS; i=i+1) begin
//             $fwrite(received_dist_data_file, "%d\n", received_dist[i]);
//             // if (expected_idx[i] != received_dist[i])
//             //     $display("mismatch %d: expected: %d, received %d", i, expected_idx[i], received_dist[i]);
//             // else
//             //     $display("match %d: expected: %d, received %d", i, expected_idx[i], received_dist[i]);
//         end

//         $display("===============Runtime Summary===============");
//         $display("KD tree: %t", kdtreetime);
//         $display("Query patches: %t", querytime);
//         $display("Main Algorithm: %t", fsmtime);
//         $display("Outputs: %t", outputtime);


    
          
//         end //end of inner loop per image pair
        
        
        
        #200;
        $finish;

    end
    
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars;
    end

    `ifdef GL
    initial begin
        $sdf_annotate("inputs/design.sdf", dut);
    end
    `endif


endmodule
