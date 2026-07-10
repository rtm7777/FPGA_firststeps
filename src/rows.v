module uartTextRow (
    input wire clk,
    input wire byteReady,
    input wire msgReady,
    input wire [7:0] data,
    input wire [3:0] outputCharIndex,
    output wire [7:0] outByte
);
    localparam bufferWidth = 128;
    reg [(bufferWidth-1):0] inputBuffer = 0;
    reg [(bufferWidth-1):0] renderBuffer = 0;
    reg [3:0] inputCharIndex = 0;
    reg [1:0] state = 0;
    reg msgConsumed = 0;

    localparam WAIT_FOR_NEXT_CHAR_STATE = 0;
    localparam WAIT_FOR_TRANSFER_FINISH = 1;
    localparam SAVING_CHARACTER_STATE = 2;
    localparam RENDERING_STATE = 3;

    always @(posedge clk) begin
        case (state)
            WAIT_FOR_NEXT_CHAR_STATE: begin
                if (msgReady == 0) msgConsumed <= 0;

                if (byteReady == 0) begin
                    state <= WAIT_FOR_TRANSFER_FINISH;
                end else if ((msgReady == 1) && (msgConsumed == 0)) begin
                    state <= RENDERING_STATE;
                end
            end
            WAIT_FOR_TRANSFER_FINISH: begin
                if (byteReady == 1)
                    state <= SAVING_CHARACTER_STATE;
            end
            SAVING_CHARACTER_STATE: begin
                inputCharIndex <= inputCharIndex + 1;
                inputBuffer[({4'd0,inputCharIndex}<<3)+:8] <= data;
                state <= WAIT_FOR_NEXT_CHAR_STATE;
            end
            RENDERING_STATE: begin
                renderBuffer <= inputBuffer;
                inputCharIndex <= 0;
                inputBuffer <= 0;
                msgConsumed <= 1;
                state <= WAIT_FOR_NEXT_CHAR_STATE;
            end
        endcase
    end

    assign outByte = renderBuffer[({4'd0, outputCharIndex} << 3)+:8];
endmodule

module decRow(
    input wire clk,
    input wire [7:0] value,
    input wire [3:0] outputCharIndex,
    output wire [7:0] outByte
);
    reg [7:0] outByteReg;

    wire [7:0] decChar1, decChar2, decChar3;
    toDec dec(clk, value, decChar1, decChar2, decChar3);
    
    always @(posedge clk) begin
        case (outputCharIndex)
            0: outByteReg <= "D";
            1: outByteReg <= "e";
            2: outByteReg <= "c";
            3: outByteReg <= ":";
            4:outByteReg <= decChar1;
            5: outByteReg <= decChar2;
            6: outByteReg <= decChar3;
            default: outByteReg <= " ";
        endcase
    end

    assign outByte = outByteReg;
endmodule

module toDec(
    input wire clk,
    input wire [7:0] value,
    output reg [7:0] hundreds = "0",
    output reg [7:0] tens = "0",
    output reg [7:0] units = "0"
);
    reg [11:0] digits = 0;
    reg [7:0] cachedValue = 0;
    reg [3:0] stepCounter = 0;
    reg [3:0] state = 0;

    localparam START_STATE = 0;
    localparam ADD3_STATE = 1;
    localparam SHIFT_STATE = 2;
    localparam DONE_STATE = 3;

    always @(posedge clk) begin
        case (state)
            START_STATE: begin
            cachedValue <= value;
            stepCounter <= 0;
            digits <= 0;
            state <= ADD3_STATE;
        end
        ADD3_STATE: begin
            digits <= digits + 
                ((digits[3:0] >= 5) ? 12'd3 : 12'd0) + 
                ((digits[7:4] >= 5) ? 12'd48 : 12'd0) + 
                ((digits[11:8] >= 5) ? 12'd768 : 12'd0);
            state <= SHIFT_STATE;
        end
        SHIFT_STATE: begin
            digits <= {digits[10:0],cachedValue[7]};
            cachedValue <= {cachedValue[6:0],1'b0};
            if (stepCounter == 7)
                state <= DONE_STATE;
            else begin
                state <= ADD3_STATE;
                stepCounter <= stepCounter + 1;
            end
        end
        DONE_STATE: begin
            hundreds <= 8'd48 + digits[11:8];
            tens <= 8'd48 + digits[7:4];
            units <= 8'd48 + digits[3:0];
            state <= START_STATE;
        end
        endcase
    end
endmodule

module progressRow(
    input wire clk,
    input wire [7:0] value,
    input wire [9:0] pixelAddress,
    output wire [7:0] outByte
);
    reg [7:0] outByteReg;
    wire [6:0] column;

    assign column  = pixelAddress[6:0];

    reg [7:0] bar, border;
    wire topRow;

    assign topRow = !pixelAddress[7];

    always @(posedge clk) begin
    if (topRow) begin
        case (column)
            0, 127: begin
                bar = 8'b11000000;
                border = 8'b11000000;
            end
            1, 126: begin
                bar = 8'b11100000;
                border = 8'b01100000;
            end
            2, 125: begin
                bar = 8'b11100000;
                border = 8'b00110000;
            end
            default: begin
                bar = 8'b11110000;
                border = 8'b00010000;
            end
        endcase
    end
    else begin
        case (column)
            0, 127: begin
                bar = 8'b00000011;
                border = 8'b00000011;
            end
            1, 126: begin
                bar = 8'b00000111;
                border = 8'b00000110;
            end
            2, 125: begin
                bar = 8'b00000111;
                border = 8'b00001100;
            end
            default: begin
                bar = 8'b00001111;
                border = 8'b00001000;
            end
        endcase
    end

    if (column > value[7:1])
        outByteReg <= border;
    else
        outByteReg <= bar;
end

    assign outByte = outByteReg;
endmodule
