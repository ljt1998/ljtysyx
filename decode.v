`include "defines.v"
module decode(
    input wire [63:0]  pc_i,
    input wire [31:0]  inst_i,
    input wire predict_is_yes_i,
    // new forwarding
    input wire [63:0]  wb_data_i,
    input wire [63:0]  ex_data_comb_i,
    input wire [63:0]  mem_data_comb_i,
    input wire [1:0]   if_rs1_foward_type_i,
    input wire [1:0]   if_rs2_foward_type_i,
    input wire [63:0]  load_data_i,
    input wire         load_forward_rs1_en,
    input wire         load_forward_rs2_en,
    //read regfile
    input wire [63:0]  rs1_data_i,
    input wire [63:0]  rs2_data_i,

    //crtl-signal branch inst
    output wire flush_and_pc_redir_en,

    //branch pc_redir
    output wire [63:0] pc_redir,

    //output --> regfile
    output wire [4:0] rs1_addr_o,
    output wire [4:0] rs2_addr_o,
    output wire       rs1_r_en_o,
    output wire       rs2_r_en_o,

//output --> IDEX
    output wire [`AluOpBus]   aluop_o,//运算子类型
    output wire [`AluSelBus]  alusel_o,//运算类型
    output wire [63:0]        rs1_data_o,
    output wire [63:0]        rs2_data_o,
    output wire [63:0]        pc_addr_o,
    output wire [4:0]         wb_addr_o, 
    output wire               wb_en_o,
    // lsu-mem-ctrl
    output wire               mem_r_en_o,
    output wire               mem_w_en_o,
    output wire [7:0]         mem_mask_o,
    output wire               mem_load_is_signed_o,
    output wire [63:0]        difftest_pc_o,
    output wire [63:0]        mem_wr_data_o
);
  wire [63:0] id_rs1;
  wire [63:0] id_rs2;
  wire [`RegBus]              branch_add_result;
  wire [`RegBus]              branch_rs2_complement_sel;
  wire [`InstAddrBus]         branch_pc_addr;
  wire branch_check;
  wire [1:0] branch_check_type;
 // wire [63:0]         pc_addr_next_4 = pc_i + 64'd4;
//*******************inst decode**************************************************//
  wire [6:0] opcode       = inst_i[6:0];
  wire [4:0] rv64_rd_addr = inst_i[11:7];
  wire [2:0] rv64_func3   = inst_i[14:12];
  wire [6:0] rv64_func7   = inst_i[31:25];
  wire [4:0] rv64_rs1     = inst_i[19:15];
  wire [4:0] rv64_rs2     = inst_i[24:20];

//*******************imm decode**************************************************//
  wire [11:0] I_imm       = inst_i[31:20];
  wire [19:0] U_imm       = inst_i[31:12];
  wire [19:0] J_imm       = {inst_i[31],inst_i[19:12],inst_i[20],inst_i[30:21]};
  wire [11:0] B_imm       = {inst_i[31],inst_i[7],inst_i[30:25],inst_i[11:8]  };
  wire [11:0] S_imm       = {inst_i[31:25],inst_i[11:7]};
