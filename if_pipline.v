`include "defines.v"
module if_pipline(
    input wire clk,
    input wire rst,
    input wire flush,
    input wire stall,
    input wire [63:0] pc_i,
    input wire [31:0] inst_i,
    input wire predict_is_yes_i,
    output reg difftest_flush_o,
    output reg predict_is_yes_o,
    output reg [63:0] pc_o,
    output reg [31:0] inst_o
);
    wire [63:0] pc_d;
    wire [31:0] inst_d;
    wire predict_is_yes_d;
    `DFFENR(clk,rst,1'b1,pc_d,pc_o,'d0)
    assign pc_d   = flush ? 'd0 : stall ? pc_o : pc_i;
    `DFFENR(clk,rst,1'b1,inst_d,inst_o,'d0)
    assign inst_d = flush ? 'd0 : stall ? inst_o : inst_i;
    `DFFENR(clk,rst,1'b1,predict_is_yes_d,predict_is_yes_o,'d0)
    assign predict_is_yes_d = flush ? 'd0 : stall ? predict_is_yes_o : predict_is_yes_i;
    `DFFENR(clk,rst,1'b1,flush,difftest_flush_o,'d0)
endmodule