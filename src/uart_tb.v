module test();
    reg clk = 0;
    reg uart_rx = 1;
    wire uart_tx;
    reg btn1 = 1;
    wire [5:0] led;

    uart #(8'd8) u(
        clk,
        uart_rx,
        uart_tx,
        btn1,
        led
    );

    always
        #1  clk = ~clk;

    initial begin
        $display("Starting UART RX");
        $monitor("LED Value %b", led);
        #10 uart_rx=0;
        #16 uart_rx=1;
        #16 uart_rx=0;
        #16 uart_rx=0;
        #16 uart_rx=0;
        #16 uart_rx=0;
        #16 uart_rx=1;
        #16 uart_rx=1;
        #16 uart_rx=0;
        #16 uart_rx=1;
        #4 btn1=0;
        #4 btn1=1;
        #1000 $finish;
    end

    initial begin
        $dumpfile("uart.vcd");
        $dumpvars(0,test);
    end
endmodule