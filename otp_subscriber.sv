class otp_subscriber extends uvm_component;
    `uvm_component_utils(otp_subscriber)
  
    otp_seq_item ip_trans,op_trans;
    real ip_cov, op_cov;
    int op_val, count_ip , count_op;
    bit status;
    uvm_tlm_analysis_fifo #(otp_seq_item) ip_fifo;
    uvm_tlm_analysis_fifo #(otp_seq_item) op_fifo;

  covergroup ip_cg;     
        user_in: coverpoint ip_trans.user_in iff(ip_trans.user_latch) {
            bins valid_low   = {[0:2]};    // S bins: 0-2
            bins valid_mid   = {[3:5]};    // M bins: 3-5
            bins valid_high  = {[6:9]};    // L bins: 6-9
            illegal_bins illegal_digits  = {[10:15]};  // Illegal bins
        }
        
        otp_latch_transitions: coverpoint ip_trans.otp_latch {
            bins latch_0_to_1 = (0 => 1);
            bins latch_1_to_0 = (1 => 0);
        }

        user_latch_transitions: coverpoint ip_trans.user_latch {
            bins latch_0_to_1 = (0 => 1);
            bins latch_1_to_0 = (1 => 0);
        }

        user_in_x_user_latch: cross user_in, user_latch_transitions { //only consider 0_to_1
            bins latch_0_to_1_low = binsof(user_in.valid_low) && binsof(user_latch_transitions.latch_0_to_1);
            bins latch_0_to_1_mid = binsof(user_in.valid_mid) && binsof(user_latch_transitions.latch_0_to_1);
            bins latch_0_to_1_high = binsof(user_in.valid_high) && binsof(user_latch_transitions.latch_0_to_1);
            illegal_bins latch_0_to_1_illegal = binsof(user_latch_transitions.latch_1_to_0);
        }
  endgroup
   
  covergroup op_cg;
        lfsr_out: coverpoint op_trans.lfsr_out {
            bins valid_low   = {[0:2]};    // S bins: 0-2
            bins valid_mid   = {[3:5]};    // M bins: 3-5
            bins valid_high  = {[6:9]};    // L bins: 6-9
            bins attempt_no[]   = {[1:3]};   
            bins locked = {10};
            bins unlocked = {11};
            bins expired = {12};
            bins dash = {13};
            bins attempt = {14};
            bins off = {15};
        }
        user_out: coverpoint op_trans.user_out {
            bins valid_low   = {[0:2]};    
            bins valid_mid   = {[3:5]};   
            bins valid_high  = {[6:9]};   
        }
        cp_an: coverpoint op_trans.an {
            bins an[] = {[0:3]};
        }
  endgroup

  function new(string name = "otp_subscriber", uvm_component parent=null);
    super.new(name, parent);
    ip_cg = new();
    op_cg = new();
    ip_fifo = new("ip_fifo", this);
    op_fifo = new("op_fifo", this);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    fork
      forever begin
        ip_fifo.get(ip_trans);
        ip_cg.sample();
      end

      forever begin
        op_fifo.get(op_trans);
        case(op_trans.user_out)
            7'b1000000: op_trans.user_out = 7'd0;
            7'b1111001: op_trans.user_out = 7'd1;
            7'b0100100: op_trans.user_out = 7'd2;
            7'b0110000: op_trans.user_out = 7'd3;
            7'b0011001: op_trans.user_out = 7'd4;
            7'b0010010: op_trans.user_out = 7'd5;
            7'b0000010: op_trans.user_out = 7'd6;
            7'b1111000: op_trans.user_out = 7'd7;
            7'b0000000: op_trans.user_out = 7'd8;
            7'b0010000: op_trans.user_out = 7'd9;
            7'b1111111: op_trans.user_out = 7'd15; 
      endcase

        case(op_trans.lfsr_out)
            7'b1000000: op_trans.lfsr_out = 7'd0;
            7'b1111001: op_trans.lfsr_out = 7'd1;
            7'b0100100: op_trans.lfsr_out = 7'd2;
            7'b0110000: op_trans.lfsr_out = 7'd3;
            7'b0011001: op_trans.lfsr_out = 7'd4;
            7'b0010010: op_trans.lfsr_out = 7'd5;
            7'b0000010: op_trans.lfsr_out = 7'd6;
            7'b1111000: op_trans.lfsr_out = 7'd7;
            7'b0000000: op_trans.lfsr_out = 7'd8;
            7'b0010000: op_trans.lfsr_out = 7'd9;
            7'b1000111: op_trans.lfsr_out = 7'd10; // L
            7'b1000001: op_trans.lfsr_out = 7'd11; // U
            7'b0000110: op_trans.lfsr_out = 7'd12; // E
            7'b0111111: op_trans.lfsr_out = 7'd13; // -
            7'b0001000: op_trans.lfsr_out = 7'd14; // A
            7'b1111111: op_trans.lfsr_out = 7'd15; // OFF
      endcase
        op_cg.sample();
      end
    join
  endtask

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    ip_cov = ip_cg.get_coverage();
    op_cov = op_cg.get_coverage();

    `uvm_info(get_type_name(), $sformatf("COVERAGE SUMMARY:"), UVM_LOW);
    `uvm_info(get_type_name(), $sformatf("  I/P Coverage: %.2f%%", ip_cov), UVM_LOW);
    `uvm_info(get_type_name(), $sformatf("  O/P Coverage:  %.2f%%", op_cov), UVM_LOW);
    `uvm_info(get_type_name(), $sformatf("  Overall Coverage: %.2f%%", (ip_cov + op_cov)/2), UVM_LOW);
  endfunction

endclass

