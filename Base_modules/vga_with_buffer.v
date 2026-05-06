`timescale 1ns / 1ps

module vga_with_buffer (
    input           clk,   
    input           reset,
    input           data_ready,
    input   [31:0]  rgb_in,
    output  [11:0]  rgb_out,
    output          buffer_free,
    output          hsync,
    output          vsync
);

    localparam HPW = 96;
    localparam HBP = 48;
    localparam HDP = 640;
    localparam HFP = 16;
    localparam VPW = 2;
    localparam VBP = 33;
    localparam VDP = 480;
    localparam VFP = 10;

    localparam word_size = 32;
    localparam address_size = 10;
    localparam FIFO_SIZE = (1<<address_size);

    reg [word_size - 1:0] mem [0:FIFO_SIZE - 1];
    reg [address_size - 1:0] read_ptr = 0;
    reg [address_size - 1:0] write_ptr = 0;
    reg [address_size:0] size = 0;

    reg read_enb = 0;
    wire write_enb = data_ready;

    reg [31:0] data_buf;
    reg data_valid = 0;
    reg [11:0] data_out;

    reg [1:0] sub_clk_counter = 0;

    reg [9:0] h_counter = 0;
    reg [9:0] v_counter = 0;
    reg hsync_reg = 1;
    reg vsync_reg = 1;

    assign buffer_free = size < FIFO_SIZE;
    assign rgb_out = data_out;
    assign hsync = hsync_reg;
    assign vsync = vsync_reg;

    always @(posedge clk ) begin
        if(reset) begin
            read_ptr <= 0;
            write_ptr <= 0;
            size <= 0;
            h_counter <= 0;
            v_counter <= 0;
            hsync_reg <= 1;
            vsync_reg <= 1;
        end else begin
            //FIFO
            if(read_enb && write_enb) begin
                if(size == FIFO_SIZE) begin
                    data_buf <= mem[read_ptr];
                    read_ptr <= read_ptr + 1;
                    size <= size - 1;
                end else if(size == 0) begin
                    mem[write_ptr] <= rgb_in;
                    write_ptr <= write_ptr + 1;
                    size <= size + 1;
                end else begin
                    data_buf <= mem[read_ptr];
                    read_ptr <= read_ptr + 1;
                    mem[write_ptr] <= rgb_in;
                    write_ptr <= write_ptr + 1;
                end
            end else if(read_enb) begin
                if(size > 0) begin
                    data_buf <= mem[read_ptr];
                    read_ptr <= read_ptr + 1;
                    size <= size - 1;
                end
            end else if(write_enb) begin
                if(size < FIFO_SIZE) begin
                    mem[write_ptr] <= rgb_in;
                    write_ptr <= write_ptr + 1;
                    size <= size + 1;
                end
            end

            //VGA
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
                        if(size > 0 && !data_valid) begin
                            read_enb <= 1;
                        end
                    end
                    1: begin
                        if(read_enb) begin
                            if(0 <= data_buf[31:22] && data_buf[31:22] < HDP && 0 <= data_buf[21:12] && data_buf[21:12] < VDP) data_valid <= 1;
                            else data_valid <= 0;
                            read_enb <= 0;
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