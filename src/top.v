`default_nettype none

module top
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
    wire [7:0] pixelData;

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
        .led     (led)
    );

    screen #(
        .STARTUP_WAIT(32'd10000000)
    ) screen_instance(
        .clk(clk),
        .io_sclk(io_sclk),
        .io_sdin(io_sdin),
        .io_cs(io_cs),
        .io_dc(io_dc),
        .io_reset(io_reset), 
        .pixelAddress(pixelAddress),
        .pixelData(pixelData)
    );

    textEngine textEngine_instance(
        .clk(clk),
        .pixelAddress(pixelAddress),
        .pixelData(pixelData)
    );

endmodule
