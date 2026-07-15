`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: California Polytechnic University, San Luis Obispo
// Engineer: Bowman "The Big Cheese" Edebohls
// Create Date: 02/25/2023 10:55:14 PM
// Module Name: TwoMux
//////////////////////////////////////////////////////////////////////////////////

module WB_MUX(
    input logic [1:0] SEL, // test4.4
    input logic [31:0] PC4, // test4.4
    input logic [31:0] DM,
    input logic [31:0] ALU,
    output logic [31:0] OUT
    );
    
    always_comb begin
        case(SEL)
            2'b00: begin OUT = PC4; end // test4.4
            2'b10: begin OUT = DM; end // test4.4
            2'b11: begin OUT = ALU; end // test4.4
            default: begin OUT = 32'b0; end // test4.4
        endcase
    end
    
endmodule
