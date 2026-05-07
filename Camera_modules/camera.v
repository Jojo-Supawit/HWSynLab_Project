`timescale 1ns / 1ps

module camera (
    input           pclk,
    input           reset,
    input   [7:0]   din,
    input           href,
    input           vsync,
    output  [31:0]  dout,
    output  reg     dvalid,
    output  reg     synconized
);
    reg [31:0] out_reg = 32'hFFFFFFFF;

    // reg [3:0] out_buffer = 0;
    reg [9:0] h_counter = 0;
    reg [9:0] v_counter = 0;
    reg byte_number = 0;
    reg hstate = 0;

    assign dout = out_reg;

    initial begin
        dvalid <= 0;
        synconized <= 0;
    end

    always @(posedge pclk ) begin
        if(reset) begin
            synconized <= 0;
            dvalid <= 0;
        end else begin
            if(!synconized) begin
                if(vsync) begin
                    synconized <= 1;
                    byte_number <= 0;
                end 
            end else begin
                if(vsync) begin
                    v_counter <= 0;
                    h_counter <= 0;
                    dvalid <= 0;
                end else begin
                    if (hstate && !href) begin
                        h_counter <= 0;
                        v_counter <= v_counter + 1;
                        hstate <= 0;
                        dvalid <= 0;
                        byte_number <= 0;
                    end else if(href) begin
                        if(!hstate) hstate <= 1;
                        if(!byte_number) begin
                            out_reg[3:0] <= din[3:0];
                            byte_number <= 1;
                            dvalid <= 0;
                        end else begin
                            out_reg[31:22] <= h_counter;
                            out_reg[21:12] <= v_counter;
                            out_reg[11:8] <= din[3:0];
                            out_reg[7:4] <= din[7:4];
                            // out_reg[3:0] <= out_buffer;
                            byte_number <= 0;
                            dvalid <= (0 <= h_counter && h_counter < 640) && (0 <= v_counter && v_counter < 480);
                            h_counter <= h_counter + 1;
                        end
                    end
                end
            end
        end
    end

endmodule