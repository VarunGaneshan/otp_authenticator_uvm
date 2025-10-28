class otp_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(otp_scoreboard)

  otp_seq_item ip_trans, op_trans;
  virtual otp_if vif;

  int LFSR_PASS, LFSR_FAIL;
  int USER_OTP_PASS, USER_OTP_FAIL;
  int EXPIRY_PASS, EXPIRY_FAIL;
  int LOCK_PASS, LOCK_FAIL;
  int UNLOCK_PASS, UNLOCK_FAIL;
  int ATTEMPT_PASS, ATTEMPT_FAIL;

  parameter int MASTER_FREQ     = 50_000_000;        // 50 MHz master clock
  parameter int CLK_2KHZ_DIV    = MASTER_FREQ / (2 * 2000); // toggle every 12,500 cycles
  parameter int CLK_0_5HZ_DIV   = MASTER_FREQ / (2 * 0.5);  // toggle every 50 M cycles

  bit clk_2khz, clk_0_5hz;
  bit [15:0] lfsr_reg;
  bit [6:0] lfsr_exp [4]; //should be outside begin-end
  int attempt;
  uvm_tlm_analysis_fifo #(otp_seq_item) ip_fifo;
  uvm_tlm_analysis_fifo #(otp_seq_item) op_fifo;

  function new(string name="otp_scoreboard", uvm_component parent=null);
    super.new(name, parent);
    ip_fifo = new("ip_fifo", this);
    op_fifo = new("op_fifo", this);

    LFSR_PASS = 0; LFSR_FAIL = 0;
    USER_OTP_PASS = 0; USER_OTP_FAIL = 0;
    EXPIRY_PASS = 0; EXPIRY_FAIL = 0;
    LOCK_PASS = 0; LOCK_FAIL = 0;
    UNLOCK_PASS = 0; UNLOCK_FAIL = 0;
    ATTEMPT_PASS = 0; ATTEMPT_FAIL = 0;
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual otp_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "No virtual interface found");
  endfunction

  // 2 kHz for output capture, 0.5 Hz for status toggling
  task automatic gen_divided_clocks();
    int count_2k = 0;
    int count_05 = 0;

    forever begin
      @(posedge vif.clk);
      count_2k++;
      count_05++;

      if (count_2k >= CLK_2KHZ_DIV) begin
        clk_2khz = ~clk_2khz;
        count_2k = 0;
      end
      if (count_05 >= CLK_0_5HZ_DIV) begin
        clk_0_5hz = ~clk_0_5hz;
        count_05 = 0;
        `uvm_info(get_type_name(), $sformatf("[%0t] 0.5Hz clock toggled → Display mode: %s",
                  clk_0_5hz ? "STATUS (L/U/E)" : "OTP DIGITS", $time), UVM_LOW);
      end
    end
  endtask

  function automatic bit [15:0] gen_lfsr(input logic reset, input logic otp_latch);
    static logic [15:0] lfsr = 16'hACE1;
    logic tap;
    logic [15:0] lfsr_next;
    logic [3:0] q1, q2, q3, q4;

    if (!reset)
      lfsr = 16'hACE1;
    else if (!otp_latch) begin
      tap = lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10] ^ lfsr[8] ^ lfsr[6];
      lfsr_next = {lfsr[14:0], tap};
      lfsr = lfsr_next;
    end

    q1 = lfsr[15:12] % 10;
    q2 = lfsr[11:8]  % 10;
    q3 = lfsr[7:4]   % 10;
    q4 = lfsr[3:0]   % 10;
    return {q1, q2, q3, q4};
  endfunction

  task automatic start_timer(input logic master_clk, output bit flag);
    flag = 0;
    repeat (50) @(posedge master_clk);
    flag = 1;
  endtask

  function bit check_expiry_flag(input bit [6:0] seg, input bit [1:0] an, input int attempts);
    if (clk_0_5hz && an == 0 && seg == 7'b0000110 && attempts >= 3)
      return 1;
    else
      return 0;
  endfunction

  function bit check_lock_flag(input bit [6:0] seg, input bit [1:0] an);
    return (clk_0_5hz && an == 0 && seg == 7'b1000111); // L
  endfunction

  function bit check_unlock_flag(input bit [6:0] seg, input bit [1:0] an);
    return (clk_0_5hz && an == 0 && seg == 7'b1000001); // U
  endfunction

  function bit check_attempt_display(input bit [6:0] seg, input bit [1:0] an, input int attempts);
    bit [6:0] seg_expected [4];
    seg_expected[0] = 7'b1000000; // 0
    seg_expected[1] = 7'b1111001; // 1
    seg_expected[2] = 7'b0100100; // 2
    seg_expected[3] = 7'b0110000; // 3

    if (an == 1 && seg == seg_expected[attempts])
      return 1;
    else
      return 0;
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);

    fork
      gen_divided_clocks();

      begin
        //bit [6:0] lfsr_exp [4];
        bit [6:0] dut_lfsr [4];
        bit [6:0] dut_otp [4];
        int lfsr_c = 0, user_c = 0;

        forever begin
          @(posedge clk_2khz);
          ip_fifo.get(ip_trans);
          `uvm_info(get_type_name(), $sformatf("[%0t] IP_TRANS: otp_latch=%0b user_latch=%0b an=%0d", $time, ip_trans.otp_latch, ip_trans.user_latch, ip_trans.an), UVM_LOW);

          // LFSR check (shown when 0.5 Hz = 0)
          if (!clk_0_5hz && ip_trans.otp_latch) begin
            op_fifo.get(op_trans);
            `uvm_info(get_type_name(), $sformatf("[%0t] OP_TRANS(LFSR): an=%0d lfsr_out=%b", $time, op_trans.an, op_trans.lfsr_out), UVM_LOW);
            dut_lfsr[op_trans.an] = op_trans.lfsr_out;
            lfsr_c++;
            if (lfsr_c == 3) begin
              if (lfsr_exp == dut_lfsr) begin
                LFSR_PASS++;
                `uvm_info(get_type_name(), $sformatf("[%0t] LFSR matched expected sequence", $time), UVM_LOW);
              end else begin
                LFSR_FAIL++;
                `uvm_warning(get_type_name(), $sformatf("[%0t] LFSR mismatch detected", $time));
              end
              lfsr_c = 0;
            end
          end

          else if (!clk_0_5hz && ip_trans.user_latch && attempt < 3) begin
            op_fifo.get(op_trans);
            `uvm_info(get_type_name(), $sformatf("[%0t] OP_TRANS(USER): an=%0d user_out=%b", $time, op_trans.an, op_trans.user_out), UVM_LOW);
            dut_otp[op_trans.an] = op_trans.user_out;
            user_c++;

            if (user_c == 3) begin
              if (dut_otp == dut_lfsr) begin
                USER_OTP_PASS++;
                attempt = 0;
                `uvm_info(get_type_name(), $sformatf("[%0t] USER OTP matched LFSR sequence → UNLOCK check", $time), UVM_LOW);
                if (check_unlock_flag(op_trans.user_out, op_trans.an))
                  UNLOCK_PASS++;
                else
                  UNLOCK_FAIL++;
              end else begin
                USER_OTP_FAIL++;
                attempt++;
                `uvm_warning(get_type_name(), $sformatf("[%0t] OTP mismatch | Attempt #%0d", $time, attempt));

                if (check_attempt_display(op_trans.user_out, 1, attempt))
                  ATTEMPT_PASS++;
                else
                  ATTEMPT_FAIL++;

                if (attempt >= 3) begin
                  `uvm_info(get_type_name(), $sformatf("[%0t] 3 failed attempts → Checking LOCK", $time), UVM_LOW);
                  if (check_lock_flag(op_trans.user_out, op_trans.an))
                    LOCK_PASS++;
                  else
                    LOCK_FAIL++;
                end
              end
              user_c = 0;
            end
          end
        end
      end

      begin
        bit expire;
        forever begin
          @(posedge clk_0_5hz);
          ip_fifo.peek(ip_trans);
          op_fifo.peek(op_trans);
          if(ip_trans.otp_latch)
                start_timer(vif.clk, expire);
                if (expire) begin
                        if (check_expiry_flag(op_trans.lfsr_out, op_trans.an, attempt)) begin
                                EXPIRY_PASS++;
                                `uvm_info(get_type_name(), $sformatf("[%0t] Expiry condition PASS — 'E' detected", $time), UVM_LOW);
                        end else begin
                                EXPIRY_FAIL++;
                                `uvm_warning(get_type_name(), $sformatf("[%0t] Expiry check FAIL — expected 'E' not seen", $time));
                        end
                end
        end
      end

      begin
        forever begin
          @(posedge vif.sb_cb or negedge vif.sb_cb.reset_n);
          lfsr_reg = gen_lfsr(vif.sb_cb.reset_n, vif.sb_cb.otp_latch);
          case(lfsr_reg[3:0])
            0: lfsr_exp[0] = 7'b1000000;
            1: lfsr_exp[0] = 7'b1111001;
            2: lfsr_exp[0] = 7'b0100100;
            3: lfsr_exp[0] = 7'b0110000;
            4: lfsr_exp[0] = 7'b0011001;
            5: lfsr_exp[0] = 7'b0010010;
            6: lfsr_exp[0] = 7'b0000010;
            7: lfsr_exp[0] = 7'b1111000;
            8: lfsr_exp[0] = 7'b0000000;
            9: lfsr_exp[0] = 7'b0010000;
            default: lfsr_exp[3] = 7'b1111111;
          endcase
          case(lfsr_reg[7:4])
            0: lfsr_exp[1] = 7'b1000000;
            1: lfsr_exp[1] = 7'b1111001;
            2: lfsr_exp[1] = 7'b0100100;
            3: lfsr_exp[1] = 7'b0110000;
            4: lfsr_exp[1] = 7'b0011001;
            5: lfsr_exp[1] = 7'b0010010;
            6: lfsr_exp[1] = 7'b0000010;
            7: lfsr_exp[1] = 7'b1111000;
            8: lfsr_exp[1] = 7'b0000000;
            9: lfsr_exp[1] = 7'b0010000;
            default: lfsr_exp[1] = 7'b1111111;
          endcase
          case(lfsr_reg[11:8])
            0: lfsr_exp[2] = 7'b1000000;
            1: lfsr_exp[2] = 7'b1111001;
            2: lfsr_exp[2] = 7'b0100100;
            3: lfsr_exp[2] = 7'b0110000;
            4: lfsr_exp[2] = 7'b0011001;
            5: lfsr_exp[2] = 7'b0010010;
            6: lfsr_exp[2] = 7'b0000010;
            7: lfsr_exp[2] = 7'b1111000;
            8: lfsr_exp[2] = 7'b0000000;
            9: lfsr_exp[2] = 7'b0010000;
            default: lfsr_exp[2] = 7'b1111111;
          endcase
          case(lfsr_reg[15:12])
            0: lfsr_exp[3] = 7'b1000000;
            1: lfsr_exp[3] = 7'b1111001;
            2: lfsr_exp[3] = 7'b0100100;
            3: lfsr_exp[3] = 7'b0110000;
            4: lfsr_exp[3] = 7'b0011001;
            5: lfsr_exp[3] = 7'b0010010;
            6: lfsr_exp[3] = 7'b0000010;
            7: lfsr_exp[3] = 7'b1111000;
            8: lfsr_exp[3] = 7'b0000000;
            9: lfsr_exp[3] = 7'b0010000;
            default: lfsr_exp[3] = 7'b1111111;
          endcase
          `uvm_info(get_type_name(), $sformatf("[%0t] Generated Expected LFSR: %p", $time, lfsr_exp), UVM_LOW);
        end
      end
    join_none
  endtask

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), $sformatf({
      "\n================ OTP SCOREBOARD SUMMARY ================\n",
      "LFSR_PASS     = %0d\n",
      "LFSR_FAIL     = %0d\n",
      "USER_OTP_PASS = %0d\n",
      "USER_OTP_FAIL = %0d\n",
      "ATTEMPT_PASS  = %0d\n",
      "ATTEMPT_FAIL  = %0d\n",
      "LOCK_PASS     = %0d\n",
      "LOCK_FAIL     = %0d\n",
      "UNLOCK_PASS   = %0d\n",
      "UNLOCK_FAIL   = %0d\n",
      "EXPIRY_PASS   = %0d\n",
      "EXPIRY_FAIL   = %0d\n",
      "========================================================\n"
      },
      LFSR_PASS, LFSR_FAIL,
      USER_OTP_PASS, USER_OTP_FAIL,
      ATTEMPT_PASS, ATTEMPT_FAIL,
      LOCK_PASS, LOCK_FAIL,
      UNLOCK_PASS, UNLOCK_FAIL,
      EXPIRY_PASS, EXPIRY_FAIL), UVM_LOW)
  endfunction
endclass
 