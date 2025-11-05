class otp_passive_agent extends uvm_agent;
  	`uvm_component_utils(otp_passive_agent)
	otp_passive_monitor monitor;

  	function new(string name = "otp_passive_agent", uvm_component parent);
		super.new(name,parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		monitor = otp_passive_monitor::type_id::create("monitor",this);
	endfunction
endclass
