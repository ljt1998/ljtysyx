`include "defines.v"
module id_pipline(
    input wire clk,
    input wire rst,

    input wire [31:0] inst_i,
    input wire [`AluOpBus]   aluop_i,//运算子类型
    input wire [`AluSelBus]  alusel_i,//运算类型
    input wire [63:0]        rs1_data_i,
    input wire [63:0]        rs2_data_i,
    input wire [63:0]        pc_addr_i,
    input wire [4:0]         wb_addr_i, 
    input wire               wb_en_i,
    input wire               hazard_flush_i,
    // lsu-mem-ctrl
    input wire               mem_r_en_i,
    input wire               mem_w_en_i,
    input wire               mem_is_signed_i,
    input wire [7:0]         mem_mask_i,
    input wire [63:0]        mem_wr_data_i,
    input wire [4:0]         rs1_addr_id_i,
    input wire [4:0]         rs2_addr_id_i,
    input wire [63:0]        difftest_pc_i,
    input wire               difftest_flush_i,
    output reg               mem_is_signed_o,
    output reg               difftest_flush_o,
    output reg [31:0]        inst_o,
    output reg [63:0]        difftest_pc_o,
    output reg [4:0]         rs1_addr_id_o,
    output reg [4:0]         rs2_addr_id_o,
    output reg [`AluOpBus]   aluop_o,//运算子类型
    output reg [`AluSelBus]  alusel_o,//运算类型
    output reg [63:0]        rs1_data_pipline_o,
    output reg [63:0]        rs2_data_pipline_o,
    output reg [63:0]        pc_addr_o,
    output reg [4:0]         wb_addr_o, 
    output reg               wb_en_o,
    // lsu-mem-ctrl
 //   output reg               harzard_flush_o,
    output reg               mem_r_en_o,
    output reg               mem_w_en_o,
    output reg [7:0]         mem_mask_o,
    output reg [63:0]        mem_wr_data_o
    
);
//`DFFENR(clk, rst, 1'b1, aluop_i, aluop_o, 'd0)
//`DFFENR(clk, rst, 1'b1, alusel_i, alusel_o, 'd0)
//`DFFENR(clk, rst, 1'b1, rs1_data_i, rs1_data_pipline_o, 'd0)
//`DFFENR(clk, rst, 1'b1, rs2_data_i, rs2_data_pipline_o, 'd0)
//`DFFENR(clk, rst, 1'b1, pc_addr_i, pc_addr_o, 'd0)
//`DFFENR(clk, rst, 1'b1, wb_addr_i, wb_addr_o, 'd0)
//`DFFENR(clk, rst, 1'b1, wb_en_i, wb_en_o, 'd0)
//`DFFENR(clk, rst, 1'b1, mem_r_en_i, mem_r_en_o, 'd0)
//`DFFENR(clk, rst, 1'b1, mem_w_en_i, mem_w_en_o, 'd0)
//`DFFENR(clk, rst, 1'b1, mem_mask_i, mem_mask_o, 'd0)
//`DFFENR(clk, rst, 1'b1, mem_wr_data_i, mem_wr_data_o, 'd0)
//
//`DFFENR(clk, rst, 1'b1, rs1_addr_id_i, rs1_addr_id_o, 'd0)
//`DFFENR(clk, rst, 1'b1, rs2_addr_id_i, rs2_addr_id_o, 'd0)
//
//`DFFENR(clk, rst, 1'b1, inst_i, inst_o, 'd0)
//`DFFENR(clk, rst, 1'b1, difftest_pc_i, difftest_pc_o, 'd0)
//`DFFENR(clk, rst, 1'b1, difftest_flush_i, difftest_flush_o, 'd0)

wire [`AluOpBus] aluop_new_i;
`DFFENR(clk, rst, 1'b1, aluop_new_i, aluop_o, 'd0)
assign aluop_new_i = hazard_flush_i ? 'd0 : aluop_i;

wire [`AluSelBus] alusel_new_i;
`DFFENR(clk, rst, 1'b1, alusel_new_i, alusel_o, 'd0)
assign alusel_new_i = hazard_flush_i ? 'd0 : alusel_i;

wire [63:0] rs1_data_new_i;
`DFFENR(clk, rst, 1'b1, rs1_data_new_i, rs1_data_pipline_o, 'd0)
assign rs1_data_new_i = hazard_flush_i ? 'd0 : rs1_data_i;

wire [63:0] rs2_data_new_i;
`DFFENR(clk, rst, 1'b1, rs2_data_new_i, rs2_data_pipline_o, 'd0)
assign rs2_data_new_i = hazard_flush_i ? 'd0 : rs2_data_i;

wire [63:0] pc_addr_new_i;
`DFFENR(clk, rst, 1'b1, pc_addr_new_i, pc_addr_o, 'd0)
assign pc_addr_new_i = hazard_flush_i ? 'd0 : pc_addr_i;

wire [4:0] wb_addr_new_i;
`DFFENR(clk, rst, 1'b1, wb_addr_new_i, wb_addr_o, 'd0)
assign wb_addr_new_i = hazard_flush_i ? 'd0 : wb_addr_i;

wire wb_en_new_i;
`DFFENR(clk, rst, 1'b1, wb_en_new_i, wb_en_o, 'd0)
assign wb_en_new_i = hazard_flush_i ? 'd0 : wb_en_i;

wire mem_is_signed_new_i;
`DFFENR(clk, rst, 1'b1, mem_is_signed_new_i, mem_is_signed_o, 'd0)
assign mem_is_signed_new_i = hazard_flush_i ? 'd0 : mem_is_signed_i;

wire mem_r_en_new_i;
`DFFENR(clk, rst, 1'b1, mem_r_en_new_i, mem_r_en_o, 'd0)
assign mem_r_en_new_i = hazard_flush_i ? 'd0 : mem_r_en_i;

wire mem_w_en_new_i;
`DFFENR(clk, rst, 1'b1, mem_w_en_new_i, mem_w_en_o, 'd0)
assign mem_w_en_new_i = hazard_flush_i ? 'd0 : mem_w_en_i;

wire [7:0] mem_mask_new_i;
`DFFENR(clk, rst, 1'b1, mem_mask_new_i, mem_mask_o, 'd0)
assign mem_mask_new_i = hazard_flush_i ? 'd0 : mem_mask_i;

wire[63:0] mem_wr_data_new_i;
`DFFENR(clk, rst, 1'b1, mem_wr_data_new_i, mem_wr_data_o, 'd0)
assign mem_wr_data_new_i = hazard_flush_i ? 'd0 : mem_wr_data_i;

wire [4:0] rs1_addr_id_new_i;
`DFFENR(clk, rst, 1'b1, rs1_addr_id_new_i, rs1_addr_id_o, 'd0)
assign rs1_addr_id_new_i = hazard_flush_i ? 'd0 : rs1_addr_id_i;

wire [4:0] rs2_addr_id_new_i;
`DFFENR(clk, rst, 1'b1, rs2_addr_id_new_i, rs2_addr_id_o, 'd0)
assign rs2_addr_id_new_i = hazard_flush_i ? 'd0 : rs2_addr_id_i;

wire [31:0] inst_new_i;
`DFFENR(clk, rst, 1'b1, inst_new_i, inst_o, 'd0)
assign inst_new_i = hazard_flush_i ? 'd0 : inst_i;

wire[63:0] difftest_pc_new_i;
`DFFENR(clk, rst, 1'b1, difftest_pc_new_i, difftest_pc_o, 'd0)
assign difftest_pc_new_i = hazard_flush_i ? 'd0 : difftest_pc_i;

wire  difftest_flush_new_i;
`DFFENR(clk, rst, 1'b1, difftest_flush_new_i, difftest_flush_o, 'd0)
assign difftest_flush_new_i = hazard_flush_i ? 'd1 : difftest_flush_i;


endmodule
