// ===================== Sequence item =====================
class fifo_item extends uvm_sequence_item;
  `uvm_object_utils(fifo_item)

  // stimulus (randomized)
  rand bit       wr_en;
  rand bit       rd_en;
  rand bit [7:0] data;

  // observed (filled by monitor)
  bit [7:0] data_out;
  bit       full, empty, rst;

  function new(string name = "fifo_item");
    super.new(name);
  endfunction

  function string convert2string();
    return $sformatf("wr=%0b rd=%0b din=0x%02h | dout=0x%02h full=%0b empty=%0b rst=%0b",
                     wr_en, rd_en, data, data_out, full, empty, rst);
  endfunction
endclass

// ===================== Sequences =====================
class fifo_base_seq extends uvm_sequence #(fifo_item);
  `uvm_object_utils(fifo_base_seq)
  int unsigned n = 10;
  function new(string name = "fifo_base_seq");
    super.new(name);
  endfunction
endclass

// write only (n > 7 so we also try writing when full)
class fifo_fill_seq extends fifo_base_seq;
  `uvm_object_utils(fifo_fill_seq)
  function new(string name = "fifo_fill_seq"); super.new(name); endfunction
  task body();
    repeat (n) `uvm_do_with(req, { wr_en == 1; rd_en == 0; })
  endtask
endclass

// read only (n > 7 so we also try reading when empty)
class fifo_drain_seq extends fifo_base_seq;
  `uvm_object_utils(fifo_drain_seq)
  function new(string name = "fifo_drain_seq"); super.new(name); endfunction
  task body();
    repeat (n) `uvm_do_with(req, { wr_en == 0; rd_en == 1; })
  endtask
endclass

// simultaneous read and write
class fifo_simul_seq extends fifo_base_seq;
  `uvm_object_utils(fifo_simul_seq)
  function new(string name = "fifo_simul_seq"); super.new(name); endfunction
  task body();
    repeat (n) `uvm_do_with(req, { wr_en == 1; rd_en == 1; })
  endtask
endclass

// constrained-random with adjustable write/read bias (percent)
class fifo_rand_seq extends fifo_base_seq;
  `uvm_object_utils(fifo_rand_seq)
  int unsigned wr_w = 50;
  int unsigned rd_w = 50;
  function new(string name = "fifo_rand_seq"); super.new(name); endfunction
  task body();
    repeat (n) `uvm_do_with(req, {
      wr_en dist { 1 := local::wr_w, 0 := 100 - local::wr_w };
      rd_en dist { 1 := local::rd_w, 0 := 100 - local::rd_w };
    })
  endtask
endclass
