`timescale 1ns / 1ps

module FourMux(
    input logic [1:0] SEL,
    input logic [31:0] RS2,
    input logic [31:0] I_TYPE,
    input logic [31:0] S_TYPE,
    input logic [31:0] PC_OUT,
    output logic [31:0] MUX_srcB
    );
    
    //Create a generic, four-to-one MUX. To be used for the Reg File
    //and the ALU.
    always_comb begin
        case(SEL) //Case dependent on Select.
            2'b00: begin MUX_srcB = RS2; end
            2'b01: begin MUX_srcB = I_TYPE; end
            2'b10: begin MUX_srcB = S_TYPE; end
            2'b11: begin MUX_srcB = PC_OUT; end
            default: begin MUX_srcB = 32'b0; end
        endcase
    end
    
endmodule
