module KB_Handler (
    CLOCK_50,

    PS2_CLK,
    PS2_DAT,

    KEY,

    HEX1,
    HEX0,
    LEDR,

    out
);
    input CLOCK_50;
    inout PS2_CLK;
    inout PS2_DAT;
    input [3:0] KEY;
    output [6:0] HEX1, HEX0;
    output [9:0] LEDR;
    output [7:0] out;

    wire [7:0] ps2_received_data;
    wire ps2_received_data_en;

    reg [7:0] last_data;

    localparam [7:0]
        KEY_A     = 8'h1C,
        KEY_D     = 8'h23,
        KEY_W     = 8'h1D,
        KEY_S     = 8'h1B,
        KEY_SPACE = 8'h29,
        KEY_J     = 8'h3B,
        KEY_ESCAPE= 8'h76;

    reg left = 1'b0, right = 1'b0, up = 1'b0, down = 1'b0, jump = 1'b0, dash = 1'b0, menu = 1'b0;

    PS2_Controller #(.INITIALIZE_MOUSE(0)) ps2 (
        .CLOCK_50(CLOCK_50),
        .reset(~KEY[0]),

        .PS2_CLK(PS2_CLK),
        .PS2_DAT(PS2_DAT),

        .received_data(ps2_received_data),
        .received_data_en(ps2_received_data_en),
    );

    always @ (posedge CLOCK_50) begin
        if (~KEY[0])
            last_data <= 8'h00;
        else if (ps2_received_data_en) begin
            if (last_data == 8'hF0) begin
                case (ps2_received_data)
                    KEY_A: 
                        left  <= 1'b0;
                    KEY_D:
                        right <= 1'b0;
                    KEY_W:
                        up    <= 1'b0;
                    KEY_S:
                        down  <= 1'b0;
                    KEY_SPACE:
                        jump  <= 1'b0;
                    KEY_J:
                        dash  <= 1'b0;
                    KEY_ESCAPE:
                        menu  <= 1'b0;
                    default: begin
                    end
                endcase
            end
            else begin
                case (ps2_received_data)
                    KEY_A: 
                        left  <= 1'b1;
                    KEY_D:
                        right <= 1'b1;
                    KEY_W:
                        up    <= 1'b1;
                    KEY_S:
                        down  <= 1'b1;
                    KEY_SPACE:
                        jump  <= 1'b1;
                    KEY_J:
                        dash  <= 1'b1;
                    KEY_ESCAPE:
                        menu  <= 1'b1;
                    default: begin
                    end
                endcase
            end

            last_data <= ps2_received_data;
        end
    end

    seg7 h0 (.s(last_data[3:0]), .display(HEX0));
    seg7 h1 (.s(last_data[7:4]), .display(HEX1));

    assign out[0] = left;
    assign out[1] = right;
    assign out[2] = up;
    assign out[3] = down;
    assign out[4] = jump;
    assign out[5] = dash;
    assign out[6] = 1'b0;
    assign out[7] = menu;

    assign LEDR[7:0] = out;
    assign LEDR[9:8] = 1'b0;

endmodule
