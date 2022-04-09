`define DATA_WIDTH (4)
`define ADDR_WIDTH (4)
`define DEPTH (16)

interface ram_if (input bit clk);
	logic [`ADDR_WIDTH - 1 : 0] radr;
	logic [`ADDR_WIDTH - 1 : 0] wadr;
	logic [`DATA_WIDTH - 1 : 0] wdata;
	logic wen;
	logic ren;
	logic [`DATA_WIDTH - 1 : 0] rdata;
endinterface

class ram_item;
  rand bit [`ADDR_WIDTH - 1 : 0] radr;
  rand bit [`DATA_WIDTH - 1 : 0] rdata;
  rand bit ren;
  rand bit [`ADDR_WIDTH - 1 : 0] wadr;
  rand bit [`DATA_WIDTH - 1 : 0] wdata;
  rand bit wen;

  function void print(string tag="");
    $display("T=%0t [%s] radr=%h rdata=%h ren=%h wadr=%h wdata=%h wen=%h", $time, tag, radr, rdata, ren, wadr, wdata, wen);
  endfunction
endclass;

class driver;
  virtual ram_if vif;
  mailbox drv_mbx;
    
  task run();
    $display ("T=%0t [Write driver] Starting ...", $time);
    @ (posedge vif.clk);
    forever begin
      ram_item transaction;
      drv_mbx.get(transaction);
      vif.wen = transaction.wen;
      vif.wadr = transaction.wadr;
      vif.wdata = transaction.wdata;
      vif.ren = transaction.ren;
      vif.radr = transaction.radr;
      @ (posedge vif.clk);
    end       
  endtask
endclass

class monitor; 
  virtual ram_if vif;
  mailbox scb_mbx; // mailbox connected to scoreboard

  task run();
    $display("T=%0t [Read monitor] Starting ...", $time);
    forever begin
      ram_item transaction = new;

      @ (posedge vif.clk);
      transaction.rdata = vif.rdata;
      
      scb_mbx.put(transaction);
    end
  endtask
endclass

class scoreboard;
  mailbox scb_mbx;
  reg [`DATA_WIDTH : 0] expected_data;

  task run();
    forever begin
      ram_item transaction;
      scb_mbx.get(transaction);
      scb_mbx.get(transaction);
      // In the first two cycles we won't get valid read data 
      expected_data = 0;
      while(expected_data < `DEPTH) begin
        scb_mbx.get(transaction);
        if (transaction.rdata != expected_data[`DATA_WIDTH - 1 : 0]) begin
          $display("T=%0t [Scoreboard] Error! Received = %h, expected = %h", $time, transaction.rdata, expected_data[`DATA_WIDTH - 1 : 0]);
        end else begin
          $display("T=%0t [Scoreboard] Pass! Received = %h, expected = %h", $time, transaction.rdata, expected_data[`DATA_WIDTH - 1: 0]);
        end
        expected_data = expected_data + 1;
      end
      $finish;
    end
  endtask
endclass

class env;
  driver d0;
  monitor m0;
  scoreboard s0;
  mailbox scb_mbx;
  virtual ram_if vif;

  function new();
    d0 = new; 
    m0 = new;
    s0 = new;
    scb_mbx = new();
  endfunction

  virtual task run();
    d0.vif = vif;
    m0.vif = vif;
    m0.scb_mbx = scb_mbx;
    s0.scb_mbx = scb_mbx;

    fork
      s0.run();
      d0.run();
      m0.run();    
    join_any 
    endtask   
endclass    

class test;
  env e0;
  mailbox drv_mbx;
  reg [`ADDR_WIDTH : 0] stim_addr;

  function new();
    drv_mbx = new();
    e0 = new();
  endfunction

  virtual task run();
    e0.d0.drv_mbx = drv_mbx;
    fork 
      e0.run();
    join_none

    apply_stim();
  endtask

  virtual task apply_stim();
    ram_item transaction;
    $display ("T=%0t [Test] Starting write stimulus ...", $time);

    transaction = new;
    transaction.wadr = 0;
    transaction.wdata = 0;
    transaction.wen = 1;
    transaction.radr = 0;
    transaction.ren = 0;
    drv_mbx.put(transaction);

    stim_addr = 1;
    while(stim_addr < `DEPTH) begin
      transaction = new;
      transaction.wadr = stim_addr[`ADDR_WIDTH - 1 : 0];
      transaction.wdata = stim_addr[`DATA_WIDTH - 1 : 0]; // In this simple test, I just write the address to the data
      transaction.wen = 1;
      transaction.radr = stim_addr[`ADDR_WIDTH - 1 : 0] - 1;
      transaction.ren = 1;
      drv_mbx.put(transaction);
      stim_addr = stim_addr + 1;
    end

    transaction = new;
    transaction.wadr = 0;
    transaction.wdata = 0;
    transaction.wen = 0;
    transaction.radr = stim_addr[`ADDR_WIDTH - 1 : 0] - 1;
    transaction.ren = 1;
    drv_mbx.put(transaction);
  endtask
endclass

module ram_sync_1r1w_tb;

    reg clk;

    always #10 clk =~clk;
    
    ram_if _if (clk);

    ram_sync_1r1w #(
      .DATA_WIDTH(`DATA_WIDTH), 
      .ADDR_WIDTH(`ADDR_WIDTH), 
      .DEPTH(`DEPTH)
    ) dut (
      .clk(_if.clk),
      .radr(_if.radr),
      .wadr(_if.wadr),
      .wdata(_if.wdata),
      .rdata(_if.rdata),
      .wen(_if.wen),
      .ren(_if.ren)
    );

    initial begin
        test t0;

        clk <= 0;

        t0 = new(); 
        t0.e0.vif = _if;
        t0.run();
    end

    initial begin
        $vcdplusfile("dump.vcd");
        $vcdplusmemon();
        $vcdpluson(0, ram_sync_1r1w_tb);
        #20000000;
        $finish(2);
    end

endmodule
