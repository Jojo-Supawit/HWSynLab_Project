`timescale 1ns / 1ps

module I2C_master (
    input clk,
    input reset,
    output reg ready,
    output reg exception,
    input [6:0] addr,
    input addr_valid,
    input mode,
    input [7:0] din,
    input din_valid,
    output [7:0] dout,
    output dout_valid,
    input dout_ack,
    output scl,
    inout sda
);

reg [4:0] state;
reg [6:0] address;
reg rw_mode;
reg [7:0] data_in;
reg [7:0] data_out;
reg dvalid = 0;

reg slave_ack;

reg scl_reg = 1;
reg sda_out = 1;
reg sda_output_mode = 1;

reg [2:0] addr_send_index = 6;
reg [2:0] data_send_index = 7;

assign dout = data_out;
assign dout_valid = dvalid;

assign scl = scl_reg;
assign sda = (sda_output_mode)? sda_out : 1'bz;

initial begin
    state <= 0;
    dvalid <= 0;
    sda_output_mode <= 1;
    sda_out <= 1;
    scl_reg <= 1;
    ready <= 0;
    exception <= 0;
end

always @(posedge clk ) begin
    if(reset) begin
        state <= 0;
        ready <= 0;
        dvalid <= 0;
        sda_output_mode <= 1;
        sda_out <= 1;
        scl_reg <= 1;
        exception <= 0;
    end else begin
        case (state)
            0: begin
                dvalid <= 0;
                ready <= 1;
                state <= 1;
                exception <= 0;
                scl_reg <= 1;
                sda_out <= 1;
            end
            1: begin
                if(addr_valid && (mode || din_valid)) begin
                    address <= addr;
                    rw_mode <= mode;
                    if(!mode) data_in <= din;
                    ready <= 0;
                    state <= 2;
                end
            end
            2: begin
                sda_out <= 0;
                state <= 3;
                addr_send_index <= 6;
            end
            3: begin
                scl_reg <= 0;
                state <= 4;
            end
            4: begin
                sda_out <= address[addr_send_index];
                state <= 5;
            end
            5: begin
                scl_reg <= 1; // scl_clk = 1-7
                state <= 6;
            end
            6: begin
                if(addr_send_index > 0) begin
                    state <= 3;
                    addr_send_index <= addr_send_index - 1;
                end else begin
                    state <= 7;
                end
            end
            7: begin
                scl_reg <= 0;
                state <= 8;
            end
            8: begin
                sda_out <= rw_mode;
                state <= 9;
            end
            9: begin
                scl_reg <= 1; // scl_clk = 8
                state <= 10;
            end
            10: begin
                state <= 11;
            end
            11: begin
                scl_reg <= 0;
                state <= 12;
            end
            12: begin
                sda_output_mode <= 0;
                state <= 13;
            end
            13: begin
                scl_reg <= 1; // scl_clk = 9
                state <= 14;
                slave_ack <= 1;
            end
            14: begin
                slave_ack <= sda;
                state <= 15;
            end
            15: begin
                if(slave_ack == 0) begin
                    scl_reg <= 0;
                    state <= 16;
                    data_send_index <= 7;
                end else begin
                    state <= 31;
                    exception <= 1;
                    sda_output_mode <= 1;
                end
            end
            16: begin
                if(!rw_mode) begin
                    sda_output_mode <= 1;
                    sda_out <= data_in[data_send_index];
                end
                state <= 17;
            end
            17: begin
                scl_reg <= 1; // scl_clk = 10-17
                state <= 18;
            end
            18:begin
                if(rw_mode) begin
                    data_out[data_send_index] <= sda;
                end
                state <= 19;
            end
            19: begin
                scl_reg <= 0;
                if(data_send_index > 0) begin
                    data_send_index <= data_send_index - 1;
                    state <= 16;
                end else begin
                    state <= 20;
                end
            end
            20: begin
                if(!rw_mode) sda_output_mode <= 0;
                else sda_output_mode <= 1;
                sda_out <= 0;
                state <= 21;
            end
            21: begin
                scl_reg <= 1; // scl_clk = 18
                state <= 22;
                slave_ack <= 1;
            end
            22: begin
                if(!rw_mode) slave_ack <= sda;
                state <= 23;
            end
            23: begin
                sda_output_mode <= 1;
                if(!rw_mode && slave_ack != 0) begin
                    exception <= 1;
                    state <= 31;
                end else begin
                    scl_reg <= 0;
                    if(rw_mode) begin
                        dvalid <= 1;
                    end
                    state <= 24;
                end
            end
            24: begin
                sda_out <= 0;
                state <= 25;
            end
            25: begin
                scl_reg <= 1;
                state <= 26;
            end
            26: begin
                sda_out <= 1;
                if(dout_ack || !rw_mode) begin
                    dvalid <= 0;
                    state <= 0;
                end
            end
            31: begin
                sda_out <= 1;
                state <= 0;
            end
        endcase
    end
end
endmodule