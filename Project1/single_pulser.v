`timescale 1ns / 1ps

module single_pulser (
    input       clk,
    input       din,
    input reg   dout
);
    reg [1:0] state = 0;

    always @(posedge clk ) begin
        case (state)
            0: begin
                if(din) begin
                    dout <= 1;
                    state <= 1;
                end
            end 
            1: begin
                if(din) begin
                    state <= 2;
                end else begin
                    state <= 0;
                end
                dout <= 0;
            end
            2: begin
                if(!din) begin
                    state <= 0;
                end
            end
        endcase
    end

endmodule