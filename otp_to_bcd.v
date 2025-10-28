`include "clk_div.v"
`include "clk_div_2sec.v"
module otp_to_bcd(
    input clk, rstn,
    input unlock, lock, expire,
    input [1:0] wrng_att,
    input [15:0] user_otp, lfsr_otp,
    output reg [3:0] bcd1, bcd2,
    output reg [1:0] an,
    output wire shft
);
    wire clk_out_disp;
    wire clk_out_disp2;
    
    clk_div inst2(.clk(clk),
                  .rstn(rstn),
                  .clk_out_disp(clk_out_disp));
    
    clk_div_2sec inst3(.clk(clk),
                       .rstn(rstn),
                       .clk_out_disp2(clk_out_disp2));
    
    reg [1:0] disp1;
    reg [1:0] disp2;
    reg [3:0] mode;
    reg shift;
    reg ON;
    
    always @ (posedge clk_out_disp2 or negedge rstn) begin
        if(!rstn)
            shift <= 0;
        else
            shift <= ~shift;
    end
    
    always @ (*) begin
        if(unlock)
            mode = 4'b0111;
        else if(lock)
            mode = 4'b0110;
        else if(expire)
            mode = 4'b0101;
        else
            mode = 4'd0;
    end
    
    always @(posedge clk_out_disp or negedge rstn) begin
        if(!rstn) begin
            ON <= 0;
            disp1 <= 2'd0;
            disp2 <= 2'd0;
        end
        else begin
            ON <= 1;
            disp1 <= disp1 + 2'd1;
            disp2 <= disp2 + 2'd1;
        end
    end
    
    always @(*) begin
        if(!ON) begin
            bcd1 = 4'b1111;
            an = 2'b00;
        end
        else begin
            case (disp1)
                2'd0: begin 
                    an = 2'b00;
                    bcd1 = user_otp[3:0];
                end
                2'd1: begin
                    an = 2'b01;
                    bcd1 = user_otp[7:4];
                end 
                2'd2: begin
                    an = 2'b10;
                    bcd1 = user_otp[11:8];
                end
                2'd3: begin
                    an = 2'b11;
                    bcd1 = user_otp[15:12];
                end
                default: begin
                    an = 2'b11;
                    bcd1 = 4'd0;
                end
        endcase
        end
    end
    
    always @(*) begin
        if(!ON) begin
            bcd2 = 4'd10;
        end
        else begin
        if(shift) begin
            case(disp2)
                2'd3: begin 
                       bcd2 = 4'b1111;
                    end
                2'd2: begin
                       bcd2 = {2'b00, wrng_att + 2'd1};
                end
                2'd1: begin
                       bcd2 = 4'b1000;
                end 
                2'd0: begin 
                       bcd2 = mode;
                end
                default: begin
                        bcd2 = 4'd0;
                end
            endcase
        end
        else begin
            case (disp2)
                2'd0: begin 
                   bcd2 = lfsr_otp[3:0];
                end
                2'd1: begin
                   bcd2 = lfsr_otp[7:4];
                end 
                2'd2: begin
                    bcd2 = lfsr_otp[11:8];
                end
                2'd3: begin
                    bcd2 = lfsr_otp[15:12];
                end
                default: begin
                        bcd2 = 4'd0;
                end
            endcase
        end
        end
    end
    assign shft = shift;

endmodule
