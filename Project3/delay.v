`timescale 1ns / 1ps

module delay #(
    parameter word_size = 1
) (
    input       clk,
    input  [word_size - 1:0]      din,
    output reg [word_size - 1:0]  dout
);
    always @(posedge clk ) begin
        dout <= din;
    end
endmodule