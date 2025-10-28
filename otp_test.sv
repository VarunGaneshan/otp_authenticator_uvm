class otp_base_test extends uvm_test;
  `uvm_component_utils(otp_base_test)
  otp_env env;
  otp_latch_sequence otp_seq;
  otp_input_sequence user_in_seq;

  function new(string name = "otp_base_test", uvm_component parent=null);
    super.new(name,parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = otp_env::type_id::create("env", this);
  endfunction

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    otp_seq = otp_latch_sequence::type_id::create("otp_seq");
    user_in_seq = otp_input_sequence::type_id::create("user_in_seq");
    otp_seq.start(env.active_agent.sequencer);
    user_in_seq.start(env.active_agent.sequencer);
    #5ms;
    phase.drop_objection(this);
  endtask
endclass



