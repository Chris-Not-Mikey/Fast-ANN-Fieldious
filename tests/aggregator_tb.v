`define DATA_WIDTH 16
`define FETCH_WIDTH 4

module aggregator_tb;

  reg clk;
  reg rst_n;
  wire [`DATA_WIDTH - 1 : 0] fifo_dout;
  wire fifo_empty_n;
  wire fifo_deq;
  wire [`FETCH_WIDTH * `DATA_WIDTH - 1 : 0] receiver_din;
  reg  [`FETCH_WIDTH * `DATA_WIDTH - 1 : 0] expected_dout;
  reg receiver_full_n;
  wire receiver_enq;
  reg [`DATA_WIDTH - 1 : 0] fifo_din;
  wire fifo_enq;
  wire fifo_full_n;
  reg stall;

  always #10 clk =~clk;
  
  aggregator
  #(
    .DATA_WIDTH(`DATA_WIDTH),
    .FETCH_WIDTH(`FETCH_WIDTH)
  ) aggregator_inst
  (
    .clk(clk),
    .rst_n(rst_n),
    .sender_data(fifo_dout),
    .sender_empty_n(fifo_empty_n),
    .sender_deq(fifo_deq),
    .receiver_data(receiver_din),
    .receiver_full_n(receiver_full_n),
    .receiver_enq(receiver_enq)
  );

  fifo
  #(
    .DATA_WIDTH(`DATA_WIDTH),
    .FIFO_DEPTH(3),
    .COUNTER_WIDTH(1)
  ) fifo_inst (
    .clk(clk),
    .rst_n(rst_n),
    .din(fifo_din),
    .enq(fifo_enq),
    .full_n(fifo_full_n),
    .dout(fifo_dout),
    .deq(fifo_deq),
    .empty_n(fifo_empty_n),
    .clr(1'b0)
  );

  initial begin
    clk <= 0;
    rst_n <= 0;
    stall <= 0; 
    expected_dout <= 0;
    receiver_full_n <= 1;
    #20 rst_n <= 0;
    #20 rst_n <= 1;
  end

  assign fifo_enq = rst_n && fifo_full_n && (!stall);

  always @ (posedge clk) begin
    if (rst_n) begin
      stall <= $urandom % 2;
      receiver_full_n <= 1;
      if (fifo_enq) begin
        fifo_din <= fifo_din + 1;
      end
    end else begin
      fifo_din <= 0;
    end
  end

  genvar i;
  generate
    for (i = 0; i < `FETCH_WIDTH; i++) begin
      always @ (posedge clk) begin
        if (receiver_enq) begin
          assert(receiver_din[(i + 1)*`DATA_WIDTH - 1 : i * `DATA_WIDTH] == expected_dout + i);
          $display("%t: received = %d, expected = %d", $time, 
            receiver_din[(i + 1)*`DATA_WIDTH - 1 : i * `DATA_WIDTH], expected_dout + i);
        end
      end
    end
  endgenerate

  always @ (posedge clk) begin
    if (receiver_enq) begin
      expected_dout <= expected_dout + `FETCH_WIDTH;
    end 
  end

  initial begin
    $vcdplusfile("dump.vcd");
    $vcdplusmemon();
    $vcdpluson(0, aggregator_tb);
    #2000;
    $finish(2);
  end

endmodule
