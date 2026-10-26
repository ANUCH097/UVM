// ===================== Scoreboard =====================
// Reference model = SV queue. Checks (1) full/empty flags vs model,
// (2) data_out vs expected data (appears one clock after a read).
class fifo_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(fifo_scoreboard)
  uvm_analysis_imp #(fifo_item, fifo_scoreboard) imp;

  localparam int DEPTH = 7;      // 8 entries, 3-bit pointers -> 7 usable
  bit [7:0] model_q[$];
  bit       seen_reset, check_next;
  bit [7:0] exp_data;
  int       pass_cnt, err_cnt, wr_cnt, rd_cnt;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    imp = new("imp", this);
  endfunction

  function void write(fifo_item t);
    bit exp_full, exp_empty;

    if (t.rst) begin                 // reset clears the model
      model_q.delete();
      check_next = 0;
      seen_reset = 1;
      return;
    end
    if (!seen_reset) return;

    // 1) data check for a read accepted on the previous clock
    if (check_next) begin
      if (t.data_out !== exp_data) begin
        err_cnt++;
        `uvm_error("SB", $sformatf("DATA MISMATCH exp=0x%02h got=0x%02h", exp_data, t.data_out))
      end
      else pass_cnt++;
      check_next = 0;
    end

    // 2) flag check against the model
    exp_full  = (model_q.size() == DEPTH);
    exp_empty = (model_q.size() == 0);
    if (t.full !== exp_full) begin
      err_cnt++;
      `uvm_error("SB", $sformatf("FULL flag mismatch exp=%0b got=%0b (level=%0d)", exp_full, t.full, model_q.size()))
    end
    if (t.empty !== exp_empty) begin
      err_cnt++;
      `uvm_error("SB", $sformatf("EMPTY flag mismatch exp=%0b got=%0b (level=%0d)", exp_empty, t.empty, model_q.size()))
    end

    // 3) update model (accept decisions use pre-update flags, like the DUT)
    if (t.wr_en && !exp_full) begin
      model_q.push_back(t.data);
      wr_cnt++;
    end
    if (t.rd_en && !exp_empty) begin
      exp_data   = model_q.pop_front();
      check_next = 1;
      rd_cnt++;
    end
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("SB", $sformatf("writes=%0d reads=%0d data_checks_passed=%0d errors=%0d",
                              wr_cnt, rd_cnt, pass_cnt, err_cnt), UVM_NONE)
    if (err_cnt == 0 && pass_cnt > 0) `uvm_info("SB", "*** TEST PASSED ***", UVM_NONE)
    else                              `uvm_error("SB", "*** TEST FAILED ***")
  endfunction
endclass

// ===================== Functional coverage =====================
class fifo_coverage extends uvm_subscriber #(fifo_item);
  `uvm_component_utils(fifo_coverage)
  fifo_item item;

  covergroup cg;
    option.per_instance = 1;
    cp_wr    : coverpoint item.wr_en;
    cp_rd    : coverpoint item.rd_en;
    cp_full  : coverpoint item.full;
    cp_empty : coverpoint item.empty;
    x_wr_full  : cross cp_wr, cp_full;    // includes write-when-full
    x_rd_empty : cross cp_rd, cp_empty;   // includes read-when-empty
    x_wr_rd    : cross cp_wr, cp_rd;      // includes simultaneous wr+rd
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    cg = new();
  endfunction

  function void write(fifo_item t);
    if (t.rst) return;
    item = t;
    cg.sample();
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("COV", $sformatf("Functional coverage = %0.2f%%", cg.get_inst_coverage()), UVM_NONE)
  endfunction
endclass

// ===================== Env =====================
class fifo_env extends uvm_env;
  `uvm_component_utils(fifo_env)
  fifo_agent      agent;
  fifo_scoreboard sb;
  fifo_coverage   cov;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = fifo_agent::type_id::create("agent", this);
    sb    = fifo_scoreboard::type_id::create("sb", this);
    cov   = fifo_coverage::type_id::create("cov", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    agent.mon.ap.connect(sb.imp);
    agent.mon.ap.connect(cov.analysis_export);
  endfunction
endclass
