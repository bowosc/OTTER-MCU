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


module PC_Register(
        input PC_REGISTER_RST,
        input PC_REGISTER_LD,
        input logic [31:0] PC_REGISTER_D_IN,
        input CLK,

        output logic [31:0] PC_REGISTER_Q
    );
    
    always_ff @(posedge CLK) begin
        case ({PC_REGISTER_RST, PC_REGISTER_LD})
            2'b00: PC_REGISTER_Q <= PC_REGISTER_Q;
            2'b01: PC_REGISTER_Q <= PC_REGISTER_D_IN; // load
            2'b10: PC_REGISTER_Q <= 32'b00000000000000000000000000000000; // reset
            2'b11: PC_REGISTER_Q <= 32'b00000000000000000000000000000000; // both active, so we prioritize reset
            default: PC_REGISTER_Q <= 32'hdeadbeef; // how did we get here?
        endcase
    end
            
        
endmodule


