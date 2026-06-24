module screen
#(
    parameter STARTUP_WAIT = 32'd10000000
)
(
    input  wire clk,
    output wire io_sclk,
    output wire io_sdin,
    output wire io_cs,
    output wire io_dc,
    output wire io_reset,

    output [9:0] pixelAddress,
    input [7:0] pixelData
);

    localparam STATE_INIT_POWER = 3'd0;
    localparam STATE_LOAD_INIT_CMD = 3'd1;
    localparam STATE_SEND = 3'd2;
    localparam STATE_CHECK_FINISHED_INIT = 3'd3;
    localparam STATE_LOAD_DATA = 3'd4;

    reg [31:0] counter = 0;
    reg [2:0] state = 0;
    
    reg dc = 1;
    reg sclk = 1;
    reg sdin = 0;
    reg reset = 1;
    reg cs = 0;
    
    reg [7:0] dataToSend = 0;
    reg [2:0] bitNumber = 0;
    reg [9:0] pixelCounter = 0;

    assign pixelAddress = pixelCounter;

    assign io_sclk = sclk;
    assign io_sdin = sdin;
    assign io_dc = dc;
    assign io_reset = reset;
    assign io_cs = cs;

    localparam SETUP_INSTRUCTIONS = 23;
    reg [4:0] commandIndex = 5'd0;

    function [7:0] startupCommand;
        input [4:0] idx;
        case (idx)
            5'd0:  startupCommand = 8'hAE;  // display off
            5'd1:  startupCommand = 8'h81;  // contrast value to 0x7F according to datasheet
            5'd2:  startupCommand = 8'h7F;
            5'd3:  startupCommand = 8'hA6;  // normal screen mode (not inverted)
            5'd4:  startupCommand = 8'h20;  // horizontal addressing mode
            5'd5:  startupCommand = 8'h00;
            5'd6:  startupCommand = 8'hC8;  // normal scan direction
            5'd7:  startupCommand = 8'h40;  // first line to start scanning from
            5'd8:  startupCommand = 8'hA1;  // address 0 is segment 0
            5'd9:  startupCommand = 8'hA8;  // mux ratio
            5'd10: startupCommand = 8'h3f;  // 63 (64 -1)
            5'd11: startupCommand = 8'hD3;  // display offset
            5'd12: startupCommand = 8'h00;  // no offset
            5'd13: startupCommand = 8'hD5;  // clock divide ratio
            5'd14: startupCommand = 8'h80;  // set to default ratio/osc frequency
            5'd15: startupCommand = 8'hD9;  // set precharge
            5'd16: startupCommand = 8'h22;  // switch precharge to 0x22 default
            5'd17: startupCommand = 8'hDB;  // vcom deselect level
            5'd18: startupCommand = 8'h20;  // 0x20
            5'd19: startupCommand = 8'h8D;  // charge pump config
            5'd20: startupCommand = 8'h14;  // enable charge pump
            5'd21: startupCommand = 8'hA4;  // resume RAM content
            5'd22: startupCommand = 8'hAF;  // display on
            default: startupCommand = 8'h00;
        endcase
    endfunction

    always @(posedge clk) begin
    case (state)
        STATE_INIT_POWER: begin
                counter <= counter + 1;
                if (counter < STARTUP_WAIT)
                    reset <= 1;
                else if (counter < STARTUP_WAIT * 2)
                    reset <= 0;
                else if (counter < STARTUP_WAIT * 3)
                    reset <= 1;
                else begin
                    state <= STATE_LOAD_INIT_CMD;
                    counter <= 32'b0;
                end
            end
            STATE_LOAD_INIT_CMD: begin
                dc <= 0;
                dataToSend <= startupCommand(commandIndex);
                state <= STATE_SEND;
                bitNumber <= 3'd7;
                cs <= 0;
                if (commandIndex == SETUP_INSTRUCTIONS - 1)
                    commandIndex <= 0;
                else
                    commandIndex <= commandIndex + 1;
            end
            STATE_SEND: begin
                if (counter == 32'd0) begin
                    sclk <= 0;
                    sdin <= dataToSend[bitNumber];
                    counter <= 32'd1;
                end
                else begin
                    counter <= 32'd0;
                    sclk <= 1;
                    if (bitNumber == 0)
                        state <= STATE_CHECK_FINISHED_INIT;
                    else
                        bitNumber <= bitNumber - 1;
                end
            end
            STATE_CHECK_FINISHED_INIT: begin
                cs <= 1;
                if (commandIndex == 0)
                    state <= STATE_LOAD_DATA; 
                else
                    state <= STATE_LOAD_INIT_CMD; 
            end
            STATE_LOAD_DATA: begin
                pixelCounter <= pixelCounter + 1;
                cs <= 0;
                dc <= 1;
                bitNumber <= 3'd7;
                state <= STATE_SEND;
                dataToSend <= pixelData;
            end
        endcase
    end

endmodule
