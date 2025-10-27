class otp_seq_item extends uvm_sequence_item;
  rand logic user_latch;
  rand logic otp_latch;
  rand logic [3:0] user_in;
  logic [1:0] an;
  logic [6:0] user_out;
  logic [6:0] lfsr_out;

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

