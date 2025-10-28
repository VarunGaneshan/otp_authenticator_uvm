module lfsr(
    input  clk,
    input  reset,
    output reg [15:0] d_out
);
 
    reg [15:0] lfsr, lfsr_next;
    reg [3:0] q_reg1, q_reg2, q_reg3, q_reg4; // digits
    reg tap;
 
    // Sequential logic for 16-bit LFSR
    always @(posedge clk or negedge reset) begin
        if (!reset)
            lfsr <= 16'hACE1;  // seed value
        else
            lfsr <= lfsr_next;
    end
 
    // Combinational next state logic (16-bit LFSR with multiple taps)
    always @(*) begin
        // x^16 + x^14 + x^13 + x^11 + x^9 + x^7 + 1
        tap = lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10] ^ lfsr[8] ^ lfsr[6];
        lfsr_next = {lfsr[14:0], tap};
    end
 
    // Split 16-bit LFSR into 4 digits (0-9) safely
    always @(*) begin
        q_reg1 = lfsr[15:12] % 10;
        q_reg2 = lfsr[11:8]  % 10;
        q_reg3 = lfsr[7:4]   % 10;
        q_reg4 = lfsr[3:0]   % 10;
    end
 
    // Concatenate into 16-bit output
    always @(*) begin
        d_out = {q_reg1, q_reg2, q_reg3, q_reg4};
    end
 
endmodule