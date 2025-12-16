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


module CU_FSM(
    input FSM_RST,
    input [6:0] FSM_opcode, //opcode
    input clk,
    output logic FSM_PCWrite, //enables PC to update
    output logic FSM_regWrite, //enables reg_file to write
    output logic FSM_memWE2, //memory write enable
    output logic FSM_memRDEN1, //memory read enable for instruction fetch
    output logic FSM_memRDEN2, //memory read enable for data
    output logic FSM_reset //internal reset signal
    );

//define 3 FSM states
typedef enum {ST_init, ST_fetch, ST_execute, ST_wb} STATES;

STATES NS, PS;

always_ff @(posedge clk) begin
    if (FSM_RST) //if FSM_RST is high, reset to ST_init
        PS <= ST_init; 
    else
        PS <= NS; //update state
    end
    
always_comb begin
//default values for all control signals
    NS = PS;
    FSM_PCWrite = 1'b0;
    FSM_regWrite = 1'b0;
    FSM_memWE2 = 1'b0;
    FSM_memRDEN1 = 1'b0;
    FSM_memRDEN2 = 1'b0;
    FSM_reset = 1'b0;
    NS = PS;
    
    case (PS)
        ST_init: begin
            FSM_reset = 1'b1; //acvtivate internal reset
            NS = ST_fetch; //move to instruction fetch
        end
        
        ST_fetch: begin
            FSM_memRDEN1 = 1'b1; //read instruction from memeory
           
            NS = ST_execute; //next: execute instruction
        end
        
        ST_execute: begin
            case (FSM_opcode) //LUI opcode execute case
                7'b0110111: begin
                    FSM_PCWrite = 1'b1; //update PC
                    FSM_regWrite = 1'b1; //Write result to register file
                    NS = ST_fetch; //fetch is next instruction
                end
                
                7'b0010011: begin //I-type opcode
                    FSM_regWrite = 1'b1;
                    FSM_PCWrite = 1'b1;
                    NS = ST_fetch;
                end
                
                7'b0110011: begin //R-type opcode
                    FSM_regWrite = 1'b1;
                    FSM_PCWrite = 1'b1;
                    NS = ST_fetch;
                end 
                
                7'b0010111: begin //AUIPC opcode
                    FSM_regWrite = 1'b1;
                    FSM_PCWrite = 1'b1;
                    NS = ST_fetch;
                end 
                
                7'b0000011: begin //load opcode
                    FSM_memRDEN2 = 1'b1; //enable data memory read
                    NS = ST_wb; //go to write-back state
                end
                
                7'b0100011: begin //store opcode
                    FSM_memWE2 = 1'b1;
                    FSM_PCWrite = 1'b1;
                    NS = ST_fetch;
                end
                
                7'b1100011: begin //branch opcode
                    FSM_PCWrite = 1'b1;
                    NS = ST_fetch;
                end
                
                7'b1101111: begin //jal opcode
                    FSM_regWrite = 1'b1;
                    FSM_PCWrite = 1'b1;
                    NS = ST_fetch;
                end
                
                7'b1100111: begin //jalr opcode
                    FSM_regWrite = 1'b1;
                    FSM_PCWrite = 1'b1;
                    NS = ST_fetch;
                end
                
                default: begin //default for unrecognized opcodes
                    FSM_PCWrite = 1'b1; //still step the pc
                     NS = ST_fetch;
                end
            endcase
        end
        
        ST_wb: begin
            FSM_PCWrite = 1'b1; //after write-back, advance PC
            FSM_regWrite = 1'b1; //Write loaded data into destination register
            NS = ST_fetch; //go back to instruction fetch
        end
    endcase
end
endmodule
