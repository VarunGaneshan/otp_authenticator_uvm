class otp_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(otp_scoreboard)
   
    otp_seq_item ip_trans, op_trans;
    virtual otp_if vif;
   
    uvm_tlm_analysis_fifo #(otp_seq_item) ip_fifo;
    uvm_tlm_analysis_fifo #(otp_seq_item) op_fifo;
 
    int LFSR_PASS, LFSR_FAIL;
    int OTP_PASS, OTP_FAIL;
    int EXPIRY_PASS, EXPIRY_FAIL;
    int LOCK_PASS, LOCK_FAIL;
    int UNLOCK_PASS, UNLOCK_FAIL;
    int ATTEMPT_PASS, ATTEMPT_FAIL;
   
    parameter int MASTER_FREQ     = 50_000_000;        // 50 MHz master clock
    parameter int CLK_2KHZ_DIV    = MASTER_FREQ / (2 * 2000); // toggle every 12,500 cycles
    parameter int CLK_0_5HZ_DIV   = MASTER_FREQ / (2 * 0.5); //toggles every 50M cycles 2 sec
 
    bit clk_2khz, clk_0_5hz;
    bit [15:0] lfsr_reg;
    bit [15:0] lfsr_temp;
    bit [6:0] lfsr_exp [4];
    int attempt = 1;
    bit first_otp_latch = 1;
 
 
    //input variables
    bit [6:0] dut_ip_otp [4];
    bit [6:0] bcd_user_in;
   
    //output variables
    bit [6:0] dut_lfsr_data [4];
    bit [6:0] dut_lfsr_status [4];
    bit [6:0] dut_user_out [4];
    bit [6:0] bcd_attempt;
    bit flag_out = 0;
    bit unlock_flag = 0, lock_flag = 0, expire_flag = 0;
    int in_c = 0, out_c_lfsr = 0, out_c_status = 0, count_50sec = 2500000000; //50 sec at 50Mhz
    bit status_data = 0; // 0 - data , 1 - status
    bit otp_compare = 0, not_expire_flag = 0;
   
 
    function new(string name="otp_scoreboard", uvm_component parent=null);
            super.new(name, parent);  
            ip_fifo = new("ip_fifo", this);
            op_fifo = new("op_fifo", this);
       
            LFSR_PASS = 0; LFSR_FAIL = 0;
            OTP_PASS = 0; OTP_FAIL = 0;
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
 
    task automatic gen_divided_clocks();
 
        int count_2k = 0; //output capture happens in 2khz
        int count_0_5 = 0;  // 2 sec clock to capture 1st time
 
        forever begin
            @(vif.sb_cb); //based on 50Mhz clock
 
            count_2k++;
            count_0_5++;
 
 
            if (count_0_5 >= CLK_0_5HZ_DIV) begin
                clk_0_5hz = ~clk_0_5hz;
                count_0_5 = 0;
            end
            if (count_2k >= CLK_2KHZ_DIV) begin
                clk_2khz = ~clk_2khz;
                count_2k = 0;
            end
        end
    endtask
 task static gen_lfsr(
        input  bit reset,
        output bit [15:0] otp_value          
    );
        static bit [15:0] lfsr = 16'hACE1;
        bit tap;
        bit [3:0] q1, q2, q3, q4;
 
        if (!reset)
            lfsr = 16'hACE1;
        else begin
            tap = lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10] ^ lfsr[8] ^ lfsr[6];
            lfsr = {lfsr[14:0], tap};
        end
 
        q1 = lfsr[15:12] % 10;
        q2 = lfsr[11:8]  % 10;
        q3 = lfsr[7:4]   % 10;
        q4 = lfsr[3:0]   % 10;
        otp_value = {q1, q2, q3, q4};
    endtask
 
    task automatic convert_to_bcd(
        input  logic [3:0] user_in,    // decimal input 0–9
        output logic [6:0] bcd_out     // 7-segment encoded output
    );
        case (user_in)
            4'd0: bcd_out = 7'b1000000;
            4'd1: bcd_out = 7'b1111001;
            4'd2: bcd_out = 7'b0100100;
            4'd3: bcd_out = 7'b0110000;
            4'd4: bcd_out = 7'b0011001;
            4'd5: bcd_out = 7'b0010010;
            4'd6: bcd_out = 7'b0000010;
            4'd7: bcd_out = 7'b1111000;
            4'd8: bcd_out = 7'b0000000;
            4'd9: bcd_out = 7'b0010000;
            default: bcd_out = 7'b1111111; // all segments off (invalid input)
        endcase
    endtask
 
 
 
    task run_phase(uvm_phase phase);
        super.run_phase(phase);
 
        fork
            gen_divided_clocks();
 
            forever begin: input_process
                ip_fifo.get(ip_trans); //otp_latch,user_in,user_latch
                `uvm_info(get_type_name(), $sformatf("[%0t] IP_TRANS: otp_latch=%0b user_latch=%0b user_in=%0d", $time, ip_trans.otp_latch, ip_trans.user_latch,ip_trans.user_in), UVM_LOW);
               
                if(ip_trans.user_latch && attempt < 4 && in_c <= 3)begin
                    convert_to_bcd(ip_trans.user_in,bcd_user_in);
                    dut_ip_otp[in_c] = bcd_user_in;
                    in_c++;
                end
            end
 
            forever begin: output_process
                op_fifo.get(op_trans);
 
                 if(out_c_lfsr <= 4 && attempt < 4 && !status_data)begin
                    dut_lfsr_data[op_trans.an] = op_trans.lfsr_out;
                    out_c_lfsr++;
                 end
                 else if (out_c_status <= 4 && attempt < 4 && status_data) begin
                    dut_lfsr_status[op_trans.an] = op_trans.lfsr_out;
                    out_c_status++;
                 end
            end
 
            forever begin
                wait(in_c==4);
                    repeat(4)@(posedge clk_2khz)begin
                        dut_user_out[vif.sb_cb.an] = vif.sb_cb.user_out;
                    end
                    otp_compare = 1;
                    in_c = 0;
            end
           
 
            forever begin: toggle_lfsr_status
                status_data = 0; //means its data
                @(posedge clk_0_5hz); //2sec
                status_data = 1; //means its status
                @(posedge clk_0_5hz); //2sec
                status_data = 0; //means its data
            end
 
            // forever begin: count_50sec_process
            //     @(posedge vif.sb_cb);
            //     if(vif.sb_cb.otp_latch)begin
            //         `uvm_info(get_type_name(), $sformatf("[%0t] OTP LATCHED, Starting 50 sec count... count_50sec= %0d", $time, count_50sec), UVM_LOW);
            //         repeat(2500000000)begin
            //             @(posedge vif.sb_cb);
            //              `uvm_info(get_type_name(), $sformatf("[%0t] Counting for 50 sec expiry... count= %0d", $time, count_50sec), UVM_LOW);
            //             if(flag_out) break;
            //         end
            //         `uvm_info(get_type_name(), $sformatf("[%0t] 50 sec COUNT COMPLETED count_50sec= %0d", $time, count_50sec), UVM_LOW);
            //         expire_flag = 1;
            //         flag_out = 1;
            //     end
            // end
            forever begin: count_50sec_process
                @(vif.sb_cb);
                if(vif.sb_cb.otp_latch)begin
                    repeat(50_000_000)begin //50secs
                        repeat(50)begin
                        @(vif.sb_cb);//20ns
                        if(flag_out) begin //lock || unlock
                           not_expire_flag = 1;
                            break;
                        end
                        end
                        if(flag_out) break;
                    end
                    if(!not_expire_flag) begin
                        $display("[%0t] 50 SEC TIMEOUT EXPIRED,count:%0d", $time,count_50sec);
                        expire_flag = 1;
                        flag_out = 1;
                    end
                end
            end
 
            forever begin: compare_logic
                @(posedge clk_2khz); //compare at 2khz clock
                 //compare logic after 4 outputs captured
                 if(out_c_lfsr > 3 && !status_data)begin
                     out_c_lfsr = 0;
                    //LFSR compare
                    if(lfsr_exp == dut_lfsr_data) begin
                        LFSR_PASS++;
                         `uvm_info(get_type_name(), $sformatf("[%0t] LFSR [DATA] MATCH : DUT LFSR=%p, Expected LFSR=%p", $time, dut_lfsr_data, lfsr_exp), UVM_LOW);
                    end
                    else begin
                        LFSR_FAIL++;
                         `uvm_error(get_type_name(), $sformatf("[%0t] LFSR [DATA] MISMATCH : DUT LFSR=%p, Expected LFSR=%p", $time, dut_lfsr_data, lfsr_exp))
                    end
                 end
 
                    //User OTP compare
                 if(otp_compare)begin
                        if( dut_lfsr_data == dut_user_out)begin
                            OTP_PASS++;
                            `uvm_info(get_type_name(), $sformatf("[%0t] |||| OTP MATCH at ATTEMPT %0d ||||: DUT GEN OTP=%p, Input USER OTP=%p", $time, attempt,  dut_lfsr_data, dut_user_out), UVM_LOW);
                            unlock_flag = 1;
                            flag_out = 1;
                           
                        end
                        else begin
                            OTP_FAIL++;
                            if (attempt == 3)begin
                                lock_flag = 1;
                                flag_out = 1;
                            end
                            `uvm_error(get_type_name(), $sformatf("[%0t] |||| OTP MISMATCH at ATTEMPT %0d ||||: DUT GEN OTP=%p, Input USER OTP=%p", $time,attempt, dut_lfsr_data, dut_user_out));
                            if(attempt<3)
                                attempt++;
                        end
                        otp_compare = 0;
                       
                 end
                 else if( out_c_status > 3 && status_data)begin
                 
                    convert_to_bcd(attempt,bcd_attempt);
                    out_c_status = 0;
                   
 
                    if (flag_out)begin
                        if(unlock_flag)begin //A-1/2/3 U
                            if(dut_lfsr_status[0] ==  7'b1000001 &&
                            dut_lfsr_status[1] ==  7'b0111111 &&
                            dut_lfsr_status[2] ==  bcd_attempt &&
                            dut_lfsr_status[3] ==  7'b0001000)begin
                                UNLOCK_PASS++;
                                `uvm_info(get_type_name(), $sformatf("[%0t] //// DEVICE UNLOCKED at ATTEMPT %0d ////", $time, attempt), UVM_LOW);
                            //     `uvm_info(get_type_name(), $sformatf("[%0t] LFSR [STATUS] MATCH : DUT LFSR=%p, bcd=%p", $time, dut_lfsr_status, bcd_attempt), UVM_LOW);
                             end
                            else begin
                                UNLOCK_FAIL++;
                                `uvm_error(get_type_name(), $sformatf("[%0t] //// DEVICE UNLOCK STATUS MISMATCH at ATTEMPT %0d ////", $time, attempt));//attempt will be incremented already
                            end
                        end
                       
 
                        else if(lock_flag)begin// A-3 L
                            if(dut_lfsr_status[0] ==  7'b1000111 &&
                            dut_lfsr_status[1] ==  7'b0111111 &&
                            dut_lfsr_status[2] ==  bcd_attempt &&
                            dut_lfsr_status[3] ==  7'b0001000)begin
                                LOCK_PASS++;
                                `uvm_info(get_type_name(), $sformatf("[%0t] //// DEVICE LOCKED after 3 UNSUCCESSFUL attempts ////", $time), UVM_LOW);
                            end
                            else begin
                                LOCK_FAIL++;
                                `uvm_error(get_type_name(), $sformatf("[%0t] //// DEVICE LOCK STATUS MISMATCH after 3 UNSUCCESSFUL attempts ////", $time));
                            end
                        end
                        else if (expire_flag) begin // A - 1/2/3 E (expiry flag set after 50 sec)
                            if(dut_lfsr_status[0] ==  7'b0000110 &&
                            dut_lfsr_status[1] ==  7'b0111111 &&
                            dut_lfsr_status[2] ==  bcd_attempt &&
                            dut_lfsr_status[3] ==  7'b0001000)begin
                                EXPIRY_PASS++;
                                `uvm_info(get_type_name(), $sformatf("[%0t] //// DEVICE EXPIRED [50SEC] ////", $time), UVM_LOW);
                            end
                            else begin
                                EXPIRY_FAIL++;
                                `uvm_error(get_type_name(), $sformatf("[%0t] //// DEVICE EXPIRY STATUS MISMATCH ////", $time));
                            end
                        end
                    end
 
                    else begin //enter otp check only attempt here
                        if(dut_lfsr_status[0] ==   7'b1111111 &&
                            dut_lfsr_status[1] ==  7'b0111111 &&
                            dut_lfsr_status[2] ==  bcd_attempt &&
                            dut_lfsr_status[3] ==  7'b0001000)
                            begin
                                ATTEMPT_PASS++;
                                `uvm_info(get_type_name(), $sformatf("[%0t] ---- ATTEMPT %0d STATUS MATCH ----", $time, attempt), UVM_LOW);
                                // `uvm_info(get_type_name(), $sformatf("[%0t] LFSR status Match with SCB generated: DUT LFSR=%p, bcd=%p", $time, dut_lfsr_status, bcd_attempt), UVM_LOW);
                            end
                            else begin
                                ATTEMPT_FAIL++;
                                `uvm_error(get_type_name(), $sformatf("[%0t] ---- ATTEMPT %0d STATUS MISMATCH ----", $time, attempt));
                                // `uvm_info(get_type_name(), $sformatf("[%0t] LFSR status Mis-Match with SCB generated: DUT LFSR=%p, bcd=%p", $time, dut_lfsr_status, bcd_attempt), UVM_LOW);
                            end
                    end
                end
            end
       
 
           
            forever begin: flag_output
                @(posedge clk_2khz); //wait for 5 sec clock
                if(flag_out)begin
                        repeat(5 * MASTER_FREQ)@(posedge vif.sb_cb);
                        flag_out = 0;
                        unlock_flag = 0;
                        lock_flag = 0;
                        expire_flag = 0;
                        first_otp_latch = 1;
                        not_expire_flag = 0;
 
                        attempt = 1;
                        dut_lfsr_data = '{7'b1000000,7'b1000000,7'b1000000,7'b1000000};
                        lfsr_exp = '{7'b1000000,7'b1000000,7'b1000000,7'b1000000};
                        dut_user_out = '{7'b1000000,7'b1000000,7'b1000000,7'b1000000};
 
                    end
 
            end
 
           
 
            forever begin: lfsr_gen_process
                @(posedge vif.sb_cb or negedge vif.sb_cb.reset_n);
               
                gen_lfsr(vif.sb_cb.reset_n, lfsr_temp);
 
                if(first_otp_latch && vif.sb_cb.otp_latch)begin//for 1st latch only make it 0 after that till end of 3 attempts
                    lfsr_reg = lfsr_temp;
                    first_otp_latch = 0;
                    $display("[%0t] LFSR Generated Value Latched: %0h", $time, lfsr_reg);
 
                    convert_to_bcd(lfsr_reg[3:0],     lfsr_exp[0]);  // LSB
                    convert_to_bcd(lfsr_reg[7:4],     lfsr_exp[1]);
                    convert_to_bcd(lfsr_reg[11:8],    lfsr_exp[2]);
                    convert_to_bcd(lfsr_reg[15:12],   lfsr_exp[3]);  // MSB
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
        "OTP_PASS      = %0d\n",
        "OTP_FAIL      = %0d\n",
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
        OTP_PASS, OTP_FAIL,
        ATTEMPT_PASS, ATTEMPT_FAIL,
        LOCK_PASS, LOCK_FAIL,
        UNLOCK_PASS, UNLOCK_FAIL,
        EXPIRY_PASS, EXPIRY_FAIL), UVM_LOW)
    endfunction
endclass
 