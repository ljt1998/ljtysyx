`include "defines.v"
module alu(
  //input wire rst_n,
    input wire [`AluOpBus]    aluop_i,
    input wire [`AluSelBus]   alusel_i,
    input wire [63:0]         rs1_data_i,
    input wire [63:0]         rs2_data_i,
    //load forwarding
    input wire [63:0]         forward_load_data_i,
    input wire                forward_load_rs1_en,
    input wire                forward_load_rs2_en,
    //fowarding type RAW
   // input wire [1:0]       rs1_foward_type_i,
   // input wire [1:0]       rs2_foward_type_i,
 //   input wire [63:0]      ex_data_i,
  //  input wire [63:0]      mem_data_i,
  //  input wire [63:0]      wb_pc_addr_i,
    output wire [63:0]     wb_data_o
);
    wire [63:0] pccount;
    wire [63:0] logiccount;
    reg [63:0]  shiftcount;
    reg  [63:0] arithmeticcount;
    wire [63:0] add_result;
 //   wire [63:0] sub_result = 
    wire [63:0] rs2_complement_sel;
    wire compare_result;
//**********************************************************************// 
    wire rv32_aluop_or             = ( aluop_i  == `EXE_OR_OP  );
    wire rv32_aluop_and            = ( aluop_i  == `EXE_ANDI_OP);
    wire rv32_aluop_xor            = ( aluop_i  == `EXE_XORI_OP);
    wire rv32_aluop_shift_left     = ( aluop_i  == `EXE_SLL_OP );
    wire rv32_aluop_shift_signed   = ( aluop_i  == `EXE_SRA_OP );
    wire rv32_aluop_shift_right    = ( aluop_i  == `EXE_SRL_OP );
    wire rv32_aluop_add            = ( aluop_i  == `EXE_ADD_OP );
    wire rv32_aluop_sub            = ( aluop_i  == `EXE_SUB_OP );
    wire rv32_aluop_slti           = ( aluop_i  == `EXE_SLTA_OP);
    wire rv32_aluop_sltu           = ( aluop_i  == `EXE_SLTU_OP);
    wire rv32_aluop_divu           = ( aluop_i  == `EXE_DIVU_OP);
    wire rv32_aluop_div            = ( aluop_i  == `EXE_DIV_OP );
    wire rv32_aluop_remu           = ( aluop_i  == `EXE_REMU_OP);
    wire rv32_aluop_rem            = ( aluop_i  == `EXE_REM_OP );
    wire rv64_aluop_addiw          = ( aluop_i  == `EXE_ADDW_OP);
