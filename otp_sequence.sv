class otp_latch_sequence extends uvm_sequence #(otp_seq_item);
  `uvm_object_utils(otp_latch_sequence)
  
  function new(string name="otp_latch_sequence");
    super.new(name);
  endfunction
  
  virtual task body();
    otp_seq_item item;
    item = otp_seq_item::type_id::create("latch");
    start_item(item);
    item.randomize() with {otp_latch == 1;user_latch == 0;};
    `uvm_info(get_type_name(), $sformatf("[%0t] Driving OTP Latch: otp_latch=%0b, user_latch=%0b", $time, item.otp_latch, item.user_latch), UVM_LOW);
    finish_item(item);
    item = otp_seq_item::type_id::create("latch");
    start_item(item);
    item.randomize() with {otp_latch == 0;user_latch == 0;};
    `uvm_info(get_type_name(), $sformatf("[%0t] Driving OTP Latch Release: otp_latch=%0b, user_latch=%0b", $time, item.otp_latch, item.user_latch), UVM_LOW);
    finish_item(item);
  endtask
endclass

class otp_input_sequence extends uvm_sequence #(otp_seq_item);
  `uvm_object_utils(otp_input_sequence)
  
  function new(string name="otp_input_sequence");
    super.new(name);
  endfunction
  
  virtual task body();
    otp_seq_item item;
    repeat(4) begin
      item = otp_seq_item::type_id::create("digit");
      start_item(item);
      item.randomize() with {user_latch == 1; user_in inside {[0:9]};};
      `uvm_info(get_type_name(), $sformatf("[%0t] Driving User Input: user_latch=%0b, user_in=%0d", $time, item.user_latch, item.user_in), UVM_LOW);
      finish_item(item);
      item = otp_seq_item::type_id::create("digit");
      start_item(item);
      item.randomize() with {user_latch == 0;};
      `uvm_info(get_type_name(), $sformatf("[%0t] Driving User Input Release: user_latch=%0b", $time, item.user_latch), UVM_LOW);
      finish_item(item);
    end
  endtask
endclass

class expire_50_sequence extends uvm_sequence #(otp_seq_item);
  `uvm_object_utils(expire_50_sequence)

  function new(string name="expire_50_sequence");
    super.new(name);
  endfunction
  
  virtual task body();
    otp_seq_item item;
    item = otp_seq_item::type_id::create("latch");
    start_item(item);
    item.randomize() with {otp_latch == 1;user_latch == 0;};
    `uvm_info(get_type_name(), $sformatf("[%0t] Driving OTP Latch: otp_latch=%0b, user_latch=%0b", $time, item.otp_latch, item.user_latch), UVM_LOW);
    finish_item(item);
    item = otp_seq_item::type_id::create("latch");
    start_item(item);
    item.randomize() with {otp_latch == 0;user_latch == 0;};
    `uvm_info(get_type_name(), $sformatf("[%0t] Driving OTP Latch Release: otp_latch=%0b, user_latch=%0b", $time, item.otp_latch, item.user_latch), UVM_LOW);
    finish_item(item);
    #51s;
    `uvm_info(get_type_name(), $sformatf("[%0t] 50+ second timer expired", $time), UVM_LOW);
  endtask
endclass


