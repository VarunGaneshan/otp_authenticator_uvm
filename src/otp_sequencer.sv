class otp_sequencer extends uvm_sequencer #(otp_seq_item);
  `uvm_component_utils(otp_sequencer)
  
  function new(string name = "otp_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
endclass
