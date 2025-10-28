module pos_edge(
    input  clk,
    input  reset,
    input  sig_in,        // raw input (sync it first if from button!)
    output reg rise_edge  // 1 clk-cycle pulse on rising edge
);
    reg sig_d;  
    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            sig_d     <= 0;
            rise_edge <= 0;
        end else begin
            sig_d     <= sig_in;
            rise_edge <= sig_in & ~sig_d; 
        end
    end
endmodule