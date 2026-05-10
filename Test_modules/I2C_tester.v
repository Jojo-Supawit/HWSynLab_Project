`timescale 1ns / 1ps

module I2C_tester;
    reg clk, reset;
    wire ready;
    wire exception;
    reg [6:0] addr;
    reg addr_valid;
    reg mode;
    reg [7:0] din;
    reg din_valid;
    wire dout;
    wire dout_valid;
    reg dout_ack;
    wire scl;
    wire sda;

    reg sda_out = 0;
    reg sda_out_enb = 0;

    assign sda = (sda_out_enb) ? sda_out : 1'bz;

    integer count;

    I2C_master dut(
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
        .dout_ack(dout_ack),
        .scl(scl),
        .sda(sda)
    );

    always #10 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        dout_ack = 0;
        din_valid = 0;
        addr_valid = 0;
        sda_out = 0;
        sda_out_enb = 0;

        #35 reset = 0;

        while (!ready) begin
            #20;
        end

        addr = 7'b1000000;
        addr_valid = 1;
        mode = 0;
        din = 8'b10010010;
        din_valid = 1;

        while(ready) begin
            #20;
        end

        addr_valid = 0;
        din_valid = 0;

        while(scl) begin
            #20;
        end

        count = 0;
        while(count < 8) begin
            while (!scl) begin
                #20;
            end
            count = count + 1;
            while (scl) begin
                #20;
            end
        end

        sda_out_enb = 1;
        while (!scl) begin
            #20;
        end
        while (scl) begin
            #20;
        end
        sda_out_enb = 0;

        count = 0;
        while(count < 8) begin
            while (!scl) begin
                #20;
            end
            count = count + 1;
            while (scl) begin
                #20;
            end
        end

        sda_out_enb = 1;
        while (!scl) begin
            #20;
        end
        while (scl) begin
            #20;
        end
        sda_out_enb = 0;

        while(!ready) begin
            #20;
        end

        addr = 7'b1100000;
        addr_valid = 1;
        mode = 1;

        while(ready) begin
            #20;
        end

        addr_valid = 0;

        while(scl) begin
            #20;
        end

        count = 0;
        while(count < 8) begin
            while (!scl) begin
                #20;
            end
            count = count + 1;
            while (scl) begin
                #20;
            end
        end

        sda_out_enb = 1;
        while (!scl) begin
            #20;
        end
        while (scl) begin
            #20;
        end

        count = 0;
        while(count < 8) begin
            while (!scl) begin
                #20;
            end
            count = count + 1;
            while (scl) begin
                #20;
            end
        end
        sda_out_enb = 0;
        while (!dout_valid) begin
            #20;
        end
        dout_ack = 1;

        while(!ready) begin
            #20;
        end

        $finish;

    end

endmodule