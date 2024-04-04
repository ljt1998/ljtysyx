`include "defines.v"
module ex_pipline(
    input wire clk,
    input wire rst,
    input wire [63:0]     wb_data_i,
    input wire [4:0]      wb_addr_i, 
    input wire            wb_en_i,
    input wire [31:0]     inst_i,
    input wire [63:0]     pc_i, 
    input wire            difftest_flush_i, 
    // lsu-mem-ctrl
    input wire            mem_is_signed_i,
    input wire            mem_r_en_i,
    input wire            mem_w_en_i,
    input wire [7:0]      mem_mask_i,
    input wire [63:0]     mem_wr_data_i,
    output reg [31:0]     inst_o,
    output reg [63:0]     pc_o,
    output reg [63:0]     wb_data_o,
    output reg [4:0]      wb_addr_o, 
    output reg            wb_en_o,
    output reg            difftest_flush_o,
    // lsu-mem-ctrl
    output reg            mem_is_signed_o,
    output reg            mem_r_en_o,
    output reg            mem_w_en_o,
    output reg [7:0]      mem_mask_o,
    output reg [63:0]     mem_wr_data_o
    
);
wire [63:0] mem_wr_data_temp_i;
`DFFENR(clk, rst, 1'b1, wb_data_i, wb_data_o, 'd0)
`DFFENR(clk, rst, 1'b1, wb_addr_i, wb_addr_o, 'd0)
`DFFENR(clk, rst, 1'b1, wb_en_i, wb_en_o, 'd0)
`DFFENR(clk, rst, 1'b1, mem_r_en_i, mem_r_en_o, 'd0)
`DFFENR(clk, rst, 1'b1, mem_w_en_i, mem_w_en_o, 'd0)
`DFFENR(clk, rst, 1'b1, mem_mask_i, mem_mask_o, 'd0)
`DFFENR(clk, rst, 1'b1, mem_wr_data_temp_i, mem_wr_data_o, 'd0)
assign mem_wr_data_temp_i = mem_wr_data_i; 
`DFFENR(clk, rst, 1'b1, inst_i, inst_o, 'd0)
`DFFENR(clk, rst, 1'b1, pc_i, pc_o, 'd0)
`DFFENR(clk, rst, 1'b1, difftest_flush_i, difftest_flush_o, 'd0)
`DFFENR(clk, rst, 1'b1, mem_is_signed_i, mem_is_signed_o, 'd0)
endmodule
