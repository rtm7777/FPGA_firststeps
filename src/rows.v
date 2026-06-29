module uartTextRow (
    input wire clk,
    input wire byteReady,
    input wire [7:0] data,
    input wire [3:0] outputCharIndex,
    output wire [7:0] outByte
);
    localparam bufferWidth = 128;
    reg [(bufferWidth-1):0] textBuffer = 0;
    reg [3:0] inputCharIndex = 0;
    reg [1:0] state = 0;

    localparam WAIT_FOR_NEXT_CHAR_STATE = 0;
    localparam WAIT_FOR_TRANSFER_FINISH = 1;
    localparam SAVING_CHARACTER_STATE = 2;

    always @(posedge clk) begin
        case (state)
            WAIT_FOR_NEXT_CHAR_STATE: begin
                if (byteReady == 0)
                    state <= WAIT_FOR_TRANSFER_FINISH;
            end
            WAIT_FOR_TRANSFER_FINISH: begin
                if (byteReady == 1)
                    state <= SAVING_CHARACTER_STATE;
            end
            SAVING_CHARACTER_STATE: begin
                inputCharIndex <= inputCharIndex + 1;
                textBuffer[({4'd0,inputCharIndex}<<3)+:8] <= data;
                state <= WAIT_FOR_NEXT_CHAR_STATE;
            end
        endcase
    end

    assign outByte = textBuffer[({4'd0, outputCharIndex} << 3)+:8];
endmodule
