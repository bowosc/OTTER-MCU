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


module PC_MUX(
    input logic [31:0] PC_MUX_A, 
    input logic [31:0] PC_MUX_B,
    input logic [31:0] PC_MUX_C,
    input logic [31:0] PC_MUX_D,
    input logic [1:0] PC_MUX_SEL,
    
    output logic [31:0] PC_MUX_Q
);
    
    always_comb begin
        case(PC_MUX_SEL)
            0: PC_MUX_Q = PC_MUX_A; //00
            1: PC_MUX_Q = PC_MUX_B; //01
            2: PC_MUX_Q = PC_MUX_C; //10
            3: PC_MUX_Q = PC_MUX_D; //11
            default: PC_MUX_Q = 32'hdeadbeef; // should never get to this point
        endcase
    end
endmodule



