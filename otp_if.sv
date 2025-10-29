interface otp_if(input bit clk, reset_n);
	bit otp_latch;
  bit user_latch;
  bit [3:0] user_in;
  bit [6:0] lfsr_out;
  bit [6:0] user_out;
  bit [1:0]an;

  clocking drv_cb @(posedge clk);
    default output #0;
    input reset_n;
	  output otp_latch;
    output user_latch;
    output user_in;
  endclocking 
  
  clocking act_mon_cb @(posedge clk);
    default input #1step;
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
