`timescale 1ns / 1ps

// Simulation stub for the Xilinx OBUFT primitive used by the DUT.
module OBUFT #(
    parameter integer DRIVE = 12,
    parameter IOSTANDARD = "DEFAULT",
    parameter SLEW = "SLOW"
) (
    output wire O,
    input wire I,
    input wire T
);

assign O = T ? 1'bz : I;

endmodule
