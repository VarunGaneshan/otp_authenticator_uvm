/*class otp_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(otp_scoreboard)
    
    otp_seq_item ip_trans, op_trans;
    virtual otp_if vif;
    
    uvm_tlm_analysis_fifo #(otp_seq_item) ip_fifo;
    uvm_tlm_analysis_fifo #(otp_seq_item) op_fifo;

    int LFSR_PASS, LFSR_FAIL;
    int USER_OTP_PASS, USER_OTP_FAIL;
    int EXPIRY_PASS, EXPIRY_FAIL;
    int LOCK_PASS, LOCK_FAIL;
    int UNLOCK_PASS, UNLOCK_FAIL;
    int ATTEMPT_PASS, ATTEMPT_FAIL;
    
    parameter int MASTER_FREQ     = 50_000_000;        // 50 MHz master clock
    parameter int CLK_2KHZ_DIV    = MASTER_FREQ / (2 * 2000); // toggle every 12,500 cycles
    parameter int CLK_0_5HZ_DIV   = MASTER_FREQ / (2 * 0.5); //toggles every 50M cycles 2 sec
    parameter int CLK_0_1HZ_DIV   = (MASTER_FREQ * 5) / 2;  // toggle every 5 seconds
    parameter int CLK_0_01HZ_DIV  = (MASTER_FREQ * 50) / 2; // 50 seconds expiry time

    bit clk_2khz, clk_0_5hz, clk_0_1hz,clk_0_01hz;
    bit [15:0] lfsr_reg;
    bit [15:0] lfsr_temp;
    bit [6:0] lfsr_exp [4]; 
    int attempt = 1;
    bit flag_1s = 1;
    bit first_otp_latch = 1;
    bit  first_posedge_50 = 1;
    bit first_posedge_5 = 1;

    //input variables 
    bit [6:0] dut_ip_otp [4];
    bit [6:0] bcd_user_in;
    int lfsr_c = 0;
    
    //output variables
    bit [6:0] dut_lfsr_data [4];
    bit [6:0] dut_lfsr_status [4];
    bit [6:0] dut_user_out [4];
    bit [6:0] bcd_attempt;
    bit flag_out = 0;
    bit unlock_flag = 0, lock_flag = 0, expire_flag = 0;
    int in_c = 0, out_c_data = 0, out_c_status = 0;
    bit status_data = 0, start_status_data; // 0 - data , 1 - status 
  
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

    task automatic gen_divided_clocks();

        int count_2k = 0; //output capture happens in 2khz
        int count_0_5 = 0;  // 2 sec clock to capture 1st time 
        int count_0_1 = 0;  // 5 sec clock for hold time
        int count_0_01 = 0; //50 sec clock for expiry time

        forever begin
            @(posedge vif.clk); //based on 50Mhz clock

            count_2k++;
            count_0_5++;
            count_0_1++;
            count_0_01++;

            if (count_0_5 >= CLK_0_5HZ_DIV) begin
                clk_0_5hz = ~clk_0_5hz;
                count_0_5 = 0;
            end
            if (count_2k >= CLK_2KHZ_DIV) begin
                clk_2khz = ~clk_2khz;
                count_2k = 0;
            end
            if (count_0_1 >= CLK_0_1HZ_DIV) begin
                clk_0_1hz = ~clk_0_1hz;  // toggles every 5 seconds
                count_0_1 = 0;
            end
            if (count_0_01 >= CLK_0_01HZ_DIV) begin
                clk_0_01hz = ~clk_0_01hz; // toggles every 50 s
                count_0_01 = 0;
            end
        end
    endtask

    task automatic gen_lfsr(
        input  logic reset,
        input  logic otp_latch,
        output bit [15:0] otp_value        
    );
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
        
        `uvm_info(get_type_name(), "=== Scoreboard run_phase started ===", UVM_LOW);

        fork

            gen_divided_clocks();

            forever begin: input_process
                ip_fifo.get(ip_trans); //otp_latch,user_in,user_latch
                `uvm_info(get_type_name(), $sformatf("[%0t] IP_TRANS: otp_latch=%0b user_latch=%0b user_in=%0d", $time, ip_trans.otp_latch, ip_trans.user_latch,ip_trans.user_in), UVM_LOW);
                
                if(ip_trans.user_latch && attempt < 4 && in_c < 4)begin
                    convert_to_bcd(ip_trans.user_in,bcd_user_in);
                    dut_ip_otp[in_c] = bcd_user_in;
                    in_c++;
                    `uvm_info(get_type_name(), $sformatf("[%0t] Captured user input %0d at index %0d", $time, ip_trans.user_in, in_c-1), UVM_HIGH);
                end
            end

            forever begin: output_process
                op_fifo.get(op_trans);
                `uvm_info(get_type_name(), $sformatf("[%0t] OP_TRANS: an=%0d lfsr_out=%0b user_out=%0b", $time, op_trans.an, op_trans.lfsr_out,op_trans.user_out), UVM_LOW);
                 
                 if(out_c_data < 4 && attempt < 4 && !status_data)begin
                    start_status_data = 0;
                    dut_lfsr_data[op_trans.an] = op_trans.lfsr_out;
                    dut_user_out[op_trans.an] = op_trans.user_out;
                    out_c_data++;
                    `uvm_info(get_type_name(), $sformatf("[%0t] Captured DATA mode output at an=%0d, count=%0d", $time, op_trans.an, out_c_data), UVM_HIGH);
                 end
                 else if (out_c_status < 4 && attempt < 4 && status_data) begin
                    start_status_data = 1;
                    dut_lfsr_status[op_trans.an] = op_trans.lfsr_out;
                    dut_user_out[op_trans.an] = op_trans.user_out;
                    out_c_status++;
                    `uvm_info(get_type_name(), $sformatf("[%0t] Captured STATUS mode output at an=%0d, count=%0d", $time, op_trans.an, out_c_status), UVM_HIGH);
                 end
            end

            forever begin: toggle_lfsr_status
                status_data = 0; //means its data
                @(posedge clk_0_5hz); //2sec
                status_data = 1; //means its status 
            end

            forever begin: count_50sec_process
                @(posedge clk_0_01hz);
                if(first_posedge_50)begin
                    first_posedge_50 = 0;
                end
                else begin
                    expire_flag = 1;
                    flag_out = 1;
                end
            end

            forever begin: compare_logic
                 @(posedge vif.clk); // Add clock edge to prevent infinite loop
                 //compare logic after 4 outputs captured
                 if(in_c > 3 && out_c_data > 3 && !start_status_data)begin
                    in_c = 0; out_c_data = 0;
                    //LFSR compare
                    if(lfsr_exp == dut_lfsr_data) begin
                        LFSR_PASS++;
                        `uvm_info(get_type_name(), $sformatf("[%0t] LFSR Match with SCB generated: DUT LFSR=%p, Expected LFSR=%p", $time, dut_lfsr_data, lfsr_exp), UVM_LOW);
                    end
                    else begin
                        LFSR_FAIL++;
                        `uvm_error(get_type_name(), $sformatf("[%0t] LFSR MISMATCH : DUT LFSR=%p, Expected LFSR=%p", $time, dut_lfsr_data, lfsr_exp))
                    end

                    //User OTP compare
                    if(dut_lfsr_data == dut_user_out)begin
                        USER_OTP_PASS++;
                        `uvm_info(get_type_name(), $sformatf("[%0t] USER OTP Match: DUT GEN OTP=%p, Input USER OTP=%p", $time,  dut_lfsr_data,dut_user_out), UVM_LOW);
                        unlock_flag = 1;
                        flag_out = 1;
                    end
                    else begin
                        USER_OTP_FAIL++;
                        if (attempt == 3)begin
                            lock_flag = 1;
                            flag_out = 1;
                        end
                        `uvm_error(get_type_name(), $sformatf("[%0t] USER OTP MISMATCH at ATTEMPT %0d: DUT GEN OTP=%p, Input USER OTP=%p", $time,attempt, dut_lfsr_data, dut_user_out));
                        attempt++;
                    end
                 end
                else if(in_c > 3 && out_c_status > 3 && start_status_data)begin
                    //status compare
                    convert_to_bcd(attempt-1,bcd_attempt);
                    in_c = 0; out_c_status = 0;

                    if (flag_out)begin
                        if(unlock_flag)begin //A-1/2/3 U
                            if(dut_lfsr_status[0] ==  7'b1000001 &&
                            dut_lfsr_status[1] ==  7'b0111111 &&
                            dut_lfsr_status[2] ==  bcd_attempt &&
                            dut_lfsr_status[3] ==  7'b0001000)begin
                                UNLOCK_PASS++;
                                `uvm_info(get_type_name(), $sformatf("[%0t] DEVICE UNLOCKED at ATTEMPT %0d", $time, attempt-1), UVM_LOW);
                            end
                            else begin
                                UNLOCK_FAIL++;
                                `uvm_error(get_type_name(), $sformatf("[%0t] DEVICE UNLOCK STATUS MISMATCH at ATTEMPT %0d", $time, attempt-1));//attempt will be incremented already
                            end 
                        end

                        else if(lock_flag)begin// A-3 L
                            if(dut_lfsr_status[0] ==  7'b1000111 &&
                            dut_lfsr_status[1] ==  7'b0111111 && 
                            dut_lfsr_status[2] ==  bcd_attempt &&
                            dut_lfsr_status[3] ==  7'b0001000)begin
                                LOCK_PASS++;
                                `uvm_info(get_type_name(), $sformatf("[%0t] DEVICE LOCKED after 3 unsuccessful attempts", $time), UVM_LOW);
                            end
                            else begin
                                LOCK_FAIL++;
                                `uvm_error(get_type_name(), $sformatf("[%0t] DEVICE LOCK STATUS MISMATCH after 3 unsuccessful attempts", $time));
                            end
                        end
                        else if (expire_flag) begin // A - 1/2/3 E (expiry flag set after 50 sec)
                            if(dut_lfsr_status[0] ==  7'b0000110 &&
                            dut_lfsr_status[1] ==  7'b0111111 &&
                            dut_lfsr_status[2] ==  bcd_attempt && 
                            dut_lfsr_status[3] ==  7'b0001000)begin
                                EXPIRY_PASS++;
                                `uvm_info(get_type_name(), $sformatf("[%0t] DEVICE EXPIRED after hold time", $time), UVM_LOW);
                            end
                            else begin
                                EXPIRY_FAIL++;
                                `uvm_error(get_type_name(), $sformatf("[%0t] DEVICE EXPIRY STATUS MISMATCH after 50 sec hold time", $time));
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
                                `uvm_info(get_type_name(), $sformatf("[%0t] ATTEMPT %0d STATUS MATCH", $time, attempt-1), UVM_LOW);
                            end
                            else begin
                                ATTEMPT_FAIL++;
                                `uvm_error(get_type_name(), $sformatf("[%0t] ATTEMPT %0d STATUS MISMATCH", $time, attempt-1));
                            end
                    end
                end

                else if (start_status_data)begin //enter otp check only attempt here 
                        if(dut_lfsr_status[0] ==   7'b1111111 &&
                            dut_lfsr_status[1] ==  7'b0111111 && 
                            dut_lfsr_status[2] ==  bcd_attempt &&
                            dut_lfsr_status[3] ==  7'b0001000)
                            begin
                                ATTEMPT_PASS++;
                                `uvm_info(get_type_name(), $sformatf("[%0t] ATTEMPT %0d STATUS MATCH", $time, attempt-1), UVM_LOW);
                            end
                            else begin
                                ATTEMPT_FAIL++;
                                `uvm_error(get_type_name(), $sformatf("[%0t] ATTEMPT %0d STATUS MISMATCH", $time, attempt-1));
                            end
                end
            end

            forever begin: flag_output
                @(posedge clk_0_1hz); //wait for 5 sec clock
                if(first_posedge_5)begin
                    first_posedge_5 = 0;
                end
                if(flag_out)begin
                        flag_out = 0;
                        unlock_flag = 0;
                        lock_flag = 0;
                        expire_flag = 0;
                        first_otp_latch = 1;
                    end
  
            end

            forever begin: lfsr_gen_process
                @(posedge vif.sb_cb or negedge vif.sb_cb.reset_n);
                
                // Try to peek at input transaction, but use interface signal if not available
                if (ip_fifo.try_peek(ip_trans)) begin
                    gen_lfsr(vif.sb_cb.reset_n, ip_trans.otp_latch, lfsr_temp);
                end else begin
                    gen_lfsr(vif.sb_cb.reset_n, vif.otp_latch, lfsr_temp);
                end

                if(first_otp_latch)begin//for 1st latch only make it 0 after that till end of 3 attempts 
                    lfsr_reg = lfsr_temp;
                    first_otp_latch = 0;
                end

                // Use the peeked transaction if available, otherwise use interface
                if (ip_fifo.try_peek(ip_trans) && ip_trans.otp_latch) begin
                    `uvm_info(get_type_name(), $sformatf("[%0t] LFSR Latched", $time), UVM_LOW);

                    convert_to_bcd(lfsr_reg[3:0],     lfsr_exp[0]);  // LSB
                    convert_to_bcd(lfsr_reg[7:4],     lfsr_exp[1]);
                    convert_to_bcd(lfsr_reg[11:8],    lfsr_exp[2]);
                    convert_to_bcd(lfsr_reg[15:12],   lfsr_exp[3]);  // MSB

                    `uvm_info(get_type_name(), $sformatf("[%0t] SCB -> Expected LFSR Output: %0b %0b %0b %0b", $time, lfsr_exp[3], lfsr_exp[2], lfsr_exp[1], lfsr_exp[0]), UVM_LOW);
                    `uvm_info(get_type_name(), $sformatf("[%0t] SCB -> Expected LFSR Output as array: %p", $time, lfsr_exp), UVM_LOW);
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
endclass*/

