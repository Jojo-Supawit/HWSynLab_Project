`timescale 1ns / 1ps

module I2C_master#(
    parameter word_number = 1
) (
    output [9:0] test_wire,

    input clk,
    input reset,
    output reg ready,
    output reg exception,
    input [6:0] addr,
    input addr_valid,
    input mode,
    input [(8*word_number) - 1:0] din,
    input din_valid,
    output [(8*word_number) - 1:0] dout,
    output dout_valid,
    input dout_ack,
    output scl,
    inout sda
);

reg [3:0] state;
reg [6:0] address;
reg rw_mode;
reg [(8*word_number) - 1:0] data_in;
reg [(8*word_number) - 1:0] data_out;
reg dvalid = 0;

reg slave_ack;

reg scl_reg = 1;
reg sda_out = 1;
reg sda_output_mode = 1;

reg [2:0] addr_send_index = 6;
reg [2:0] data_send_index = 7;
reg [9:0] word_index = word_number - 1;

assign dout = data_out;
assign dout_valid = dvalid;

assign scl = scl_reg;
assign sda = (sda_output_mode)? sda_out : 1'bz;

assign test_wire = word_index;

initial begin
    state <= 0;
    dvalid <= 0;
    sda_output_mode <= 1;
    sda_out <= 1;
    scl_reg <= 1;
    ready <= 0;
    exception <= 0;
end

reg [1:0] counter = 0;
always @(posedge clk ) begin
    if(reset) begin
        state <= 0;
        ready <= 0;
        dvalid <= 0;
        sda_output_mode <= 1;
        sda_out <= 1;
        scl_reg <= 1;
        exception <= 0;
        counter <= 0;
    end else begin
        case (state)
            0: begin
                dvalid <= 0;
                ready <= 1;
                state <= 1;
                exception <= 0;
                scl_reg <= 1;
                sda_out <= 1;
                counter <= 0;
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
                case (counter)
                    0: begin
                        sda_output_mode <= 1;
                    end
                    1: begin
                        sda_out <= 0;
                    end
                    3: begin
                        scl_reg <= 0;
                        state <= 3;
                        addr_send_index <= 6;
                    end
                endcase
                counter <= counter + 1;
            end
            3: begin
                case (counter)
                    0: begin
                        sda_out <= address[addr_send_index];
                    end
                    1: begin
                        scl_reg <= 1;
                    end
                    3: begin
                        scl_reg <= 0;
                        if(addr_send_index == 0) state <= 4;
                        else addr_send_index <= addr_send_index - 1;
                    end
                endcase
                counter <= counter + 1;
            end
            4: begin
                case (counter)
                    0: begin
                        sda_out <= rw_mode;
                    end
                    1: begin
                        scl_reg <= 1;
                    end
                    3: begin
                        scl_reg <= 0;
                        state <= 5;
                    end
                endcase
                counter <= counter + 1;
            end
            5: begin
                case (counter)
                    0: begin
                        sda_output_mode <= 0;
                    end
                    1: begin
                        scl_reg <= 1;
                    end
                    2: begin
                        slave_ack <= sda;
                    end
                    3: begin
                        scl_reg <= 0;
                        if(!slave_ack) begin
                            state <= 6;
                            data_send_index <= 7;
                            word_index <= word_number - 1;
                        end else begin
                            exception <= 1;
                            state <= 15;
                        end
                    end
                endcase
                counter <= counter + 1;
            end
            6: begin
                if(!rw_mode) begin //WRITE
                    case (counter)
                        0: begin
                            sda_output_mode <= 1;
                            sda_out <= data_in[(8*word_index) + data_send_index];
                        end
                        1: begin
                            scl_reg <= 1;
                        end
                        3: begin
                            scl_reg <= 0;
                            if(data_send_index == 0) state <= 7;
                            else data_send_index <= data_send_index - 1;
                        end
                    endcase
                end else begin //READ
                    case (counter)
                        0: begin
                            sda_output_mode <= 0;
                        end
                        1: begin
                            scl_reg <= 1;
                        end
                        2: begin
                            data_out[(8*word_index) + data_send_index] <= sda;
                        end
                        3: begin
                            scl_reg <= 0;
                            if(data_send_index == 0) state <= 7;
                            else data_send_index <= data_send_index - 1;
                        end
                    endcase
                end
                counter <= counter + 1;
            end
            7: begin
                if(!rw_mode) begin //WRITE
                    case (counter)
                        0: begin
                            sda_output_mode <= 0;
                        end
                        1: begin
                            scl_reg <= 1;
                        end
                        2: begin
                            slave_ack <= sda;
                        end
                        3: begin
                            scl_reg <= 0;
                            if(slave_ack) begin
                                exception <= 1;
                                state <= 15;
                            end 
                            else begin
                                if(word_index == 0) state <= 15;
                                else begin
                                    data_send_index <= 7;
                                    word_index <= word_index - 1;
                                    state <= 6;
                                end
                            end
                        end
                    endcase
                end else begin //READ
                    case (counter)
                        0: begin
                            sda_output_mode <= 1;
                            if(word_index == 0) sda_out <= 1;
                            else sda_out <= 0;
                        end
                        1: begin
                            scl_reg <= 1;
                        end
                        3: begin
                            scl_reg <= 0;
                            if(word_index == 0) state <= 15;
                            else begin
                                data_send_index <= 7;
                                word_index <= word_index - 1;
                                state <= 6;
                            end
                        end
                    endcase
                end
                counter <= counter + 1;
            end
            15: begin
                case (counter)
                    0: begin
                        sda_output_mode <= 1;
                        sda_out <= 0;
                    end
                    1: begin
                        scl_reg <= 1;
                    end
                    3: begin
                        sda_out <= 1;
                        state <= 0;
                    end
                endcase
                counter <= counter + 1;
            end
        endcase
    end
end

endmodule