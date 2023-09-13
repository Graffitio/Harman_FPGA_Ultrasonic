`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/12 17:02:11
// Design Name: 
// Module Name: tb_UltraSonic
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_UltraSonic();
    
    reg clk, reset_p;
    reg echo;
    wire trig;
    wire [8:0] distance;
    
    UltraSonic DUT(clk, reset_p, echo, trig, distance);
    
    initial begin
        clk = 0;
        reset_p = 1;
        echo = 0;
    end
    
    always #4 clk = ~clk; // 8nsÂ¥¸® clk
    
    initial begin
        #8;
        reset_p = 0; #8;
        
        #50;
        wait(trig);
        wait(!trig);
        
//        #22000;
        
        #30000;
        echo = 1; #831560;
        echo = 0;
        #100;
        $display("distance : %d", DUT.distance);
        #30000;
        $stop;
    end
endmodule
