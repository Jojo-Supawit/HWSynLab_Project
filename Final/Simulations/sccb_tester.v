`timescale 1ns / 1ps

module sccb_tester (
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
    output  [11:0] rgb,

    input [15:0] sw,
    input btnR
);
    wire xclk_gen;
    wire nclk;
    wire sccb_clk;
    wire [1:0] subclk_counter;

    wire video_on;
    wire [9:0] h_index;
    wire [9:0] v_index;
    // wire [19:0] address = {v_index, h_index};
    reg  [11:0] rgb_reg = 0;
    reg  vga_sync = 0;
    reg  vga_out_group = 1;

    wire [31:0] camera_dout;
    wire [31:0] delay_camera_dout;
    wire camera_dvalid;
    wire sgp_camera_dvalid;
    wire camera_synchronized;
    wire sgp_camera_vsync;
    reg  data_group = 0;

    reg  [17:0] read_address = 0;
    reg  [17:0] write_address = 0;
    reg  write_enb = 0;
    reg  [9:0] mem_in;
    wire [9:0] data_buf;

    assign rgb = rgb_reg;

    assign camera_xclk = xclk_gen;
    assign camera_pwdn = 0;
    assign camera_reset = !reset;

    wire sda_test;
    wire [3:0] state_test;
    wire [15:0] sccb_dout;
    wire [9:0] test_counter;

    reg [15:0] sccb_din = 0;
    wire sccb_din_ready;
    wire dbc_btnR;
    wire sgp_dbc_btnR;
    reg sccb_din_valid = 0;

    clk_wiz_0 clk_wiz(
        .clk_in1(clk),
        .clk_out1(xclk_gen),
        .clk_out2(nclk)
    );

    reg [9:0] sccb_clk_counter = 0;
    assign sccb_clk = sccb_clk_counter == 0;
    always @(posedge nclk ) begin
        if(sccb_clk_counter == 249) sccb_clk_counter <= 0;
        else sccb_clk_counter <= sccb_clk_counter + 1;
    end

    // vga_slave_controller vc(
    //     .clk(nclk),
    //     .reset(reset),
    //     .master_sync(vga_sync),
    //     .video_on(video_on),
    //     .h_index(h_index),
    //     .v_index(v_index),
    //     .hsync(hsync),
    //     .vsync(vsync),
    //     .subclk(subclk_counter)
    // );

    // camera cam(
    //     .pclk(camera_pclk),
    //     .reset(reset),
    //     .din(camera_din),
    //     .href(camera_href),
    //     .vsync(camera_vsync),
    //     .dout(camera_dout),
    //     .dvalid(camera_dvalid),
    //     .synchronized(camera_synchronized)
    // );

    // single_pulser sgp(
    //     .clk(nclk),
    //     .din(camera_dvalid),
    //     .dout(sgp_camera_dvalid)
    // );

    // single_pulser camv_sgp(
    //     .clk(nclk),
    //     .din(camera_vsync),
    //     .dout(sgp_camera_vsync)
    // );

    // delay #(
    //     .word_size(32)
    // ) dout_delay(
    //     .clk(nclk),
    //     .din(camera_dout),
    //     .dout(delay_camera_dout)
    // );

    deboucer #(
        .sample_size(1023)
    ) dbc (
        .clk(nclk),
        .din(btnR),
        .dout(dbc_btnR)
    );

    single_pulser sccb_sgp(
        .clk(nclk),
        .din(dbc_btnR),
        .dout(sgp_dbc_btnR)
    );

    camera_sccb sccb(
        .clk(sccb_clk),
        .reset(reset),
        .scl(scl),
        .sda(sda),
        .sda_test(sda_test),
        .test_counter(test_counter),
        .dindex(state_test),
        .sccb_din(sccb_din),
        .sccb_din_valid(sccb_din_valid),
        .sccb_din_ready(sccb_din_ready)
    );

    // blk_mem_gen_0 mem(
    //     .addra(write_address),
    //     .clka(nclk),
    //     .dina(mem_in),
    //     .wea(write_enb),
    //     .addrb(read_address),
    //     .clkb(nclk),
    //     .doutb(data_buf)
    // );

    //TEST

    ila_1 ila_inst(
        .clk(nclk),
        .probe0(scl),
        .probe1(sda_test),
        .probe2(state_test),
        .probe3(test_counter),
        .probe4(sccb_din_valid),
        .probe5(sccb_din_ready),
        .probe6(sgp_dbc_btnR),
        .probe7(btnR),
        .probe8(dbc_btnR)
    );
    //END

    // always @(posedge nclk ) begin
    //     if(reset) begin
    //         vga_sync <= 0;
    //         data_group <= 0;
    //     end else begin
    //         if(camera_synchronized && sgp_camera_vsync) data_group <= !data_group;
    //         if(camera_synchronized && sgp_camera_dvalid && delay_camera_dout[22] == data_group) begin
    //             vga_sync <= 1;
    //             write_address <= {delay_camera_dout[21:12],delay_camera_dout[30:23]};
    //             mem_in[9:7] <= delay_camera_dout[11:9]; 
    //             mem_in[6:4] <= delay_camera_dout[7:5]; 
    //             mem_in[3:1] <= delay_camera_dout[3:1]; 
    //             mem_in[0] <= (delay_camera_dout[4]&(delay_camera_dout[8] | delay_camera_dout[0])) | (delay_camera_dout[8]&delay_camera_dout[0]); 
    //             write_enb <= 1;
    //         end else begin
    //             write_enb <= 0;
    //         end
    //     end
    // end

    // always @(posedge nclk) begin
    //     if(reset || !vga_sync) begin
    //         vga_out_group <= 1;
    //     end else begin
    //         case (subclk_counter)
    //             0: begin
    //                 read_address <= {h_index, v_index[8:1]};
    //             end 
    //             3: begin
    //                 if(video_on) begin
    //                     rgb_reg[11:9] <= data_buf[9:7];
    //                     rgb_reg[8] <= data_buf[0];
    //                     rgb_reg[7:5] <= data_buf[6:4];
    //                     rgb_reg[4] <= data_buf[0];
    //                     rgb_reg[3:1] <= data_buf[3:1];
    //                     rgb_reg[0] <= data_buf[0];
    //                 end else begin
    //                     rgb_reg <= 0;
    //                 end
    //                 if(h_index == 639 && v_index == 479) vga_out_group <= !vga_out_group;
    //             end
    //         endcase
    //     end
    // end

    always @(posedge nclk ) begin
        if(sccb_din_ready && sgp_dbc_btnR) begin
            sccb_din_valid <= 1;
            sccb_din <= sw;
        end else if(!sccb_din_ready && sccb_din_valid) begin
            sccb_din_valid <= 0;
        end
    end
endmodule

