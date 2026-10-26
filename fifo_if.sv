`timescale 1ns / 1ps
interface fifo_if (input logic clk);

  logic       rst     = 1'b1;
  logic       wr_enb  = 1'b0;
  logic       rd_enb  = 1'b0;
  logic [7:0] data_in = '0;
  logic [7:0] data_out;
  logic       full;
  logic       empty;

  // Driver drives through this
  clocking drv_cb @(posedge clk);
    default input #1step output #1;
    output rst, wr_enb, rd_enb, data_in;
  endclocking

  // Monitor samples through this (values just BEFORE the clock edge)
  clocking mon_cb @(posedge clk);
    default input #1step;
    input rst, wr_enb, rd_enb, data_in, data_out, full, empty;
  endclocking

  // ---------------- Assertions (SVA) ----------------
  // full and empty can never both be high
  a_full_empty_excl: assert property (
    @(posedge clk) disable iff (rst) !(full && empty))
    else $error("SVA: full and empty both high");

  // after reset the FIFO is empty and not full
  a_reset_state: assert property (
    @(posedge clk) rst |=> (empty && !full))
    else $error("SVA: not empty after reset");

  // a full FIFO stays full unless a read happens
  a_full_holds: assert property (
    @(posedge clk) disable iff (rst) (full && !rd_enb) |=> full)
    else $error("SVA: full dropped without a read");

  // read on empty must not change data_out
  a_no_read_when_empty: assert property (
    @(posedge clk) disable iff (rst) (empty && rd_enb) |=> $stable(data_out))
    else $error("SVA: data_out changed on read-when-empty");

endinterface
