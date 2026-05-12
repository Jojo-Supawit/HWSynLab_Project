`timescale 1ns / 1ps

module filter (
    input         clk,
    input  [2:0]  filter_select,
    input  [9:0]  raw343,
    output [11:0] rgb
);
    reg [11:0] dout;
    
    assign rgb = dout;

    wire [3:0] red = {raw343[9:7], raw343[9]};
    wire [3:0] green = raw343[6:3];
    wire [3:0] blue = {raw343[2:0], raw343[2]};

    wire [11:0] white = (77*(red) + 151*(green) + 28*(blue))>>8;

    wire [3:0] ired = 15 - red;
    wire [3:0] igreen = 15 - green;
    wire [3:0] iblue = 15 - blue;

    always @(posedge clk ) begin
        case (filter_select)
            0: dout <= {red, green, blue};
            1: dout <= (red > white[3:0])? {red, white[3:0], white[3:0]} : {white[3:0], white[3:0], white[3:0]};
            2: dout <= (green > white[3:0])? {white[3:0], green, white[3:0]} : {white[3:0], white[3:0], white[3:0]};
            3: dout <= (blue > white[3:0])? {white[3:0], white[3:0], blue} : {white[3:0], white[3:0], white[3:0]};
            4: dout <= {white[3:0], white[3:0], white[3:0]};
            5: dout <= {ired, igreen, iblue};
            default: dout <= {red, green, blue};
        endcase
    end

endmodule