class otp_passive_monitor extends uvm_monitor;
    `uvm_component_utils(otp_passive_monitor)
    virtual otp_if vif;
    uvm_analysis_port#(otp_seq_item) mon_port;
    otp_seq_item mon_trans;

  function new(string name="otp_passive_monitor", uvm_component parent=null);
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
    #0.25ms;
    forever begin	
      @(vif.pas_mon_cb);
      monitor_dut();
      mon_port.write(mon_trans);
      #0.5ms; 
   end
  endtask             
         
  virtual task monitor_dut();
    mon_trans.user_out = vif.pas_mon_cb.user_out;
    mon_trans.lfsr_out = vif.pas_mon_cb.lfsr_out;
    mon_trans.an = vif.pas_mon_cb.an;
    //`uvm_info(get_type_name(), $sformatf("[%0t] Captured Outputs: user_out=%b, lfsr_out=%b, an=%0d", $time, mon_trans.user_out, mon_trans.lfsr_out, mon_trans.an), UVM_LOW);
  endtask
endclass
