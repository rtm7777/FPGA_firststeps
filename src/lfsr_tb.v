module test();
  reg clk = 0;
  wire l1Bit, l2Bit, l3Bit;

  lfsr #(
    .SEED(5'd1),
    .TAPS(5'h12),
    .NUM_BITS(5)
  ) l1(
    clk,
    l1Bit
  );

  lfsr #(
    .SEED(5'd1),
    .TAPS(5'h1B),
    .NUM_BITS(5)
  ) l2(
    clk,
    l2Bit
  );

  lfsr #(
    .SEED(5'd1),
    .TAPS(5'h1E),
    .NUM_BITS(5)
  ) l3(
    clk,
    l3Bit
  );

  always
    #1  clk = ~clk;

  initial begin
    #1000 $finish;
  end

  initial begin
    $dumpfile("lfsr.vcd");
    $dumpvars(0,test);
  end
endmodule
