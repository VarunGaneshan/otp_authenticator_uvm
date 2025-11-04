`include "pos_edge.v"
`include "lfsr.v"
`include "fsm.v"
`include "top_7_seg.v"
module top(
input clk, input reset_n,
input [3:0]user_in,
input otp_latch,input user_latch,
output [6:0] lfsr_out,
output [6:0] user_out,
output [1:0] an
  );
 
wire [15:0]d_out, user_otp, otp;
wire [1:0] wrng_atmpt;
wire lock, unlock, expire;

wire lfsr_button, user_button;

pos_edge edge1 (.clk(clk), //lsfr button edge detector
                .reset(reset_n),
                .sig_in(otp_latch),
                .rise_edge(lfsr_button));
                
pos_edge edge2 (.clk(clk), //user button edge detector
                .reset(reset_n),
                .sig_in(user_latch),
                .rise_edge(user_button));
                
lfsr dut1( 
    .clk(clk),
    .reset(reset_n),
    .d_out(d_out)
);
//coverage toggle_ignore otp 15 3
fsm dut2(.clk(clk),
    .reset(reset_n),
    .lfsr_digit(d_out),
    .lfsr_latch(lfsr_button),
    .user_digit(user_in),
    .user_latch(user_button),
    .unlock(unlock),
    .reset_sys(lock),
    .expired(expire),
    .wrng_atmpt(wrng_atmpt),
    .user_otp_out(user_otp),
    .otp(otp)
    );
    
 top_7_seg dut3(
    .clk(clk),
    .rstn(reset_n),
    .lock(lock),
    .unlock(unlock),
    .expire(expire),
    .wrng_att(wrng_atmpt),
    .user_otp(user_otp),
    .lfsr_otp(otp),
    .seg1(user_out),
    .seg2(lfsr_out),
    .an(an)
    );
      
endmodule
