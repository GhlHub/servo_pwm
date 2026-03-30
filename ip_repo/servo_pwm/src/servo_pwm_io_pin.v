`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/08/2025 08:05:07 PM
// Design Name: 
// Module Name: servo_pwm_io_pin
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


module servo_pwm_io_pin(
    input pwm_t,
    input pwm_out,
    output pwm_pin
    );
    
   OBUFT #(
      .DRIVE(12),   // Specify the output drive strength
      .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
      .SLEW("SLOW") // Specify the output slew rate
   ) OBUFT_inst (
      .O(pwm_pin),     // Buffer output (connect directly to top-level port)
      .I(pwm_out),     // Buffer input
      .T(pwm_t)      // 3-state enable input
   );
    
    
    
    
endmodule
