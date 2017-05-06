
//
// Hacked up getting to an interface
//
`timescale 1ns/10ps

`include "if.sv"
`include "alu9.svp"
`include "wrap.sv"

package alu_pkg;

import uvm_pkg::*;

`include "t0.sv"

endpackage: alu_pkg


module top_tb;

import uvm_pkg::*;
import alu_pkg::*;

alu_if ALU();

// Free running clock
initial
  begin
    ALU.clk = 0;
    forever begin
      #5 ALU.clk = ~ALU.clk;
    end
  end

// starts up. Note setting alu into the configuration data base.
initial
  begin
    #0;
    uvm_config_db #(virtual alu_if)::set(null, "uvm_test_top", "alu_if" , ALU);
    run_test("alu_test");
    #100;
    $finish;
  end
  
// Dump waves
  initial begin

  end

// set up the DUT

wrap a(ALU.dut_mp);

endmodule: top_tb
