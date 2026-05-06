`timescale 1ns / 1ps

module top (
    // output  [31:0]  test_wire,
    // output  [9:0]   h_pos,
    // output  [9:0]   v_pos,
    // output          dvalid,

    input   clk,
    input   reset,
    output  hsync,       // horizontal sync
    output  vsync,       // vertical sync  
    output  [11:0] rgb
);

    wire [9:0] h_index;
    wire [9:0] v_index;
    wire video_on;
    wire subclk;

    // ila_0 ila_inst(
    //     .clk(clk),
    //     .probe0(hsync),
    //     .probe1(vsync),
    //     .probe2(rgb),
    //     .probe3(h_index),
    //     .probe4(v_index)
    // );

    vga_controller vc(
        .clk(clk),
        .reset(reset),
        .video_on(video_on),
        .h_index(h_index),
        .v_index(v_index),
        .hsync(hsync),
        .vsync(vsync),
        .subclk(subclk)
    );

    wire [31:0] data_buf;
    // wire data_valid = (0 <= data_buf[31:22] && data_buf[31:22] < 640) && (0 <= data_buf[21:12] && data_buf[21:12] < 480) && !reset;
    // wire read_next = (!data_valid || (data_buf[31:22] == h_index && data_buf[21:12] == v_index)) && !reset;
    reg data_valid = 0;
    reg read_next = 0;
    reg write_enb = 0;
    wire free;

    reg [31:0] fifo_in;

    FIFO #(
        .word_size(32),
        .address_size(10)
    ) fifo_mem (
        .clk(clk),
        .reset(reset),
        .data_in(fifo_in),
        .data_out(data_buf),
        .read_enb(read_next),
        .write_enb(write_enb),
        .free(free)
    );

    reg [11:0] rgb_reg = 0;
    assign rgb = rgb_reg;

    reg [9:0] write_h = 0;
    reg [9:0] write_v = 0;

    //Test
    // assign test_wire = data_buf;
    // assign h_pos = h_index;
    // assign v_pos = v_index;
    // assign dvalid = data_valid;
    //

    always @(posedge clk ) begin
        if(reset) begin
            write_h <= 0;
            write_v <= 0;
        end else begin
            if(free) begin
                if(write_h < 320 && write_v < 240) fifo_in[11:0] <= 15;
                else if(write_h >= 320 && write_v < 240) fifo_in[11:0] <= 15<<4;
                else if(write_h < 320 && write_v >= 240) fifo_in[11:0] <= 15<<8;
                else fifo_in[11:0] <= 4095;
                fifo_in[31:22] <= write_h;
                fifo_in[21:12] <= write_v;
                // if(write_v < 240) fifo_in <= 4095;
                // else fifo_in <= 0;
                // fifo_in <= 15;
                // fifo_in <= write_h;
                write_enb <= 1;
                if(write_h == 639) begin
                    if(write_v == 479) write_v <= 0;
                    else write_v <= write_v + 1;
                    write_h <= 0;
                end else write_h <= write_h + 1;
            end else begin
                write_enb <= 0;
            end
        end
    end

    always @(posedge clk) begin
        if(reset) begin

        end else begin
            if(subclk) begin
                if(video_on && data_valid && (data_buf[31:22] == h_index && data_buf[21:12] == v_index)) begin
                    rgb_reg <= data_buf[11:0];
                    data_valid <= 0;
                end else begin
                    rgb_reg <= 0;
                end
            end else begin
                if(!data_valid) begin
                    if(!read_next) begin
                        read_next <= 1;
                    end else begin
                        read_next <= 0;
                        if((0 <= data_buf[31:22] && data_buf[31:22] < 640) && (0 <= data_buf[21:12] && data_buf[21:12] < 480)) data_valid <= 1;
                    end
                end
            end
        end
    end
    
endmodule