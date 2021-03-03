/***********************************************************************
 * A SystemVerilog top-level netlist to connect testbench to DUT
 **********************************************************************/

module top;
  timeunit 1ns/1ns;

  // user-defined types are defined in instr_register_pkg.sv
  import instr_register_pkg::*;

  // clock variables
  logic clk;
  logic test_clk;

  tb_ifc tb_intf (.clk (clk));

  // instantiate testbench and connect ports
  instr_register_test test (
    .clk(test_clk),
    .load_en(tb_intf.load_en),
    .reset_n(tb_intf.reset_n),
    .operand_a(tb_intf.operand_a),
    .operand_b(tb_intf.operand_b),
    .opcode(tb_intf.opcode),
    .write_pointer(tb_intf.write_pointer),
    .read_pointer(tb_intf.read_pointer),
    .instruction_word(tb_intf.instruction_word)
   );

  // instantiate design and connect ports
  instr_register dut (
    .clk(clk),
    .load_en(tb_intf.load_en),
    .reset_n(tb_intf.reset_n),
    .operand_a(tb_intf.operand_a),
    .operand_b(tb_intf.operand_b),
    .opcode(tb_intf.opcode),
    .write_pointer(tb_intf.write_pointer),
    .read_pointer(tb_intf.read_pointer),
    .instruction_word(tb_intf.instruction_word)
   );

  // clock oscillators
  initial begin
    clk <= 0;
    forever #5  clk = ~clk;
  end

  initial begin
    test_clk <=0;
    // offset test_clk edges from clk to prevent races between
    // the testbench and the design
    #4 forever begin
      #2ns test_clk = 1'b1;
      #8ns test_clk = 1'b0;
    end
  end

endmodule: top
