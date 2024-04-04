`include "defines.v"
module mem_pipline(
    input wire clk,
    input wire rst,
    input wire [63:0]     mem_load_data_i,
    input wire [63:0]     wb_data_i,
    input wire [4:0]      wb_addr_i, 
    input wire            wb_en_i,
    input wire [31:0]     inst_i,
    input wire [63:0]     pc_i,
    input wire            difftest_flush_i,
    output reg            difftest_flush_o,
    // lsu-mem-ctrl
    input wire            inst_is_load_i,
    output reg [63:0]     pc_o,
    output reg [31:0]     inst_o,
    output reg [63:0]     mem_load_data_o,
    output reg [63:0]     wb_data_o,
    output reg [4:0]      wb_addr_o, 
    output reg            wb_en_o,
    output reg            inst_is_load_o         
);
`DFFENR(clk, rst, 1'b1, wb_data_i, wb_data_o, 'd0)
`DFFENR(clk, rst, 1'b1, wb_addr_i, wb_addr_o, 'd0)
`DFFENR(clk, rst, 1'b1, wb_en_i, wb_en_o, 'd0)
`DFFENR(clk, rst, 1'b1, inst_is_load_i, inst_is_load_o, 'd0)
`DFFENR(clk, rst, 1'b1, mem_load_data_i, mem_load_data_o, 'd0)
`DFFENR(clk, rst, 1'b1, inst_i, inst_o, 'd0)
`DFFENR(clk, rst, 1'b1, pc_i, pc_o, 'd0)
`DFFENR(clk, rst, 1'b1, difftest_flush_i, difftest_flush_o, 'd0)
endmodule