class otp_mismatch_then_match_sequence extends uvm_sequence #(otp_seq_item);
  `uvm_object_utils(otp_mismatch_then_match_sequence)
  
  function new(string name="otp_mismatch_then_match_sequence");
    super.new(name);
  endfunction
  
  virtual task body();
    otp_seq_item item;
    item = otp_seq_item::type_id::create("latch");
    start_item(item);
    item.randomize() with {otp_latch == 1;user_latch == 0;};
    `uvm_info(get_type_name(), $sformatf("[%0t] Driving OTP Latch: otp_latch=%0b, user_latch=%0b", $time, item.otp_latch, item.user_latch), UVM_LOW);
    finish_item(item);
    item = otp_seq_item::type_id::create("latch");
    start_item(item);
    item.randomize() with {otp_latch == 0;user_latch == 0;};
    `uvm_info(get_type_name(), $sformatf("[%0t] Driving OTP Latch Release: otp_latch=%0b, user_latch=%0b", $time, item.otp_latch, item.user_latch), UVM_LOW);
    finish_item(item);
   
    repeat(4) begin
      item = otp_seq_item::type_id::create("digit");
      start_item(item);
      item.randomize() with {user_latch == 1; user_in inside {[0:9]};};
      `uvm_info(get_type_name(), $sformatf("[%0t] Driving User Input: user_latch=%0b, user_in=%0d", $time, item.user_latch, item.user_in), UVM_LOW);
      finish_item(item);
      item = otp_seq_item::type_id::create("digit");
      start_item(item);
      item.randomize() with {user_latch == 0;};
      `uvm_info(get_type_name(), $sformatf("[%0t] Driving User Input Release: user_latch=%0b", $time, item.user_latch), UVM_LOW);
      finish_item(item);
    end
  
    item = otp_seq_item::type_id::create("match_digit");
    start_item(item);
    item.randomize() with {
      user_latch == 1; 
      user_in == 1;  
    };
    `uvm_info(get_type_name(), $sformatf("[%0t] Driving User Input Match: user_latch=%0b, user_in=%0d", $time, item.user_latch, item.user_in), UVM_LOW);
    finish_item(item);

    item = otp_seq_item::type_id::create("match_digit");
    start_item(item);
    item.randomize() with {
      user_latch == 0; 
    };
    `uvm_info(get_type_name(), $sformatf("[%0t] Driving User Input Release: user_latch=%0b", $time, item.user_latch), UVM_LOW);
    finish_item(item);

    item = otp_seq_item::type_id::create("match_digit");
    start_item(item);
    item.randomize() with {
      user_latch == 1; 
      user_in == 2;  
    };
    `uvm_info(get_type_name(), $sformatf("[%0t] Driving User Input Match: user_latch=%0b, user_in=%0d", $time, item.user_latch, item.user_in), UVM_LOW);
    finish_item(item);

    item = otp_seq_item::type_id::create("match_digit");
    start_item(item);
    item.randomize() with {
      user_latch == 0; 
    };
    `uvm_info(get_type_name(), $sformatf("[%0t] Driving User Input Release: user_latch=%0b", $time, item.user_latch), UVM_LOW);
    finish_item(item);

    item = otp_seq_item::type_id::create("match_digit");
    start_item(item);
    item.randomize() with {
      user_latch == 1; 
      user_in == 3;  
    };
    `uvm_info(get_type_name(), $sformatf("[%0t] Driving User Input Match: user_latch=%0b, user_in=%0d", $time, item.user_latch, item.user_in), UVM_LOW);
    finish_item(item);

    item = otp_seq_item::type_id::create("match_digit");
    start_item(item);
    item.randomize() with {
      user_latch == 0; 
    };
    `uvm_info(get_type_name(), $sformatf("[%0t] Driving User Input Release: user_latch=%0b", $time, item.user_latch), UVM_LOW);
    finish_item(item);
  
    item = otp_seq_item::type_id::create("match_digit");
    start_item(item);
    item.randomize() with {
      user_latch == 1; 
      user_in == 4;  
    };
    `uvm_info(get_type_name(), $sformatf("[%0t] Driving User Input Match: user_latch=%0b, user_in=%0d", $time, item.user_latch, item.user_in), UVM_LOW);
    finish_item(item);

    item = otp_seq_item::type_id::create("match_digit");
    start_item(item);
    item.randomize() with {
      user_latch == 0; 
    };
    `uvm_info(get_type_name(), $sformatf("[%0t] Driving User Input Release: user_latch=%0b", $time, item.user_latch), UVM_LOW);
    finish_item(item);
  endtask
endclass
