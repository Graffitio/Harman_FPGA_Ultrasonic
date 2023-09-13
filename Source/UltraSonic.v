`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/12 16:05:58
// Design Name: 
// Module Name: UltraSonic
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




module UltraSonic(
    input clk, reset_p,
    input echo,
    output reg trig,
    output reg [8:0] distance,
    output reg [7:0] LED_bar
    );
    
    parameter S_IDLE = 5'b00001;
    parameter S_TRIG = 5'b00010;
//     parameter S_BURST = 5'b00100;
    parameter S_ECHO = 5'b01000;
    parameter S_READ_DATA = 5'b10000;
    
    parameter S_WAIT_PEDGE = 2'b01;
    parameter S_WAIT_NEDGE = 2'b10;
    
    wire clk_usec;
    reg [15:0] count_usec;
    reg count_usec_e;
    clock_usec usec_clk(.clk(clk), .reset_p(reset_p), .clk_usec(clk_usec));

    // usec Counter
    always @(negedge clk, posedge reset_p) begin
        if(reset_p) count_usec = 0; // ���� ������ ����� 0�ǵ��� ����
        else begin
            // data�� ���� �� ���ȸ� count
            if(clk_usec && count_usec_e) count_usec = count_usec + 1; // enable�� 1�̰�, clk_usec�� ���� ���� count++
            else if(!count_usec_e) count_usec = 0;
        end
    end
        
    // ���¸� ����� ���� ����
    reg [5:0] state, next_state;
    reg [1:0] read_state;
    
    // State Machine
    always @(negedge clk, posedge reset_p) begin
        if(reset_p) state = S_IDLE;
        else state = next_state; // �� Ŭ������ state�� next_state�� �ٲ��ش�.
    end
    
    //Edge�� ������ ���� �ɷ� clk ����ȭ
    wire echo_pedge, echo_nedge;
    edge_detector_n edg_echo(.clk(clk), .cp_in(echo), .rst(reset_p), .p_edge(echo_pedge), .n_edge(echo_nedge)); // Edge Detector
    
    // reg echo_flag;
    // reg echo_time;
    reg [15:0] save_st, save_end;
    always@(posedge clk, posedge reset_p) begin
        if(reset_p) begin
            count_usec_e <= 0;
            next_state <= S_IDLE;
            read_state <= S_WAIT_PEDGE;
            trig <= 0;
//            echo_flag = 0;
//            echo_time = 0;
            distance <= 0;
            save_st <= 0;
            save_end <= 0;
            LED_bar <= 8'b00_000_000;
        end
        else begin
            case(state)
                S_IDLE : begin
                    LED_bar[0] <= 1;
                    if (count_usec < 16'd655_35) begin
//                    if (count_usec < 100) begin // �ùķ��̼ǿ�
                        count_usec_e <= 1;
                        trig <= 0;
                    end
                    else begin
                        LED_bar <= 8'b00_000_000;
                        count_usec_e <= 0;
                        next_state <= S_TRIG;
                    end
                end
                S_TRIG : begin
                    LED_bar[1] <= 1;
                    if(count_usec < 16'd14) begin
                        trig <= 1;
                        count_usec_e <= 1;
                    end
                    else begin
                        count_usec_e <= 0;
                        trig <= 0;
                        next_state <= S_ECHO;
                        read_state <= S_WAIT_PEDGE;
                    end
                end
//                S_BURST : begin
//                LED_bar[2] = 1;
//                    if(count_usec < 220) begin
//                        count_usec_e = 1;
//                    end
//                    else begin
//                        count_usec_e = 0;
////                        echo_flag = 1;
//                        next_state = S_ECHO;
//                    end
//                end
                S_ECHO : begin
                    LED_bar[2] <= 1;
                    case(read_state)
                        S_WAIT_PEDGE : begin
                            LED_bar[3] <= 1;
                            if(echo_pedge) begin // burst ������, echo high �߻�
//                                count_usec_e <= 1; // echo high �ð� ī����
                                save_st <= count_usec;
                                read_state <= S_WAIT_NEDGE;
                            end
                            else if (count_usec > 16'd23_201) begin
                                read_state <= S_WAIT_PEDGE;
                                next_state <= S_IDLE;
                            end
                            else begin
                                count_usec_e <= 1;
                                read_state <= S_WAIT_PEDGE;
                            end
                        end
                        S_WAIT_NEDGE : begin
                            LED_bar[4] <= 1;
                            if(count_usec < 16'd23_201) begin // �ִ� ���� ������ �Ÿ��� 400cm(400 = 23200/58)
                                if(echo_nedge) begin
                                    LED_bar[5] <= 1;
//                                    distance = (save_end-save_st) / 58;
//                                    distance = count_usec / 58;
//                                    count_usec_e = 0;
                                    save_end <= count_usec;
                                    count_usec_e <= 0;
                                    next_state <= S_READ_DATA;
                                end
                                else begin
                                    count_usec_e <= 1;
                                    read_state <= S_WAIT_NEDGE;
                                end
                            end
                            // else begin
                            //     clk_save <= 16'd23200;
                            //     count_usec_e <= 1;
                            //     read_state <= S_WAIT_NEDGE;
                            // end
                            else begin
//                            LED_bar = 8'b11_111_111;
//                                clk_save <= 16'd23200;
//                                count_usec_e = 1;
                                next_state <= S_IDLE;
                                read_state <= S_WAIT_PEDGE;
                            end
                        end
                        default : begin
                            read_state <= S_WAIT_PEDGE;
                            next_state <= S_IDLE;
                        end
                    endcase
//                if(count_usec < 16'd23_201) begin // �ִ� 400cm
//                    if(echo_nedge) begin
//                        LED_bar[4] = 1;
////                        echo_time = count_usec;
////                        distance_buf = (count_usec * 1024) / 125;
//                        distance = count_usec / 58;
//                        count_usec_e = 0;
////                        echo_flag = 0;
//                        next_state = S_IDLE;
//                    end
//                    else begin
//                        count_usec_e = 1;    
//                    end
//                end
//                else begin
////                    count_usec = 16'd23_000;
//                    distance = 400;
//                end
                end
                S_READ_DATA : begin
//                    if(count_usec > 16'd500) begin // 500us Delay
                        LED_bar[6] <= 1;
                        distance <= (save_end-save_st) / 58;
                        save_st <= 0;
                        save_end <= 0;
                        count_usec_e <= 0;
                        next_state <= S_IDLE;
                        read_state <= S_WAIT_PEDGE;
//                    end
//                    else begin
//                        count_usec_e = 1;
//                    end                                    
                end
                default : begin
                    next_state <= S_IDLE;
                end
            endcase
        end
    end
//    wire distance = 0;
//    assign distance = 1000000 * echo_time * 1024 / 125000000;
//    assign distance = (echo_time * 1024) / 125;
endmodule

//module UltraSonic(
//    input clk, reset_p,
//    input echo,
//    output reg trig,
//    output reg [8:0] distance,
//    output reg [7:0] LED_bar
//    );
    
//    parameter S_IDLE = 5'b00001;
//    parameter S_TRIG = 5'b00010;
//    parameter S_BURST = 5'b00100;
//    parameter S_ECHO = 5'b01000;
//    parameter S_READ_DATA = 5'b10000;
    
//    parameter S_WAIT_PEDGE = 2'b01;
//    parameter S_WAIT_NEDGE = 2'b10;
    
//    wire clk_usec;
//    reg [15:0] count_usec;
//    reg count_usec_e;
//    clock_usec usec_clk(.clk(clk), .reset_p(reset_p), .clk_usec(clk_usec));

//    // usec Counter
//    always @(negedge clk, posedge reset_p) begin
//        if(reset_p) count_usec = 0; // ���� ������ ����� 0�ǵ��� ����
//        else begin
//            // data�� ���� �� ���ȸ� count
//            if(clk_usec && count_usec_e) count_usec = count_usec + 1; // enable�� 1�̰�, clk_usec�� ���� ���� count++
//            else if(!count_usec_e) count_usec = 0;
//        end
//    end
        
//    // ���¸� ����� ���� ����
//    reg [4:0] state, next_state;
//    reg [1:0] read_state;
    
//    // State Machine
//    always @(negedge clk, posedge reset_p) begin
//        if(reset_p) state = S_IDLE;
//        else state = next_state; // �� Ŭ������ state�� next_state�� �ٲ��ش�.
//    end
    
//    //Edge�� ������ ���� �ɷ� clk ����ȭ
//    wire echo_pedge, echo_nedge;
//    edge_detector_n edg_echo(.clk(clk), .cp_in(echo), .rst(reset_p), .p_edge(echo_pedge), .n_edge(echo_nedge)); // Edge Detector
    
//    reg echo_flag;
//    reg echo_time;
//    reg [15:0] clk_save;
//    always@(posedge clk, posedge reset_p) begin
//        if(reset_p) begin
//            count_usec_e <= 0;
//            next_state <= S_IDLE;
//            read_state <= S_WAIT_PEDGE;
//            trig <= 0;
////            echo_flag = 0;
////            echo_time = 0;
//            distance <= 0;
//            LED_bar <= 8'b00000000;
//        end
//        else begin
//            case(state)
//                S_IDLE : begin
//                    LED_bar <= 8'b00000000;
//                    LED_bar[0] <= 1;
//                    if (count_usec < 16'd655_35) begin
////                    if (count_usec < 100) begin // �ùķ��̼ǿ�
//                        count_usec_e <= 1;
//                        trig <= 0;
//                    end
//                    else begin
//                        count_usec_e <= 0;
//                        next_state <= S_TRIG;
//                    end
//                end
//                S_TRIG : begin
//                LED_bar[1] <= 1;
//                    if(count_usec < 16'd16) begin
//                        trig <= 1;
//                        count_usec_e <= 1;
//                    end
//                    else begin
//                        count_usec_e <= 0;
//                        trig <= 0;
//                        next_state <= S_ECHO;
//                    end
//                end
////                S_BURST : begin
////                LED_bar[2] = 1;
////                    if(count_usec < 220) begin
////                        count_usec_e = 1;
////                    end
////                    else begin
////                        count_usec_e = 0;
//////                        echo_flag = 1;
////                        next_state = S_ECHO;
////                    end
////                end
//                S_ECHO : begin
//                LED_bar[3] <= 1;
//                    case(read_state)
//                        S_WAIT_PEDGE : begin
//                            LED_bar[4] <= 1;
//                            if(echo_pedge) begin
//                                count_usec_e <= 1;
//                                read_state <= S_WAIT_NEDGE;
//                            end
//                            else count_usec_e <= 0;
//                        end
//                        S_WAIT_NEDGE : begin
//                            LED_bar[5] <= 1;
//                            if(count_usec < 16'd23_201) begin
//                                if(echo_nedge) begin
//                                    LED_bar[6] <= 1;
////                                    distance = count_usec / 58;
////                                    count_usec_e = 0;
//                                    clk_save <= count_usec;
//                                    next_state <= S_READ_DATA;
//                                end
//                            end
//                            else begin
//                                clk_save <= 16'd23200;
//                                count_usec_e <= 1;
//                                read_state <= S_WAIT_NEDGE;
//                            end
//                        end
//                        default : begin
//                            read_state = S_WAIT_PEDGE;
//                            next_state = S_IDLE;
//                        end
//                    endcase
////                if(count_usec < 16'd23_201) begin // �ִ� 400cm
////                    if(echo_nedge) begin
////                        LED_bar[4] = 1;
//////                        echo_time = count_usec;
//////                        distance_buf = (count_usec * 1024) / 125;
////                        distance = count_usec / 58;
////                        count_usec_e = 0;
//////                        echo_flag = 0;
////                        next_state = S_IDLE;
////                    end
////                    else begin
////                        count_usec_e = 1;    
////                    end
////                end
////                else begin
//////                    count_usec = 16'd23_000;
////                    distance = 400;
////                end
//                end
//                S_READ_DATA : begin
//                    LED_bar[7] <= 1;
//                    distance <= clk_save / 58;
//                    clk_save <= 0;
//                    next_state <= S_IDLE;
//                    read_state <= S_WAIT_PEDGE;                                    
//                end
//                default : begin
//                    next_state = S_IDLE;
//                end
//            endcase
//        end
//    end
    
    
////    wire distance = 0;
////    assign distance = 1000000 * echo_time * 1024 / 125000000;
////    assign distance = (echo_time * 1024) / 125;
//endmodule
