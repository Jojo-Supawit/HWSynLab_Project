`timescale 1ns / 1ps

//
// VGA Mode
// 640x480 pixels VGA screen with 25MHz pixel rate based on 60 Hz refresh rate
// 800 pixels/line * 525 lines/screen * 60 screens/second = ~25.2M pixels/second
//

module vga_controller2(
    input clk,   // from FPGA
    input reset,            // system reset
    output next_pixel,    // ON while pixel counts for x and y and within display area
    output hsync,           // horizontal sync
    output vsync,           // vertical sync
    output p_tick          // the 25MHz pixel/second rate signal, pixel tick
    );
    
    // Based on VGA standards found at vesa.org for 640x480 resolution
    // Total horizontal width of screen = 800 pixels, partitioned  into sections
    parameter HD = 640;             // horizontal display area width in pixels
    parameter HF = 48;              // horizontal front porch width in pixels
    parameter HB = 16;              // horizontal back porch width in pixels
    parameter HR = 96;              // horizontal retrace width in pixels
    parameter HMAX = HD+HF+HB+HR-1; // max value of horizontal counter = 799
    // Total vertical length of screen = 525 pixels, partitioned into sections
    parameter VD = 480;             // vertical display area length in pixels 
    parameter VF = 10;              // vertical front porch length in pixels  
    parameter VB = 33;              // vertical back porch length in pixels   
    parameter VR = 2;               // vertical retrace length in pixels  
    parameter VMAX = VD+VF+VB+VR-1; // max value of vertical counter = 524   
    
    // *** Generate 25MHz from 100MHz *********************************************************
	reg  [1:0] r_25MHz;
	wire w_25MHz;
	
	always @(posedge clk or posedge reset)
		if(reset)
		  r_25MHz <= 0;
		else
		  r_25MHz <= r_25MHz + 1;
	
	assign w_25MHz = (r_25MHz == 0) ? 1 : 0; // assert tick 1/4 of the time
    // ****************************************************************************************
    
    always @(posedge w_25MHz ) begin
        
    end
    
            
endmodule