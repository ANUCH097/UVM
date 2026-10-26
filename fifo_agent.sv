// ===================== Driver =====================
class fifo_driver extends uvm_driver #(fifo_item);
  `uvm_component_utils(fifo_driver)
  virtual fifo_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif))
      `uvm_fatal("DRV", "virtual interface not set")
  endfunction

  task run_phase(uvm_phase phase);
    // reset for 3 clocks
    vif.drv_cb.rst     <= 1;
    vif.drv_cb.wr_enb  <= 0;
    vif.drv_cb.rd_enb  <= 0;
    vif.drv_cb.data_in <= 0;
    repeat (3) @(vif.drv_cb);
    vif.drv_cb.rst <= 0;

    forever begin
      seq_item_port.get_next_item(req);
      @(vif.drv_cb);
      vif.drv_cb.wr_enb  <= req.wr_en;
      vif.drv_cb.rd_enb  <= req.rd_en;
      vif.drv_cb.data_in <= req.data;
      seq_item_port.item_done();
    end
  endtask
endclass

// ===================== Monitor =====================
class fifo_monitor extends uvm_monitor;
  `uvm_component_utils(fifo_monitor)
  virtual fifo_if vif;
  uvm_analysis_port #(fifo_item) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
    if (!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif))
      `uvm_fatal("MON", "virtual interface not set")
  endfunction

  task run_phase(uvm_phase phase);
    fifo_item item;
    forever begin
      @(vif.mon_cb);
      item = fifo_item::type_id::create("mon_item");
      item.rst      = vif.mon_cb.rst;
      item.wr_en    = vif.mon_cb.wr_enb;
      item.rd_en    = vif.mon_cb.rd_enb;
      item.data     = vif.mon_cb.data_in;
      item.data_out = vif.mon_cb.data_out;
      item.full     = vif.mon_cb.full;
      item.empty    = vif.mon_cb.empty;
      ap.write(item);
    end
  endtask
endclass

// ===================== Agent =====================
class fifo_agent extends uvm_agent;
  `uvm_component_utils(fifo_agent)
  fifo_driver                 drv;
  fifo_monitor                mon;
  uvm_sequencer #(fifo_item)  sqr;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    drv = fifo_driver::type_id::create("drv", this);
    mon = fifo_monitor::type_id::create("mon", this);
    sqr = uvm_sequencer#(fifo_item)::type_id::create("sqr", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    drv.seq_item_port.connect(sqr.seq_item_export);
  endfunction
endclass
