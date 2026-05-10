`timescale 1ns / 1ps

module deboucer #(
    parameter sample_size = 1023
) (
    input  clk,
    input  din,
    output reg dout
);

    reg [15:0] counter = 0;

    always @(posedge clk ) begin
        if(counter == 0) begin
            dout <= 0;
        end else if(counter == sample_size) begin
            dout <= 1;
        end 
        if(din && counter < sample_size) counter <= counter + 1;
        else if(!din && counter > 0) counter <= counter - 1;
    end
endmodule