`define DATA_WIDTH 4
`define FIFO_DEPTH 3
`define COUNTER_WIDTH 1

module fifo_tb;

  // Write five directed tests for the fifo module that test different corner
  // cases. For example, whether it raises the empty and full flags correctly,
  // whether it clears (empties) when you assert the clr signal. Verify its
  // behaviour on reset. You should also test whether the fifo gives the
  // expected latency between when a data goes in and the earliest it can come
  // out. 

  // Your code starts here
  reg clk;
  reg rst_n;
  reg [`DATA_WIDTH - 1 : 0] din;
  reg enq;
  wire full_n;
  wire [`DATA_WIDTH - 1 : 0] dout;
  reg deq;
  wire empty_n;
  reg clr;

  always #10 clk =~clk;
    
  fifo #(
    .DATA_WIDTH(`DATA_WIDTH), 
    .FIFO_DEPTH(`FIFO_DEPTH), 
    .COUNTER_WIDTH(`COUNTER_WIDTH)
  ) dut (
    .clk(clk),
    .rst_n(rst_n),
    .din(din),
    .enq(enq),
    .full_n(full_n),
    .dout(dout),
    .deq(deq),
    .empty_n(empty_n),
    .clr(clr)
  );

  initial begin
    clk <= 0;
    rst_n <= 0;
    clr <= 0;
    enq <= 0;
    deq <= 0;
    din <= 0;
    #40 rst_n <= 1;

    // We will first check if after reset, the fifo is empty
    assert(empty_n == 0); // Meaning empty is high
    assert(full_n  == 1); // Meaning fifo is not full
    
    // Now we will write 3 data into the fifo and check if it becomes full
    // after that. Note that we are changing testbench signals on the
    // negative edge of clock.
    #20
    enq <= 1;
    #20
    assert(empty_n == 1);
    assert(full_n == 1);
    assert(dout == 0);
    din <= 1;
    #20
    assert(empty_n == 1);
    assert(full_n == 1);
    assert(dout == 0);
    din <= 2;
    #20 
    assert(empty_n == 1);
    assert(full_n == 0);
    assert(dout == 0);
    enq <= 0;

    // Now we will dequeue all the data and see if the fifo becomes empty
    deq <= 1;
    #20
    assert(empty_n == 1);
    assert(full_n == 1);
    assert(dout == 1);
    #20 
    assert(empty_n == 1);
    assert(full_n == 1);
    assert(dout == 2);
    #20
    assert(empty_n == 0);
    assert(full_n == 1);
    assert(dout == 2);
    deq <= 0;

    // We will enqueue a data and then clear, and check if fifo becomes empty
    // again
    enq <= 1;
    din <= 3;
    #20 
    enq <= 0;
    assert(empty_n == 1);
    clr <= 1;
    #20;
    clr <= 0;
    assert(empty_n == 0);

    // We will enqueue a data and check if we can dequeue it one cycle later
    enq <= 1;
    din <= 4;
    #20
    enq <= 1;
    din <= 5;
    deq <= 1;
    assert(dout == 4);
    #20 
    enq <= 0;
    deq <= 1;
    assert(dout == 5);
    #20
    deq <= 0;
    assert(empty_n == 0);
  end 
  // Your code ends here

  initial begin
    $vcdplusfile("dump.vcd");
    $vcdplusmemon();
    $vcdpluson(0, fifo_tb);
    `ifdef FSDB
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars(0, fifo_tb);
    $fsdbDumpMDA();
    `endif
    #20000000;
    $finish(2);
  end

endmodule
