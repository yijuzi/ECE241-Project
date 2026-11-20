module game_loop (
    CLOCK_50,

    keyboard,

    player_x,
    player_y
);
    input CLOCK_50;
    input [7:0] keyboard;
    output reg [31:0] player_x, player_y;

    wire clk_en;

    reg signed [31:0] x, y, vx, vy; // fixed point with n[16] = 2^0

    reg [7:0] last_keyboard;

    localparam signed [31:0] WALK_SPEED = 	32'b0000_0000_0000_0001_0100_0000_0000_0000;
	localparam signed [31:0] GRAVITY 	= 	32'b0000_0000_0000_0000_0100_0000_0000_0000;
    localparam signed [31:0] JUMP_SPEED = 	32'b0000_0000_0000_0001_1000_0000_0000_0000;

    frame_clock frameClock (.CLOCK_50(CLOCK_50), .reset(), .tick(clk_en));

    always @ (posedge CLOCK_50) begin
        if (keyboard[7]) begin
            x <= (32'd160 << 16);
			y <= 32'b0;
			player_x <= (32'd160 << 16);
			player_y <= 32'b0;
        end
		else if (clk_en) begin
			if (keyboard[0] && !keyboard[1])
				vx <= -WALK_SPEED;
			else if (!keyboard[0] && keyboard[1])
				vx <= WALK_SPEED;
			else
				vx <= 0;

			if (x+vx < 0)
				x <= 0;
			else if (x+vx > (32'd320 << 16))
				x <= (32'd320 << 16);
			else
				x <= x + vx;

            if (~last_keyboard[4] && keyboard[4])
                vy <= -JUMP_SPEED;
			else
                vy <= vy + GRAVITY;

            if (y+vy > (32'd240 << 16))
                y <= (32'd240 << 16);
            else
                y <= y + vy;
			
			player_x <= x;
			player_y <= y;
            last_keyboard <= keyboard;
		end
        
    end

endmodule

module frame_clock (
    CLOCK_50,
    reset,
    tick
);
    input CLOCK_50, reset;
    output reg tick;

    localparam [19:0] CLOCKS_PER_TICK = 20'd833333;

    reg [19:0] counter;

    always @ (posedge CLOCK_50) begin
        if (reset) begin
            counter <= 1'b0;
            tick <= 1'b0;
        end
        else if (counter == CLOCKS_PER_TICK - 1) begin
            counter <= 1'b0;
            tick <= 1'b1;
        end
        else begin
            counter <= counter + 1;
            tick <= 1'b0;
        end
        
    end

endmodule
