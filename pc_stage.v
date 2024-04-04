`include "defines.v"

module pc_stage(
    input wire clk,
    input wire rst,
    input wire stall,// from hazard
  //  input wire flush,// from id_stage
    input wire pc_redir_en,
    input wire  [63 : 0] pre_pc,
    input wire  [63 : 0] pc_redir,
    output wire [63 : 0] pc,
    output wire [31 : 0] inst
    );
    
    parameter PC_START_RESET = `PC_START  -4;
    
    // fetch an instruction
    wire [63:0] pc_d;
    reg [63:0]  pc_q;
    
    `DFFENR(clk, rst, 1'b1, pc_d, pc_q,PC_START_RESET)
    //assign pc_d = pc_redir_en ? pc_redir : (pc_q + 'd4);
    assign pc_d = pc_redir_en ? pc_redir : stall ? pc_q : pre_pc;
    
    assign pc   = pc_q;
    RAM_1W2R  u_RAM_1W2R (
    .clk                     (clk),
    .inst_addr               (pc_q),
    .inst_ena                (1'b1),
    .ram_wr_en               (0),
    .ram_rd_en               (0),
    .ram_wmask               (0),
    .ram_addr                (0),
    .ram_wr_data             (0),
    
    //output
    .inst                    (inst),
    .ram_rd_data             ()
    );
endmodule
