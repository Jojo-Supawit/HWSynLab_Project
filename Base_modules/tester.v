`timescale 1ns / 1ps

module tester;
    reg clk, reset;
    wire hsync;
    wire vsync;
    wire [11:0] rgb;
    wire dvalid;
    wire dfailed;
    wire [31:0] test_wire;
    wire [9:0] hc_wire;
    wire [9:0] vc_wire;

    top dut(
        .clk(clk),
        .reset(reset),
        .hsync(hsync),
        .vsync(vsync),
        .rgb(rgb),
        .dvalid(dvalid),
        .dfailed(dfailed),
        .test_wire(test_wire),
        .hc_wire(hc_wire),
        .vc_wire(vc_wire)
    );

    always #10 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;

        #35 reset = 0;
    end

endmodule