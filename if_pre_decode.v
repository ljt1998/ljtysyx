`include "defines.v"
module if_pre_decode(
    input wire [`PcAddrBus]   pc_i,
    input wire [`InstBus]     inst_i,
    output wire predict_is_yes,
    output wire [`PcAddrBus]  pre_pc_o
);
    wire is_bxx    = (inst_i[6:0] == `OPCODE_BRANCH);   //条件跳转指令的操作码
    wire is_jal    = (inst_i[6:0] == `OPCODE_JAL   );   //无条件跳转指令的操作码
    wire is_jalr   = (inst_i[6:0] == `OPCODE_JALR  ) && (inst_i[14:12] == 3'b000);
    //B
    wire [11:0] B_imm       = {inst_i[31],inst_i[7],inst_i[30:25],inst_i[11:8]  };
     wire [63:0]  rv64_b_imm = {{51{inst_i[31]}},B_imm,1'b0};
    //J
    wire [63:0] j_imm   = {{44{inst_i[31]}}, inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0};
    wire [63:0] branch_target =  
                                 is_jal                      ? j_imm :
                                (is_bxx & rv64_b_imm[63])    ? rv64_b_imm : 'd4;
   assign predict_is_yes = (is_bxx & rv64_b_imm[63]) || (is_jalr);
    assign pre_pc_o  =  pc_i + branch_target;
endmodule