`timescale 1ns / 1ps

module tb_I2C_master;

    // --- ประกาศพารามิเตอร์ ---
    parameter word_number = 1; // อ้างอิงจากพารามิเตอร์ของโมดูลหลัก 
    parameter CLK_PERIOD = 10; // กำหนดความถี่ Clock สำหรับ Simulation

    // --- สัญญาณ Inputs ---
    reg clk;
    reg reset;
    reg [6:0] addr;
    reg addr_valid;
    reg mode;
    reg [(8*word_number) - 1:0] din;
    reg din_valid;
    reg dout_ack;

    // --- สัญญาณ Outputs ---
    wire [1:0] test_wire;
    wire ready;
    wire exception;
    wire [(8*word_number) - 1:0] dout;
    wire dout_valid;
    wire scl;

    // --- สัญญาณ Inouts ---
    wire sda;
    
    // ตัวแปรสำหรับให้ Testbench (จำลองเป็น Slave) ดึงสาย SDA
    reg sda_slave_drv; 

    // การจำลอง Pull-up resistor สำหรับ I2C (ถ้าไม่มีใครดึงลง สถานะจะเป็น 1)
    assign (weak1, weak0) sda = 1'b1;
    // ถ้าฝั่ง Slave (Testbench) ต้องการดึงให้เป็น 0 (เช่น ส่ง ACK)
    assign sda = sda_slave_drv ? 1'b0 : 1'bz;

    // --- การเชื่อมต่อโมดูล I2C_master ---
    I2C_master #(
        .word_number(word_number)
    ) uut (
        .test_wire(test_wire),
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
    ); // 

    // --- สร้างสัญญาณ Clock ---
    always #(CLK_PERIOD/2) clk = ~clk;

    // --- ขั้นตอนการทดสอบ ---
    initial begin
        // กำหนดค่าเริ่มต้น
        clk = 0;
        reset = 1;
        addr = 0;
        addr_valid = 0;
        mode = 0;
        din = 0;
        din_valid = 0;
        dout_ack = 0;
        sda_slave_drv = 0;

        // รอจนกว่า Reset จะเสร็จสิ้น
        #100;
        reset = 0;

        // รอให้สถานะ Ready พร้อมใช้งาน
        wait(ready == 1'b1);
        #20;

        // ==========================================
        // Test Case 1: การเขียนข้อมูล (Master Write)
        // ==========================================
        $display("--- Start Write Transaction ---");
        addr = 7'h55;       // ที่อยู่ Slave (สมมติเป็น 0x55)
        mode = 1'b0;        // mode 0 คือ Write [cite: 13, 34]
        din = 8'hAA;        // ข้อมูลที่จะส่ง (0xAA)
        addr_valid = 1'b1;
        din_valid = 1'b1;
        #10;

        @(posedge clk);
        addr_valid = 1'b0;
        din_valid = 1'b0;

        // จำลองการส่ง ACK จาก Slave สำหรับ Address
        // รอสัญญาณ SCL 8 ครั้ง (Address 7 บิต + R/W 1 บิต)
        repeat(8) @(negedge scl);
        // ใน Clock ที่ 9 ฝั่ง Master จะรออ่าน ACK
        @(negedge scl);
        sda_slave_drv = 1'b1; // ดึง SDA เป็น 0 เพื่อส่ง ACK
        @(negedge scl);
        sda_slave_drv = 1'b0; // ปล่อยสาย SDA

        // จำลองการส่ง ACK จาก Slave สำหรับ Data
        // รอสัญญาณ SCL ข้อมูลอีก 8 บิต
        repeat(8) @(negedge scl);
        @(negedge scl);
        sda_slave_drv = 1'b1; // ดึง SDA เป็น 0 เพื่อส่ง ACK
        @(negedge scl);
        sda_slave_drv = 1'b0; // ปล่อยสาย SDA

        // รอให้ทำงานเสร็จสิ้นและกลับมาสถานะพร้อมใหม่
        wait(ready == 1'b1);
        #100;

        // ==========================================
        // Test Case 2: การอ่านข้อมูล (Master Read)
        // ==========================================
        $display("--- Start Read Transaction ---");
        addr = 7'h55;       // ที่อยู่ Slave 
        mode = 1'b1;        // mode 1 คือ Read [cite: 13, 39]
        addr_valid = 1'b1;
        #10;
        
        @(posedge clk);
        addr_valid = 1'b0;

        // จำลองการส่ง ACK จาก Slave สำหรับ Address
        repeat(8) @(negedge scl);
        @(negedge scl);
        sda_slave_drv = 1'b1; // ส่ง ACK
        @(negedge scl);
        sda_slave_drv = 1'b0; // ปล่อยสาย SDA

        // หมายเหตุ: ใน Test Case อ่านข้อมูลนี้ หากต้องการให้สมบูรณ์ขึ้น
        // คุณสามารถเขียน Logic ฝั่ง Testbench ให้บังคับค่าสลับไปมาบนสาย SDA 
        // ในช่วง 8 Clock ถัดไป เพื่อจำลองข้อมูลที่ส่งมาจาก Slave

        // รอจนกระทั่งจบ Transaction
        wait(ready == 1'b1);
        #100;

        $display("--- Simulation Finished ---");
        $finish;
    end

endmodule