//*******************op decode**************************************************//
  wire opcode_1_0_00  = (opcode[1:0] == 2'b00 );
  wire opcode_1_0_01  = (opcode[1:0] == 2'b01 );
  wire opcode_1_0_10  = (opcode[1:0] == 2'b10 );
  wire opcode_1_0_11  = (opcode[1:0] == 2'b11 );
  wire opcode_4_2_000 = (opcode[4:2] == 3'b000);
  wire opcode_4_2_001 = (opcode[4:2] == 3'b001);
  wire opcode_4_2_010 = (opcode[4:2] == 3'b010);
  wire opcode_4_2_011 = (opcode[4:2] == 3'b011);
  wire opcode_4_2_100 = (opcode[4:2] == 3'b100);
  wire opcode_4_2_101 = (opcode[4:2] == 3'b101);
  wire opcode_4_2_110 = (opcode[4:2] == 3'b110);
  wire opcode_4_2_111 = (opcode[4:2] == 3'b111);
  wire opcode_6_5_00  = (opcode[6:5] == 2'b00 );
  wire opcode_6_5_01  = (opcode[6:5] == 2'b01 );
  wire opcode_6_5_10  = (opcode[6:5] == 2'b10 );
  wire opcode_6_5_11  = (opcode[6:5] == 2'b11 );

  wire rv64_func3_000 = (rv64_func3 == 3'b000);
  wire rv64_func3_001 = (rv64_func3 == 3'b001);
  wire rv64_func3_010 = (rv64_func3 == 3'b010);
  wire rv64_func3_011 = (rv64_func3 == 3'b011);
  wire rv64_func3_100 = (rv64_func3 == 3'b100);
  wire rv64_func3_101 = (rv64_func3 == 3'b101);
  wire rv64_func3_110 = (rv64_func3 == 3'b110);
  wire rv64_func3_111 = (rv64_func3 == 3'b111);

  wire rv64_func7_0000000 = (rv64_func7 == 7'b0000000);
  wire rv64_func7_0100000 = (rv64_func7 == 7'b0100000);
  wire rv64_func7_0000001 = (rv64_func7 == 7'b0000001);
  wire rv64_func7_0000101 = (rv64_func7 == 7'b0000101);
  wire rv64_func7_0001001 = (rv64_func7 == 7'b0001001);
  wire rv64_func7_0001101 = (rv64_func7 == 7'b0001101);
  wire rv64_func7_0010101 = (rv64_func7 == 7'b0010101);
  wire rv64_func7_0100001 = (rv64_func7 == 7'b0100001);
  wire rv64_func7_0010001 = (rv64_func7 == 7'b0010001);
  wire rv64_func7_0101101 = (rv64_func7 == 7'b0101101);
  wire rv64_func7_1111111 = (rv64_func7 == 7'b1111111);
  wire rv64_func7_0000100 = (rv64_func7 == 7'b0000100); 
  wire rv64_func7_0001000 = (rv64_func7 == 7'b0001000); 
  wire rv64_func7_0001100 = (rv64_func7 == 7'b0001100); 
  wire rv64_func7_0101100 = (rv64_func7 == 7'b0101100); 
  wire rv64_func7_0010000 = (rv64_func7 == 7'b0010000); 
  wire rv64_func7_0010100 = (rv64_func7 == 7'b0010100); 
  wire rv64_func7_1100000 = (rv64_func7 == 7'b1100000); 
  wire rv64_func7_1110000 = (rv64_func7 == 7'b1110000); 
  wire rv64_func7_1010000 = (rv64_func7 == 7'b1010000); 
  wire rv64_func7_1101000 = (rv64_func7 == 7'b1101000); 
  wire rv64_func7_1111000 = (rv64_func7 == 7'b1111000); 
  wire rv64_func7_1010001 = (rv64_func7 == 7'b1010001);  
  wire rv64_func7_1110001 = (rv64_func7 == 7'b1110001);  
  wire rv64_func7_1100001 = (rv64_func7 == 7'b1100001);  
  wire rv64_func7_1101001 = (rv64_func7 == 7'b1101001);  

  wire rv64_rs1_x0        = (rv64_rs1      == 5'b00000);
  wire rv64_rd_addr_x0    = (rv64_rd_addr  == 5'b00000);
  wire rv64_rd_addr_x2    = (rv64_rd_addr  == 5'b00010);
  wire rv64_rs2_x0        = (rv64_rs2      == 5'b00000);
  wire rv64_rs1_x31       = (rv64_rs1      == 5'b11111);
  wire rv64_rd_addr_x31   = (rv64_rd_addr  == 5'b11111);

//*******************inst_type op*************************************************//
  wire rv64_op_I     = opcode_6_5_00 & opcode_4_2_110 & opcode_1_0_11;
  wire rv32_op_imm   = opcode_6_5_00 & opcode_4_2_100 & opcode_1_0_11;
  wire rv64_op_csr   = opcode_6_5_11 & opcode_4_2_100 & opcode_1_0_11;
  wire rv64_op_load  = opcode_6_5_00 & opcode_4_2_000 & opcode_1_0_11; 
  wire rv64_op_lui   = opcode_6_5_01 & opcode_4_2_101 & opcode_1_0_11;
  wire rv32_op_R     = opcode_6_5_01 & opcode_4_2_100 & opcode_1_0_11;
  wire rv64_op_R     = opcode_6_5_01 & opcode_4_2_110 & opcode_1_0_11;
  wire rv64_op_auipc = opcode_6_5_00 & opcode_4_2_101 & opcode_1_0_11;
  wire rv64_op_jal   = opcode_6_5_11 & opcode_4_2_011 & opcode_1_0_11;
  wire rv64_op_jalr  = opcode_6_5_11 & opcode_4_2_001 & opcode_1_0_11;
  wire rv64_op_B     = opcode_6_5_11 & opcode_4_2_000 & opcode_1_0_11;
  wire rv64_op_S     = opcode_6_5_01 & opcode_4_2_000 & opcode_1_0_11;
//*******************inst type*******************************************//
  wire I_type  = rv32_op_imm | rv64_op_load | rv64_op_I;
  wire U_type  = rv64_op_lui | rv64_op_auipc;
  wire R_type  = rv32_op_R   | rv64_op_R;
  wire J_type  = rv64_op_jal | rv64_op_jalr;
  wire B_type  = rv64_op_B;
  wire S_type  = rv64_op_S;
  wire CSR_type= rv64_op_csr;
//*******************imm gen************************************************//
  wire rv64_imm_sel_i = I_type;               
  wire rv64_imm_sel_u = U_type;
  wire rv64_imm_sel_j = J_type;
  wire rv64_imm_sel_b = B_type;
  wire rv64_imm_sel_s = S_type;
  wire [63:0]  rv64_i_imm = {{52{inst_i[31]}},I_imm};
  wire [63:0]  rv64_u_imm = {{32{U_imm[19]}},U_imm,{12{1'b0}}};
  wire [63:0]  rv64_j_imm = {{43{inst_i[31]}},J_imm,1'b0};
  wire [63:0]  rv64_b_imm = {{51{inst_i[31]}},B_imm,1'b0};
  wire [63:0]  rv64_s_imm = {{52{inst_i[31]}},S_imm};
  wire [63:0]  rv64_imm   = ({64{rv64_imm_sel_i}} & rv64_i_imm)
                          | ({64{rv64_imm_sel_u}} & rv64_u_imm)
                          | ({64{rv64_imm_sel_j}} & rv64_j_imm)
                          | ({64{rv64_imm_sel_s}} & rv64_s_imm)
                          | ({64{rv64_imm_sel_b}} & rv64_b_imm);
//**********************inst************************************************//
  //I
  wire rv64_inst_addiw = rv64_op_I    && rv64_func3_000;
  wire rv64_inst_addi  = rv32_op_imm  && rv64_func3_000;
  wire rv64_inst_ori   = rv32_op_imm  && rv64_func3_110;
  wire rv64_inst_andi  = rv32_op_imm  && rv64_func3_111;
  wire rv64_inst_xori  = rv32_op_imm  && rv64_func3_100;
  wire rv64_inst_slli  = rv32_op_imm  && rv64_func3_001;
  wire rv64_inst_srli  = rv32_op_imm  && rv64_func3_101;
  wire rv64_inst_srai  = rv32_op_imm  && rv64_func3_101 && I_imm[10];
  wire rv64_inst_slti  = rv32_op_imm  && rv64_func3_010;
  wire rv64_inst_sltiu = rv32_op_imm  && rv64_func3_011;
  wire rv64_inst_sraiw = rv64_op_I    && rv64_func3_101 && rv64_func7_0100000;
  wire rv64_inst_srliw = rv64_op_I    && rv64_func3_101 && rv64_func7_0000000;
  wire rv64_inst_slliw = rv64_op_I    && rv64_func3_001 && rv64_func7_0000000;
  //jump
  wire rv64_inst_jalr  = rv64_op_jalr && rv64_func3_000;
  //load
  wire rv64_inst_lb    = rv64_op_load && rv64_func3_000;
  wire rv64_inst_lh    = rv64_op_load && rv64_func3_001;
  wire rv64_inst_lw    = rv64_op_load && rv64_func3_010;
  wire rv64_inst_lwu   = rv64_op_load && rv64_func3_110;
  wire rv64_inst_lbu   = rv64_op_load && rv64_func3_100;
  wire rv64_inst_lhu   = rv64_op_load && rv64_func3_101;
  wire rv64_inst_ld    = rv64_op_load && rv64_func3_011;
  //U
  wire rv64_inst_lui   = rv64_op_lui;
  wire rv64_inst_auipc = rv64_op_auipc;

  //J
  wire rv64_inst_jal   = rv64_op_jal;  

  //B
  wire rv64_inst_beq   = rv64_op_B && rv64_func3_000;
  wire rv64_inst_bne   = rv64_op_B && rv64_func3_001;
  wire rv64_inst_blt   = rv64_op_B && rv64_func3_100;
  wire rv64_inst_bge   = rv64_op_B && rv64_func3_101;
  wire rv64_inst_bltu  = rv64_op_B && rv64_func3_110;
  wire rv64_inst_bgeu  = rv64_op_B && rv64_func3_111;
    //branch is condition
  wire beq_cond;
  wire bne_cond;
  wire blt_cond;
  wire bge_cond;
  wire bltu_cond;
  wire bgeu_cond;

  //R
  wire rv64_inst_add   = rv32_op_R && rv64_func3_000 && rv64_func7_0000000;
  wire rv64_inst_sub   = rv32_op_R && rv64_func3_000 && rv64_func7_0100000;
  wire rv64_inst_and   = rv32_op_R && rv64_func3_111 && rv64_func7_0000000;
  wire rv64_inst_xor   = rv32_op_R && rv64_func3_100 && rv64_func7_0000000;
  wire rv64_inst_or    = rv32_op_R && rv64_func3_110 && rv64_func7_0000000;
  wire rv64_inst_sll   = rv32_op_R && rv64_func3_001 && rv64_func7_0000000;
  wire rv64_inst_srl   = rv32_op_R && rv64_func3_101 && rv64_func7_0000000;
  wire rv64_inst_srlw  = rv64_op_R && rv64_func3_101 && rv64_func7_0000000;
  wire rv64_inst_sra   = rv32_op_R && rv64_func3_101 && rv64_func7_0100000;
  wire rv64_inst_slt   = rv32_op_R && rv64_func3_010 && rv64_func7_0000000;
  wire rv64_inst_sltu  = rv32_op_R && rv64_func3_011 && rv64_func7_0000000;
  wire rv64_inst_sllw  = rv64_op_R && rv64_func3_001 && rv64_func7_0000000;
  wire rv64_inst_sraw  = rv64_op_R && rv64_func3_101 && rv64_func7_0100000;
  wire rv64_inst_addw  = rv64_op_R && rv64_func3_000 && rv64_func7_0000000;
  wire rv64_inst_subw  = rv64_op_R && rv64_func3_000 && rv64_func7_0100000;
    //rv64-m
  wire rv64_inst_div   = rv32_op_R && rv64_func3_100 && rv64_func7_0000001;
  wire rv64_inst_divu  = rv32_op_R && rv64_func3_101 && rv64_func7_0000001;
  wire rv64_inst_rem   = rv32_op_R && rv64_func3_110 && rv64_func7_0000001;
  wire rv64_inst_remu  = rv32_op_R && rv64_func3_111 && rv64_func7_0000001;
  //S
  wire rv64_inst_sb  = rv64_op_S && rv64_func3_000;
  wire rv64_inst_sh  = rv64_op_S && rv64_func3_001;
  wire rv64_inst_sw  = rv64_op_S && rv64_func3_010;
  wire rv64_inst_sd  = rv64_op_S && rv64_func3_011;
//**********************control enable**************************************//
  wire rv64_rd_en           = I_type | U_type | R_type | J_type;
  wire rv64_rs1_en          = I_type | R_type | B_type | S_type;
  wire rv64_rs2_en          = R_type | B_type | S_type;
  wire rs2_is_imm           = I_type | U_type | S_type;
  wire rs1_is_pc            = J_type | rv64_inst_auipc;
  assign id_rs1 = load_forward_rs1_en ? load_data_i:
                  (if_rs1_foward_type_i == 2'b11) ? mem_data_comb_i : 
                  (if_rs1_foward_type_i == 2'b01) ? ex_data_comb_i  : 
                  (if_rs1_foward_type_i == 2'b10) ? wb_data_i       :
                                                    rs1_data_i      ;

  assign id_rs2 = load_forward_rs2_en ? load_data_i :
                  (if_rs2_foward_type_i == 2'b11) ? mem_data_comb_i : 
                  (if_rs2_foward_type_i == 2'b01) ? ex_data_comb_i  : 
                  (if_rs2_foward_type_i == 2'b10) ? wb_data_i       :
                                                    rs2_data_i  ;             
  assign flush_and_pc_redir_en =  rv64_inst_jalr ? 'd1 : (branch_check != predict_is_yes_i) ? 'd1: 'd0;
  assign branch_check_type     =  rv64_inst_jalr ? 2'b10 : (
                                  ({2{(predict_is_yes_i & (!branch_check))}} & 2'b01)  //pc+4
                                | ({2{((!predict_is_yes_i) & (branch_check))}} & 2'b11));// pc+imm
  assign mem_mask_o = ({8{(rv64_inst_sb | rv64_inst_lb | rv64_inst_lbu)}}                   & 8'b0000_0001 )
                    | ({8{(rv64_inst_sh | rv64_inst_lh | rv64_inst_lhu)}}                   & 8'b0000_0011 )
                    | ({8{(rv64_inst_sw | rv64_inst_lw | rv64_inst_lwu)}}                   & 8'b0000_1111 )
                    | ({8{(rv64_inst_sd | rv64_inst_ld )}}                                  & 8'b1111_1111 );
  assign mem_load_is_signed_o = !(rv64_inst_lbu | rv64_inst_lhu | rv64_inst_lwu);

  assign rs1_r_en_o   = rv64_rs1_en ;
  assign rs2_r_en_o   = rv64_rs2_en;
  assign rs1_addr_o    = rv64_rs1&{5{rv64_rs1_en| | rv64_inst_jalr}};
  assign rs2_addr_o    = rv64_rs2&{5{rv64_rs2_en}};
//***********************branch inst*************************************************//
  assign beq_cond = (id_rs1 == id_rs2) && rv64_inst_beq;
  assign bne_cond = (id_rs1 != id_rs2) && rv64_inst_bne;
  assign blt_cond = ($signed(id_rs1) < $signed(id_rs2)) && rv64_inst_blt;
  assign bge_cond = ($signed(id_rs1) >= $signed(id_rs2)) && rv64_inst_bge;
  assign bltu_cond = (id_rs1 < id_rs2) && rv64_inst_bltu;
  assign bgeu_cond = (id_rs1 >= id_rs2) && rv64_inst_bgeu;
  assign branch_check = beq_cond | bne_cond | blt_cond | bge_cond | bltu_cond | bgeu_cond ;
//**********************aluop & alusel***********************************************//
  assign alusel_o =   ({3{(rv64_inst_ori |rv64_inst_xori |rv64_inst_andi|rv64_inst_lui |rv64_inst_and|rv64_inst_xor|rv64_inst_or)}} & `EXE_RES_LOGIC)
                    | ({3{(rv64_inst_sll |rv64_inst_slli |rv64_inst_srl |rv64_inst_srlw| rv64_inst_srliw|rv64_inst_srli|rv64_inst_sra|rv64_inst_srai| rv64_inst_sraiw | rv64_inst_sllw | rv64_inst_sraw | rv64_inst_slliw)}} & `EXE_RES_SHIFT)
                    | ({3{(rv64_inst_sltiu|rv64_inst_sltu|rv64_inst_slti | rv64_inst_slt )}} & `EXE_RES_COMPARE)
                    | ({3{(rv64_inst_subw)}} & `EXE_RES_SUBW)
                    | ({3{(rv64_inst_ld|rv64_inst_lwu|rv64_inst_sd|rv64_inst_sw|rv64_inst_sh|rv64_inst_sb|rv64_inst_auipc|rv64_inst_addw|rv64_inst_lw|rv64_inst_addiw|rv64_inst_addi|rv64_inst_add  |rv64_inst_sub |rv64_inst_slti|rv64_inst_sltiu|rv64_inst_slt|rv64_inst_sltu|rv64_op_load|rv64_inst_jal | rv64_inst_jalr)}} & `EXE_RES_ARITHMETIC);

  assign aluop_o  =   ({8{(rv64_inst_ori  |rv64_inst_lui|rv64_inst_or)}}                   & `EXE_OR_OP    )
                    | ({8{(rv64_inst_xori |rv64_inst_xor )}}                               & `EXE_XORI_OP  )
                    | ({8{(rv64_inst_andi |rv64_inst_and )}}                               & `EXE_ANDI_OP  )
                    | ({8{(rv64_inst_sll  |rv64_inst_slli)}}                               & `EXE_SLL_OP   )
                    | ({8{(rv64_inst_srl  |rv64_inst_srli)}}                               & `EXE_SRL_OP   )
                    | ({8{(rv64_inst_addi |rv64_inst_add |rv64_op_load|rv64_inst_sb|rv64_inst_sh|rv64_inst_sw|rv64_inst_sd| rv64_inst_ld
                          |rv64_inst_lwu  |rv64_inst_jal | rv64_inst_auipc | rv64_inst_jalr|rv64_inst_lw)}}  & `EXE_ADD_OP   )
                    | ({8{(rv64_inst_sub )}}                                               & `EXE_SUB_OP   )
                    | ({8{(rv64_inst_sra  |rv64_inst_srai)}}                               & `EXE_SRA_OP   )
                    | ({8{(rv64_inst_slti |rv64_inst_slt )}}                               & `EXE_SLTA_OP  )
                    | ({8{(rv64_inst_sltiu|rv64_inst_sltu)}}                               & `EXE_SLTU_OP  )
                    | ({8{(rv64_inst_srlw | rv64_inst_srliw)}}                             & `EXE_SRUW_OP  )
                    | ({8{(rv64_inst_subw)}}                                               & `EXE_SUBW_OP  )
                    | ({8{(rv64_inst_div)}}                                                & `EXE_DIV_OP   )
                    | ({8{(rv64_inst_divu)}}                                               & `EXE_DIVU_OP  )
                    | ({8{(rv64_inst_rem)}}                                                & `EXE_REM_OP   )
                    | ({8{(rv64_inst_remu)}}                                               & `EXE_REMU_OP  )
                    | ({8{rv64_inst_addiw | rv64_inst_addw}}                               & `EXE_ADDW_OP  )
                    | ({8{rv64_inst_sllw  | rv64_inst_slliw}}                              & `EXE_SLLW_OP  )
                    | ({8{rv64_inst_sraiw | rv64_inst_sraw }}                              & `EXE_SRAW_OP  );

  assign pc_addr_o = pc_i;  
  assign pc_redir = ((pc_i + 64'd4)    &{64{(branch_check_type == 2'b01)}})
                  | (((id_rs1+rv64_i_imm)&(64'hffff_ffff_ffff_fffe)) &{64{(branch_check_type == 2'b10)}})
                  | ((pc_i+ rv64_b_imm)&{64{(branch_check_type == 2'b11)}}) ;
//**********************mem ctrl****************************************************************************//
  assign mem_r_en_o = rv64_inst_lb | rv64_inst_lbu | rv64_inst_lh | rv64_inst_lhu | rv64_inst_lw | rv64_inst_lwu | rv64_inst_ld;
  assign mem_w_en_o = rv64_inst_sb | rv64_inst_sh  | rv64_inst_sw | rv64_inst_sd;
  assign mem_wr_data_o = rv64_inst_sb ? {56'd0,id_rs2[7:0]} : 
                         rv64_inst_sh ? {48'd0,id_rs2[15:0]}:
                         rv64_inst_sw ? {32'd0,id_rs2[31:0]}: 
                         rv64_inst_sd ? id_rs2:'d0;

//**********************write****************************************************************************//                    
  assign wb_en_o    =  rv64_rd_en; 
  assign wb_addr_o  =  {5{rv64_rd_en}}&rv64_rd_addr;
  assign rs1_data_o = rv64_rs1_en ? id_rs1 : 
                      rs1_is_pc   ? pc_i   :
                                 `ZERO_WORD;
  assign rs2_data_o = rs2_is_imm  ? rv64_imm : 
                      rv64_rs2_en ? id_rs2   : 
                      (rv64_op_jal|rv64_inst_jalr) ?  'd4     :
                       `ZERO_WORD;
  assign difftest_pc_o = pc_i; 
                        
endmodule