`timescale 1ns / 1ps

module vga_slave_controller (
    input           clk,   
    input           reset,
    input           master_sync,
    output          video_on,
    output  [9:0]   h_index,
    output  [9:0]   v_index,
    output          hsync,
    output          vsync,
    output  [1:0]   subclk
);

    localparam HPW = 96;
    localparam HBP = 48;
    localparam HDP = 640;
    localparam HFP = 16;
    localparam VPW = 2;
    localparam VBP = 33;
    localparam VDP = 480;
    localparam VFP = 10;

    reg [1:0] sub_clk_counter = 0;
    assign subclk = sub_clk_counter;

    reg [9:0] h_counter = 0;
    reg [9:0] v_counter = 0;
    reg hsync_reg = 1;
    reg vsync_reg = 1;

    assign hsync = hsync_reg;
    assign vsync = vsync_reg;
    assign video_on = (0 <= h_counter && h_counter < HDP) && (v_counter >= 0 && v_counter < VDP);
    assign h_index = h_counter;
    assign v_index = v_counter;

    always @(posedge clk ) begin
        if(reset || !master_sync) begin
            h_counter <= 0;
            v_counter <= 0;
            hsync_reg <= 1;
            vsync_reg <= 1;
            sub_clk_counter <= 0;
        end else begin
            //Hsync
            if(HDP + HFP <= h_counter && h_counter < HDP + HFP + HPW) begin
                hsync_reg <= 0;
            end else begin
                hsync_reg <= 1;
            end
            //Vsync
            if(VDP + VFP <= v_counter && v_counter < VDP + VFP + VPW) begin
                vsync_reg <= 0;
            end else begin
                vsync_reg <= 1;
            end
            //Counter
            if(sub_clk_counter == 3) begin
                if(h_counter == HPW + HBP + HDP + HFP - 1) begin
                    if(v_counter == VPW + VBP + VDP + VFP - 1) v_counter <= 0;
                    else v_counter <= v_counter + 1;
                    h_counter <= 0;
                end else begin
                    h_counter <= h_counter + 1;
                end
            end
            sub_clk_counter <= sub_clk_counter + 1;
        end
    end
    
endmodule