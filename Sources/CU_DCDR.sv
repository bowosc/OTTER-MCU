`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Brody Bredice, Bowman Edebohls
// 
// Create Date: 11/07/2025 12:26:23 PM
// Design Name: 
// Module Name: CU_DCDR
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

module CU_DCDR(
    input  logic [6:0] DCDR_opcode, //opcode
    input  logic [2:0] DCDR_funct3, //funct3
    input  logic       DCDR_30thBit, //30th bit
    input  logic       DCDR_eq, //rs1 == rs2
    input  logic       DCDR_lt, //rs1 < rs2 (signed)
    input  logic       DCDR_ltu, //rs1 < rs2 (unsigned)
    output logic [3:0] DCDR_alufun, // ALU operations
    output logic       DCDR_alusrcA, //ALU MUX1 select
    output logic [1:0] DCDR_alusrcB, //ALU MUX2 select
    output logic [1:0] DCDR_pcSource, //PC_MUX select
    output logic [1:0] DCDR_rfwrsel //RF_MUX select
);

    always_comb begin
        // defaults
        DCDR_alufun   = 4'b0000; //default alu is add
        DCDR_alusrcA  = 1'b0;        // rs1
        DCDR_alusrcB  = 2'b00;       // rs2
        DCDR_pcSource = 2'b00;  // fallthrough
        DCDR_rfwrsel  = 2'b00;    // ALU result

        case (DCDR_opcode)
            // LUI
            7'b0110111: begin
                DCDR_alufun   = 4'b1001; //lui alu_fun
                DCDR_alusrcA  = 1'b1;     // select U-imm on ALU_MUX1
                DCDR_rfwrsel  = 2'b11; // write ALU result
            end
            
            7'b0010011: begin //I-type
                DCDR_alusrcB = 2'b1; //alu B = I-type immediate
                DCDR_rfwrsel = 2'b11; //write alu output to rd
                if (DCDR_funct3 == 3'b101) //distinguish SRL/SRA via 30th bit
                begin
                   DCDR_alufun = {DCDR_30thBit, DCDR_funct3[2:0]}; 
                end
                else
                begin
                    DCDR_alufun = {1'b0, DCDR_funct3[2:0]};
                end
            end
            
            7'b0110011: begin //R-type
                DCDR_rfwrsel = 2'b11; //alu to register
                DCDR_alufun = {DCDR_30thBit, DCDR_funct3[2:0]}; //determines SUB vs ADD
            end
            
            7'b0010111: begin //AUIPC
                DCDR_alusrcA = 1'b1; //ALU A = PC
                DCDR_alusrcB = 2'b11; //ALU B = U-imm
                DCDR_rfwrsel = 2'b11; //Result written back to rd
            end
            
            7'b0000011: begin //Load
                DCDR_alusrcB = 2'b01; //ALU B = I-imm
                DCDR_rfwrsel = 2'b10; //Writeback from memory data
            end
            
            7'b0100011: begin //Store
                DCDR_alusrcB = 2'b10; //ALU B = S-imm
            end
            
            7'b1100011: begin //Branch
                case (DCDR_funct3)
                    3'b000: begin //BEQ
                        if (DCDR_eq == 1)
                            begin DCDR_pcSource = 2'b10;
                            end
                    end
                    3'b001: begin //BNE
                        if (DCDR_eq == 0)
                            begin DCDR_pcSource = 2'b10;
                            end
                    end
                    3'b100: begin //BLT
                        if (DCDR_lt == 1)
                            begin DCDR_pcSource = 2'b10;
                            end
                    end
                    3'b101: begin //BGE
                        if (DCDR_lt == 0)
                            begin DCDR_pcSource = 2'b10;
                            end
                    end
                    3'b110: begin //BLTU
                        if (DCDR_ltu == 1)
                            begin DCDR_pcSource = 2'b10;
                            end
                    end
                    3'b111: begin //BGEU
                        if (DCDR_ltu == 0)
                            begin DCDR_pcSource = 2'b10;
                            end
                    end
                endcase
            end
            
            7'b1101111: begin //JAL
                DCDR_pcSource = 2'b11; //Select JAL target
            end
            
            7'b1100111: begin //JALR    
                DCDR_pcSource = 2'b01; //Select JALR target
            end                    
                            
            default: begin end //default to do nothing, fallthrough to PC + 4
        endcase
    end
endmodule

