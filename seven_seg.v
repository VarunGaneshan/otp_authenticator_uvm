module seven_seg(
    input [3:0] bcd1, bcd2,
    input shift,
    output reg [6:0] seg1, seg2
    );
    
    always @ (*) begin
        case(bcd1)
            4'b0000: seg1 = 7'b1000000; // 0
            4'b0001: seg1 = 7'b1111001; // 1
            4'b0010: seg1 = 7'b0100100; // 2
            4'b0011: seg1 = 7'b0110000; // 3
            4'b0100: seg1 = 7'b0011001; // 4
            4'b0101: seg1 = 7'b0010010; // 5
            4'b0110: seg1 = 7'b0000010; // 6
            4'b0111: seg1 = 7'b1111000; // 7
            4'b1000: seg1 = 7'b0000000; // 8
            4'b1001: seg1 = 7'b0010000; // 9
            default: seg1 = 7'b1111111; // OFF
        endcase
    end
    
    always @ (*) begin
        if(shift) begin
            case(bcd2)
                4'b0001: seg2 = 7'b1111001; // 1
                4'b0010: seg2 = 7'b0100100; // 2
                4'b0011: seg2 = 7'b0110000; // 3
                4'b0110: seg2 = 7'b1000111; // L
                4'b0111: seg2 = 7'b1000001; // U
                4'b0101: seg2 = 7'b0000110; // E
                4'b1000: seg2 = 7'b0111111; // -
                4'b1111: seg2 = 7'b0001000; // A
                default: seg2 = 7'b1111111; // OFF
            endcase
        end
        else begin
                case(bcd2)
                    4'b0000: seg2 = 7'b1000000; // 0
                    4'b0001: seg2 = 7'b1111001; // 1
                    4'b0010: seg2 = 7'b0100100; // 2
                    4'b0011: seg2 = 7'b0110000; // 3
                    4'b0100: seg2 = 7'b0011001; // 4
                    4'b0101: seg2 = 7'b0010010; // 5
                    4'b0110: seg2 = 7'b0000010; // 6
                    4'b0111: seg2 = 7'b1111000; // 7
                    4'b1000: seg2 = 7'b0000000; // 8
                    4'b1001: seg2 = 7'b0010000; // 9
                    default: seg2 = 7'b1111111; // OFF
                endcase 
        end
    end

endmodule
