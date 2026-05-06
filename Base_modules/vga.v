`timescale 1ns / 1ps

module vga (
    input           clk,   
    input           reset,
    input           data_ready,
    input   [31:0]  rgb_in,
    output  [11:0]  rgb_out,
    output          buffer_avaliable,
    output          hsync,
    output          vsync,
    output          dvalid,
    output  [31:0]  test_wire,
    output  [9:0]   hc_wire,
    output  [9:0]   vc_wire
);

    localparam HPW = 96;
    localparam HBP = 48;
    localparam HDP = 640;
    localparam HFP = 16;
    localparam VPW = 2;
    localparam VBP = 33;
    localparam VDP = 480;
    localparam VFP = 10;

    reg read_enb;
    wire free;
    wire empty;

    assign buffer_avaliable = free;

    wire [31:0] data_buf;
    reg data_valid = 0;
    reg [11:0] data_out;

    assign dvalid = data_valid;
    assign rgb_out = data_out;
    assign test_wire = data_buf;

    wire sgp_read_enb;

    single_pulser sgp(
        .clk(clk),
        .reset(reset),
        .in(read_enb),
        .out(sgp_read_enb)
    );

    FIFO #(
        .word_size(32),
        .address_size(16)
    ) fifo_mem (
        .clk(clk),
        .reset(reset),
        .data_in(rgb_in),
        .data_out(data_buf),
        .read_enb(sgp_read_enb),
        .write_enb(data_ready),
        .free(free),
        .empty(empty)
    );

    reg has_read = 0;
    reg [1:0] sub_clk_counter = 0;

    reg [9:0] h_counter = 0;
    reg [9:0] v_counter = 0;
    reg hsync_reg = 1;
    reg vsync_reg = 1;

    assign hsync = hsync_reg;
    assign vsync = vsync_reg;
    assign hc_wire = h_counter;
    assign vc_wire = v_counter;

    always @(posedge clk ) begin
        if(reset) begin
            h_counter <= 0;
            v_counter <= 0;
            hsync_reg <= 1;
            vsync_reg <= 1;
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
            //Push data
            if((0 <= h_counter && h_counter < HDP) && (v_counter >= 0 && v_counter < VDP)) begin
                case (sub_clk_counter)
                    0: begin
                        if(!data_valid && !empty) begin
                            has_read <= 1;
                            read_enb <= 1;
                        end
                        else if(empty) data_valid <= 0;
                    end
                    1: begin
                        read_enb <= 0;
                    end
                    2: begin
                        if(has_read) begin
                            if(0 <= data_buf[31:22] && data_buf[31:22] < HDP && 0 <= data_buf[21:12] && data_buf[21:12] < VDP) data_valid <= 1;
                            else data_valid <= 0;
                            has_read <= 0;
                        end
                    end
                    3: begin
                        if(data_valid && data_buf[31:22] == h_counter && data_buf[21:12] == v_counter) begin
                            data_out <= data_buf[11:0];
                            data_valid <= 0;
                        end else begin
                            data_out <= 0;
                        end
                    end
                endcase
            end else begin
                data_out <= 0;
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

module single_pulser (
    input clk,
    input reset,
    input in,
    output out
);
    reg [1:0] state = 0;
    reg out_reg;

    assign out = out_reg;

    initial begin
        state <= 0;
    end

    always @(posedge clk ) begin
        if(reset) begin
            state <= 0;
        end else begin
            case (state)
                0: begin
                    if(in) begin
                        state <= 1;
                        out_reg <= 1;
                    end 
                end 
                1: begin
                    if(in) state <= 2;
                    else state <= 0;
                    out_reg <= 0;
                end
                2: begin
                    if(!in) state <= 0;
                end
            endcase
        end
    end
endmodule