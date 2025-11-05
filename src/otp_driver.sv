class otp_driver extends uvm_driver #(otp_seq_item);
  `uvm_component_utils(otp_driver)
  virtual otp_if vif;
  otp_seq_item drv_trans;
  
  function new(string name = "otp_drv", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual otp_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "Virtual interface not found in config_db");
  endfunction
  
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
	   /* if(!vif.reset_n)begin// wait until reset is de-asserted then drive inputs
				`uvm_info(get_type_name(),$sformatf("[%0t] DUT is in RESET=%0b !!!",$time,vif.reset_n),UVM_LOW);
				@(posedge vif.reset_n);
		end*/
    repeat(2) @(vif.drv_cb);
    forever begin
      seq_item_port.get_next_item(drv_trans);
      drive_transaction();
      seq_item_port.item_done();
    end
  endtask

  task drive_transaction();
	vif.drv_cb.user_in <= drv_trans.user_in;
	vif.drv_cb.otp_latch <= drv_trans.otp_latch;
	vif.drv_cb.user_latch <= drv_trans.user_latch;
	//@(vif.drv_cb); // Wait for the clocking block to update
	`uvm_info(get_type_name(), $sformatf("[%0t] Driving: user_in=%0d, otp_latch=%0b, user_latch=%0b",$time,
			drv_trans.user_in, drv_trans.otp_latch, drv_trans.user_latch), UVM_LOW);
	#1s; // Hold the signals for 1 second
  endtask

endclass