class otp_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(otp_scoreboard)
   
    otp_seq_item ip_trans, op_trans;
    virtual otp_if vif;
   
    uvm_tlm_analysis_fifo #(otp_seq_item) ip_fifo;
    uvm_tlm_analysis_fifo #(otp_seq_item) op_fifo;
 
    int LFSR_PASS, LFSR_FAIL;
    int USER_OTP_PASS, USER_OTP_FAIL;
    int EXPIRY_PASS, EXPIRY_FAIL;
    int LOCK_PASS, LOCK_FAIL;
    int UNLOCK_PASS, UNLOCK_FAIL;
    int ATTEMPT_PASS, ATTEMPT_FAIL;
   
    parameter int MASTER_FREQ     = 50_000_000;        // 50 MHz master clock
    parameter int CLK_2KHZ_DIV    = MASTER_FREQ / (2 * 2000); // toggle every 12,500 cycles
    parameter int CLK_0_5HZ_DIV   = MASTER_FREQ / (2 * 0.5); //toggles every 50M cycles 2 sec
    parameter int CLK_0_1HZ_DIV   = (MASTER_FREQ * 5) / 2;  // toggle every 5 seconds
    parameter int CLK_0_01HZ_DIV  = (MASTER_FREQ * 50) / 2; // 50 seconds expiry time
 
    bit clk_2khz, clk_0_5hz, clk_0_1hz,clk_0_01hz;
    bit [15:0] lfsr_reg;
    bit [15:0] lfsr_temp;
    bit [6:0] lfsr_exp [4];
    int attempt = 1;
    bit flag_1s = 1;
    bit first_otp_latch = 1;
    bit  first_posedge_50 = 1;
    bit first_posedge_5 = 1;
 
    //input variables
    bit [6:0] dut_ip_otp [4];
    bit [6:0] bcd_user_in;
    int lfsr_c = 0;
   
    //output variables
    bit [6:0] dut_lfsr_data [4];
    bit [6:0] dut_lfsr_status [4];
    bit [6:0] dut_user_out [4];
    bit [6:0] bcd_attempt;
    bit flag_out = 0;
    bit unlock_flag = 0, lock_flag = 0, expire_flag = 0;
    int in_c = 0, out_c_data = 0, out_c_status = 0;
    bit status_data = 0, start_status_data; // 0 - data , 1 - status
 
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
 
    task automatic gen_divided_clocks();
 
        int count_2k = 0; //output capture happens in 2khz
        int count_0_5 = 0;  // 2 sec clock to capture 1st time
        int count_0_1 = 0;  // 5 sec clock for hold time
        int count_0_01 = 0; //50 sec clock for expiry time
 
        forever begin
            @(vif.sb_cb); //based on 50Mhz clock
 
            count_2k++;
            count_0_5++;
            count_0_1++;
            count_0_01++;
 
            if (count_0_5 >= CLK_0_5HZ_DIV) begin
                clk_0_5hz = ~clk_0_5hz;
                count_0_5 = 0;
            end
            if (count_2k >= CLK_2KHZ_DIV) begin
                clk_2khz = ~clk_2khz;
                count_2k = 0;
            end
            if (count_0_1 >= CLK_0_1HZ_DIV) begin
                clk_0_1hz = ~clk_0_1hz;  // toggles every 5 seconds
                count_0_1 = 0;
            end
            if (count_0_01 >= CLK_0_01HZ_DIV) begin
                clk_0_01hz = ~clk_0_01hz; // toggles every 50 s
                count_0_01 = 0;
            end
        end
    endtask
 
    task automatic gen_lfsr(
        input  logic reset,
        input  logic otp_latch,
        output bit [15:0] otp_value          
    );
        static logic [15:0] lfsr = 16'hACE1;
        logic tap;
        logic [15:0] lfsr_next;
        logic [3:0] q1, q2, q3, q4;
 
        if (!reset)
            lfsr = 16'hACE1;
        else if (!otp_latch) begin
            tap = lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10] ^ lfsr[8] ^ lfsr[6];
            lfsr = lfsr_next;
            lfsr_next = {lfsr[14:0], tap};
        end
 
        q1 = lfsr[15:12] % 10;
        q2 = lfsr[11:8]  % 10;
        q3 = lfsr[7:4]   % 10;
        q4 = lfsr[3:0]   % 10;
 
        otp_value = {q1, q2, q3, q4};
        //$display("LFSR Value Generated: %0h", otp_value);
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
                //`uvm_info(get_type_name(), $sformatf("[%0t] IP_TRANS: otp_latch=%0b user_latch=%0b user_in=%0d", $time, ip_trans.otp_latch, ip_trans.user_latch,ip_trans.user_in), UVM_LOW);
               
                if(ip_trans.user_latch && attempt < 4 && in_c <= 3)begin
                    convert_to_bcd(ip_trans.user_in,bcd_user_in);
                    dut_ip_otp[in_c] = bcd_user_in;
                    in_c++;
                end
            end
 
            forever begin: output_process
                op_fifo.get(op_trans);
                //`uvm_info(get_type_name(), $sformatf("[%0t] OP_TRANS: an=%0d lfsr_out=%0b user_out=%0b", $time, op_trans.an, op_trans.lfsr_out,op_trans.user_out), UVM_LOW);
                 
                 if(out_c_data <=4 && attempt < 4 && !status_data)begin
                    start_status_data = 0;
                    dut_lfsr_data[op_trans.an] = op_trans.lfsr_out;
                    dut_user_out[op_trans.an] = op_trans.user_out;
                    out_c_data++;
                 end
                 else if (out_c_status <=4 && attempt < 4 && status_data) begin
                    start_status_data = 1;
                    dut_lfsr_status[op_trans.an] = op_trans.lfsr_out;
                    dut_user_out[op_trans.an] = op_trans.user_out;
                    out_c_status++;
                 end
            end
 
            forever begin: toggle_lfsr_status
                status_data = 0; //means its data
                @(posedge clk_0_5hz); //2sec
                status_data = 1; //means its status
            end
 
            forever begin: count_50sec_process
                @(posedge clk_0_01hz);
                if(first_posedge_50)begin
                    first_posedge_50 = 0;
                end
                else begin
                    expire_flag = 1;
                    flag_out = 1;
                end
            end
 
            forever begin: compare_logic
                @(posedge clk_2khz); //compare at 2khz clock
                 //compare logic after 4 outputs captured
                 if(in_c > 3 && out_c_data > 3 && !start_status_data)begin
                    in_c = 0; out_c_data = 0;
                    //LFSR compare
                    if(lfsr_exp == dut_lfsr_data) begin
                        LFSR_PASS++;
                        `uvm_info(get_type_name(), $sformatf("[%0t] LFSR Match with SCB generated: DUT LFSR=%p, Expected LFSR=%p", $time, dut_lfsr_data, lfsr_exp), UVM_LOW);
                    end
                    else begin
                        LFSR_FAIL++;
                        `uvm_error(get_type_name(), $sformatf("[%0t] LFSR MISMATCH : DUT LFSR=%p, Expected LFSR=%p", $time, dut_lfsr_data, lfsr_exp))
                    end
 
                    //User OTP compare
                    if(dut_lfsr_data == dut_user_out)begin
                        USER_OTP_PASS++;
                        `uvm_info(get_type_name(), $sformatf("[%0t] USER OTP Match: DUT GEN OTP=%p, Input USER OTP=%p", $time,  dut_lfsr_data,dut_user_out), UVM_LOW);
                        unlock_flag = 1;
                        flag_out = 1;
                    end
                    else begin
                        USER_OTP_FAIL++;
                        if (attempt == 3)begin
                            lock_flag = 1;
                            flag_out = 1;
                        end
                        `uvm_error(get_type_name(), $sformatf("[%0t] USER OTP MISMATCH at ATTEMPT %0d: DUT GEN OTP=%p, Input USER OTP=%p", $time,attempt, dut_lfsr_data, dut_user_out));
                        attempt++;
                    end
                 end
                else if(in_c > 3 && out_c_status > 3 && start_status_data)begin
                    //status compare
                    convert_to_bcd(attempt-1,bcd_attempt);
                    in_c = 0; out_c_status = 0;
 
                    if (flag_out)begin
                        if(unlock_flag)begin //A-1/2/3 U
                            if(dut_lfsr_status[0] ==  7'b1000001 &&
                            dut_lfsr_status[1] ==  7'b0111111 &&
                            dut_lfsr_status[2] ==  bcd_attempt &&
                            dut_lfsr_status[3] ==  7'b0001000)begin
                                UNLOCK_PASS++;
                                `uvm_info(get_type_name(), $sformatf("[%0t] DEVICE UNLOCKED at ATTEMPT %0d", $time, attempt-1), UVM_LOW);
                            end
                            else begin
                                UNLOCK_FAIL++;
                                `uvm_error(get_type_name(), $sformatf("[%0t] DEVICE UNLOCK STATUS MISMATCH at ATTEMPT %0d", $time, attempt-1));//attempt will be incremented already
                            end
                        end
 
                        else if(lock_flag)begin// A-3 L
                            if(dut_lfsr_status[0] ==  7'b1000111 &&
                            dut_lfsr_status[1] ==  7'b0111111 &&
                            dut_lfsr_status[2] ==  bcd_attempt &&
                            dut_lfsr_status[3] ==  7'b0001000)begin
                                LOCK_PASS++;
                                `uvm_info(get_type_name(), $sformatf("[%0t] DEVICE LOCKED after 3 unsuccessful attempts", $time), UVM_LOW);
                            end
                            else begin
                                LOCK_FAIL++;
                                `uvm_error(get_type_name(), $sformatf("[%0t] DEVICE LOCK STATUS MISMATCH after 3 unsuccessful attempts", $time));
                            end
                        end
                        else if (expire_flag) begin // A - 1/2/3 E (expiry flag set after 50 sec)
                            if(dut_lfsr_status[0] ==  7'b0000110 &&
                            dut_lfsr_status[1] ==  7'b0111111 &&
                            dut_lfsr_status[2] ==  bcd_attempt &&
                            dut_lfsr_status[3] ==  7'b0001000)begin
                                EXPIRY_PASS++;
                                `uvm_info(get_type_name(), $sformatf("[%0t] DEVICE EXPIRED after hold time", $time), UVM_LOW);
                            end
                            else begin
                                EXPIRY_FAIL++;
                                `uvm_error(get_type_name(), $sformatf("[%0t] DEVICE EXPIRY STATUS MISMATCH after 50 sec hold time", $time));
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
                                `uvm_info(get_type_name(), $sformatf("[%0t] ATTEMPT %0d STATUS MATCH", $time, attempt-1), UVM_LOW);
                            end
                            else begin
                                ATTEMPT_FAIL++;
                                `uvm_error(get_type_name(), $sformatf("[%0t] ATTEMPT %0d STATUS MISMATCH", $time, attempt-1));
                            end
                    end
                end
 
                else if (start_status_data)begin //enter otp check only attempt here
                        if(dut_lfsr_status[0] ==   7'b1111111 &&
                            dut_lfsr_status[1] ==  7'b0111111 &&
                            dut_lfsr_status[2] ==  bcd_attempt &&
                            dut_lfsr_status[3] ==  7'b0001000)
                            begin
                                ATTEMPT_PASS++;
                                `uvm_info(get_type_name(), $sformatf("[%0t] ATTEMPT %0d STATUS MATCH", $time, attempt-1), UVM_LOW);
                            end
                            else begin
                                ATTEMPT_FAIL++;
                                `uvm_error(get_type_name(), $sformatf("[%0t] ATTEMPT %0d STATUS MISMATCH", $time, attempt-1));
                            end
                end
            end
 
            forever begin: flag_output
                @(posedge clk_0_1hz); //wait for 5 sec clock
                if(first_posedge_5)begin
                    first_posedge_5 = 0;
                end
                if(flag_out)begin
                        flag_out = 0;
                        unlock_flag = 0;
                        lock_flag = 0;
                        expire_flag = 0;
                        first_otp_latch = 1;
                    end
 
            end
 
            forever begin: lfsr_gen_process
                @(vif.sb_cb or negedge vif.sb_cb.reset_n);
                //ip_fifo.peek(ip_trans);
                gen_lfsr(vif.sb_cb.reset_n, vif.sb_cb.otp_latch, lfsr_temp);
 
                if(first_otp_latch && vif.sb_cb.otp_latch)begin//for 1st latch only make it 0 after that till end of 3 attempts
                    lfsr_reg = lfsr_temp;
                    $display("Hi:%b  [%t]",lfsr_reg,$time);
                    first_otp_latch = 0;
                end
 
                if(vif.sb_cb.otp_latch) begin
                    //`uvm_info(get_type_name(), $sformatf("[%0t] LFSR Latched", $time), UVM_LOW);
 
                    convert_to_bcd(lfsr_reg[3:0],     lfsr_exp[0]);  // LSB
                    convert_to_bcd(lfsr_reg[7:4],     lfsr_exp[1]);
                    convert_to_bcd(lfsr_reg[11:8],    lfsr_exp[2]);
                    convert_to_bcd(lfsr_reg[15:12],   lfsr_exp[3]);  // MSB
 
                    //`uvm_info(get_type_name(), $sformatf("[%0t] SCB -> Expected LFSR Output: %0b %0b %0b %0b", $time, lfsr_exp[3], lfsr_exp[2], lfsr_exp[1], lfsr_exp[0]), UVM_LOW);
                    //`uvm_info(get_type_name(), $sformatf("[%0t] SCB -> Expected LFSR Output as array: %p", $time, lfsr_exp), UVM_LOW);
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