`timescale 1ns / 1ps

// Bowie's pipeline implementation

// Super useful stuff in the "Week 2-4 Pipelining Overview" in Canvas
// especially the 5.0 Pipelining and Data Hazards slides

// Bowie Note: Error I got on implementation, even with shrunk memory
// [DRC UTLZ-1] Resource utilization: LUT as Logic over-utilized in Top Level Design (This design requires more LUT as Logic cells than are available in the target device. This design requires 42030 of such cell types but only 20800 compatible sites are available in the target device. Please analyze your synthesis results and constraints to ensure the design is mapped to Xilinx primitives as expected. If so, please consider targeting a larger device. Please set tcl parameter "drc.disableLUTOverUtilError" to 1 to change this error to warning.)

// Opcode enum object
typedef enum logic [6:0] {
    LUI = 7'b0110111,
    AUIPC = 7'b0010111,
    JAL = 7'b1101111,
    JALR = 7'b1100111,
    BRANCH = 7'b1100011,
    LOAD = 7'b0000011,
    STORE = 7'b0100011,
    IMMED = 7'b0010011,
    REGST = 7'b0110011,
    SYSTEM = 7'b1110011
} opcode_t;

// Instruction struct object
typedef struct packed {

    // Seen in IF/DEC
    logic [6:0] opcode;
    logic [31:0] instruction;
    logic [31:0] pc;
    logic [31:0] pc_plus_4;
    logic [4:0] rs1_addr, rs2_addr, rd_addr;
    logic [2:0] f3b;
    logic bit_30;
    logic [24:0] ImmExtended;

    // Seen in DEC/EXE
    logic [3:0] ALU_fun;
    logic PCwrite, regWrite, Memwe2, Memrden1, Memrden2, rst;
    logic [1:0] rf_wr_sel;
    logic [31:0] rs1, rs2;
    logic ALU_srca;
    logic [1:0] ALU_srcb;
    logic [31:0] u_type, i_type, s_type, b_type, j_type;

    // Seen in EXE/MEM
    logic [31:0] ALU_result;
    logic [31:0] opB_forwarded;


    // Seen in MEM/WB
    logic [31:0] mem_data;



    // Not used yet
    logic rs1_used, rs2_used, rd_used;
    logic [31:0] wb_data;
    logic [2:0] mem_type; // {sign, size[1:0]}
} pipe_reg;

pipe_reg IF_DEC_reg, // Make the four registers (1 between each stage)
    DEC_EXE_reg,
    EXE_MEM_reg,
    MEM_WB_reg;


module OTTER_MCU (
    input CLK,
    input INTR,
    input RESET,
    input [31:0] IOBUS_IN,
    output [31:0] IOBUS_OUT,
    output [31:0] IOBUS_ADDR,
    output logic IOBUS_WR
    );

    logic flush_hold;

    DEBUGGER OTTER_DEBUGGER (
        .DEB_IF_DEC_inst(IF_DEC_reg.instruction),
        .DEB_DEC_EXE_inst(DEC_EXE_reg.instruction),
        .DEB_EXE_MEM_inst(EXE_MEM_reg.instruction),
        .DEB_MEM_WB_inst(MEM_WB_reg.instruction),
        .did_we_flush(flush_hold),
        .ignorethis() // ignore this
    );

    //===== Instruction Fetch =====
    logic [31:0] IM_read_out_1, pc, pc_out;
    logic [31:0] fetch_pc, fetch_pc_plus_4;


    // PC wires (we will need these eventually)
    logic [31:0] jalr_pc, jal_pc, branch_pc;
    logic [2:0] pc_source;
    logic stall;
    logic dcache_stall;
    logic stall_hfu; // test4.6
    logic jalr_stall; // test4.6
    logic branch_stall; //test5
    logic flush;
    // Only flush when we are actually able to redirect the PC.
    // This matters for pseudo-instruction `call`, which expands to
    // `auipc ra, ...` followed by `jalr ra, ... (ra)`.
    // The jalr must sometimes stall in decode waiting for the auipc result;
    // if we flush during that stall, the jalr disappears before it executes
    // and x1/ra keeps the auipc target base instead of PC+4.
    assign flush = (pc_source != 3'b000) && !stall;
    assign jalr_stall = (IF_DEC_reg.opcode == JALR) && (IF_DEC_reg.rs1_addr != 5'd0) && ( // test4.6
        ((DEC_EXE_reg.regWrite && (DEC_EXE_reg.rd_addr == IF_DEC_reg.rs1_addr))) || // test4.6
        ((EXE_MEM_reg.regWrite && (EXE_MEM_reg.rd_addr == IF_DEC_reg.rs1_addr)))); // test4.6
    assign branch_stall = (IF_DEC_reg.opcode == BRANCH) && ( //test5
        ((IF_DEC_reg.rs1_addr != 5'd0) && ( //test5
            (DEC_EXE_reg.regWrite && (DEC_EXE_reg.rd_addr == IF_DEC_reg.rs1_addr)) || //test5
            (EXE_MEM_reg.regWrite && (EXE_MEM_reg.rd_addr == IF_DEC_reg.rs1_addr)))) || //test5
        ((IF_DEC_reg.rs2_addr != 5'd0) && ( //test5
            (DEC_EXE_reg.regWrite && (DEC_EXE_reg.rd_addr == IF_DEC_reg.rs2_addr)) || //test5
            (EXE_MEM_reg.regWrite && (EXE_MEM_reg.rd_addr == IF_DEC_reg.rs2_addr))))); //test5
    assign stall = stall_hfu || jalr_stall || branch_stall || dcache_stall; // cache miss stalls the whole pipe


    //Instantiate the PC and connect relevant I/O
    PC PL_PC( // (Includes PC Mux)
        .CLK(CLK),
        .RST(RESET),
        .PC_WRITE(~(stall)), // tried changing this to ~(stall || flush || flush_hold) and similar, did not work much
        .PC_SOURCE(pc_source), 
        .JALR(jalr_pc), //test5
        .JAL(jal_pc), 
        .BRANCH(branch_pc),
        .MTVEC(32'b0), // idk what this is
        .MEPC(32'b0), // idk what this is

        .PC_OUT(pc),
        .PC_OUT_INC(pc_out)
    ); // inc = increment


//made a copy in case what im changing is wrong
//    Memory OTTER_INSTRUCTION_MEMORY(
//        .MEM_CLK(CLK),
//        .MEM_RDEN1(~stall), // older: NEW, used to be 1'b1.
//        .MEM_RDEN2(1'b0),
//        .MEM_WE2(1'b0),
//        .MEM_ADDR1(pc[15:2]),
//        .MEM_ADDR2(), // unused
//        .MEM_DIN2(), // unused
//        .MEM_SIZE(),
//        .MEM_SIGN(),
//       .IO_IN(), // What do we do with this? (we handle this later)
//        .IO_WR(), // What do we do with this? (we handle this later)
//
//        .MEM_DOUT1(IM_read_out_1),
//        .MEM_DOUT2() // unused
//    );
    // Synchronous instruction memory maps to BRAM. The fetched instruction
    // appears one cycle after the PC address, so fetch_pc tracks that address.
    imem OTTER_INSTRUCTION_MEMORY(
        .CLK(CLK),
        .RST(RESET),
        .EN(!stall),
        .a(pc),
        .rd(IM_read_out_1)
    );

    // In this stage, you will instantiate the PC
    // and MEM. Using a wire, connect the PC_OUT to
    // the IF/DE pipeline like below.

    always_ff @(posedge CLK) begin
        if (RESET) begin
            flush_hold <= 1'b0;
        end else begin
            flush_hold <= flush;
        end
    end

    always_ff @(posedge CLK) begin
        if (RESET) begin
            fetch_pc <= 32'd0;
            fetch_pc_plus_4 <= 32'd4;
        end else if (!stall) begin
            fetch_pc <= pc;
            fetch_pc_plus_4 <= pc_out;
        end
    end

    always_ff @(posedge CLK) begin

        if (RESET) begin
            IF_DEC_reg <= '0;
            IF_DEC_reg.instruction <= 32'h00000013;
        end else if (flush || flush_hold) begin //
            IF_DEC_reg.pc <= 32'd0;
            IF_DEC_reg.pc_plus_4 <= 32'd0;
            IF_DEC_reg.instruction <= 32'h00000013;
            IF_DEC_reg.rs1_addr <= 5'd0;
            IF_DEC_reg.rs2_addr <= 5'd0;
            IF_DEC_reg.rd_addr <= 5'd0;

            IF_DEC_reg.opcode <= 7'd0;
            IF_DEC_reg.f3b <= 3'd0;
            IF_DEC_reg.bit_30 <= 1'b0;
            IF_DEC_reg.ImmExtended <= 25'd0;

        end else if (stall == 1'b0) begin
            IF_DEC_reg.pc <= fetch_pc;
            IF_DEC_reg.pc_plus_4 <= fetch_pc_plus_4; //test5

            IF_DEC_reg.instruction <= IM_read_out_1;
            IF_DEC_reg.rs1_addr <= IM_read_out_1[19:15];
            IF_DEC_reg.rs2_addr <= IM_read_out_1[24:20];
            IF_DEC_reg.rd_addr <= IM_read_out_1[11:7];

            IF_DEC_reg.opcode <= IM_read_out_1[6:0];
            IF_DEC_reg.f3b <= IM_read_out_1[14:12];
            IF_DEC_reg.bit_30 <= IM_read_out_1[30];
            IF_DEC_reg.ImmExtended <= IM_read_out_1[31:7];
        
        end
    end


    //===== Instruction Decode =====

    // if wb is writing the register that decode needs now, use writeDataFromWBMUX, otherwise use the normal rs output (rs1_bypassed, rs2_bypassed)
    logic [31:0] writeDataFromWBMUX;
    logic [31:0] rs1_bypassed; //used when decode needs the value being written back right now 
    logic [31:0] rs2_bypassed;

    logic [31:0] rs1;
    logic [31:0] rs2;

    // DCDR wires
    logic [3:0] ALU_fun;
    logic ALU_srca;
    logic [1:0] ALU_srcb;
    logic PCwrite;
    logic regWrite;
    logic Memwe2;
    logic Memrden1;
    logic Memrden2;
    logic rst;

    logic [1:0] rf_wr_sel;
    logic uses_rs2; // test4.1

    // Immed Gen wires
    logic [31:0] u_type, i_type, s_type, b_type, j_type;

    assign uses_rs2 = (IF_DEC_reg.opcode == STORE) || (IF_DEC_reg.opcode == REGST) || (IF_DEC_reg.opcode == BRANCH); // test4.1

    REG_FILE OTTER_REG_FILE(
        .CLK(CLK),
        // These two are pulled from prev pipe reg
        .ADR1(IF_DEC_reg.rs1_addr),
        .ADR2(IF_DEC_reg.rs2_addr),

        // These are taken from the end of the pipeline (cuz this happens during WB)
        .EN(MEM_WB_reg.regWrite),
        .WA(MEM_WB_reg.rd_addr),
        .WD(writeDataFromWBMUX), // from WB mux at the end

        .RS1(rs1),
        .RS2(rs2)
    );

    //  WB-to-ID bypass so decode can see the value being written this cycle.
    assign rs1_bypassed = (MEM_WB_reg.regWrite && (MEM_WB_reg.rd_addr != 5'd0)
        && (MEM_WB_reg.rd_addr == IF_DEC_reg.rs1_addr)) // had to google syntax for this
        ? writeDataFromWBMUX : rs1; // wbdata is true, rs1 if false

    assign rs2_bypassed = (MEM_WB_reg.regWrite && (MEM_WB_reg.rd_addr != 5'd0)
        && (MEM_WB_reg.rd_addr == IF_DEC_reg.rs2_addr))
        ? writeDataFromWBMUX : rs2; // wbdata is true, rs2 if false

    // new
    logic BR_EQ, BR_LT, BR_LTU;
    BCG OTTER_BCG(
        .RS1(rs1_bypassed), // bypassed, from current instruction
        .RS2(rs2_bypassed),

        .BR_EQ(BR_EQ),
        .BR_LT(BR_LT),
        .BR_LTU(BR_LTU)
    );

    // TODO wire this up
    BAG OTTER_BAG( // all 32'b
        .RS1(rs1_bypassed),
        .I_TYPE(i_type),
        .J_TYPE(j_type),
        .B_TYPE(b_type),
        .FROM_PC(IF_DEC_reg.pc),
        .JAL(jal_pc),
        .JALR(jalr_pc),
        .BRANCH(branch_pc)
    );

    NEW_CU_DCDR OTTER_DCDR(
        .IR_30(IF_DEC_reg.bit_30),
        .IR_OPCODE(IF_DEC_reg.opcode),
        .IR_FUNCT(IF_DEC_reg.f3b),
        .BR_EQ(BR_EQ), // new new new
        .BR_LT(BR_LT),
        .BR_LTU(BR_LTU),

        .ALU_FUN(ALU_fun),
        .ALU_SRCA(ALU_srca),
        .ALU_SRCB(ALU_srcb),
        .PC_SOURCE(pc_source), 
        .RF_WR_SEL(rf_wr_sel), 
        .PC_WRITE(PCwrite),
        .REG_WRITE(regWrite),
        .MEM_WE2(Memwe2),
        .MEM_RDEN1(Memrden1),
        .MEM_RDEN2(Memrden2),
        .rst(rst)
    );

    // This is essentially the sign extender in her diagrams
    ImmediateGenerator OTTER_IMM_GEN(
        .IR(IF_DEC_reg.ImmExtended),
        .U_TYPE(u_type),
        .I_TYPE(i_type),
        .S_TYPE(s_type),
        .B_TYPE(b_type),
        .J_TYPE(j_type)
    );



    always_ff @(posedge CLK) begin

        if (RESET) begin
            DEC_EXE_reg <= '0;
            DEC_EXE_reg.instruction <= 32'h00000013;
        end else if (dcache_stall) begin
            DEC_EXE_reg <= DEC_EXE_reg;
        end else if (stall == 1'b1) begin // test4.1
            DEC_EXE_reg <= '0; /// inject a bubble here. // test4.1
            DEC_EXE_reg.instruction <= 32'h00000013;
        end else begin // test4.1
            DEC_EXE_reg <= IF_DEC_reg;

            DEC_EXE_reg.ALU_fun <= ALU_fun;
            DEC_EXE_reg.ALU_srca <= ALU_srca;
            DEC_EXE_reg.ALU_srcb <= ALU_srcb;
            DEC_EXE_reg.PCwrite <= PCwrite;
            DEC_EXE_reg.regWrite <= regWrite;
            DEC_EXE_reg.Memwe2 <= Memwe2;
            DEC_EXE_reg.Memrden1 <= Memrden1;
            DEC_EXE_reg.Memrden2 <= Memrden2;
            DEC_EXE_reg.rst <= rst;
            DEC_EXE_reg.rf_wr_sel <= rf_wr_sel;

            DEC_EXE_reg.rs1 <= rs1_bypassed;
            DEC_EXE_reg.rs2 <= rs2_bypassed;

            DEC_EXE_reg.u_type <= u_type;
            DEC_EXE_reg.i_type <= i_type;
            DEC_EXE_reg.s_type <= s_type;
            DEC_EXE_reg.b_type <= b_type;
            DEC_EXE_reg.j_type <= j_type;
        end
    end

    //===== ALU (EXECUTE) =====
    // fully wired (almost)

    // These are for forwarding values correctly (with the HFU)
    logic [31:0] opA_forwarded;
    logic [31:0] opB_forwarded;
    logic [31:0] ALU_result;
    
    // used when execute needs a recent value from a later pipeline stage instead of waiting for register writeback
    logic [31:0] rs1_forwarded_exe, rs2_forwarded_exe;
    logic [31:0] exe_mem_forward_data; //test5
    assign exe_mem_forward_data = (EXE_MEM_reg.rf_wr_sel == 2'b00) ? EXE_MEM_reg.pc_plus_4 : EXE_MEM_reg.ALU_result; //test5
    
    // These below are connected to the HFU
    wire [1:0] alu_mux_srcA_SEL, alu_mux_srcB_SEL;


    // Forward Mux1 (outputs into ALU src_A)
    always_comb begin
        case(alu_mux_srcA_SEL) //Case dependent on Select.
            2'b00: begin rs1_forwarded_exe = DEC_EXE_reg.rs1; end
            2'b01: begin rs1_forwarded_exe = exe_mem_forward_data; end //test5
            2'b10: begin rs1_forwarded_exe = writeDataFromWBMUX; end // P4Data
            default: begin rs1_forwarded_exe = 32'b0; end // used to be default: begin ALU_inA = srcB = 32'b0; end
        endcase
    end

    // Forward Mux2 (outputs into ALU src_B)
    always_comb begin
        case(alu_mux_srcB_SEL) //Case dependent on Select.
            2'b00: begin rs2_forwarded_exe = DEC_EXE_reg.rs2; end
            2'b01: begin rs2_forwarded_exe = exe_mem_forward_data; end //test5
            2'b10: begin rs2_forwarded_exe = writeDataFromWBMUX; end // P4Data
            default: begin rs2_forwarded_exe = 32'b0; end
        endcase
    end



    TwoMux OTTER_ALU_MUXA(
        .SEL(DEC_EXE_reg.ALU_srca),
        .RS1(rs1_forwarded_exe),
        .U_TYPE(DEC_EXE_reg.u_type),

        .SRC_A(opA_forwarded)
    );

    FourMux OTTER_ALU_MUXB(
        .SEL(DEC_EXE_reg.ALU_srcb),
        .RS2(rs2_forwarded_exe),
        .I_TYPE(DEC_EXE_reg.i_type),
        .S_TYPE(DEC_EXE_reg.s_type),
        .PC_OUT(DEC_EXE_reg.pc),

        .MUX_srcB(opB_forwarded)
    );

    ALU OTTER_ALU(
        .SRC_A(opA_forwarded),
        .SRC_B(opB_forwarded),
        .ALU_FUN(DEC_EXE_reg.ALU_fun),

        .RESULT(ALU_result)
    );

    HFU OTTER_HFU (
        .P2rs1(IF_DEC_reg.rs1_addr),
        .P2rs2(IF_DEC_reg.rs2_addr),
        .P3rs1(DEC_EXE_reg.rs1_addr),
        .P3rs2(DEC_EXE_reg.rs2_addr),
        .P3rd(DEC_EXE_reg.rd_addr),
        .P4rd(EXE_MEM_reg.rd_addr),
        .F3rd(EXE_MEM_reg.rd_addr), // test4
        .F4rd(MEM_WB_reg.rd_addr), // test4
        .P2uses_rs2(uses_rs2), // test4.1
        .P3we(DEC_EXE_reg.regWrite),
        .P4we(EXE_MEM_reg.regWrite),
        .F3we(EXE_MEM_reg.regWrite), // test4
        .F4we(MEM_WB_reg.regWrite), // test4
        .P3memRead(DEC_EXE_reg.Memrden2),
        
        .stall(stall_hfu), // test4.6
        .srcA_SEL(alu_mux_srcA_SEL), 
        .srcB_SEL(alu_mux_srcB_SEL) 
    );


    always_ff @(posedge CLK) begin
        if (RESET) begin
            EXE_MEM_reg <= '0;
            EXE_MEM_reg.instruction <= 32'h00000013;
        end else if (dcache_stall) begin
            EXE_MEM_reg <= EXE_MEM_reg;
        end else begin
            EXE_MEM_reg <= DEC_EXE_reg;
            EXE_MEM_reg.opB_forwarded <= rs2_forwarded_exe;
            EXE_MEM_reg.ALU_result <= ALU_result;
        end

        // // Lshift (by 2) and add to PC+4 the immextended value. (accd. to 5.0Pipeline&DataHazards.pdf, the powerpoint one)
        // EXE_MEM_reg.ImmExtended <= (DEC_EXE_reg.ImmPreExtended << 2) + DEC_EXE_reg.pc_plus_4; // TODO: this is prob wrong.
    end

    //===== Memory =====
     assign IOBUS_ADDR = EXE_MEM_reg.ALU_result;
     assign IOBUS_OUT = EXE_MEM_reg.opB_forwarded;
    
    // assign de_ex_inst.ir = 32'b0;

    logic [31:0] memdout2;


    SA_Cache OTTER_DATA_MEMORY(
        .MEM_CLK(CLK),
        .MEM_RST(RESET),
        .MEM_RDEN1(), // unused
        .MEM_RDEN2(EXE_MEM_reg.Memrden2), // addr2, ignore the other - it's used in the other module instance.
        .MEM_WE2(EXE_MEM_reg.Memwe2),
        .MEM_ADDR1(), // unused
        .MEM_ADDR2(EXE_MEM_reg.ALU_result),
        .MEM_DIN2(EXE_MEM_reg.opB_forwarded),
        .MEM_SIZE(EXE_MEM_reg.f3b[1:0]),
        .MEM_SIGN(EXE_MEM_reg.f3b[2]),
        .IO_IN(IOBUS_IN),
        .IO_WR(IOBUS_WR),
        .MEM_BUSY(dcache_stall),

        .MEM_DOUT1(),
        .MEM_DOUT2(memdout2)
    );

    always_ff @(posedge CLK) begin
        if (RESET) begin
            MEM_WB_reg <= '0;
            MEM_WB_reg.instruction <= 32'h00000013;
        end else if (dcache_stall) begin
            MEM_WB_reg <= '0;
            MEM_WB_reg.instruction <= 32'h00000013;
        end else begin
            MEM_WB_reg <= EXE_MEM_reg;
            MEM_WB_reg.mem_data <= memdout2;
        end
    end

    //===== Write Back =====
    WB_MUX OTTER_WB_MUX (
        .SEL(MEM_WB_reg.rf_wr_sel), // test4.4
        .PC4(MEM_WB_reg.pc_plus_4), // test4.4
        .DM(MEM_WB_reg.mem_data),
        .ALU(MEM_WB_reg.ALU_result),
        .OUT(writeDataFromWBMUX)
    );




endmodule


// +++++++++++ Hazard & Forwarding Unit +++++++++++

    // Forwarding

    // EX: 
    // add x1, x3, x4 (inst A)
    // add x2, x5, x6 (inst B)
    // add x9, x1, x2 (inst C)

    // INPUT
    // RS1 from DEC/ALU (inst C)
    // RS2 from DEC/ALU (inst C)
    // WD from ALU/MEM (inst B)
    // WD from MEM/WB (inst A)

    // Mux 1 switches if RS1 is the same as the ALU/MEM WD (inst B) or the MEM/WB WD (inst A)
    // Mux 2 switches if RS2 is the same as the ALU/MEM WD (inst B) or the MEM/WB WD (inst A)

    // OUTPUT
    // Mux 1 SEL (on the ALU)
    // MUX 2 SEL (on the ALU)




    // Hazard

    // EX:
    //      beq x0, x0, loc
    //      add x0, x0, x0
    //      add x0, x0, x0
    // loc: sub x0, x0, x0
    //      sub x0, x0, x0


    
