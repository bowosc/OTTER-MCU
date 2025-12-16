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

module ALU(
        input logic [31:0] ALU_srcA,
        input logic [31:0] ALU_srcB,
        input logic [3:0] ALU_fun,
        output logic [31:0] ALU_result
    );
        
    always_comb begin
    
        case(ALU_fun)
            4'b0000: ALU_result = $signed(ALU_srcA) + $signed(ALU_srcB); //add
            4'b1000: ALU_result = $signed(ALU_srcA) - $signed(ALU_srcB); //sub //why isnt this working in that block with ffff_ffff
            4'b0111: ALU_result = $signed(ALU_srcA) & $signed(ALU_srcB); //and
            4'b0110: ALU_result = $signed(ALU_srcA) | $signed(ALU_srcB); //or
            4'b0100: ALU_result = $signed(ALU_srcA) ^ $signed(ALU_srcB); //xor
            4'b0101: ALU_result = $signed(ALU_srcA) >> $signed(ALU_srcB[4:0]); //srl
            4'b0001: ALU_result = $signed(ALU_srcA) << $signed(ALU_srcB[4:0]); //sll
            4'b1101: ALU_result = $signed(ALU_srcA) >>> ALU_srcB[4:0]; //sra (shift amt is unsigned)
            4'b0010: ALU_result = {31'b0, ($signed(ALU_srcA) < $signed(ALU_srcB))}; //slt
            4'b0011: ALU_result = {31'b0, (ALU_srcA < ALU_srcB)}; //sltu
            4'b1001: ALU_result = $signed(ALU_srcA); //lui copy    
            default: ALU_result = 32'hdeadbeef; // we should never get here
        endcase
    end
    
endmodule


