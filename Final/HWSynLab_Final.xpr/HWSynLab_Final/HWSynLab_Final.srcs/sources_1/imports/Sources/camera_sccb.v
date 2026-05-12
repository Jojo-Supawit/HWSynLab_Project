`timescale 1ns / 1ps

module camera_sccb (
    output [9:0] test_counter,
    input clk,
    input reset,
    output scl,
    inout sda,
    output reg [15:0] reg_data,
    output reg sda_test,
    output [6:0] dindex,

    input [15:0] sccb_din,
    input sccb_din_valid,
    output reg sccb_din_ready
);

    reg [5:0] state = 0;
    reg [6:0] data_index = 0;

    wire ready;
    wire exception;
    reg [6:0] addr;
    reg addr_valid = 0;
    reg mode = 0;
    reg [15:0] din;
    reg din_valid = 0;
    wire [15:0] dout;
    wire dout_valid;

    assign dindex = data_index;

    always @(posedge clk ) begin
        sda_test <= sda;
    end

    I2C_master #(
        .word_number(2)
    ) dut(
        .test_wire(test_counter),
        .clk(clk),
        .reset(reset),
        .ready(ready),
        .exception(exception),
        .addr(addr),
        .addr_valid(addr_valid),
        .mode(mode),
        .din(din),
        .din_valid(din_valid),
        .dout(dout),
        .dout_valid(dout_valid),
        .scl(scl),
        .sda(sda)
    );

    reg [9:0] start_delay = 0;

    initial begin
        sccb_din_ready <= 0;
    end

    always @(posedge clk ) begin
        if(reset) begin
            state <= 0;
            addr_valid <= 0;
            din_valid <= 0;
            mode <= 0;
            data_index <= 0;
            start_delay <= 0;
            sccb_din_ready <= 0;
        end else begin
            if(start_delay < 250) begin
                start_delay <= start_delay + 1;
            end else begin
                case (state)
                    0: begin
                        addr <= 7'h21;
                        case (data_index)
                            // 1. System Reset
                            0: begin din <= {8'h12, 8'h80}; state <= 1; end
                            8'd1:  begin din <= {8'h12, 8'h04}; state <= 1; end // COM7 RGB, VGA-sized sensor output.
                            8'd2:  begin din <= {8'h11, 8'h80}; state <= 1; end // CLKRC: no divider, use input clock path.
                            8'd3:  begin din <= {8'h0C, 8'h00}; state <= 1; end // COM3: disable scaler/DCW path.
                            8'd4:  begin din <= {8'h3E, 8'h00}; state <= 1; end // COM14: normal PCLK, no scaling divider.
                            8'd5:  begin din <= {8'h04, 8'h00}; state <= 1; end // COM1: no CCIR656.
                            8'd6:  begin din <= {8'h40, 8'hD0}; state <= 1; end // COM15: RGB565, full output range.
                            8'd7:  begin din <= {8'h3A, 8'h04}; state <= 1; end // TSLB: RGB565 byte order used by common OV7670 designs.
                            8'd8:  begin din <= {8'h14, 8'h38}; state <= 1; end // COM9: AGC ceiling from proven VGA RGB565 profile.
                            8'd9:  begin din <= {8'h4F, 8'hA0}; state <= 1; end
                            8'd10: begin din <= {8'h50, 8'h9D}; state <= 1; end
                            8'd11: begin din <= {8'h51, 8'h0E}; state <= 1; end
                            8'd12: begin din <= {8'h52, 8'h38}; state <= 1; end
                            8'd13: begin din <= {8'h53, 8'h90}; state <= 1; end
                            8'd14: begin din <= {8'h54, 8'hEB}; state <= 1; end
                            8'd15: begin din <= {8'h58, 8'h9A}; state <= 1; end
                            8'd16: begin din <= {8'h3D, 8'hC2}; state <= 1; end // COM13: gamma + UV saturation + reserved bit used by Linux RGB565 profile.
                            8'd17: begin din <= {8'h17, 8'h14}; state <= 1; end // VGA windowing used by the reference design.
                            8'd18: begin din <= {8'h18, 8'h02}; state <= 1; end
                            8'd19: begin din <= {8'h32, 8'h80}; state <= 1; end
                            8'd20: begin din <= {8'h19, 8'h03}; state <= 1; end
                            8'd21: begin din <= {8'h1A, 8'h7B}; state <= 1; end
                            8'd22: begin din <= {8'h03, 8'h00}; state <= 1; end
                            8'd23: begin din <= {8'h0F, 8'h41}; state <= 1; end
                            8'd24: begin din <= {8'h1E, 8'h00}; state <= 1; end // MVFP: no mirror/flip.
                            8'd25: begin din <= {8'h33, 8'h0B}; state <= 1; end
                            8'd26: begin din <= {8'h3C, 8'h78}; state <= 1; end // COM12: HREF behavior around VSYNC.
                            8'd27: begin din <= {8'h69, 8'h00}; state <= 1; end
                            8'd28: begin din <= {8'h74, 8'h00}; state <= 1; end
                            8'd29: begin din <= {8'hB0, 8'h84}; state <= 1; end // Reserved color-stability value from common OV7670 profiles.
                            8'd30: begin din <= {8'hB1, 8'h0C}; state <= 1; end
                            8'd31: begin din <= {8'hB2, 8'h0E}; state <= 1; end
                            8'd32: begin din <= {8'hB3, 8'h80}; state <= 1; end
                            8'd33: begin din <= {8'h70, 8'h3A}; state <= 1; end
                            8'd34: begin din <= {8'h71, 8'h35}; state <= 1; end
                            8'd35: begin din <= {8'h72, 8'h11}; state <= 1; end
                            8'd36: begin din <= {8'h73, 8'hF0}; state <= 1; end
                            8'd37: begin din <= {8'hA2, 8'h02}; state <= 1; end
                            8'd38: begin din <= {8'h7A, 8'h20}; state <= 1; end
                            8'd39: begin din <= {8'h7B, 8'h10}; state <= 1; end
                            8'd40: begin din <= {8'h7C, 8'h1E}; state <= 1; end
                            8'd41: begin din <= {8'h7D, 8'h35}; state <= 1; end
                            8'd42: begin din <= {8'h7E, 8'h5A}; state <= 1; end
                            8'd43: begin din <= {8'h7F, 8'h69}; state <= 1; end
                            8'd44: begin din <= {8'h80, 8'h76}; state <= 1; end
                            8'd45: begin din <= {8'h81, 8'h80}; state <= 1; end
                            8'd46: begin din <= {8'h82, 8'h88}; state <= 1; end
                            8'd47: begin din <= {8'h83, 8'h8F}; state <= 1; end
                            8'd48: begin din <= {8'h84, 8'h96}; state <= 1; end
                            8'd49: begin din <= {8'h85, 8'hA3}; state <= 1; end
                            8'd50: begin din <= {8'h86, 8'hAF}; state <= 1; end
                            8'd51: begin din <= {8'h87, 8'hC4}; state <= 1; end
                            8'd52: begin din <= {8'h88, 8'hD7}; state <= 1; end
                            8'd53: begin din <= {8'h89, 8'hE8}; state <= 1; end
                            8'd54: begin din <= {8'h13, 8'hE0}; state <= 1; end // Disable AGC/AEC/AWB while programming limits.
                            8'd55: begin din <= {8'h00, 8'h00}; state <= 1; end
                            8'd56: begin din <= {8'h10, 8'h00}; state <= 1; end
                            8'd57: begin din <= {8'h0D, 8'h40}; state <= 1; end
                            8'd58: begin din <= {8'h14, 8'h18}; state <= 1; end
                            8'd59: begin din <= {8'hA5, 8'h05}; state <= 1; end
                            8'd60: begin din <= {8'hAB, 8'h07}; state <= 1; end
                            8'd61: begin din <= {8'h24, 8'h95}; state <= 1; end
                            8'd62: begin din <= {8'h25, 8'h33}; state <= 1; end
                            8'd63: begin din <= {8'h26, 8'hE3}; state <= 1; end
                            8'd64: begin din <= {8'h9F, 8'h78}; state <= 1; end
                            8'd65: begin din <= {8'hA0, 8'h68}; state <= 1; end
                            8'd66: begin din <= {8'hA1, 8'h03}; state <= 1; end
                            8'd67: begin din <= {8'hA6, 8'hD8}; state <= 1; end
                            8'd68: begin din <= {8'hA7, 8'hD8}; state <= 1; end
                            8'd69: begin din <= {8'hA8, 8'hF0}; state <= 1; end
                            8'd70: begin din <= {8'hA9, 8'h90}; state <= 1; end
                            8'd71: begin din <= {8'hAA, 8'h94}; state <= 1; end
                            8'd72: begin din <= {8'h13, 8'hE7}; state <= 1; end // Enable AGC/AEC/AWB; bit 1 is AWB enable.
                            8'd73: begin din <= {8'h42, 8'h00}; state <= 1; end // COM17 colorbar.
                            8'd74: begin din <= {8'h8C, 8'h00}; state <= 1; end // Keep RGB444 disabled; output stays RGB565.
                            8'd75:  begin din <= {8'h14, 8'h38}; state <= 1; end
                            8'd76:  begin din <= {8'h12, 8'h04}; state <= 1; end
                            default: begin
                                sccb_din_ready <= 1;
                                state <= 4;
                            end
                        endcase
                        mode <= 0;
                    end
                    1: begin
                        if(ready) begin
                            addr_valid <= 1;
                            mode <= 0;
                            din_valid <= 1;
                            state <= 2;
                        end
                    end
                    2: begin
                        if(!ready) begin
                            addr_valid <= 0;
                            din_valid <= 0;
                            state <= 3;
                            data_index <= data_index + 1;
                            
                        end
                    end
                    3: begin
                        if(ready) begin
                            state <= 0;
                            start_delay <= 225;
                        end 
                    end
                    4: begin
                        if(sccb_din_valid) begin
                            addr <= 7'h21;
                            mode <= 0;
                            state <= 5;
                            din <= sccb_din;
                            sccb_din_ready <= 0;
                        end 
                    end
                    5: begin
                        if(ready) begin
                            addr_valid <= 1;
                            mode <= 0;
                            din_valid <= 1;
                            state <= 6;
                        end
                    end
                    6: begin
                        if(!ready) begin
                            addr_valid <= 0;
                            din_valid <= 0;
                            state <= 7;
                            sccb_din_ready <= 1;
                        end
                    end
                    7: begin
                        if(ready) begin
                            state <= 4;
                            start_delay <= 225;
                        end
                    end
                endcase
            end
        end
    end
    
endmodule