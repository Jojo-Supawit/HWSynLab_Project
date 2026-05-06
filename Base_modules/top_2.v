`timescale 1ns / 1ps

module top_2 (
    input   clk,
    input   reset,
    output  hsync,       // horizontal sync
    output  vsync,       // vertical sync  
    output  [11:0] rgb
);

    reg data_ready;
    reg [9:0] h_counter;
    reg [9:0] v_counter;
    reg [31:0] data_in;
    wire free;

    vga_with_buffer vwb(
        .clk(clk),
        .reset(reset),
        .data_ready(data_ready),
        .rgb_in(data_in),
        .rgb_out(rgb),
        .buffer_free(free),
        .hsync(hsync),
        .vsync(vsync)
    );

    always @(posedge clk ) begin
        if(reset) begin
            h_counter <= 0;
            v_counter <= 0;
            data_in <= 0;
            data_ready <= 0;
        end else begin
            if(free) begin
                if(h_counter < 320 && v_counter < 240) data_in[11:0] <= 15;
                else if(h_counter >= 320 && v_counter < 240) data_in[11:0] <= 15<<4;
                else if(h_counter < 320 && v_counter >= 240) data_in[11:0] <= 15<<8;
                else data_in[11:0] <= 4095;
                data_in[31:22] <= h_counter;
                data_in[21:12] <= v_counter;
                // if(v_counter < 240) data_in <= 4095;
                // else data_in <= 0;
                // data_in <= 15;
                // data_in <= h_counter;
                data_ready <= 1;
                if(h_counter == 639) begin
                    if(v_counter == 479) v_counter <= 0;
                    else v_counter <= v_counter + 1;
                    h_counter <= 0;
                end else h_counter <= h_counter + 1;
            end else begin
                data_ready <= 0;
            end
        end
    end

endmodule