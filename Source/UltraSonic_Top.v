`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/12 18:22:03
// Design Name: 
// Module Name: UltraSonic_Top
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


module UltraSonic_Top(
    input clk, reset_p,
    input echo,
    output trig,
    output [3:0] com,
    output [7:0] seg_7,
    output [7:0] LED_bar
    );
    
    wire [8:0] distance;
    UltraSonic ultra(.clk(clk), .reset_p(reset_p), .echo(echo), .trig(trig), .distance(distance), .LED_bar(LED_bar));
    
    wire [15:0] distance_dec;
    bin_to_dec humi_b2d(.bin(distance), .bcd(distance_dec));
    
    FND_4digit_cntr fnd_cntr(.clk(clk), .rst(reset_p), .value(distance_dec), .com(com), .seg_7(seg_7));
endmodule
