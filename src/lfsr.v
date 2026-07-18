module lfsr
#(
  parameter SEED = 5'd1,
  parameter TAPS = 5'h1B,
  parameter NUM_BITS = 5
)
(
    input wire clk,
    output reg randomBit
);

  reg [NUM_BITS-1:0] sr = SEED;

  wire finalFeedback;
  
always @(posedge clk) begin
  sr <= {sr[NUM_BITS-2:0],finalFeedback};
  randomBit <= sr[NUM_BITS-1];
end

genvar i;
generate
  for (i = 0; i < NUM_BITS; i = i + 1) begin: lf
    wire feedback;
    if (i == 0) begin: first
      assign feedback = sr[i] & TAPS[i];
    end else begin: rest
      assign feedback = lf[i-1].feedback ^ (sr[i] & TAPS[i]);
    end
  end
endgenerate

assign finalFeedback = lf[NUM_BITS-1].feedback;
  
endmodule