//**********************************************************************//    
    wire rv32_alusel_logic         = ( alusel_i == `EXE_RES_LOGIC);
    wire rv32_alusel_shift         = ( alusel_i == `EXE_RES_SHIFT);
    wire rv32_alusel_arithmetic    = ( alusel_i == `EXE_RES_ARITHMETIC);
    wire rv32_alusel_compare       = ( alusel_i == `EXE_RES_COMPARE);
    wire rv32_alusel_subw          = ( alusel_i == `EXE_RES_SUBW);
//*****alu fowarding*****
    wire [63:0] alu_rs1;
    wire [63:0] alu_rs2;
    wire [63:0] rv64_alu_result;
    wire [31:0] rv32_arithmetic_result=((({32{alu_rs1[31]}})<<(6'd32-({1'b0,alu_rs2[4:0]}))) | (alu_rs1[31:0]>>alu_rs2[4:0]));
    wire [64:0]   sltu_intern = {1'b0,alu_rs1} - {1'b0,alu_rs2};   
    wire [63:0] unsigned_result;
    reg  [63:0] subwcount;
//    wire [64:0]   sltu_intern = {1'b0,src1} - {1'b0,src2};
    wire [63:0]   sltu_result = {63'b0 , sltu_intern[64]};  
    wire [31:0]   sub_result  = alu_rs1[31:0] - alu_rs2[31:0];
    wire [63:0]   slt_result  = {63'b0, compare_result};
    reg  [63:0]   signed_result;
    reg [63:0]   comparecount; 
    assign alu_rs1 = forward_load_rs1_en ? forward_load_data_i :  rs1_data_i;
    assign alu_rs2 = forward_load_rs2_en ? forward_load_data_i :  rs2_data_i;
//***********************sub****************************************//
    assign rs2_complement_sel   = (rv32_aluop_sub||rv32_aluop_slti) ?((~alu_rs2)+1):(alu_rs2);
    assign add_result = alu_rs1 + rs2_complement_sel;
//***********************compare******************************************//
    assign compare_result =  ( alu_rs1[63] && (~alu_rs2[63]))                    
                        || (((~alu_rs1[63])&& (~alu_rs2[63]))&&add_result[63])
                        || ((( alu_rs1[63])&& ( alu_rs2[63]))&&add_result[63]); 
    assign signed_result  = {63'd0,compare_result};
   // assign unsigned_result= {63'd0,sltu_intern[64]};
    assign comparecount   = {63'd0,(rv32_aluop_sltu ? sltu_intern[64]:compare_result)};
//*************************************************************//
always @(*) begin
      //  arithmeticcount = 'd0;
    case (aluop_i)
      `EXE_ADD_OP:   arithmeticcount = add_result;
      `EXE_SUB_OP:   arithmeticcount = alu_rs1 - alu_rs2;
      `EXE_ADDW_OP:  begin 
                     arithmeticcount[31:0] = alu_rs1[31:0] + alu_rs2[31:0];
                     arithmeticcount[63:32] = {32{arithmeticcount[31]}};  
                     end
    //  `EXE_SUBW_OP:  begin 
    //                 arithmeticcount[31:0] = sub_result;               
    //                 arithmeticcount[63:32] = {32{sub_result[31]}};  
    //                 end
    //  `EXE_AND_OP:   arithmeticcount = alu_rs1 & alu_rs2;
    //  `EXE_OR_OP:    arithmeticcount = alu_rs1 | alu_rs2;
    //  `EXE_XORI_OP:  arithmeticcount = alu_rs1 ^ alu_rs2;
        `EXE_SLL_OP:   shiftcount = alu_rs1 << alu_rs2[5:0];
        `EXE_SRL_OP:   shiftcount = alu_rs1 >> alu_rs2[5:0];
        `EXE_SRA_OP:   shiftcount = ((({64{alu_rs1[63]}})<<(7'd64-({1'b0,alu_rs2[4:0]}))) | (alu_rs1>>alu_rs2[4:0]));
        `EXE_SLLW_OP:  begin shiftcount[31:0] = alu_rs1[31:0] << alu_rs2[4:0];
                             shiftcount[63:32] = {32{shiftcount[31]}};  
                       end
        `EXE_SRAW_OP:  begin 
                      shiftcount[31:0] = rv32_arithmetic_result;               
                      shiftcount[63:32] = {32{alu_rs1[31]}};  
                      end
        `EXE_SRUW_OP:begin 
                      shiftcount[31:0]  = alu_rs1[31:0] >> alu_rs2[4:0];              
                      shiftcount[63:32] = {32{shiftcount[31]}};  
                      end
  //    `EXE_SRAW:  begin arithmeticcount = {{32{alu_rs1[31]}}, alu_rs1[31:0]} >> alu_rs2[4:0];   arithmeticcount[63:32] = {32{arithmeticcount[31]}};  end
     //  `EXE_SLTA_OP:   shiftcount = slt_result;
      // `EXE_SLTU_OP:   comparecount = sltu_result;
      default:   begin 
                      arithmeticcount = 'd0;
                      shiftcount      = 'd0; 
                 end
    endcase
  end

  always @(*) begin
    case (aluop_i)
      `EXE_SLTA_OP: comparecount = slt_result;
      `EXE_SLTU_OP: comparecount = sltu_result; 
      default: comparecount = 'd0; 
    endcase
  end

   always @(*) begin
    case (aluop_i)
      `EXE_SUBW_OP: begin
                    subwcount[31:0]  = sub_result;
                    subwcount[63:32] ={32{sub_result[31]}}; 
                    end
     // `EXE_SLTU_OP: comparecount = sltu_result; 
      default: subwcount = 'd0; 
    endcase
  end
  //  assign wb_addr_o  = wb_addr_i;
  //  assign wb_en_o    = wb_en_i;
//*************************div***********************************//
 //   assign stallreq_for_div = (div_readyen_i == `DivResultNotReady)&&(rv32_aluop_div||rv32_aluop_divu||rv32_aluop_remu||rv32_aluop_rem);
 //   assign div_starten_o    = (div_readyen_i == `DivResultNotReady)&&(rv32_aluop_div||rv32_aluop_divu||rv32_aluop_remu||rv32_aluop_rem);
 //   assign signed_div_o     =  rv32_aluop_div||rv32_aluop_rem; 
 //   assign div_quotient     =  div_resultdata_i[31:0];
 //   assign div_remainder    =  div_resultdata_i[63:32];
 //   assign div_datafinish   = (div_readyen_i == `DivResultReady)&&(rv32_aluop_div ||rv32_aluop_divu);
 //   assign rem_datafinish   = (div_readyen_i == `DivResultReady)&&(rv32_aluop_remu||rv32_aluop_rem );
 //   assign div_datafinish_div = (div_readyen_i == `DivResultReady)&&(rv32_aluop_div||rv32_aluop_divu);
//*************************************************************//
   // assign pccount = wb_pc_addr_i;
 //   assign arithmeticcount =  ({64{rv32_aluop_add |rv32_aluop_sub| rv64_aluop_addiw  }} & add_result)
  //                          | ({64{rv32_aluop_slti|rv32_aluop_sltiu}} & {63'b0,compare_result}); 
  //  assign rv64_alu_result = rv64_aluop_addiw ? {{32{arithmeticcount[31]}},arithmeticcount[31:0]} : arithmeticcount;
    assign logiccount =  ({64{rv32_aluop_or }}   & (alu_rs1 | alu_rs2))
                       | ({64{rv32_aluop_and}}   & (alu_rs1 & alu_rs2))
                       | ({64{rv32_aluop_xor}}   & (alu_rs1 ^ alu_rs2));

 //   assign shiftcount =  ({64{rv32_aluop_shift_left }}   & (alu_rs1 << alu_rs2[5:0]))
 //                      | ({64{rv32_aluop_shift_right}}   & (alu_rs1 >> alu_rs2[5:0]))
 //                      | ({64{rv32_aluop_shift_signed}}) & ((({64{alu_rs1[31]}})<<(6'd32-({1'b0,alu_rs2[5:0]}))) | (alu_rs1>>alu_rs2[5:0]));

    assign wb_data_o  = ({64{rv32_alusel_logic}}      & logiccount)
                       |({64{rv32_alusel_shift}}      & shiftcount)
                       |({64{rv32_alusel_compare}}    & comparecount)
                       |({64{rv32_alusel_subw}}       & subwcount)
                       |({64{rv32_alusel_arithmetic}} & arithmeticcount);
       //                |({64{rv32_alusel_pc}}         & pccount);
             //          |({32{div_datafinish}}         & div_quotient)
             //          |({32{rem_datafinish}}         & div_remainder);

 //   assign stallreq_from_ex_o = stallreq_for_div;
endmodule 