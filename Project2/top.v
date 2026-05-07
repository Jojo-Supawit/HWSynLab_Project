`timescale 1ns / 1ps

module top (
    input   clk,
    input   reset,

    output  scl,
    inout   sda,
    output  camera_reset,
    output  camera_pwdn,
    output  camera_xclk,
    input   camera_pclk,
    input   [7:0] camera_din,
    input   camera_href,
    input   camera_vsync,

    output  hsync,       // horizontal sync
    output  vsync,       // vertical sync  
    output  [11:0] rgb
);
    wire xclk_gen;
    reg  xclk_counter = 0;
    wire nclk;
    wire [1:0] subclk_counter;

    wire video_on;
    wire [9:0] h_index;
    wire [9:0] v_index;
    // wire [19:0] address = {v_index, h_index};
    reg  [11:0] rgb_reg = 0;
    reg  vga_sync = 0;

    wire [31:0] camera_dout;
    wire [31:0] delay_camera_dout;
    wire camera_dvalid;
    wire sgp_camera_dvalid;
    wire camera_synchronized;

    wire [31:0] data_buf;
    // wire read_next = data_buf[31:22] == v_index && data_buf[21:12] == h_index && video_on && subclk;
    reg read_next = 0;
    // reg called_read = 0;
    reg write_enb;
    reg [31:0] fifo_in;
    // reg [19:0] last_address = 20'hFFFFF;
    wire free;
    wire slow;

    assign rgb = rgb_reg;

    assign camera_xclk = xclk_counter;
    assign camera_pwdn = 0;
    assign camera_reset = !reset;

    clk_wiz_0 clk_wiz(
        .clk_in1(clk),
        .clk_out1(xclk_gen),
        .clk_out2(nclk)
    );

    vga_slave_controller vc(
        .clk(nclk),
        .reset(reset),
        .master_sync(vga_sync),
        .video_on(video_on),
        .h_index(h_index),
        .v_index(v_index),
        .hsync(hsync),
        .vsync(vsync),
        .subclk(subclk_counter)
    );

    camera cam(
        .pclk(camera_pclk),
        .reset(reset),
        .din(camera_din),
        .href(camera_href),
        .vsync(camera_vsync),
        .dout(camera_dout),
        .dvalid(camera_dvalid),
        .synchronized(camera_synchronized)
    );

    single_pulser sgp(
        .clk(nclk),
        .din(camera_dvalid),
        .dout(sgp_camera_dvalid)
    );

    delay #(
        .word_size(32)
    ) dout_delay(
        .clk(nclk),
        .din(camera_dout),
        .dout(delay_camera_dout)
    );

    FIFO #(
        .word_size(32),
        .address_size(14)
    ) fifo_mem (
        .clk(nclk),
        .reset(reset),
        .data_in(fifo_in),
        .data_out(data_buf),
        .read_enb(read_next),
        .write_enb(write_enb),
        .free(free),
        .trigger(slow)
    );

    ila_0 ila_inst(
        .clk(nclk),
        .probe0(hsync),
        .probe1(vsync),
        .probe2(rgb),
        .probe3(h_index),
        .probe4(v_index),
        .probe5(sgp_camera_dvalid),
        .probe6(delay_camera_dout),
        .probe7(data_buf),
        .probe8(slow),
        .probe9(write_enb),
        .probe10(read_next)
    );

    always @(posedge xclk_gen && !(slow && camera_href)) begin
        if(reset) begin
            xclk_counter <= 0;
        end else begin
            xclk_counter <= !xclk_counter;
        end
    end

    always @(posedge nclk ) begin
        if(reset) begin
            vga_sync <= 0;
        end else begin
            if(free && camera_synchronized && sgp_camera_dvalid) begin
                vga_sync <= 1;
                fifo_in <= delay_camera_dout;
                write_enb <= sgp_camera_dvalid;
                // last_address <= delay_camera_dout[31:12];
            end else begin
                write_enb <= 0;
            end
        end
    end

    always @(posedge nclk) begin
        if(reset) begin

        end else begin
            case (subclk_counter)
                0: begin
                    read_next <= 0;
                end
                1: begin
                    if(data_buf == 32'hFFFFFFFF) begin
                        read_next <= 1;
                    end
                end
                2: begin
                    read_next <= 0;
                end
                3: begin
                    if(video_on && data_buf[31:22] == v_index && data_buf[21:12] == h_index) begin
                        rgb_reg <= data_buf[11:0];
                        read_next <= 1;
                    end else if(!video_on) begin
                        rgb_reg <= 0;
                    end
                end
            endcase
        end
    end

endmodule

