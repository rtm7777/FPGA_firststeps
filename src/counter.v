module counterM
#(
    parameter WAIT_TIME = 27000000
)
(
    input wire clk,
    output reg [7:0] counterValue = 0
);
    reg [32:0] clockCounter = 0;

    always @(posedge clk) begin
        if (clockCounter == WAIT_TIME) begin
            clockCounter <= 0;
            counterValue <= counterValue + 1;
        end
        else
            clockCounter <= clockCounter + 1;
    end
endmodule