//1. Base test: Latch OTP and random user input in the first attempt.
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

//2. First attempt match test: Latch OTP and provide matching user input in the first attempt.
class otp_first_attempt_match extends uvm_test;
  `uvm_component_utils(otp_first_attempt_match)
  otp_env env;
  otp_latch_sequence otp_latch_seq;
  otp_match_sequence match_seq;

  function new(string name = "otp_first_attempt_match", uvm_component parent=null);
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
    otp_latch_seq = otp_latch_sequence::type_id::create("otp_latch_seq");
    match_seq = otp_match_sequence::type_id::create("match_seq");

    otp_latch_seq.start(env.active_agent.sequencer);
    match_seq.start(env.active_agent.sequencer);
    #2s;
    phase.drop_objection(this);
  endtask
endclass

//3. Second attempt match test: Latch OTP, provide one non-matching user input, then a matching one.
class otp_second_attempt_match_test extends uvm_test;
  `uvm_component_utils(otp_second_attempt_match_test)
  otp_env env;
  otp_latch_sequence otp_seq;
  otp_input_sequence user_in_seq;
  otp_match_sequence match_seq;

  function new(string name = "otp_second_attempt_match_test", uvm_component parent=null);
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
    match_seq = otp_match_sequence::type_id::create("match_seq");

    otp_seq.start(env.active_agent.sequencer);
    user_in_seq.start(env.active_agent.sequencer);
    match_seq.start(env.active_agent.sequencer);
    #2s;
    phase.drop_objection(this);
  endtask
endclass

//4. Third attempt match test: Latch OTP, provide two non-matching user inputs, then a matching one.
class otp_third_attempt_match_test extends uvm_test;
  `uvm_component_utils(otp_third_attempt_match_test)
  otp_env env;
  otp_latch_sequence otp_latch_seq;
  otp_input_sequence user_in_seq;
  otp_match_sequence match_seq;

  function new(string name = "otp_third_attempt_match_test", uvm_component parent=null);
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
    otp_latch_seq = otp_latch_sequence::type_id::create("otp_latch_seq");
    user_in_seq = otp_input_sequence::type_id::create("user_in_seq");
    match_seq = otp_match_sequence::type_id::create("match_seq");
    otp_latch_seq.start(env.active_agent.sequencer);
    repeat(2) begin
      user_in_seq.start(env.active_agent.sequencer);
      #2s;
    end
    match_seq.start(env.active_agent.sequencer);
    phase.drop_objection(this);
  endtask
endclass

//5. OTP Locked test: Latch OTP and provide three non-matching user inputs.
class otp_locked_test extends uvm_test;
  `uvm_component_utils(otp_locked_test)
  otp_env env;
  otp_latch_sequence otp_seq;
  otp_input_sequence user_in_seq;

  function new(string name = "otp_locked_test", uvm_component parent=null);
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
    repeat(3) begin
      user_in_seq.start(env.active_agent.sequencer);
      #2s;
    end
    phase.drop_objection(this);
  endtask
endclass

//6. OTP Expire 50 test: Latch OTP and wait for 50 time units before providing user input.
class otp_expire_50_test extends uvm_test;
  `uvm_component_utils(otp_expire_50_test)
  otp_env env;
  otp_latch_sequence otp_seq;
  otp_input_sequence user_in_seq;

  function new(string name = "expire_50_test", uvm_component parent=null);
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
    #50s;
    phase.drop_objection(this);
  endtask
endclass

//7. OTP Out of Range test: Latch OTP and provide out-of-range user input.
class otp_out_of_range_test extends uvm_test;
  `uvm_component_utils(otp_out_of_range_test)
  otp_env env;
  otp_latch_sequence otp_seq;
  otp_out_of_range_sequence user_in_seq;

  function new(string name = "otp_out_of_range_test", uvm_component parent=null);
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
    user_in_seq = otp_out_of_range_sequence::type_id::create("user_in_seq");

    otp_seq.start(env.active_agent.sequencer);
    user_in_seq.start(env.active_agent.sequencer);
    #1s;
    phase.drop_objection(this);
  endtask
endclass

//8. OTP User Latch High test: Latch OTP with user_latch high and provide user input.
class otp_user_latch_high_test extends uvm_test;
  `uvm_component_utils(otp_user_latch_high_test)
  otp_env env;
  otp_latch_sequence otp_seq;
  otp_user_latch_high_sequence user_in_seq;

  function new(string name = "otp_user_latch_high_test", uvm_component parent=null);
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
    user_in_seq = otp_user_latch_high_sequence::type_id::create("user_in_seq");

    otp_seq.start(env.active_agent.sequencer);
    user_in_seq.start(env.active_agent.sequencer);
    #1s;
    phase.drop_objection(this);
  endtask

endclass

//9. OTP Latch Low test: otp_latch is kept 0 and provide user_latch, user input.
class otp_latch_low_test extends uvm_test;
  `uvm_component_utils(otp_latch_low_test)
  otp_env env;
  otp_latch_low_sequence otp_seq;
  otp_input_sequence user_in_seq;

  function new(string name = "otp_latch_low_test", uvm_component parent=null);
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
    otp_seq = otp_latch_low_sequence::type_id::create("otp_seq");
    user_in_seq = otp_input_sequence::type_id::create("user_in_seq");

    otp_seq.start(env.active_agent.sequencer);
    user_in_seq.start(env.active_agent.sequencer);
    #1s;
    phase.drop_objection(this);
  endtask
endclass

//10. OTP Latch In Between test: Latch OTP, provide user input, latch OTP again.
class otp_latch_in_between_test extends uvm_test;
  `uvm_component_utils(otp_latch_in_between_test)
  otp_env env;
  otp_latch_sequence otp_seq;
  otp_input_sequence user_in_seq;

  function new(string name = "otp_latch_in_between_test", uvm_component parent=null);
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
    otp_seq.start(env.active_agent.sequencer);
    #1s;
    phase.drop_objection(this);
  endtask
endclass

class regression_test extends uvm_test;
  `uvm_component_utils(regression_test)
  otp_env env;
  otp_latch_sequence otp_latch_seq;
  otp_match_sequence match_seq;
  otp_input_sequence user_in_seq;

  function new(string name = "regression_test", uvm_component parent=null);
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
    otp_latch_seq = otp_latch_sequence::type_id::create("otp_latch_seq");
    match_seq = otp_match_sequence::type_id::create("match_seq");
    user_in_seq = otp_input_sequence::type_id::create("user_in_seq");

    otp_latch_seq.start(env.active_agent.sequencer);
    match_seq.start(env.active_agent.sequencer);
    #4s;
    // 13 secs
    // Now run the otp_locked_test part
    otp_latch_seq.start(env.active_agent.sequencer);
    //15 secs
    repeat(3) begin
      user_in_seq.start(env.active_agent.sequencer);
      //24+15=39 secs
    end
    #7s;
    phase.drop_objection(this);
  endtask
endclass  