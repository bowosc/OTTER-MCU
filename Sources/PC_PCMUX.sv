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


module PC_PCMUX(
        //input logic [31:0] PC_PCMUX_D_IN,
        input logic [31:0] PC_PCMUX_Jalr_IN,
        input logic [31:0] PC_PCMUX_Branch_IN, 
        input logic [31:0] PC_PCMUX_Jal_IN,
        input logic [1:0] PC_PCMUX_Source,
        
        input PC_PCMUX_LD,
        input PC_PCMUX_RST,
        
        input CLK,

        output logic [31:0] PC_PCMUX_OUT
    );
        
    logic [31:0] MUX_TO_PC_WIRE;
    
    PC_MUX instance0 (
        .PC_MUX_A(PC_PCMUX_OUT + 4),
        .PC_MUX_B(PC_PCMUX_Jalr_IN), // TEST: subbed FOUR
        .PC_MUX_C(PC_PCMUX_Branch_IN),
        .PC_MUX_D(PC_PCMUX_Jal_IN), // TEST: subbed FOUR
        
        .PC_MUX_SEL(PC_PCMUX_Source),
        
        .PC_MUX_Q(MUX_TO_PC_WIRE)
    );

    PC_Register instance1 (
        .PC_REGISTER_D_IN(MUX_TO_PC_WIRE),
        .PC_REGISTER_LD(PC_PCMUX_LD),
        .PC_REGISTER_RST(PC_PCMUX_RST),
        .CLK(CLK),
        .PC_REGISTER_Q(PC_PCMUX_OUT)
    );
endmodule


