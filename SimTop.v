
//--xuezhen--

`include "defines.v"

module SimTop(
    input         clock,
    input         reset,

    input  [63:0] io_logCtrl_log_begin,
    input  [63:0] io_logCtrl_log_end,
    input  [63:0] io_logCtrl_log_level,
    input         io_perfInfo_clean,
    input         io_perfInfo_dump,

    output        io_uart_out_valid,
    output [7:0]  io_uart_out_ch,
    output        io_uart_in_valid,
    input  [7:0]  io_uart_in_ch
);

// if_stage
wire [63 : 0] pc;
wire [31 : 0] inst;
wire pc_redir_en;
wire [63 : 0] pc_redir;
wire [63:0] if_pipline_pc;
wire [31:0] if_pipline_inst;
wire [63:0] pre_pc;
wire predict_is_yes;
wire predict_is_yes_o;
wire flush_and_pc_redir_en;
// id_stage
wire [4:0] rs1_addr_id,rs2_addr_id; 
wire [`AluOpBus]   aluop_decode;
wire [`AluSelBus]  alusel_decode;
wire rs1_r_en_o,rs2_r_en_o;
wire [63:0] rs1_data_o;
wire [63:0] rs2_data_o;
wire [63:0] pc_addr_o;
wire [4:0] wb_addr_o;
wire wb_en_o;
wire mem_r_en_o,mem_w_en_o;
wire [7:0] mem_mask_o;
wire [63:0] mem_wr_data_o,difftest_pc_o,difftest_pc_id;
wire [31:0] inst_id_o,inst_ex_o,inst_mem_o;

// id_stage -> regfile
wire rs1_r_ena;
wire [4 : 0]rs1_r_addr;
wire rs2_r_ena;
wire [4 : 0]rs2_r_addr;
wire rd_w_ena;
wire [4 : 0]rd_w_addr;
// id_stage -> exe_stage
wire [4 : 0]inst_type;
wire [7 : 0]inst_opcode;
wire [`REG_BUS]op1;
wire [`REG_BUS]op2;

// regfile -> id_stage
wire [`REG_BUS] r_data1;
wire [`REG_BUS] r_data2;
// regfile -> difftest
wire [`REG_BUS] regs[0 : 31];
// id-stage 
//wire [4:0] rs1_addr_id,rs2_addr_id;
wire [63:0] pc_addr_id,pc_addr_id_i;
wire [63:0] rs1_data_i,rs2_data_i,pc_addr_i;
wire wb_en_i;
wire [4:0] wb_addr_i;
wire mem_r_en_i,mem_w_en_i;
wire [7:0] mem_mask_i;
wire [63:0] mem_wr_data_i;
wire [`AluOpBus] aluop_id,aluop_i;
wire [`AluSelBus]  alusel_id,alusel_i;
wire [4:0] rs1_addr_id_i,rs2_addr_id_i;
wire stall;
// exe_stage
wire [4:0] wb_addr_exe,wb_addr_alu;
wire       wb_en_exe,wb_en_alu;
wire [63:0] wb_data_alu;
wire [7:0]  mem_mask_alu;
wire [63:0] mem_wr_data_alu;
wire mem_r_en_alu,mem_w_en_alu;
wire [63:0] rs1_data_alu;
wire [63:0] rs2_data_alu;
// exe_stage -> other stage
wire [4 : 0]inst_type_o;
// fowarding net
wire [1:0] alu_rs1_foward_type,if_rs1_foward_type;
wire [1:0] alu_rs2_foward_type,if_rs2_foward_type;
wire [63:0] pc_o_ex;
wire [63:0] pc_o_mem;
// exe_stage -> regfile
wire [`REG_BUS]rd_data;
// mem_stage 
wire mem_rd_en;
wire mem_wr_en;
wire [63:0] mem_addr;
wire [63:0] mem_wr_data,mem_rd_data;
wire [7:0] mem_byte_enble;

// mem_pipline -> wbu
wire [63:0] mem_load_data;
wire [63:0] wb_regfile_data;
wire [4:0]  wb_addr;
wire        wb_w_en;
wire        inst_is_load_mem;
// wbu -> regfile
wire [63:0]   wb_data_result;

pc_stage u_pc_stage(
//input
  .clk                (clock),
  .rst                (reset),
  .stall              (stall),
  .pc_redir_en        (flush_and_pc_redir_en),
  .pre_pc             (pre_pc),
  .pc_redir           (pc_redir),
//output
  .pc                 (pc),
  .inst               (inst)
);
if_pre_decode u_if_pre_decode(
  //input
  .pc_i               (pc),
  .inst_i             (inst),
  //output
  .predict_is_yes     (predict_is_yes),
  .pre_pc_o           (pre_pc)
);
wire difftest_flush_o;
if_pipline  u_if_pipline (
    .clk              ( clock  ),
    .rst              ( reset  ),
    .flush            (flush_and_pc_redir_en),
    .stall            (stall),
    .pc_i             ( pc     ),
    .inst_i           ( inst   ),
    .predict_is_yes_i (predict_is_yes),

    .difftest_flush_o (difftest_flush_o),
    .predict_is_yes_o (predict_is_yes_o),
    .pc_o             ( if_pipline_pc    ),
    .inst_o           ( if_pipline_inst  )
);
wire mem_load_is_signed_id_comb;
decode  u_decode (
    .pc_i                    ( if_pipline_pc           ),
    .inst_i                  ( if_pipline_inst         ),
    .load_data_i             ( mem_rd_data),
    .load_forward_rs1_en     ( id_foward_rs1_en),
    .load_forward_rs2_en     ( id_foward_rs2_en),
    .wb_data_i               ( wb_data_result          ),
    .predict_is_yes_i        ( predict_is_yes_o        ),
    .rs1_data_i              ( rs1_data_i              ),
    .rs2_data_i              ( rs2_data_i              ),
    .ex_data_comb_i          ( wb_data_alu                ),
    .mem_data_comb_i         ( mem_addr          ),
    .if_rs1_foward_type_i    ( if_rs1_foward_type      ),
    .if_rs2_foward_type_i    ( if_rs2_foward_type      ),
    .flush_and_pc_redir_en   ( flush_and_pc_redir_en   ),
    .pc_redir                ( pc_redir                ),
    .aluop_o                 ( aluop_i                 ),
    .alusel_o                ( alusel_i                ),
    // regfile
    .rs1_addr_o              ( rs1_addr_id_i           ),
    .rs2_addr_o              ( rs2_addr_id_i           ),
    .rs1_r_en_o              ( rs1_r_en_o              ),
    .rs2_r_en_o              ( rs2_r_en_o              ),
    // next stage
    .rs1_data_o              ( rs1_data_o              ),
    .rs2_data_o              ( rs2_data_o              ),
    .pc_addr_o               ( pc_addr_o               ),
    .wb_addr_o               ( wb_addr_o               ),
    .wb_en_o                 ( wb_en_o                 ),
    .difftest_pc_o           ( difftest_pc_o           ),
    .mem_r_en_o              ( mem_r_en_o              ),
    .mem_w_en_o              ( mem_w_en_o              ),
    .mem_mask_o              ( mem_mask_o              ),
    .mem_load_is_signed_o    ( mem_load_is_signed_id_comb),
    .mem_wr_data_o           ( mem_wr_data_o           )
);

hazard  u_hazard (
    .id_inst_is_load_i       ( mem_r_en_alu        ),
    .id_rd_addr_i            ( wb_addr_alu         ),
    .if_rs1_addr_i           ( rs1_addr_id_i       ),
    .if_rs2_addr_i           ( rs2_addr_id_i       ),

    .stall                   ( stall               )
);
wire difftest_flush_id_o;
wire mem_is_signed_id_o;
id_pipline  u_id_pipline (
    .clk                     ( clock           ),
    .rst                     ( reset           ),
    .mem_is_signed_i         (mem_load_is_signed_id_comb),
    .difftest_pc_i            (difftest_pc_o   ), 
    .inst_i                  ( if_pipline_inst ),
    .aluop_i                 ( aluop_i         ),
    .alusel_i                ( alusel_i        ),
    .hazard_flush_i          ( stall           ),
    .rs1_data_i              ( rs1_data_o      ),
    .rs2_data_i              ( rs2_data_o      ),
    .pc_addr_i               ( if_pipline_pc       ),
    .wb_addr_i               ( wb_addr_o       ),
    .wb_en_i                 ( wb_en_o         ),
    .mem_r_en_i              ( mem_r_en_o      ),
    .mem_w_en_i              ( mem_w_en_o      ),
    .mem_mask_i              ( mem_mask_o      ),
    .mem_wr_data_i           ( mem_wr_data_o   ),
    .rs1_addr_id_i           ( rs1_addr_id_i),
    .rs2_addr_id_i           ( rs2_addr_id_i),
    .difftest_flush_i        ( difftest_flush_o || stall),
    .difftest_pc_o           ( difftest_pc_id    ),
    .difftest_flush_o        ( difftest_flush_id_o),
    .inst_o                  ( inst_id_o),
    .aluop_o                 ( aluop_id),
    .alusel_o                ( alusel_id),
    .rs1_addr_id_o           ( rs1_addr_id),//load_forward
    .rs2_addr_id_o           ( rs2_addr_id),//load_forward
    .rs1_data_pipline_o      ( rs1_data_alu      ),
    .rs2_data_pipline_o      ( rs2_data_alu      ),
    .pc_addr_o               ( pc_addr_id      ),
    .wb_addr_o               ( wb_addr_alu       ),
    .wb_en_o                 ( wb_en_alu         ),
    .mem_r_en_o              ( mem_r_en_alu      ),
    .mem_w_en_o              ( mem_w_en_alu      ),
    .mem_mask_o              ( mem_mask_alu      ),
    .mem_is_signed_o         ( mem_is_signed_id_o),
    .mem_wr_data_o           ( mem_wr_data_alu   )
);
alu  u_alu (
    .rs1_data_i              ( rs1_data_alu          ),
    .rs2_data_i              ( rs2_data_alu          ),
    .aluop_i                 (aluop_id),
    .alusel_i                (alusel_id),
    .forward_load_rs1_en     (load_forward_rs1_en),
    .forward_load_rs2_en     (load_forward_rs2_en),
    .forward_load_data_i     (mem_load_data),

    .wb_data_o               ( wb_data_alu           )
);
wire load_forward_rs1_en,load_forward_rs2_en;
wire id_foward_rs1_en,id_foward_rs2_en;
fowarding  u_fowarding (
    .if_rs1_addr_i           ( rs1_addr_id_i     ),
    .if_rs2_addr_i           ( rs2_addr_id_i    ),
    .id_rs1_addr_i           ( rs1_addr_id     ),
    .id_rs2_addr_i           ( rs2_addr_id    ),
    .wb_rd_addr_i            ( wb_addr     ),//load_forward
    .wb_rd_en_i              ( wb_w_en     ),//load_forward
    .wb_inst_is_load_i       ( inst_is_load_mem),
    .ex_rd_addr_i            ( wb_addr_alu      ),
    .ex_rd_en_i              ( wb_en_alu        ),
    .ex_inst_is_load_i       ( mem_rd_en),
    .id_foward_rs1_en        ( id_foward_rs1_en),
    .id_foward_rs2_en        ( id_foward_rs2_en),

    .mem_rd_addr_i           ( wb_addr_exe    ),
    .mem_rd_en_i             ( wb_en_exe       ),

    .if_rs1_foward_type         ( if_rs1_foward_type   ),
    .if_rs2_foward_type         ( if_rs2_foward_type   ),
    .load_forward_rs1_en     ( load_forward_rs1_en   ),
    .load_forward_rs2_en     ( load_forward_rs2_en   )
);
wire difftest_flush_ex_o;
wire mem_is_signed_ex_o;
ex_pipline  u_ex_pipline (
    .clk                     ( clock             ),
    .rst                     ( reset             ),
    .inst_i                  ( inst_id_o         ),
    .pc_i                    ( difftest_pc_id        ),
    .wb_data_i               ( wb_data_alu       ),
    .wb_addr_i               ( wb_addr_alu       ),
    .wb_en_i                 ( wb_en_alu         ),
    .mem_is_signed_i         ( mem_is_signed_id_o),
    .mem_r_en_i              ( mem_r_en_alu      ),
    .mem_w_en_i              ( mem_w_en_alu    ),
    .mem_mask_i              ( mem_mask_alu      ),
    .mem_wr_data_i           ( mem_wr_data_alu   ),
    .difftest_flush_i        ( difftest_flush_id_o),
    .difftest_flush_o        ( difftest_flush_ex_o),
    .inst_o                  ( inst_ex_o         ),
    .pc_o                    ( pc_o_ex           ),
    .wb_data_o               ( mem_addr       ),
    .wb_addr_o               ( wb_addr_exe     ),
    .wb_en_o                 ( wb_en_exe         ),
    .mem_is_signed_o         ( mem_is_signed_ex_o),
    .mem_r_en_o              ( mem_rd_en      ),
    .mem_w_en_o              ( mem_wr_en      ),
    .mem_mask_o              ( mem_byte_enble  ),
    .mem_wr_data_o           ( mem_wr_data     )
);
mem_ctrl  u_mem_ctrl (
    .rst                     ( reset                   ),
    .clk                     ( clock                   ),
    .mem_load_is_signed      ( mem_is_signed_ex_o),
    .mem_byte_enble          ( mem_byte_enble        ),
    .mem_addr                ( mem_addr              ),
    .mem_rd_en               ( mem_rd_en             ),
    .mem_wr_en               ( mem_wr_en             ),
    .mem_wr_data             ( mem_wr_data           ),
    .mem_rd_data             ( mem_rd_data           )
);
wire difftest_flush_mem_o;
mem_pipline  u_mem_pipline (
    .clk                     ( clock               ),
    .rst                     ( reset               ),
    .mem_load_data_i         ( mem_rd_data   ),
    .wb_data_i               ( mem_addr         ),
    .wb_addr_i               ( wb_addr_exe         ),
    .wb_en_i                 ( wb_en_exe           ),
    .inst_is_load_i          ( mem_rd_en    ),
    .inst_i                  ( inst_ex_o    ),
    .pc_i                    ( pc_o_ex),
    .difftest_flush_i        (difftest_flush_ex_o),
    .difftest_flush_o        (difftest_flush_mem_o),
    .pc_o                    ( pc_o_mem),
    .inst_o                  ( inst_mem_o   ),
    .mem_load_data_o         ( mem_load_data   ),
    .wb_data_o               ( wb_regfile_data   ),
    .wb_addr_o               ( wb_addr         ),
    .wb_en_o                 ( wb_w_en           ),
    .inst_is_load_o          ( inst_is_load_mem   )
);

wbu  u_wbu (
    .mem_load_data_i         ( mem_load_data     ),
    .wb_data_i               ( wb_regfile_data   ),
    .wb_en_i                 ( wb_w_en           ),
    .inst_is_load_i          ( inst_is_load_mem  ),

    .wb_data_result          ( wb_data_result    )
);
regfile Regfile(
  .clk                (clock),
  .rst                (reset),
  .w_addr             (wb_addr),
  .w_data             (wb_data_result),
  .w_ena              (wb_w_en),
  
  .r_addr1            (rs1_addr_id_i),
  .r_data1            (rs1_data_i),
  .r_ena1             (rs1_r_en_o),
  .r_addr2            (rs2_addr_id_i),
  .r_data2            (rs2_data_i),
  .r_ena2             (rs2_r_en_o),
 // .regs               (regs)
  .regs_o             (regs)
);

wire [63:0] cmt_pipline_pc,cmt_pipline_data;
wire cmt_pipline_w_en;
wire [4:0] cmt_pipline_addr;
wire [31:0] cmt_pipline_inst;
cmt_pipline  u_cmt_pipline (
    .clk                     ( clock         ),
    .rst                     ( reset         ),
    .wb_data_i               ( wb_data_result   ),
    .wb_addr_i               ( wb_addr   ),
    .wb_en_i                 ( wb_w_en     ),
    .inst_i                  ( inst_mem_o      ),
    .pc_i                    ( pc_o_mem        ),

    .inst_o                  ( cmt_pipline_inst      ),
    .pc_o                    ( cmt_pipline_pc        ),
    .wb_data_o               ( cmt_pipline_data   ),
    .wb_addr_o               ( cmt_pipline_addr   ),
    .wb_en_o                 ( cmt_pipline_w_en     )
);

// Difftest
reg cmt_wen;
reg [7:0] cmt_wdest;
reg [63:0] cmt_wdata;
reg [63:0] cmt_pc;
reg [31:0] cmt_inst;
reg cmt_valid;
reg trap;
reg [7:0] trap_code;
reg [63:0] cycleCnt;
reg [63:0] instrCnt;
reg [63:0] regs_diff [0 : 31];

wire inst_valid = ((pc_o_mem != `PC_START) | (inst_mem_o != 'd0)) && (difftest_flush_mem_o != 1'b1) ;

