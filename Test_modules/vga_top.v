`timescale 1ns / 1ps

module vga_top (
    input   clk,
    input   reset,
    output  hsync,       // horizontal sync
    output  vsync,       // vertical sync  
    output  [11:0] rgb
);

wire video_on;
wire p_tick;

reg vga_enb;

vga_controller vga_control(
    .clk_100MHz(clk),
    .reset(reset || !vga_enb),
    .video_on(video_on),
    .hsync(hsync),
    .vsync(vsync),
    .p_tick(p_tick)
);

reg [11:0] fifo_in;
reg read_enb;
reg write_enb;

FIFO #(
    .word_size(12),
    .address_size(16)
) fifo_mem (
    .clk(clk),
    .reset(reset),
    .data_in(fifo_in),
    .data_out(rgb),
    .read_enb(read_enb),
    .write_enb(write_enb)
);

reg [11:0] counter = 0;
reg [3:0] start_counter = 0;

initial begin
    counter <= 0;
    read_enb <= 0;
    write_enb <= 0;
    vga_enb <= 0;
    start_counter <= 0;
end

always @(posedge clk) begin
    if(reset) begin
        counter <= 0;
        read_enb <= 0;
        write_enb <= 0;
        vga_enb <= 0;
    end else begin
        if(start_counter < 4) begin
            write_enb <= 1;
            fifo_in <= counter;
            counter <= counter + 1;
            start_counter <= start_counter + 1;
            if(start_counter == 3) begin
                // read_enb <= 1;
                vga_enb <= 1;
            end 
        end else begin
            read_enb <= video_on && p_tick;
            write_enb <= video_on && p_tick;
            if(video_on && p_tick) begin
                fifo_in <= counter;
                if(counter == 639)  counter <= 0;
                else counter <= counter + 1;
            end
        end

    end

end
    
endmodule

