class otp_active_monitor extends uvm_monitor;
  `uvm_component_utils(otp_active_monitor)
    virtual otp_if vif;
    uvm_analysis_port#(otp_seq_item) mon_port;
    otp_seq_item mon_trans;

  function new(string name="otp_active_monitor", uvm_component parent=null);
    super.new(name, parent);
    mon_trans = new();
    mon_port = new("mon_port", this);
  endfunction
   
  virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if(!uvm_config_db#(virtual otp_if)::get(this, "", "vif", vif)) begin
        `uvm_fatal("NOVIF", "No virtual interface found");
      end
  endfunction
 
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    @(posedge vif.act_mon_cb.reset_n);
    `uvm_info(get_type_name(), $sformatf("[%0t] Monitor: Reset De-asserted",$time), UVM_LOW);
    @(vif.act_mon_cb);
   
    forever begin
      monitor_dut();
      mon_port.write(mon_trans);
      #1s;
      //one_sec_delay();
    end
  endtask            
    
  virtual task monitor_dut();
    mon_trans.user_in = vif.act_mon_cb.user_in;
    mon_trans.otp_latch = vif.act_mon_cb.otp_latch;
    mon_trans.user_latch = vif.act_mon_cb.user_latch;
    `uvm_info(get_type_name(), $sformatf("[%0t] Captured inputs: user_in=%0d, otp_latch=%0b, user_latch=%0b", $time, mon_trans.user_in, mon_trans.otp_latch, mon_trans.user_latch), UVM_LOW);
  endtask
 
endclass

 
/*task one_sec_delay();
  int cycle_count = 0;
  `uvm_info("monitor", "Signals applied, waiting 1 second...", UVM_MEDIUM);

        while (cycle_count < `CYCLES_PER_SECOND) begin
            @(posedge vif.clk);
            cycle_count++;
        end

  `uvm_info("monitor", "1 second wait completed", UVM_MEDIUM);
endtask*/

