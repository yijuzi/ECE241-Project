`default_nettype none

// 320 x 240 display, 9-bit RGB colour.
// KEY[0]: reset. KEY[1]: draw sprite at its starting position.
// no keyboard yet
module vga_display (CLOCK_50, KEY, VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK);
					
	input wire CLOCK_50;
	input wire [3:0] KEY;
	
	wire Resetn, draw_sprite;
	
	// VGA
	output wire [7:0] VGA_R, VGA_G, VGA_B;
	output wire VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK;
	
	// object
	wire [8:0] O1_x, O1_y;
	wire [8:0] O1_color;
	wire O1_write, O1_done;
	
	// tiles
	wire [8:0] map_x, map_y;
	wire [8:0] map_color;
	wire map_write, map_done;
	
	// ps2 keyboard control (to be updated)
	
	assign Resetn = KEY[0];
	sync draw_button (~KEY[1], Resetn, CLOCK_50, draw_sprite);
	
	
	// draw to tiles
	tile_render t0 (
		.Clock(CLOCK_50),
		.Resetn(Resetn),
		.pixel_x(map_x),
		.pixel_y(map_y),
		.pixel_color(map_color),
		.pixel_write(map_write),
		.done(map_done)
	);
	
	// instatiate the sprite (change this)
	
	object O1 (
        .Resetn(Resetn),
        .Clock(CLOCK_50),
        .go(1'b0), // draw_sprite
        .dir(2'b00),
        .VGA_x(O1_x),
        .VGA_y(O1_y),
        .VGA_color(O1_color),
        .VGA_write(O1_write),
        .done_write(O1_done), 
        .ps2_rec(1'b0)
    );
		
	// connect to VGA controller
    vga_adapter VGA (
		.resetn(Resetn),
		.clock(CLOCK_50),
		.color(9'b111000000), // map_done ? O1_color : map_color
		.x(map_done ? O1_x : map_x),
		.y(map_done ? O1_y : map_y),
		.write(map_done ? O1_write : map_write),
		.VGA_R(VGA_R),
		.VGA_G(VGA_G),
		.VGA_B(VGA_B),
		.VGA_HS(VGA_HS),
		.VGA_VS(VGA_VS),
		.VGA_BLANK_N(VGA_BLANK_N),
		.VGA_SYNC_N(VGA_SYNC_N),
		.VGA_CLK(VGA_CLK)
	);
			
	// background
	defparam VGA.RESOLUTION = "320x240";
	defparam VGA.COLOR_DEPTH = 9;
	defparam VGA.BACKGROUND_IMAGE = "./MIF/bmp_320_9.mif";

endmodule 


// syncronizer, implemented as two FFs in series
module sync(D, Resetn, Clock, Q);
    input wire D;
    input wire Resetn, Clock;
    output reg Q;

    reg Qi; // internal node

    always @(posedge Clock)
        if (Resetn == 0) begin
            Qi <= 1'b0;
            Q <= 1'b0;
        end
        else begin
            Qi <= D;
            Q <= Qi;
        end
endmodule

// n-bit register with enable
module regn(R, Resetn, E, Clock, Q);
    parameter n = 8;

    input wire [n-1:0] R;
    input wire Resetn, E, Clock;
    output reg [n-1:0] Q;

    always @(posedge Clock)
        if (!Resetn)
            Q <= 0;
        else if (E)
            Q <= R;
endmodule


// up and down counter for spirte location (L/R and U/D)
module counter_ud (R, Clock, Resetn, L, Enable, Direction, Q);
	parameter n = 8;
	input wire [n-1:0] R;
	input wire Clock, Resetn, Enable, L, Direction;
	output reg [n-1:0] Q;
	
	always @(posedge Clock)
		if (Resetn == 0)
			Q <= 1'b0;
		else if (L == 1)
			Q <= R;
		else if (Enable)
			if (Direction) // when direction is 1 (right/up), add 1
				Q <= Q + {{n-1{1'b0}},1'b1};
			else 
				Q <= Q - {{n-1{1'b0}},1'b1};
					
endmodule

// only needs the updated object coordinates
module object (Resetn, Clock, go, dir, VGA_x, VGA_y, VGA_color, VGA_write, done_write, ps2_rec);
	
	// -- parameters 
	parameter OFFSET_X = 160;
	parameter OFFSET_Y = 120;
	parameter SPRITE_X_BITS = 4, SPRITE_Y_BITS = 4; 
	parameter obj_address = SPRITE_X_BITS + SPRITE_Y_BITS;
	parameter INIT_FILE = "./MIF/test_sprite2.mif";
	
	parameter LEFT  = 2'b00;
	parameter RIGHT = 2'b11;
	parameter UP    = 2'b01;
	parameter DOWN  = 2'b10;
	
	// FSM states to draw object
	parameter A = 3'b000, B = 3'b001, C = 3'b010, D = 3'b011, E = 3'b100,
			  F = 3'b101, G = 3'b110, H = 3'b111;
	input wire Clock, Resetn;
	input wire go, ps2_rec;
	
	// -- vga communication
	output wire [8:0] VGA_x, VGA_y; // for syncing with object memory
	output wire [8:0] VGA_color;
	output wire VGA_write;
	output reg done_write;
	input wire [1:0] dir;
	
	// -- objects
	wire [8:0] X_initial, Y_initial;
	wire [8:0] obj_X, obj_Y; // starting location
	wire [SPRITE_X_BITS-1:0] obj_XC;
	wire [SPRITE_Y_BITS-1:0] obj_YC; // access object memory (counters)
	wire Left, Right, Up, Down;
    wire [8:0] obj_color;
	reg obj_x_load, obj_y_load, obj_x_enable, obj_y_enable; // object counter controls (screen positions)
	reg erase; // erase/draw object
	reg write, pixel_X_load, pixel_Y_load, pixel_X_enable, pixel_Y_enable; // advances pixels inside sprite
	localparam SPRITE_WIDTH  = 16;
	localparam SPRITE_HEIGHT = 16;
	
	// FSM
	reg [2:0] y_Q, Y_D;			  
	
	
	// Initialize locations
	assign X_initial = OFFSET_X;
	assign Y_initial = OFFSET_Y;
	
	counter_ud UX (X_initial, Clock, Resetn, obj_x_load, obj_x_enable, Right, obj_X);
        defparam UX.n = 9;
    counter_ud UY (Y_initial, Clock, Resetn, obj_y_load, obj_y_enable, Down, obj_Y);
        defparam UY.n = 9;

		
	// generate (x, y) coords to read object pixels (i think your code may go here)
    counter_ud U3 ({SPRITE_X_BITS{1'd0}}, Clock, Resetn, pixel_X_load, pixel_X_enable, 1'b1, obj_XC); // object column counter
        defparam U3.n = SPRITE_X_BITS;
    counter_ud U4 ({SPRITE_Y_BITS{1'd0}}, Clock, Resetn, pixel_Y_load, pixel_Y_enable, 1'b1, obj_YC); // object row counter
        defparam U4.n = SPRITE_Y_BITS;	
	
    assign Left = (dir == LEFT);
    assign Right = (dir == RIGHT);
    assign Up = (dir == UP);
    assign Down = (dir == DOWN);
	
	
	// signals to enable 
	
	// FSM state table (this will be changed depending on your code since it uses ps2)
    always @ (*)
        case (y_Q)
            A:  Y_D = B;                        // load (x,y) location counters
            B:  if (go) Y_D = F;                // pushbutton KEY pressed to show object
                else if (ps2_rec) Y_D = C;      // PS2 key received to move object
                else Y_D = B;                   // wait
            C:  if (obj_XC != SPRITE_WIDTH-1) Y_D = C;    // erase row of object
                else Y_D = D;
            D:  if (obj_YC != SPRITE_HEIGHT-1) Y_D = C;    // next row of object to erase
                else Y_D = E;                   // done erase cycle
            E:  Y_D = F;                        // +/- (x,y)
            F:  if (obj_XC != SPRITE_WIDTH-1) Y_D = F;    // draw row of object
                else Y_D = G;
            G:  if (obj_YC != SPRITE_HEIGHT-1) Y_D = F;    // next row of object to draw
                else Y_D = H;                   // done draw cycle
            H:  if (go) Y_D = H;                // wait for KEY press
                else Y_D = B;
            default: Y_D = A;
        endcase
    // FSM outputs
    always @ (*)
    begin
        // default assignments
		obj_x_load = 1'b0;
		obj_y_load = 1'b0;
		obj_x_enable = 1'b0;
		obj_y_enable = 1'b0;
		write = 1'b0;
		
		pixel_X_load = 1'b0;
		pixel_Y_load = 1'b0;
		pixel_X_enable = 1'b0;
		pixel_Y_enable = 1'b0;
		erase = 1'b0;
		done_write = 1'b0;
		
		case (y_Q) 
			A: begin
				// load starting positions of object
				obj_x_load = 1'b1;
				obj_y_load = 1'b1;
			end
			
			B: begin
				// return to first pixel inside sprite (set pixel counter to 0)
				pixel_X_load = 1'b1;
				pixel_Y_load = 1'b1;
			end
			
			C: begin
				// restore the background pixels inside the sprite across row
				pixel_X_enable = 1'b1; // advance counter
				write = 1'b1;
				erase = 1'b1; // choose background colour
			end
			
			D: begin
				// go to next row while erasing/changing the background
				pixel_X_load = 1'b1;
				pixel_Y_enable = 1'b1;
				erase = 1'b1;
			end
			
			E: begin
				// move object position on the screen (Change this)
				obj_x_enable = Right | Left;
				obj_y_enable = Up | Down;
			end
			
			F: begin
				// draw the pixels of the sprite across the row
				pixel_X_enable = 1'b1;
				write = 1'b1;
			end
			
			G: begin
				// move to next row while drawing
				pixel_X_load = 1'b1;
				pixel_Y_enable = 1'b1;
			end
			
			H: done_write = 1'b1;
		endcase
	end
	

    // FSM state FFs
    always @(posedge Clock)
        if (!Resetn)
            y_Q <= 3'b0;
        else
            y_Q <= Y_D;
	
	
	// reads pixel color from object memory
	object_mem U6 ({obj_YC, obj_XC}, Clock, obj_color);
		defparam U6.n = 9;
		defparam U6.Mn = SPRITE_X_BITS + SPRITE_Y_BITS;
		defparam U6.INIT_FILE = INIT_FILE;
	
	
	// find (x, y) of current pixel to be drawn or erased
	regn U7 (obj_X + obj_XC, Resetn, 1'b1, Clock, VGA_x);
		defparam U7.n = 9;
	
	regn U8 (obj_Y + obj_YC, Resetn, 1'b1, Clock, VGA_y);
		defparam U8.n = 9;
	
	// synchronize write signal with VGA_x, VGA_y, VGA_color 
    regn U9 (write, Resetn, 1'b1, Clock, VGA_write);
        defparam U9.n = 1;
		
	// remember erase or draw for pixel for one clock cycle since memory is slower
	reg erase_delay;
	 
	always @(posedge Clock) begin
		if (!Resetn)
			erase_delay <= 1'b0;
		else 
			erase_delay <= erase;
	end
	 
	wire [8:0] background_color;
	// select color for the pixel stored in the ROM	 
	wire transparent_pixel;
	assign transparent_pixel = (obj_color == 9'b111000111);
	 
	assign VGA_color = (erase_delay || transparent_pixel) ? background_color : obj_color;
	 
	// use background when erasing by making background a read only inside ROM
	 
	// screen coordinates assign the background pixels
	wire [8:0] background_x;
	wire [8:0] background_y;
	
	assign background_x = obj_X + obj_XC;
	assign background_y = obj_Y + obj_YC;
	 
	wire [16:0] background_address;
	 
	assign background_address = background_y * 17'd320 + background_x;

	// read pixel colour from the background ROM
	background_mem b0 (
		.address(background_address),
		.clock(Clock),
		.q(background_color)
	);
	 

endmodule
	
	
	