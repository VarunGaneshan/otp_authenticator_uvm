`include "otp_to_bcd.v"
`include "seven_seg.v"
module top_7_seg(
    input wire clk, rstn, unlock, lock, expire,
    input [1:0] wrng_att,
    input wire [15:0] user_otp, lfsr_otp,
    output wire [6:0] seg1, seg2,
    output wire [1:0] an
    );
    
    wire [3:0] bcd1, bcd2;
    wire shift;
    //coverage toggle_ignore lfsr_otp 15 3
    otp_to_bcd U1 (.clk(clk),
                   .rstn(rstn),
                   .lock(lock),
                   .unlock(unlock),
                   .expire(expire),
                   .wrng_att(wrng_att),
                   .user_otp(user_otp),
                   .lfsr_otp(lfsr_otp),
                   .bcd1(bcd1),
                   .bcd2(bcd2),
                   .an(an),
                   .shft(shift));
                   
    seven_seg U2 (.bcd1(bcd1),
                  .bcd2(bcd2),
                  .seg1(seg1),
                  .seg2(seg2),
                  .shift(shift));
endmodule
