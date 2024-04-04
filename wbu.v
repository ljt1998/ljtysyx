`include "defines.v"
module wbu(
    input  wire [63:0]     mem_load_data_i,
    input  wire [63:0]     wb_data_i,
    input  wire            wb_en_i,
    input  wire            inst_is_load_i,
    output wire [63:0]     wb_data_result         
);
    assign wb_data_result = (wb_en_i && inst_is_load_i) ? mem_load_data_i : wb_data_i;
endmodule