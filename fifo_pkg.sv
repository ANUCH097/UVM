`timescale 1ns / 1ps
package fifo_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "fifo_item_seq.sv"
  `include "fifo_agent.sv"
  `include "fifo_env.sv"
  `include "fifo_test.sv"
endpackage
