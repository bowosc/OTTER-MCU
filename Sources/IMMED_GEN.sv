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


module IMMED_GEN(
        input logic [24:0] IMMED_GEN_ir,
        output logic [31:0] IMMED_GEN_j_type,
        output logic [31:0] IMMED_GEN_b_type,
        output logic [31:0] IMMED_GEN_u_type,
        output logic [31:0] IMMED_GEN_i_type,
        output logic [31:0] IMMED_GEN_s_type
    );
    
    
    
    // input its bits 31:7 of the instruction
    assign IMMED_GEN_i_type = {{20{IMMED_GEN_ir[24]}}, IMMED_GEN_ir[23:18], IMMED_GEN_ir[17:13]};
    assign IMMED_GEN_s_type = {{20{IMMED_GEN_ir[24]}}, IMMED_GEN_ir[23:18], IMMED_GEN_ir[4:0]};
    assign IMMED_GEN_b_type = {{19{IMMED_GEN_ir[24]}}, IMMED_GEN_ir[0], IMMED_GEN_ir[23:18], IMMED_GEN_ir[4:1], 1'b0};
    assign IMMED_GEN_u_type = {IMMED_GEN_ir[24:5], {12{1'b0}}};
    assign IMMED_GEN_j_type = {{11{IMMED_GEN_ir[24]}}, IMMED_GEN_ir[12:5], IMMED_GEN_ir[13], IMMED_GEN_ir[23:14], 1'b0};
    
endmodule


