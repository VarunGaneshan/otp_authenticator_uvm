bind top otp_assertions otp_assert_inst (
  .clk(clk),
  .reset_n(reset_n),
  .user_in(user_in),
  .otp_latch(otp_latch),
  .user_latch(user_latch),
  .lfsr_out(lfsr_out),
  .user_out(user_out),
  .an(an)
);