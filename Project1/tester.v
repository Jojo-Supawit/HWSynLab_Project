`timescale 1ns / 1ps

module tester;
    reg clk, reset;
    wire hsync;
    wire vsync;
    wire [11:0] rgb;
    wire [31:0] test_wire;
    wire [9:0] hc_wire;
    wire [9:0] vc_wire;
    wire dvalid;

    top dut(
        .clk(clk),
        .reset(reset),
        .hsync(hsync),
        .vsync(vsync),
        .rgb(rgb),
        .test_wire(test_wire),
        .h_pos(hc_wire),
        .v_pos(vc_wire),
        .dvalid(dvalid)
    );

    always #10 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;

        #35 reset = 0;
    end

endmodule