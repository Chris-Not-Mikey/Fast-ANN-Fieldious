`timescale 1 ns / 1 ps
module top_tb();
    parameter DATA_WIDTH = 11;
    parameter LEAF_SIZE = 8;
    parameter PATCH_SIZE = 5;
    parameter NUM_LEAVES = 64;
    parameter ADDR_WIDTH = $clog2(NUM_LEAVES);

    logic clk;
    logic rst_n;
    logic fsm_start;

    top dut(
        .clk(clk),
        .rst_n(rst_n),
        .fsm_start(fsm_start)
    );

    initial begin 
        clk = 0;
        forever begin
            #10 clk = ~clk;
        end 
    end

    initial begin

        // for (int i=0; i<LEAF_SIZE; i=i+1) begin
        //     $readmemh("leaves_mem_dummy.txt", dut.leaf_mem_inst.loop_ram_patch_gen[i].ram_patch_inst.mem);
        // end
        $readmemh("leaves_mem_dummy0.txt", dut.leaf_mem_inst.loop_ram_patch_gen[0].ram_patch_inst.mem);
        $readmemh("leaves_mem_dummy0.txt", dut.leaf_mem_inst.loop_ram_patch_gen[1].ram_patch_inst.mem);
        $readmemh("leaves_mem_dummy0.txt", dut.leaf_mem_inst.loop_ram_patch_gen[2].ram_patch_inst.mem);
        $readmemh("leaves_mem_dummy0.txt", dut.leaf_mem_inst.loop_ram_patch_gen[3].ram_patch_inst.mem);
        $readmemh("leaves_mem_dummy1.txt", dut.leaf_mem_inst.loop_ram_patch_gen[4].ram_patch_inst.mem);
        $readmemh("leaves_mem_dummy1.txt", dut.leaf_mem_inst.loop_ram_patch_gen[5].ram_patch_inst.mem);
        $readmemh("leaves_mem_dummy1.txt", dut.leaf_mem_inst.loop_ram_patch_gen[6].ram_patch_inst.mem);
        $readmemh("leaves_mem_dummy1.txt", dut.leaf_mem_inst.loop_ram_patch_gen[7].ram_patch_inst.mem);
        

        rst_n = 0;
        fsm_start = 0;
        #20 rst_n = 1;
        #40;

        @(negedge clk) fsm_start = 1'b1;
        @(negedge clk) fsm_start = 1'b0;

        #20000;

    end

endmodule