class fifo_base_test extends uvm_test;
  `uvm_component_utils(fifo_base_test)
  fifo_env env;

  function new(string name = "fifo_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = fifo_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    fifo_fill_seq  fill;
    fifo_drain_seq drain;
    fifo_simul_seq simul;
    fifo_rand_seq  rnd;

    phase.raise_objection(this);

    fill  = fifo_fill_seq ::type_id::create("fill");   fill.n  = 10;  fill.start(env.agent.sqr);   // fill + write-when-full
    simul = fifo_simul_seq::type_id::create("simul");  simul.n = 20;  simul.start(env.agent.sqr);  // wr+rd while full
    drain = fifo_drain_seq::type_id::create("drain");  drain.n = 12;  drain.start(env.agent.sqr);  // drain + read-when-empty

    rnd = fifo_rand_seq::type_id::create("rnd_wr_heavy");
    rnd.n = 300; rnd.wr_w = 70; rnd.rd_w = 30;  rnd.start(env.agent.sqr);
    rnd = fifo_rand_seq::type_id::create("rnd_rd_heavy");
    rnd.n = 300; rnd.wr_w = 30; rnd.rd_w = 70;  rnd.start(env.agent.sqr);

    #100ns;  // let the last read reach the scoreboard
    phase.drop_objection(this);
  endtask
endclass
