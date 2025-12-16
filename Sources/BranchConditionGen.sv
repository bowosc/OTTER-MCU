`timescale 1ns / 1ps

//CONDITION

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


module BranchConditionGen(
        input logic [31:0] BCG_rs1,
        input logic [31:0] BCG_rs2,
        output logic BCG_br_eq,
        output logic BCG_br_lt,
        output logic BCG_br_ltu
    );
    
    assign BCG_br_eq = BCG_rs1 == BCG_rs2;
    assign BCG_br_lt = $signed(BCG_rs1) < $signed(BCG_rs2);
    assign BCG_br_ltu = BCG_rs1 < BCG_rs2;
    
endmodule

