module textEngine (
    input  wire       clk,
    input  wire [9:0] pixelAddress,
    output wire [7:0] pixelData,
    output wire [5:0] charAddress,
    input  wire [7:0] charOutput
);
    reg [7:0] fontBuffer [1519:0];
    reg [7:0] outputBuffer;
    initial $readmemh("font.hex", fontBuffer);

    wire [2:0] columnAddress;    
    wire topRow;    

    wire [7:0] chosenChar;
    wire [10:0] fontIndex;

    assign charAddress = {pixelAddress[9:8],pixelAddress[6:3]};
    assign columnAddress = pixelAddress[2:0];
    assign topRow = !pixelAddress[7];

    assign chosenChar = (charOutput >= 32 && charOutput <= 126) ? charOutput : 32;
    assign fontIndex = ((chosenChar-8'd32) << 4) + (columnAddress << 1) + (topRow ? 0 : 1);
    assign pixelData = outputBuffer;

    always @(posedge clk) begin
        outputBuffer <= fontBuffer[fontIndex];
    end

    // wire [7:0] charOutput1, charOutput2, charOutput3, charOutput4;

    // textRow #(6'd0) t1(
    //     clk,
    //     charAddress,
    //     charOutput1
    // );
    // textRow #(6'd16) t2(
    //     clk,
    //     charAddress,
    //     charOutput2
    // );
    // textRow #(6'd32) t3(
    //     clk,
    //     charAddress,
    //     charOutput3
    // );
    // textRow #(6'd48) t4(
    //     clk,
    //     charAddress,
    //     charOutput4
    // );

    // assign charOutput = (charAddress[5] && charAddress[4]) ? charOutput4 : ((charAddress[5]) ? charOutput3 : ((charAddress[4]) ? charOutput2 : charOutput1));

endmodule

module textRow #(
    parameter ADDRESS_OFFSET = 8'd0
) (
    input  wire       clk,
    input  wire [5:0] readAddress,
    output wire [7:0] outByte
);
    reg [7:0] textBuffer [15:0];
    integer i;
    initial begin
        for (i=0; i<16; i=i+1) begin
            textBuffer[i] = 48 + ADDRESS_OFFSET + i;
        end
    end

    assign outByte = textBuffer[(readAddress-ADDRESS_OFFSET)];
endmodule

