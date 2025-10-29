class otp_seq_item extends uvm_sequence_item;
  rand bit user_latch;
  rand bit otp_latch;
  rand bit [3:0] user_in;
  bit [1:0] an;
  bit [6:0] user_out;
  bit [6:0] lfsr_out;

  function new(string name="otp_seq_item");
    super.new(name);
  endfunction

  `uvm_object_utils_begin(otp_seq_item)
    `uvm_field_int(user_latch,UVM_ALL_ON);
    `uvm_field_int(otp_latch,UVM_ALL_ON);
    `uvm_field_int(user_in,UVM_ALL_ON);
    `uvm_field_int(an,UVM_ALL_ON);
    `uvm_field_int(user_out,UVM_ALL_ON);
    `uvm_field_int(lfsr_out,UVM_ALL_ON);
  `uvm_object_utils_end
endclass

