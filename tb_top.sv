`timescale 1ns / 1ps
module tb_top;
  import uvm_pkg::*;
  import fifo_pkg::*;
  `include "uvm_macros.svh"

  logic clk = 0;
  always #5 clk = ~clk;          // 100 MHz

  fifo_if intf (clk);

  fifo_8_8 dut (
    .clk     (clk),
    .rst     (intf.rst),
    .wr_enb  (intf.wr_enb),
    .rd_enb  (intf.rd_enb),
    .data_in (intf.data_in),
    .data_out(intf.data_out),
    .full    (intf.full),
    .empty   (intf.empty)
  );

  initial begin
    uvm_config_db#(virtual fifo_if)::set(null, "*", "vif", intf);
    run_test("fifo_base_test");
  end
endmodule
