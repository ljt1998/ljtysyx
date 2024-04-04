/***************************************************************************************
* Copyright (c) 2020-2021 Institute of Computing Technology, Chinese Academy of Sciences
* Copyright (c) 2020-2021 Peng Cheng Laboratory
*
* XiangShan is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

import "DPI-C" function void ram_write_helper
(
  input  longint    wIdx,
  input  longint    wdata,
  input  longint    wmask,
  input  bit        wen
);

import "DPI-C" function longint ram_read_helper
(
  input  bit        en,
  input  longint    rIdx
);

module RAMHelper(
  input         clk,
  input         en,
  input  [63:0] rIdx,
  output [63:0] rdata,
  input  [63:0] wIdx,
  input  [63:0] wdata,
  input  [63:0] wmask,
  input         wen
);
//
  assign rdata = ram_read_helper(en, rIdx);
//
  always @(posedge clk) begin
    ram_write_helper(wIdx, wdata, wmask, wen && en);
  end
//
endmodule

module RAM_1W2R(
    input clk,
    
    input [63:0]inst_addr,
    input inst_ena,
    output [31:0]inst,

    // DATA PORT
    input ram_wr_en,
    input ram_rd_en,
    input [63:0]ram_wmask,
    input [63:0]ram_addr,
    input [63:0]ram_wr_data,
    output reg [63:0]ram_rd_data
);

    // INST PORT

    wire[63:0] inst_2 = ram_read_helper(inst_ena,{3'b000,(inst_addr-64'h0000_0000_8000_0000)>>3});

    assign inst = inst_addr[2] ? inst_2[63:32] : inst_2[31:0];

    // DATA PORT 
    assign ram_rd_data = ram_read_helper(ram_rd_en, {3'b000,(ram_addr-64'h0000_0000_8000_0000)>>3});

    always @(posedge clk) begin
        ram_write_helper((ram_addr-64'h0000_0000_8000_0000)>>3, ram_wr_data, ram_wmask, ram_wr_en);
    end

endmodule

