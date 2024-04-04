`include "defines.v"
module cmt_pipline(
    input wire clk,
    input wire rst,
    input wire [63:0]     wb_data_i,
    input wire [4:0]      wb_addr_i, 
    input wire            wb_en_i,
    input wire [31:0]     inst_i,
    input wire [63:0]     pc_i,  
    // lsu-mem-ctrl
    output reg [31:0]     inst_o,
    output reg [63:0]     pc_o,
    output reg [63:0]     wb_data_o,
    output reg [4:0]      wb_addr_o, 
    output reg            wb_en_o
);
// Assuming DFFENR is a macro for a D flip-flop with enable and reset
`DFFENR(clk, rst, 1'b1, wb_data_i, wb_data_o, 'd0)
`DFFENR(clk, rst, 1'b1, wb_addr_i, wb_addr_o, 'd0)
`DFFENR(clk, rst, 1'b1, wb_en_i, wb_en_o, 'd0)
`DFFENR(clk, rst, 1'b1, inst_i, inst_o, 'd0)
`DFFENR(clk, rst, 1'b1, pc_i, pc_o, 'd0)

endmodule
