module top (
    CLOCK_50,
    SW,
    KEY,
    PS2_CLK,
    PS2_DAT,
    HEX0,
    HEX1,
    HEX2,
    HEX3,
    HEX4,
    HEX5,
    LEDR,
	 VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK
);
    input CLOCK_50;
    input [9:0] SW;
    input [3:0] KEY;

    inout PS2_CLK;
    inout PS2_DAT;

    output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
    output [9:0] LEDR;
	 output wire [7:0] VGA_R, VGA_G, VGA_B;
	 output wire VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK;

	 
    wire [7:0] keyboard;

    KB_Handler kb (
        .CLOCK_50(CLOCK_50),
        .PS2_CLK(PS2_CLK),
        .PS2_DAT(PS2_DAT),
        .KEY(),
        .HEX1(),
        .HEX0(),
        .LEDR(LEDR),
        .out(keyboard)
    );

    wire [31:0] player_x, player_y;

    game_loop gl (
        .CLOCK_50(CLOCK_50),
        .keyboard(keyboard),
        .player_x(player_x),
        .player_y(player_y)
    );
	 
	 
	 wire [8:0] tile_map_render_address, tile_map_logic_address;
	 wire [3:0] tile_map_render_id, tile_map_logic_id;
	 
	 tile_map t0 (
        .Clock(CLOCK_50),
        .render_address(tile_map_render_address),
        .render_tile_id(tile_map_render_id),
		  .logic_address(tile_map_logic_address),
		  .logic_tile_id(tile_map_logic_id)
    );
	 
	 vga_display v0 (
        .CLOCK_50(CLOCK_50), 
		  .KEY(KEY), 
		  .VGA_R(VGA_R), 
		  .VGA_G(VGA_G), 
		  .VGA_B(VGA_B), 
		  .VGA_HS(VGA_HS), 
		  .VGA_VS(VGA_VS), 
		  .VGA_BLANK_N(VGA_BLANK_N), 
		  .VGA_SYNC_N(VGA_SYNC_N), 
		  .VGA_CLK(VGA_CLK),
		  .tile_map_address(tile_map_render_address), 
		  .tile_map_id(tile_map_render_id)
	 );

	 
    seg7 h0 (.s(player_y[19:16]), .display(HEX0));
    seg7 h1 (.s(player_y[23:20]), .display(HEX1));
    seg7 h2 (.s(player_y[27:24]), .display(HEX2));

    seg7 h3 (.s(player_x[19:16]), .display(HEX3));
    seg7 h4 (.s(player_x[23:20]), .display(HEX4));
    seg7 h5 (.s(player_x[27:24]), .display(HEX5));
	 

endmodule