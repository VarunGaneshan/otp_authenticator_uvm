class otp_active_agent extends uvm_agent;
  	`uvm_component_utils(otp_active_agent)
	otp_driver driver;
	otp_sequencer sequencer;
	otp_active_monitor monitor;

  	function new(string name = "otp_active_agent", uvm_component parent);
		super.new(name,parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		driver = otp_driver::type_id::create("driver",this);
		sequencer = otp_sequencer::type_id::create("sequencer",this);
		monitor = otp_active_monitor::type_id::create("monitor",this);
	endfunction

	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		driver.seq_item_port.connect(sequencer.seq_item_export);
	endfunction
endclass

