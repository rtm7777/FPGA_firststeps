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
    output wire [5:0] led,

    output wire io_sclk,
    output wire io_sdin,
    output wire io_cs,
    output wire io_dc,
    output wire io_reset
);

    localparam WAIT_TIME = 13500000;
    reg [5:0] ledCounter = 0;

    reg [23:0] clockCounter = 0;

    wire [9:0] pixelAddress;
    wire [7:0] textPixelData, chosenPixelData;
    wire [5:0] charAddress;
    reg [7:0] charOutput;

    wire uartByteReady;
    wire [7:0] uartDataIn;
    wire [1:0] rowNumber;

    always @(posedge clk) begin
        clockCounter <= clockCounter + 24'd1;
        if (clockCounter == WAIT_TIME) begin
            clockCounter <= 0;
            ledCounter <= ledCounter + 6'd1;
        end
    end

    uart #(
        .DELAY_FRAMES(234)
    ) uart_inastance(
        .clk     (clk),
        .uart_rx (uart_rx),
        .uart_tx (uart_tx),
        .btn1    (btn1),
        .led     (led),
        .byteReady(uartByteReady),
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
        clk,
        uartByteReady,
        uartDataIn,
        charAddress[3:0],
        charOut1
    );

    always @(posedge clk) begin
        case (rowNumber)
            0: charOutput <= charOut1;
            1: charOutput <= "B";
            2: charOutput <= "C";
            3: charOutput <= "D";
        endcase
    end
    assign chosenPixelData = textPixelData;

endmodule
