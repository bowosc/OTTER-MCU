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


module ALU_MUX_B(
    input logic [31:0] ALU_MUX_B_inputA, 
    input logic [31:0] ALU_MUX_B_inputB,
    input logic [31:0] ALU_MUX_B_inputC,
    input logic [31:0] ALU_MUX_B_inputD,
    input logic ALU_MUX_B_SEL,
    
    output logic [31:0] ALU_MUX_B_OUT
);
    
    always_comb begin
        case(ALU_MUX_B_SEL)
            0: ALU_MUX_B_OUT = ALU_MUX_B_inputA; //0
            1: ALU_MUX_B_OUT = ALU_MUX_B_inputB; //1
            2: ALU_MUX_B_OUT = ALU_MUX_B_inputC; //2
            3: ALU_MUX_B_OUT = ALU_MUX_B_inputD; //3
            default: ALU_MUX_B_OUT = 32'hdeadbeef; // should never get to this point
        endcase
    end
endmodule