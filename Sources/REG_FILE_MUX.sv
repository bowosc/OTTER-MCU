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

module REG_FILE_MUX(
    input logic [31:0] REG_FILE_MUX_inputA, 
    input logic [31:0] REG_FILE_MUX_inputB,
    input logic [31:0] REG_FILE_MUX_inputC,
    input logic [31:0] REG_FILE_MUX_inputD,
    input logic [1:0] REG_FILE_MUX_SEL,
    
    output logic [31:0] REG_FILE_MUX_OUT
);
    
    always_comb begin
        case(REG_FILE_MUX_SEL)
            0: REG_FILE_MUX_OUT = REG_FILE_MUX_inputA; //0
            1: REG_FILE_MUX_OUT = REG_FILE_MUX_inputB; //1
            2: REG_FILE_MUX_OUT = REG_FILE_MUX_inputC; //2
            3: REG_FILE_MUX_OUT = REG_FILE_MUX_inputD; //3
            default: REG_FILE_MUX_OUT = 32'hdeadbeef; // should never get to this point
        endcase
    end
endmodule


// 1010 1010 0000 0101 0101 <-12 0010 1011 0111