/***********************************************************************
 * A SystemVerilog top-level netlist to connect testbench to DUT
 *
 * SystemVerilog Training Workshop.
 * Copyright 2006, 2013 by Sutherland HDL, Inc.
 * Tualatin, Oregon, USA.  All rights reserved.
 * www.sutherland-hdl.com
 **********************************************************************/

module top;
  timeunit 1ns/1ns;

  // user-defined types are defined in instr_register_pkg.sv
  import instr_register_pkg::*;

  // clock variables
  logic clk;


 // instantiate the testbench interface
  tb_ifc tbifc (.clk(clk));

  // connect interface to testbench
  instr_register_test test (.tbifc(tbifc));

  // connect interface to design using discrete ports
  instr_register dut (
    .clk(clk),
    .load_en(tbifc.load_en),
    .reset_n(tbifc.reset_n),
    .operand_a(tbifc.operand_a),
    .operand_b(tbifc.operand_b),
    .opcode(tbifc.opcode),
    .write_pointer(tbifc.write_pointer),
    .read_pointer(tbifc.read_pointer),
    .instruction_word(tbifc.instruction_word)
   );

  // clock oscillators
  initial begin
    clk <= 0;
    forever #5  clk = ~clk;
  end

endmodule: top
