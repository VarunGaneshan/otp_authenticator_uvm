interface otp_assertions (
  input logic clk,
  input logic reset_n,
  input logic [3:0] user_in,
  input logic otp_latch,
  input logic user_latch,
  input logic [6:0] lfsr_out,
  input logic [6:0] user_out,
  input logic [1:0] an
);

  property clk_valid_check;
    @(posedge clk) !$isunknown(clk);
  endproperty
  assert_clk_valid: assert property (clk_valid_check)
    else $error("[ASSERTION] Clock signal is unknown at time %0t", $time);

  property reset_n_valid_check;
    @(posedge clk) !$isunknown(reset_n);
  endproperty
  assert_reset_n_valid: assert property (reset_n_valid_check)
    else $error("[ASSERTION] Reset_n signal is unknown at time %0t", $time);

  property user_in_valid_check;
    @(posedge clk) !$isunknown(user_in);
  endproperty
  assert_user_in_valid: assert property (user_in_valid_check)
    else $error("[ASSERTION] user_in signal is unknown at time %0t", $time);
    
  property otp_latch_valid_check;
    @(posedge clk) !$isunknown(otp_latch);
  endproperty
  assert_otp_latch_valid: assert property (otp_latch_valid_check)
    else $error("[ASSERTION] otp_latch signal is unknown at time %0t", $time);
  
  property user_latch_valid_check;
    @(posedge clk) !$isunknown(user_latch);
  endproperty
  assert_user_latch_valid: assert property (user_latch_valid_check)
    else $error("[ASSERTION] user_latch signal is unknown at time %0t", $time);
    
  property lfsr_out_valid_check;
    @(posedge clk) !$isunknown(lfsr_out);
  endproperty
  assert_lfsr_out_valid: assert property (lfsr_out_valid_check)
    else $error("[ASSERTION] lfsr_out signal is unknown at time %0t", $time);

  property user_out_valid_check;
    @(posedge clk) !$isunknown(user_out);
  endproperty
  assert_user_out_valid: assert property (user_out_valid_check)
    else $error("[ASSERTION] user_out signal is unknown at time %0t", $time);
    
  property an_valid_check;
    @(posedge clk) !$isunknown(an);
  endproperty
  assert_an_valid: assert property (an_valid_check)
    else $error("[ASSERTION] an signal is unknown at time %0t", $time);
/*
  wire #(1ps) reset_n_delay = reset_n;

   property reset_lfsr_out;
    @(posedge reset_n_delay) (1'b1 |-> reset_n && lfsr_out == 7'b1111111)
   endproperty
    assert_reset_lfsr_out_assertion: assert property (reset_lfsr_out)
      else $error("[ASSERTION] LFSR output not reset to all 1's at time %0t", $time);

   property reset_user_out;
    @(posedge reset_n_delay) (1'b1 |-> reset_n && user_out == 7'b1111111)
  endproperty
  assert_reset_user_out_assertion: assert property (reset_user_out)
      else $error("[ASSERTION] User output not reset to all 1's at time %0t", $time);
*/
endinterface