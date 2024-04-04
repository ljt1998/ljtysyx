//   ____  ___ ____   ____   __     __    ||   _        _ _____ 
//  |  _ \|_ _/ ___| / ___|  \ \   / /    ||  | |      | |_   _|
//  | |_) || |\___ \| |   ____\ \ / /     ||  | |   _  | | | |  
//  |  _ < | | ___) | |__|_____\ V /      ||  | |__| |_| | | |  
//  |_| \_\___|____/ \____|     \_/       ||  |_____\___/  |_|  
//                                        ||  
`timescale 1ns / 1ps

`define ZERO_WORD  64'h00000000_00000000
`define PC_START   64'h00000000_80000000  
`define REG_BUS    63 : 0     
`define INST_ADD   8'h11

`define RISCV_PRIV_MODE_U   0
`define RISCV_PRIV_MODE_S   1
`define RISCV_PRIV_MODE_M   3
`define BUS_WIDTH 63:0

`define DFFENR(clk, rst, en, din, dout,rst_value) \
    always @(posedge clk or posedge rst) begin \
        if (rst) \
            dout <= rst_value; \
        else if (en) \
            dout <= din; \
    end
`define RstEnable             1'b0  
`define RstDisable            1'b1
`define ZeroWord             32'd0
`define DZeroWord            64'd0
`define WriteEnable           1'b1
`define WriteDisable          1'b0
`define ReadEnable            1'b1
`define ReadDisable           1'b0
`define AluOpBus              7:0   //译码阶段的输出aluop_p的宽度
`define AluSelBus             2:0   //            alusel_o的宽度
`define InstValid             1'b1
`define InstInvalid           1'b0
`define ChipEnable            1'b1
`define ChipDisable           1'b0

//************************** branch inst *************************//
`define OPCODE_BRANCH       7'b1100011
`define OPCODE_JAL          7'b1101111   
`define OPCODE_JALR         7'b1100111  
//************************** Alu-op/sel **************************//

//Aluop   运算子类型
`define EXE_SUBW_OP   8'b0010_1111
`define EXE_AND_OP    8'b0010_0100
`define EXE_OR_OP     8'b0010_0101
`define EXE_XOR_OP    8'b0010_0110
`define EXE_NOR_OP    8'b0010_0111
`define EXE_ANDI_OP   8'b0101_1001
`define EXE_ORI_OP    8'b0101_1010
`define EXE_XORI_OP   8'b0101_1011
`define EXE_LUI_OP    8'b0101_1100   
`define EXE_ADDW_OP   8'b0101_1101
`define EXE_SLL_OP    8'b0111_1100
`define EXE_SLLI_OP   8'b0000_0100
`define EXE_SRL_OP    8'b0000_0010
`define EXE_SRLV_OP   8'b0000_0110
`define EXE_SRA_OP    8'b0000_0011
`define EXE_SRAV_OP   8'b0000_0111
`define EXE_SRAW_OP   8'b1000_0000
`define EXE_SRUW_OP   8'b1100_0000
`define EXE_NOP_OP    8'b0000_0000
`define EXE_SLTA_OP   8'b0010_1010
`define EXE_SLTU_OP   8'b0010_1011
`define EXE_SLTI_OP   8'b0101_0111
`define EXE_SLTIU_OP  8'b0101_1000   
`define EXE_ADD_OP    8'b0010_0000
`define EXE_ADDU_OP   8'b0010_0001
`define EXE_SUB_OP    8'b0010_0010
`define EXE_SUBU_OP   8'b0010_0011
`define EXE_ADDI_OP   8'b0101_0101
`define EXE_ADDIU_OP  8'b0101_0110
`define EXE_SLLW_OP   8'b0101_1111

`define EXE_MULT_OP   8'b0001_1000
`define EXE_MULTU_OP  8'b0001_1001
`define EXE_MUL_OP    8'b1010_1001

//Alusel     运算类型
`define EXE_RES_NOP        3'b000
`define EXE_RES_LOGIC      3'b001       
`define EXE_RES_SHIFT      3'b010
`define EXE_RES_SUBW       3'b011	
`define EXE_RES_ARITHMETIC 3'b100	
`define EXE_RES_MUL        3'b101
`define EXE_RES_COMPARE    3'b110
//**************************  inst-memory **************************//
`define InstAddrBus        31:0
`define PcAddrBus          63:0
`define InstBus            31:0
`define InstMemNum         131071
`define InstMemNumLog2     17

//**************************  Regfile **************************//
`define RegAddrBus          4:0 
`define RegBus              31:0
`define RegWidth            32
`define DoubleRegWidth      64
`define DoubleRegBus        63:0
`define RegNum              32
`define RegNumLog2           5
`define NOPRegAddr           5'b00000 
//**************************Branch ********************************//
`define Branch             1'b1   //转移
`define NotBranch          1'b0   //不转移
//**************************stall ********************************//
`define Stop               1'b1
`define NoStop             1'b0
//**************************dual ram ********************************//
`define DataAddrBus         31:0
`define DataBus             31:0
`define DataMemNum          131071
`define DataMemNumLog2      17
`define ByteWidth           7:0
//************************** div unit ********************************//
`define DivFree             2'b00
`define DivByZero           2'b01
`define DivOn               2'b10
`define DivEnd              2'b11
`define DivResultReady      1'b1
`define DivResultNotReady   1'b0
`define DivStart            1'b1
`define DivStop             1'b0
`define EXE_DIV_OP          8'b00011010
`define EXE_DIVU_OP         8'b00011011
`define EXE_REM_OP          8'b1011_0000
`define EXE_REMU_OP         8'b1011_0001
