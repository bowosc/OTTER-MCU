`timescale 1ns / 1ps

module TwoMux(
    input logic SEL,
    input logic [31:0] RS1,
    input logic [31:0] U_TYPE,
    output logic [31:0] SRC_A
    );
    
    //Create a generic two-to-one MUX to be used for the ALU.
    always_comb begin
        case(SEL)
            1'b0: begin SRC_A = RS1; end
            1'b1: begin SRC_A = U_TYPE; end
        endcase
    end
    
endmodule
