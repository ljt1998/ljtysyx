`include "defines.v"
// load-use
module hazard(
    input wire       id_inst_is_load_i,
    input wire [4:0] id_rd_addr_i,
    input wire [4:0] if_rs1_addr_i,
    input wire [4:0] if_rs2_addr_i,
    output wire stall
);
    wire addr_is_eq = (id_rd_addr_i ==  if_rs1_addr_i) || (id_rd_addr_i ==  if_rs2_addr_i);
    assign stall = id_inst_is_load_i && addr_is_eq;
    
endmodule