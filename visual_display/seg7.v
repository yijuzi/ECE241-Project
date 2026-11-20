module seg7(s, display);
    input [3:0] s;
    output [6:0] display;

    assign display[0] = (~s[3] & ~s[2] & ~s[1] & s[0])
            | (~s[3] & s[2] & ~s[1] & ~s[0])
            | (s[3] & ~s[2] & s[1] & s[0])
            | (s[3] & s[2] & ~s[1] & s[0]);

    assign display[1] = (~s[3] & s[2] & ~s[1] & s[0])
            | (s[2] & s[1] & ~s[0])
            | (s[3] & s[2] & ~s[0])
            | (s[3] & s[1] & s[0]);

    assign display[2] = (~s[3] & ~s[2] & s[1] & ~s[0])
            | (s[3] & s[2] & ~s[0])
            | (s[3] & s[2] & s[1] & s[0]);

    assign display[3] = (~s[3] & ~s[2] & ~s[1] & s[0])
            | (~s[3] & s[2] & ~s[1] & ~s[0])
            | (s[3] & ~s[2] & s[1] & ~s[0])
            | (s[2] & s[1] & s[0]);

    assign display[4] = (~s[3] & s[0])
            | (~s[2] & ~s[1] & s[0])
            | (~s[3] & s[2] & ~s[1]);

    assign display[5] = (~s[3] & ~s[2] & s[1])
            | (~s[3] & ~s[2] & ~s[1] & s[0])
            | (~s[3] & s[2] & s[1] & s[0])
            | (s[3] & s[2] & ~s[1] & s[0]);

    assign display[6] = (~s[3] & ~s[2] & ~s[1])
            | (~s[3] & s[2] & s[1] & s[0])
            | (s[3] & s[2] & ~s[1] & ~s[0]);

endmodule
