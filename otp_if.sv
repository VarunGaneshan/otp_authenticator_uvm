interface otp_if(input bit clk, reset_n);
	logic otp_latch;
  logic user_latch;
  logic [3:0] user_in;
  logic [6:0] lfsr_out;
  logic [6:0] user_out;
  logic [1:0]an;

  clocking drv_cb @(posedge clk);
    input reset_n;
	  output otp_latch;
    output user_latch;
    output user_in;
  endclocking 
  
  clocking act_mon_cb @(posedge clk);
    input reset_n;
	  input otp_latch;
    input user_latch;
    input user_in;
  endclocking

  clocking pas_mon_cb @(posedge clk);
    input reset_n;
    input lfsr_out;
    input user_out;
    input an;
  endclocking

  clocking sb_cb @(posedge clk);
    input reset_n;
    input otp_latch;
  endclocking 
endinterface
