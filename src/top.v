`default_nettype none

module top
#(
    parameter STARTUP_WAIT = 32'd10000000
)
(
    input  wire       clk,
    input  wire       uart_rx,
    output wire       uart_tx,
    input  wire       btn1,
    input  wire       btn2,
    output wire [5:0] led,

    output wire io_sclk,
    output wire io_sdin,
    output wire io_cs,
    output wire io_dc,
    output wire io_reset,

    output wire flashClk,
    input  wire flashMiso,
    output wire flashMosi,
    output wire flashCs
);

    localparam WAIT_TIME = 13500000;
    reg [5:0] ledCounter = 0;

    reg [23:0] clockCounter = 0;

    wire [9:0] pixelAddress;
    wire [7:0] textPixelData, chosenPixelData;
    wire [5:0] charAddress;
    reg [7:0] charOutput;

    wire uartByteReady;
    wire uartMsgReady;
    wire [7:0] uartDataIn;
    wire [1:0] rowNumber;

    always @(posedge clk) begin
        clockCounter <= clockCounter + 24'd1;
        if (clockCounter == WAIT_TIME) begin
            clockCounter <= 0;
            ledCounter <= ledCounter + 6'd1;
        end
    end

    localparam BTN_DEBOUNCE_CYCLES = 25'd270000; // ~10ms @ 27MHz

    reg [1:0] btn1Sync = 2'b11;
    reg [1:0] btn2Sync = 2'b11;
    reg btn1Clean = 1;
    reg btn2Clean = 1;

    reg [24:0] btn1DebounceCounter = 0;
    reg [24:0] btn2DebounceCounter = 0;

    always @(posedge clk) begin
        btn1Sync <= {btn1Sync[0], btn1};
        btn2Sync <= {btn2Sync[0], btn2};

        if (btn1Sync[1] != btn1Clean) begin
            if (btn1DebounceCounter == BTN_DEBOUNCE_CYCLES) begin
                btn1Clean <= btn1Sync[1];
                btn1DebounceCounter <= 0;
            end else
                btn1DebounceCounter <= btn1DebounceCounter + 1;
        end else
            btn1DebounceCounter <= 0;

        if (btn2Sync[1] != btn2Clean) begin
            if (btn2DebounceCounter == BTN_DEBOUNCE_CYCLES) begin
                btn2Clean <= btn2Sync[1];
                btn2DebounceCounter <= 0;
            end else
                btn2DebounceCounter <= btn2DebounceCounter + 1;
        end else
            btn2DebounceCounter <= 0;
    end

    uart #(
        .DELAY_FRAMES(234)
    ) uart_inastance(
        .clk     (clk),
        .uart_rx (uart_rx),
        .uart_tx (uart_tx),
        .btn1    (btn1Clean),
        .led     (led),
        .byteReady(uartByteReady),
        .msgReady(uartMsgReady),
        .dataIn  (uartDataIn)
    );

    screen #(
        .STARTUP_WAIT(STARTUP_WAIT)
    ) screen_instance(
        .clk(clk),
        .io_sclk(io_sclk),
        .io_sdin(io_sdin),
        .io_cs(io_cs),
        .io_dc(io_dc),
        .io_reset(io_reset), 
        .pixelAddress(pixelAddress),
        .pixelData(chosenPixelData)
    );

    wire [7:0] charOutFlash;

    flashNavigator externalFlash(
        .clk(clk),
        .flashClk(flashClk),
        .flashMiso(flashMiso),
        .flashMosi(flashMosi),
        .flashCs(flashCs),
        .charAddress(charAddress),
        .charOutput(charOutFlash),
        .btn1(btn1Clean),
        .btn2(btn2Clean)
    );

    textEngine textEngine_instance(
        .clk(clk),
        .pixelAddress(pixelAddress),
        .pixelData(textPixelData),
        .charAddress(charAddress),
        .charOutput(charOutput)
    );

    assign rowNumber = charAddress[5:4];

    wire [7:0] charOut1;

    uartTextRow row1(
        .clk(clk),
        .byteReady(uartByteReady),
        .msgReady(uartMsgReady),
        .data(uartDataIn),
        .outputCharIndex(charAddress[3:0]),
        .outByte(charOut1)
    );

    wire [7:0] counterValue;
    wire [7:0] charOut2;

    counterM
    #(
        .WAIT_TIME(1000000)
    ) c (
        .clk(clk),
        .counterValue(counterValue)
    );

    decRow row2(
        .clk(clk),
        .value(counterValue),
        .outputCharIndex(charAddress[3:0]),
        .outByte(charOut2)
    );

    wire [7:0] progressPixelData;
    progressRow row4(
        .clk(clk),
        .value(counterValue),
        .pixelAddress(pixelAddress),
        .outByte(progressPixelData)
    );

    always @(posedge clk) begin
        case (rowNumber)
            0: charOutput <= charOut1;
            1: charOutput <= charOut2;
            2: charOutput <= "C";
            3: charOutput <= charOutFlash;
        endcase
    end
    assign chosenPixelData = (rowNumber == 2) ? progressPixelData : textPixelData;

endmodule
