`timescale 1ns / 1ps

//ADDRESS
//ADDRESS

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Bowman Edebohls
// 
// Create Date: 
// Design Name: 
// Module Name: 
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

module BranchAddressGen(
        input logic [31:0] BAG_PC,
        input logic [31:0] BAG_J,
        input logic [31:0] BAG_B,
        input logic [31:0] BAG_I,
        input logic [31:0] BAG_rs1,
        output logic [31:0] BAG_jal,
        output logic [31:0] BAG_branch,
        output logic [31:0] BAG_jalr
    );
    
    assign BAG_jal = BAG_PC + BAG_J;
    assign BAG_branch = BAG_PC + BAG_B;
    assign BAG_jalr = BAG_rs1 + BAG_I;
    
endmodule


