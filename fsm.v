`define HOLD_TIME 50_000_000
`define EXPIRE_TIME 50_000_000
module fsm(
    input clk,reset,
    input [15:0] lfsr_digit,
    input lfsr_latch,
    input [3:0] user_digit,
    input user_latch,
    output reg unlock,
    output reg reset_sys,
    output reg expired,
    output reg [1:0] wrng_atmpt,
    output [15:0] user_otp_out,
    output reg [15:0] otp
    );
    

    reg [31:0] total_time;
    reg [27:0] hold_time;
    reg [1:0] current,next;
    reg [3:0] user_otp[0:3];
    reg [2:0]j;//index of generated otp
    parameter IDLE = 2'B00,GENERATE_OTP = 2'B01, ENTER_OTP = 2'B10 ,UNLOCK = 2'B11;
    
    always @(posedge clk or negedge reset) begin
    if (!reset) begin
        otp <= 16'b0;
        current    <= IDLE;
        total_time <= 0;
        hold_time <= 0;
        wrng_atmpt <= 0;
        unlock     <= 0;
        reset_sys  <= 0;
        expired    <= 0;
        j          <= 0;
        {user_otp[0], user_otp[1], user_otp[2], user_otp[3]} <= 16'd0;
    end 
    
    else begin
        current <= next;
        case (current)
        
            IDLE: begin
                otp <= 16'b0;
                total_time <= 0;
                hold_time <= 0;
                unlock <= 0;
                reset_sys <= 0;   
                expired    <= 0;  
                wrng_atmpt <= 0; 
                j  <= 0;     
                {user_otp[0], user_otp[1], user_otp[2], user_otp[3]} <= 16'd0;   
            end
            
            GENERATE_OTP: if (lfsr_latch) begin
                               otp <= lfsr_digit;  
                           end
                           
            ENTER_OTP: begin
                total_time <= total_time + 1;
                if(total_time > (`EXPIRE_TIME*50)) begin
                    if(hold_time < (`HOLD_TIME*5)) begin 
                        expired   <= 1;
                        hold_time <= hold_time + 1;
                    end else begin
                        expired   <= 0;
                        hold_time <= 0;
                    end
                end
                else if (user_latch ) begin
                    user_otp[j[1:0]] <= user_digit;
                    j <= j + 1;
                end
            end 
            
            UNLOCK: begin  
                if (otp == {{user_otp[0]},{user_otp[1]},{user_otp[2]},{user_otp[3]}}) begin
                    unlock <= 1;
                    hold_time <= hold_time + 1;
                end 
                else begin
                    j <= 0;
                     if (wrng_atmpt == 2) begin 
                        reset_sys <= 1;
                        hold_time <= hold_time + 1;
                    end
                    else begin
                        reset_sys <= 0;
                        hold_time <= 0;
                        wrng_atmpt <= wrng_atmpt + 1;
                    end
                end
            end
        endcase
    end
end
  
   always @(*) begin
    next = current; // default
    case (current)
        IDLE:        next = GENERATE_OTP;
        GENERATE_OTP: if (lfsr_latch) next = ENTER_OTP;
        ENTER_OTP:   if (total_time > (`EXPIRE_TIME*50) && hold_time == (`HOLD_TIME*5)) next = IDLE;// 30 secs
                     else if (total_time > (`EXPIRE_TIME*50)) next = ENTER_OTP;//30 secs
                     else if (j > 3)    next = UNLOCK;
        UNLOCK:      if (( otp == {{user_otp[0]},{user_otp[1]},{user_otp[2]},{user_otp[3]}} ) && hold_time == (`HOLD_TIME*5)) next = IDLE;//hold_time <250_000_000 5 secs
                     else if ( otp == {{user_otp[0]},{user_otp[1]},{user_otp[2]},{user_otp[3]}}) next = UNLOCK;
        else if (wrng_atmpt >= 2 && hold_time == (`HOLD_TIME*5) )  next = IDLE;//hold_time <250000000  5 secs
                     else if (wrng_atmpt >= 2)  next = UNLOCK; 
                     else next = ENTER_OTP ; // go back after check
    endcase
end
assign user_otp_out = {{user_otp[0]},{user_otp[1]},{user_otp[2]},{user_otp[3]}};
endmodule

 







