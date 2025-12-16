`timescale 1ns / 1ps
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


module ALU_MUX_A(
    input logic [31:0] ALU_MUX_A_inputA, 
    input logic [31:0] ALU_MUX_A_inputB,
    input logic ALU_MUX_A_SEL,
    
    output logic [31:0] ALU_MUX_A_OUT
);
    
    always_comb begin
        case(ALU_MUX_A_SEL)
            0: ALU_MUX_A_OUT = ALU_MUX_A_inputA; //0
            1: ALU_MUX_A_OUT = ALU_MUX_A_inputB; //1
            default: ALU_MUX_A_OUT = 32'hdeadbeef; // should never get to this point
        endcase
    end
endmodule