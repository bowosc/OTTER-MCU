`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Bowman Edebohls
// 
// Create Date: 
// Design Name: TOP LEVEL OTTER CPU
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


module OTTER(
        input logic RST,
        input logic INTR,
        input logic [31:0] IOBUS_IN,
        input logic CLK,
        
        output logic IOBUS_WR,
        output logic [31:0] IOBUS_OUT,
        output logic [31:0] IOBUS_ADDR
    );
        
    logic [31:0] CSR_reg = 32'h00000000; // unused
    
    logic PCWrite;
    logic regWrite;
    logic memWE2;
    logic memRDEN1;
    logic memRDEN2;
    logic reset;
    
    logic [3:0] alu_fun;
    logic alu_srcA;
    logic [1:0] alu_srcB;
    logic [1:0] pcSource;
    logic [1:0] rf_wr_sel;
    
    logic br_eq;
    logic br_lt;
    logic br_ltu;
    
    logic [31:0] reg_rs1_wire;
    logic [31:0] reg_rs2_wire;
    
    
    CU_FSM cufsm ( // new b version
        .clk(CLK),
        .FSM_RST(RST),
        .FSM_opcode(ir[6:0]), 
        
        .FSM_PCWrite(PCWrite),
        .FSM_regWrite(regWrite),
        .FSM_memWE2(memWE2),
        .FSM_memRDEN1(memRDEN1),
        .FSM_memRDEN2(memRDEN2),
        .FSM_reset(reset)
    );

    
    CU_DCDR cudcdr (
        .DCDR_opcode(ir[6:0]),
        .DCDR_funct3(ir[14:12]),
        .DCDR_30thBit(ir[30]),
        .DCDR_eq(br_eq),
        .DCDR_lt(br_lt),
        .DCDR_ltu(br_ltu),
        
        .DCDR_alufun(alu_fun),
        .DCDR_alusrcA(alu_srcA),
        .DCDR_alusrcB(alu_srcB),
        .DCDR_pcSource(pcSource),
        .DCDR_rfwrsel(rf_wr_sel)
    );

    BranchConditionGen bcg (
        .BCG_rs1(reg_rs1_wire),
        .BCG_rs2(reg_rs2_wire),
        .BCG_br_eq(br_eq),
        .BCG_br_lt(br_lt),
        .BCG_br_ltu(br_ltu)
    );
    
    logic [31:0] muxtoregfile_wire;
    
    REG_FILE_MUX reggiemux (
        .REG_FILE_MUX_inputA(pc_out_wire),
        .REG_FILE_MUX_inputB(CSR_reg),
        .REG_FILE_MUX_inputC(mem_dout2_wire),
        .REG_FILE_MUX_inputD(alu_result_wire),
        
        .REG_FILE_MUX_SEL(rf_wr_sel),
        .REG_FILE_MUX_OUT(muxtoregfile_wire)
    );
    
    
    REG_FILE reggie (
        .REG_FILE_en(regWrite),
        .REG_FILE_wd(muxtoregfile_wire),
        .REG_FILE_adr1(ir[19:15]),
        .REG_FILE_adr2(ir[24:20]),
        .REG_FILE_wa(ir[11:7]),
        .REG_FILE_CLK(CLK),
        
        .REG_FILE_Rs1(reg_rs1_wire),
        .REG_FILE_Rs2(reg_rs2_wire)
    );
    
    logic [31:0] immed_u_type_wire;
    logic [31:0] immed_i_type_wire;
    logic [31:0] immed_s_type_wire;
    logic [31:0] immed_b_type_wire;
    logic [31:0] immed_j_type_wire;
    
    IMMED_GEN immy(
        .IMMED_GEN_ir(ir[31:7]),
        
        .IMMED_GEN_j_type(immed_j_type_wire),
        .IMMED_GEN_b_type(immed_b_type_wire),
        .IMMED_GEN_u_type(immed_u_type_wire),
        .IMMED_GEN_i_type(immed_i_type_wire),
        .IMMED_GEN_s_type(immed_s_type_wire)
    );
    
    logic [31:0] bag_to_pc_jalr_wire;
    logic [31:0] bag_to_pc_branch_wire;
    logic [31:0] bag_to_pc_jal_wire;
    
    BranchAddressGen baggy(
        .BAG_PC(pc_out_wire),
        .BAG_J(immed_j_type_wire),
        .BAG_B(immed_b_type_wire),
        .BAG_I(immed_i_type_wire),
        .BAG_rs1(reg_rs1_wire),
        
        .BAG_jal(bag_to_pc_jal_wire),
        .BAG_branch(bag_to_pc_branch_wire),
        .BAG_jalr(bag_to_pc_jalr_wire)
    );
    
    logic [31:0] alu_mux_to_A_wire;
    logic [31:0] alu_mux_to_B_wire;
  
    ALU_MUX_A muxyA(
        .ALU_MUX_A_inputA(reg_rs1_wire),
        .ALU_MUX_A_inputB(immed_u_type_wire),
        .ALU_MUX_A_SEL(alu_srcA),
        
        .ALU_MUX_A_OUT(alu_mux_to_A_wire)
    );
    
    ALU_MUX_B muxyB(
        .ALU_MUX_B_inputA(reg_rs2_wire),
        .ALU_MUX_B_inputB(immed_i_type_wire),
        .ALU_MUX_B_inputC(immed_s_type_wire),
        .ALU_MUX_B_inputD(pc_out_wire),
        .ALU_MUX_B_SEL(alu_srcB),
        
        .ALU_MUX_B_OUT(alu_mux_to_B_wire)
    );
    
    logic [31:0] alu_result_wire;
    
    ALU aluey(
        .ALU_srcA(alu_mux_to_A_wire),
        .ALU_srcB(alu_mux_to_B_wire),
        .ALU_fun(alu_fun),
        .ALU_result(alu_result_wire)
    );
    
    logic [31:0] ir;
    logic [31:0] mem_dout2_wire;
    
    Memory memmy (
        .MEM_CLK(CLK),
        .MEM_RDEN1(memRDEN1),
        .MEM_RDEN2(memRDEN2),
        .MEM_WE2(memWE2),
        .MEM_ADDR1(pc_out_wire[15:2]),
        .MEM_ADDR2(alu_result_wire),
        .MEM_DIN2(reg_rs2_wire),
        .MEM_SIZE(ir[13:12]),
        .MEM_SIGN(ir[14]),
        .IO_IN(IOBUS_IN),
        
        .IO_WR(IOBUS_WR),
        .MEM_DOUT1(ir),
        .MEM_DOUT2(mem_dout2_wire)
    );
    
    logic [31:0] pc_out_wire;
    
    PC_PCMUX pcpcmux(
        .PC_PCMUX_Jalr_IN(bag_to_pc_jalr_wire),
        .PC_PCMUX_Branch_IN(bag_to_pc_branch_wire),
        .PC_PCMUX_Jal_IN(bag_to_pc_jal_wire),
        .PC_PCMUX_Source(pcSource),
        .CLK(CLK),
        .PC_PCMUX_LD(PCWrite),
        .PC_PCMUX_RST(reset),
        
        .PC_PCMUX_OUT(pc_out_wire)
    );
    
    assign IOBUS_OUT = reg_rs2_wire;
    assign IOBUS_ADDR = alu_result_wire;
    
endmodule
