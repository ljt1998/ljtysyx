`include"defines.v"
module fowarding(
    //RAW input 
    input  wire [4:0] if_rs1_addr_i,
    input  wire [4:0] if_rs2_addr_i,
    input  wire [4:0] id_rs1_addr_i,
    input  wire [4:0] id_rs2_addr_i,
    input  wire [4:0] ex_rd_addr_i,
    input  wire       ex_rd_en_i,
    input  wire       ex_inst_is_load_i,
    input  wire [4:0] mem_rd_addr_i,
    input  wire       mem_rd_en_i,
    input wire  wb_inst_is_load_i,
    input  wire [4:0] wb_rd_addr_i,
    input  wire       wb_rd_en_i,

    //load forward
    output wire       id_foward_rs1_en,
    output wire       id_foward_rs2_en,
    output wire       load_forward_rs1_en,
    output wire       load_forward_rs2_en,
    output wire [1:0] if_rs1_foward_type,
    output wire [1:0] if_rs2_foward_type 
);
    //RAW
    wire ex_cond  = ex_rd_en_i  && (ex_rd_addr_i != 'd0);
    wire mem_cond = mem_rd_en_i && (mem_rd_addr_i != 'd0);
    wire wb_cond  = wb_rd_en_i  && (wb_rd_addr_i != 'd0);

    assign if_rs1_foward_type = (ex_cond  && (if_rs1_addr_i == ex_rd_addr_i))   ? 2'b01 : 
                                (mem_cond && (if_rs1_addr_i == mem_rd_addr_i))  ? 2'b11 :
                                (wb_cond  && (if_rs1_addr_i == wb_rd_addr_i))   ? 2'b10 :
                                                                                  2'd0  ;
    assign if_rs2_foward_type = (ex_cond  && (if_rs2_addr_i == ex_rd_addr_i))   ? 2'b01 : 
                                (mem_cond && (if_rs2_addr_i == mem_rd_addr_i))  ? 2'b11 :
                                (wb_cond  && (if_rs2_addr_i == wb_rd_addr_i))   ? 2'b10 : 
                                                                                  2'd0  ;
    assign load_forward_rs1_en = (id_rs1_addr_i == wb_rd_addr_i) && wb_cond && wb_inst_is_load_i;
    assign load_forward_rs2_en = (id_rs2_addr_i == wb_rd_addr_i) && wb_cond && wb_inst_is_load_i;
    assign id_foward_rs1_en = (if_rs1_addr_i == mem_rd_addr_i) && mem_cond && ex_inst_is_load_i;
    assign id_foward_rs2_en = (if_rs2_addr_i == mem_rd_addr_i) && mem_cond && ex_inst_is_load_i;
endmodule