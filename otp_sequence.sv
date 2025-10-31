//1. OTP Latch Sequence: Latch OTP and release.
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

//2. OTP Input Sequence: Provide 4 random user inputs with user latch and then release.
class otp_input_sequence extends uvm_sequence #(otp_seq_item);
  `uvm_object_utils(otp_input_sequence)
  
  function new(string name="otp_input_sequence");
    super.new(name);
  endfunction
  
  virtual task body();
    otp_seq_item item;
   repeat (4) begin
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

//3. OTP Match Sequence: Provide 4 matching user inputs with user latch and then release.
class otp_match_sequence extends uvm_sequence #(otp_seq_item);
  `uvm_object_utils(otp_match_sequence)

  function new(string name="otp_match_sequence");
    super.new(name);
  endfunction
  
  virtual task body();
    otp_seq_item item;
  
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
      user_in == 8;  
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
      user_in == 5;  
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

//4. OTP Out of Range Sequence: Provide 4 out-of-range user inputs with user latch and then release.
class otp_out_of_range_sequence extends uvm_sequence #(otp_seq_item);
  `uvm_object_utils(otp_out_of_range_sequence)

  function new(string name="otp_out_of_range_sequence");
    super.new(name);    
  endfunction
        
  virtual task body();                                                             
    otp_seq_item item;           
   repeat (4) begin
      item = otp_seq_item::type_id::create("digit");
      start_item(item);
      item.randomize() with {user_latch == 1; user_in inside {[10:15]};};
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

//5. OTP User Latch High Sequence: Provide 4 random user inputs with user latch high.continously (user_latch=1_) 
class otp_user_latch_high_sequence extends uvm_sequence #(otp_seq_item);
  `uvm_object_utils(otp_user_latch_high_sequence)

  function new(string name="otp_user_latch_high_sequence");
    super.new(name);
  endfunction
  
  virtual task body();
    otp_seq_item item;
   repeat (4) begin
      item = otp_seq_item::type_id::create("digit");
      start_item(item);
      item.randomize() with {user_latch == 1; user_in inside {[0:9]};};
      `uvm_info(get_type_name(), $sformatf("[%0t] Driving User Input: user_latch=%0b, user_in=%0d", $time, item.user_latch, item.user_in), UVM_LOW);
      finish_item(item);
    end
  endtask
endclass

//6. OTP Latch Low Sequence: otp_latch is kept 0 and provide user_latch, user input.
class otp_latch_low_sequence extends uvm_sequence #(otp_seq_item);
  `uvm_object_utils(otp_latch_low_sequence)

  function new(string name="otp_latch_low_sequence");
    super.new(name);
  endfunction
  
  virtual task body();
    otp_seq_item item;
    item = otp_seq_item::type_id::create("latch");
    start_item(item);
    item.randomize() with {otp_latch == 0;};
    `uvm_info(get_type_name(), $sformatf("[%0t] Driving OTP Latch: otp_latch=%0b, user_latch=%0b", $time, item.otp_latch, item.user_latch), UVM_LOW);
    finish_item(item);
  endtask
endclass

