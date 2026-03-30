`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/08/2025 08:01:41 PM
// Design Name: 
// Module Name: servo_pwm_gen
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


module servo_pwm_gen(
    input wire clk,
    input wire rst,
    input wire pulse_ui,
    input wire pulse_sof,
    input wire [11:0] ch0_pulse_width_ui,
    input wire [11:0] ch1_pulse_width_ui,
    input wire [11:0] ch2_pulse_width_ui,
    input wire [11:0] ch3_pulse_width_ui,
    input wire [3:0]  ch_en,
    input wire [3:0]  io_enb,
    output wire [3:0] ch_pwm_pin,
    output wire [3:0] ch_active
    );

servo_pwm_ch servo_pwm_ch0(
    .clk                (clk),
    .rst                (rst),
    .pulse_sof          (pulse_sof),
    .pulse_ui           (pulse_ui),
    .ch_pulse_width_ui  (ch0_pulse_width_ui),
    .ch_en              (     ch_en[0]),
    .io_enb             (    io_enb[0]),
    .ch_pwm_pin         (ch_pwm_pin[0]),
    .ch_active          ( ch_active[0])
    );    

servo_pwm_ch servo_pwm_ch1(
    .clk                (clk),
    .rst                (rst),
    .pulse_sof          (pulse_sof),
    .pulse_ui           (pulse_ui),
    .ch_pulse_width_ui  (ch1_pulse_width_ui),
    .ch_en              (     ch_en[1]),
    .io_enb             (    io_enb[1]),    
    .ch_pwm_pin         (ch_pwm_pin[1]),
    .ch_active          ( ch_active[1])
    );
        
servo_pwm_ch servo_pwm_ch2(
    .clk                (clk),
    .rst                (rst),
    .pulse_sof          (pulse_sof),
    .pulse_ui           (pulse_ui),
    .ch_pulse_width_ui  (ch2_pulse_width_ui),
    .ch_en              (     ch_en[2]),
    .io_enb             (    io_enb[2]),    
    .ch_pwm_pin         (ch_pwm_pin[2]),
    .ch_active          ( ch_active[2])
    );
        
servo_pwm_ch servo_pwm_ch3(
    .clk                (clk),
    .rst                (rst),
    .pulse_sof          (pulse_sof),
    .pulse_ui           (pulse_ui),
    .ch_pulse_width_ui  (ch3_pulse_width_ui),
    .ch_en              (     ch_en[3]),
    .io_enb             (    io_enb[3]),    
    .ch_pwm_pin         (ch_pwm_pin[3]),
    .ch_active          ( ch_active[3])
    );    

endmodule

