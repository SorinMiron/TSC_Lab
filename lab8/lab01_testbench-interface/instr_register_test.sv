/***********************************************************************
 * A SystemVerilog testbench for an instruction register.
 * The course labs will convert this to an object-oriented testbench
 * with constrained random test generation, functional coverage, and
 * a scoreboard for self-verification.
 *
 * SystemVerilog Training Workshop.
 * Copyright 2006, 2013 by Sutherland HDL, Inc.
 * Tualatin, Oregon, USA.  All rights reserved.
 * www.sutherland-hdl.com
 **********************************************************************/

module instr_register_test (tb_ifc tbifc);  // interface port

  timeunit 1ns/1ns;

  // user-defined types are defined in instr_register_pkg.sv
  import instr_register_pkg::*;

  int seed = 555;
class Transaction;
  rand opcode_t       opcode;
  rand operand_t      operand_a, operand_b;
  address_t      write_pointer;

  constraint rand_operand_a{
  operand_a >= -15;
  operand_a <= 15;
  }
  constraint rand_operand_b{
    operand_b >= 0;
    operand_b <= 15;
  }

  // function void randomize_transaction();
  //   static int temp = 0;
  //   operand_a     = $random(seed)%16;                 // between -15 and 15
  //   operand_b     = $unsigned($random)%16;            // between 0 and 15
  //   opcode        = opcode_t'($unsigned($random)%8);  // between 0 and 7, cast to opcode_t type
  //   write_pointer = temp++;
  // endfunction : randomize_transaction

  function void print_transaction;
    $display("Writing to register location %0d: ", write_pointer);
    $display("  opcode = %0d (%s)", opcode, opcode.name);
    $display("  operand_a = %0d",   operand_a);
    $display("  operand_b = %0d\n", operand_b);
  endfunction: print_transaction
endclass: Transaction
  
class Driver;
  virtual tb_ifc vifc;
  Transaction tr;
    
     covergroup inputs_measure;
    
    cov_0: coverpoint vifc.cb.opcode {
      bins val_zero = {ZERO};
      bins val_passA = {PASSA};
      bins val_passB = {PASSB};
      bins val_add = {ADD};
      bins val_sub = {SUB};
      bins val_mult = {MULT};
      bins val_div = {DIV};
      bins val_mod = {MOD};
    }
    cov_1: coverpoint vifc.cb.operand_a {
      bins val_opA[] = {[-15:15]};
      bins val_max = {15};
      bins val_min = {-15};
	  bins val_zero = {0};
    }
    cov_2: coverpoint vifc.cb.operand_b {
      bins val_opB[] = {[0:15]};
      bins val_max = {15};
      bins val_min = {0};
    }
    cov_3: coverpoint vifc.cb.operand_a {
      bins neg = {[-15:-1]};
      bins poz = {[0:15]};
    }
    cov_4: cross cov_0, cov_3 {
       ignore_bins poz_ignore = binsof (cov_3.poz);
    }
    cov_5: cross cov_0, cov_1, cov_2{
     ignore_bins opA_ignore = binsof (cov_1.val_opA);
     ignore_bins opB_ignore = binsof (cov_2.val_opB);
    }
    cov_6: cross cov_0, cov_1, cov_2{
     ignore_bins opA_ignore1 = binsof (cov_1.val_opA);
     ignore_bins opA_ignore2 = binsof (cov_1.val_max);
     ignore_bins opB_ignore1 = binsof (cov_2.val_opB);
     ignore_bins opB_ignore2 = binsof (cov_2.val_max);
    }
	cov_7: cross cov_0, cov_3{
     ignore_bins opA_ignore1 = binsof (cov_3.neg);
    }
	cov_8: cross cov_1, cov_2{
     ignore_bins opB_ignore1 = binsof (cov_2.val_opB);
     ignore_bins opB_ignore2 = binsof (cov_2.val_max);
	 
	 ignore_bins opA_ignore1 = binsof (cov_1.val_opA);
     ignore_bins opA_ignore2 = binsof (cov_1.val_max);
	 ignore_bins opA_ignore3 = binsof (cov_1.val_min);
    }
  endgroup;

    function new(virtual tb_ifc vifc);
      this.vifc = vifc;
      inputs_measure = new();
      tr = new();
    endfunction 

    task generate_transaction();
      $display("\nReseting the instruction register...");
      this.reset_signals();
      repeat(1000)
      begin
         @(vifc.cb) tr.randomize();
         this.assing_signals();
         @(vifc.cb) tr.print_transaction();
         inputs_measure.sample();
      end
      @vifc.cb vifc.cb.load_en <= 1'b0;  
    endtask

    task assing_signals();
        static int temp = 0;
        vifc.cb.operand_a <= tr.operand_a;
        vifc.cb.operand_b <= tr.operand_b;
        vifc.cb.opcode <= tr.opcode;
        vifc.cb.write_pointer <= temp++;
    endtask

    task reset_signals();
      vifc.cb.write_pointer   <= 5'h00;      // initialize write pointer
      vifc.cb.read_pointer    <= 5'h1F;      // initialize read pointer
      vifc.cb.load_en         <= 1'b0;       // initialize load control line
      vifc.cb.reset_n         <= 1'b0;       // assert reset_n (active low)
       repeat (2) @(vifc.cb) ;                // hold in reset for 2 clock cycles
        vifc.cb.reset_n         <= 1'b1;       // deassert reset_n (active low)
    endtask

    
endclass: Driver

class Monitor;
    virtual tb_ifc vifc;

    function new(virtual tb_ifc vifc);
      this.vifc = vifc;
    endfunction

    function void print_results;
      $display("Read from register location %0d: ", vifc.cb.read_pointer);
      $display("  opcode = %0d (%s)", vifc.cb.instruction_word.opc, tbifc.cb.instruction_word.opc.name);
      $display("  operand_a = %0d",   vifc.cb.instruction_word.op_a);
      $display("  operand_b = %0d\n", vifc.cb.instruction_word.op_b);
    endfunction: print_results

    task read_transaction();
      $display("\nReading back the same register locations written...");
      for (int i=0; i<=2; i++) begin
        @(this.vifc.cb) this.vifc.cb.read_pointer <= i;
        @(this.vifc.cb) this.print_results();
      end
    endtask
endclass: Monitor


initial begin
    Driver drv;
    Monitor mon;

    drv = new(tbifc);
    mon = new(tbifc);

    drv.generate_transaction();
    mon.read_transaction();

    $finish;
end
endmodule: instr_register_test
