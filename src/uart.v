module uart
#(
    parameter DELAY_FRAMES = 234 // 27,000,000 (27Mhz) / 115200 Baud rate
)
(
    input  wire       clk,
    input  wire       uart_rx,
    output wire       uart_tx,
    input  wire       btn1,
    output reg  [5:0] led
);
    localparam HALF_DELAY_WAIT = (DELAY_FRAMES / 2);
    localparam MEMORY_LENGTH = 11;

    reg [7:0] testMemory [MEMORY_LENGTH-1:0];

    initial begin
        testMemory[0] = "I";
        testMemory[1] = "O";
        testMemory[2] = "T";
        testMemory[3] = ".";
        testMemory[4] = "C";
        testMemory[5] = "K";
        testMemory[6] = ".";
        testMemory[7] = "U";
        testMemory[8] = "A";
        testMemory[9] = 8'h0D;
        testMemory[10] = 8'h0A; 
    end

    localparam RX_STATE_IDLE = 0;
    localparam RX_STATE_START_BIT = 1;
    localparam RX_STATE_READ_WAIT = 2;
    localparam RX_STATE_READ = 3;
    localparam RX_STATE_STOP_BIT = 4;

    localparam TX_STATE_IDLE = 0;
    localparam TX_STATE_START_BIT = 1;
    localparam TX_STATE_WRITE = 2;
    localparam TX_STATE_STOP_BIT = 3;
    localparam TX_STATE_DEBOUNCE = 4;

    reg [3:0] rxState = 0;
    reg [12:0] rxCounter = 0;
    reg [2:0] rxBitNumber = 0;
    reg [7:0] dataIn = 0;
    reg byteReady = 0;

    reg [3:0] txState = 0;
    reg [24:0] txCounter = 0;
    reg [7:0] dataOut = 0;
    reg txPinRegister = 1;
    reg [2:0] txBitNumber = 0;
    reg [3:0] txByteCounter = 0;

    assign uart_tx = txPinRegister;

    // Synchronize and debounce btn1 so the FSM only ever sees a clean,
    // stable level (raw button bounce was glitching the FSM mid-transmission).
    localparam BTN_DEBOUNCE_CYCLES = 25'd270000; // ~10ms @ 27MHz

    reg [1:0] btn1Sync = 2'b11;
    reg btn1Clean = 1;
    reg [24:0] btn1DebounceCounter = 0;

    always @(posedge clk) begin
        btn1Sync <= {btn1Sync[0], btn1};

        if (btn1Sync[1] != btn1Clean) begin
            if (btn1DebounceCounter == BTN_DEBOUNCE_CYCLES) begin
                btn1Clean <= btn1Sync[1];
                btn1DebounceCounter <= 0;
            end else
                btn1DebounceCounter <= btn1DebounceCounter + 1;
        end else
            btn1DebounceCounter <= 0;
    end

    always @(posedge clk) begin
        case (rxState)
            RX_STATE_IDLE: begin
                if (uart_rx == 0) begin
                    rxState <= RX_STATE_START_BIT;
                    rxCounter <= 1;
                    rxBitNumber <= 0;
                    byteReady <= 0;
                end
            end 
            RX_STATE_START_BIT: begin
                if (rxCounter == HALF_DELAY_WAIT) begin
                    rxState <= RX_STATE_READ_WAIT;
                    rxCounter <= 1;
                end else 
                    rxCounter <= rxCounter + 1;
            end
            RX_STATE_READ_WAIT: begin
                rxCounter <= rxCounter + 1;
                if ((rxCounter + 1) == DELAY_FRAMES) begin
                    rxState <= RX_STATE_READ;
                end
            end
            RX_STATE_READ: begin
                rxCounter <= 1;
                dataIn <= {uart_rx, dataIn[7:1]};
                rxBitNumber <= rxBitNumber + 1;
                if (rxBitNumber == 3'b111)
                    rxState <= RX_STATE_STOP_BIT;
                else
                    rxState <= RX_STATE_READ_WAIT;
            end
            RX_STATE_STOP_BIT: begin
                rxCounter <= rxCounter + 1;
                if ((rxCounter + 1) == DELAY_FRAMES) begin
                    rxState <= RX_STATE_IDLE;
                    rxCounter <= 0;
                    byteReady <= 1;
                end
            end
        endcase
    end

    always @(posedge clk) begin
        if (byteReady) begin
            led <= ~dataIn[5:0];
        end
    end

    always @(posedge clk) begin
        case (txState)
            TX_STATE_IDLE: begin
                if (btn1Clean == 0) begin
                    txState <= TX_STATE_START_BIT;
                    txCounter <= 0;
                    txByteCounter <= 0;
                end
                else begin
                    txPinRegister <= 1;
                end
            end 
            TX_STATE_START_BIT: begin
                txPinRegister <= 0;
                if ((txCounter + 1) == DELAY_FRAMES) begin
                    txState <= TX_STATE_WRITE;
                    dataOut <= testMemory[txByteCounter];
                    txBitNumber <= 0;
                    txCounter <= 0;
                end else 
                    txCounter <= txCounter + 1;
            end
            TX_STATE_WRITE: begin
                txPinRegister <= dataOut[txBitNumber];
                if ((txCounter + 1) == DELAY_FRAMES) begin
                    if (txBitNumber == 3'b111) begin
                        txState <= TX_STATE_STOP_BIT;
                    end else begin
                        txState <= TX_STATE_WRITE;
                        txBitNumber <= txBitNumber + 1;
                    end
                    txCounter <= 0;
                end else 
                    txCounter <= txCounter + 1;
            end
            TX_STATE_STOP_BIT: begin
                txPinRegister <= 1;
                if ((txCounter + 1) == DELAY_FRAMES) begin
                    if (txByteCounter == MEMORY_LENGTH - 1) begin
                        txState <= TX_STATE_DEBOUNCE;
                    end else begin
                        txByteCounter <= txByteCounter + 1;
                        txState <= TX_STATE_START_BIT;
                    end
                    txCounter <= 0;
                end else 
                    txCounter <= txCounter + 1;
            end
            TX_STATE_DEBOUNCE: begin
                if (btn1Clean == 1)
                    txState <= TX_STATE_IDLE;       // button released (already debounced)
            end
        endcase      
    end

endmodule
