module clk_div(
    input clk, rstn,
    output reg clk_out_disp
);

    reg [13:0] ct2;
    
    parameter DISP = 12_500;//0.5ms 0.25ms 0.75ms 
    
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            ct2 <= 14'd0;
            clk_out_disp <= 1'b0;
        end else begin
            if (ct2 == DISP-1) begin
                ct2 <= 14'd0;
                clk_out_disp <= ~clk_out_disp;
            end else begin
                ct2 <= ct2 + 14'd1;
            end
        end
    end

endmodule
