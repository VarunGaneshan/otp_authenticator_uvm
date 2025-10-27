class otp_env extends uvm_env;
  `uvm_component_utils(otp_env)
  
  otp_passive_agent passive_agent;
  otp_active_agent active_agent;
  otp_scoreboard scoreboard;
  otp_subscriber subscriber;

  function new(string name="otp_env",uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    passive_agent = otp_passive_agent::type_id::create("passive_agent", this);
    active_agent = otp_active_agent::type_id::create("active_agent", this);
    scoreboard = otp_scoreboard::type_id::create("scoreboard", this);
    subscriber = otp_subscriber::type_id::create("subscriber", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    passive_agent.monitor.mon_port.connect(scoreboard.op_fifo.analysis_export);
    passive_agent.monitor.mon_port.connect(subscriber.op_fifo.analysis_export);
    active_agent.monitor.mon_port.connect(scoreboard.ip_fifo.analysis_export);
    active_agent.monitor.mon_port.connect(subscriber.ip_fifo.analysis_export);
  endfunction

endclass