always @(negedge clock) begin
  if (reset) begin
    {cmt_wen, cmt_wdest, cmt_wdata, cmt_pc, cmt_inst, cmt_valid, trap, trap_code, cycleCnt, instrCnt} <= 0;
  end
  else if (~trap) begin
    cmt_wen <= wb_w_en;
    cmt_wdest <= {3'd0, wb_addr};
    cmt_wdata <= wb_data_result;
    cmt_pc <= pc_o_mem;
    cmt_inst <= inst_mem_o;
    cmt_valid <= inst_valid ;

		regs_diff <= regs;

    trap <= (inst_mem_o[6:0] == 7'h6b);
    trap_code <= regs[10][7:0];
    cycleCnt <= cycleCnt + 1;
    instrCnt <= instrCnt + {63'd0,inst_valid};
  end
end

DifftestInstrCommit DifftestInstrCommit(
  .clock              (clock),
  .coreid             (0),
  .index              (0),
  .valid              (cmt_valid),
  .pc                 (cmt_pc),
  .instr              (cmt_inst),
  .special            (0),
  .skip               (0),
  .isRVC              (0),
  .scFailed           (0),
  .wen                (cmt_wen),
  .wdest              (cmt_wdest),
  .wdata              (cmt_wdata)
);

DifftestArchIntRegState DifftestArchIntRegState (
  .clock              (clock),
  .coreid             (0),
  .gpr_0              (regs_diff[0]),
  .gpr_1              (regs_diff[1]),
  .gpr_2              (regs_diff[2]),
  .gpr_3              (regs_diff[3]),
  .gpr_4              (regs_diff[4]),
  .gpr_5              (regs_diff[5]),
  .gpr_6              (regs_diff[6]),
  .gpr_7              (regs_diff[7]),
  .gpr_8              (regs_diff[8]),
  .gpr_9              (regs_diff[9]),
  .gpr_10             (regs_diff[10]),
  .gpr_11             (regs_diff[11]),
  .gpr_12             (regs_diff[12]),
  .gpr_13             (regs_diff[13]),
  .gpr_14             (regs_diff[14]),
  .gpr_15             (regs_diff[15]),
  .gpr_16             (regs_diff[16]),
  .gpr_17             (regs_diff[17]),
  .gpr_18             (regs_diff[18]),
  .gpr_19             (regs_diff[19]),
  .gpr_20             (regs_diff[20]),
  .gpr_21             (regs_diff[21]),
  .gpr_22             (regs_diff[22]),
  .gpr_23             (regs_diff[23]),
  .gpr_24             (regs_diff[24]),
  .gpr_25             (regs_diff[25]),
  .gpr_26             (regs_diff[26]),
  .gpr_27             (regs_diff[27]),
  .gpr_28             (regs_diff[28]),
  .gpr_29             (regs_diff[29]),
  .gpr_30             (regs_diff[30]),
  .gpr_31             (regs_diff[31])
);

DifftestTrapEvent DifftestTrapEvent(
  .clock              (clock),
  .coreid             (0),
  .valid              (trap),
  .code               (trap_code),
  .pc                 (cmt_pc),
  .cycleCnt           (cycleCnt),
  .instrCnt           (instrCnt)
);

DifftestCSRState DifftestCSRState(
  .clock              (clock),
  .coreid             (0),
  .priviledgeMode     (`RISCV_PRIV_MODE_M),
  .mstatus            (0),
  .sstatus            (0),
  .mepc               (0),
  .sepc               (0),
  .mtval              (0),
  .stval              (0),
  .mtvec              (0),
  .stvec              (0),
  .mcause             (0),
  .scause             (0),
  .satp               (0),
  .mip                (0),
  .mie                (0),
  .mscratch           (0),
  .sscratch           (0),
  .mideleg            (0),
  .medeleg            (0)
);

DifftestArchFpRegState DifftestArchFpRegState(
  .clock              (clock),
  .coreid             (0),
  .fpr_0              (0),
  .fpr_1              (0),
  .fpr_2              (0),
  .fpr_3              (0),
  .fpr_4              (0),
  .fpr_5              (0),
  .fpr_6              (0),
  .fpr_7              (0),
  .fpr_8              (0),
  .fpr_9              (0),
  .fpr_10             (0),
  .fpr_11             (0),
  .fpr_12             (0),
  .fpr_13             (0),
  .fpr_14             (0),
  .fpr_15             (0),
  .fpr_16             (0),
  .fpr_17             (0),
  .fpr_18             (0),
  .fpr_19             (0),
  .fpr_20             (0),
  .fpr_21             (0),
  .fpr_22             (0),
  .fpr_23             (0),
  .fpr_24             (0),
  .fpr_25             (0),
  .fpr_26             (0),
  .fpr_27             (0),
  .fpr_28             (0),
  .fpr_29             (0),
  .fpr_30             (0),
  .fpr_31             (0)
);

endmodule