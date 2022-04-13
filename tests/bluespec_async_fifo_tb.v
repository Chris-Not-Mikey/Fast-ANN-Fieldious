//
// Testbench
//
module bluespec_syncfifo_tb;

  parameter DSIZE = 11;
  parameter ASIZE = 4;

  logic [DSIZE-1:0] rdata;
  logic wfull;
  logic rempty;
  logic [DSIZE-1:0] wdata;
  logic winc, wclk, wrst_n;
  logic rinc, rclk, rrst_n;

  // Model a queue for checking data
  logic [DSIZE-1:0] verif_data_q[$];
  logic [DSIZE-1:0] verif_wdata;


  // Instantiate the FIFO
  SyncFIFO #(DSIZE, 4, 2)
  dut (
   
    .sCLK(wclk),
    .sRST(wrst_n),
    .dCLK(rclk),
    .sENQ(winc),
    .sD_IN(wdata),
    .sFULL_N(wfull),
    .dDEQ(rinc),
    .dD_OUT(rdata),
    .dEMPTY_N(rempty)
  
  );

  initial begin
    wclk = 1'b0;
    rclk = 1'b0;

    fork
      forever #20ns wclk = ~wclk;
      forever #10ns rclk = ~rclk; //change to 6.66 for real test
    join
  end

  initial begin
    winc = 1'b0;
    wdata = '0;
    wrst_n = 1'b0;
    repeat(5) @(posedge wclk);
    wrst_n = 1'b1;

    for (int iter=0; iter<2; iter++) begin
      for (int i=0; i<32; i++) begin
        @(posedge wclk iff wfull);
        winc = (i%2 == 0)? 1'b1 : 1'b0;
        if (winc) begin
          wdata = $urandom;
          verif_data_q.push_front(wdata);
        end
      end
      #1us;
    end
  end

  initial begin
    rinc = 1'b0;

    rrst_n = 1'b0;
    repeat(8) @(posedge rclk);
    rrst_n = 1'b1;

    for (int iter=0; iter<2; iter++) begin
      for (int i=0; i<32; i++) begin
        @(posedge rclk iff rempty)
        rinc = (i%2 == 0)? 1'b1 : 1'b0;
        if (rinc) begin
          verif_wdata = verif_data_q.pop_back();
          // Check the rdata against modeled wdata
         // $display("Checking rdata: expected wdata = %h, rdata = %h", verif_wdata, rdata);
          assert(rdata === verif_wdata) else $error("Checking failed: expected wdata = %h, rdata = %h", verif_wdata, rdata);
        end
      end
      #1us;
    end

    $finish;
  end
  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
//     $vcdplusmemon();
//     $vcdpluson(0, aggregator_tb);
    #20000;
    $finish(2);
  end

endmodule
