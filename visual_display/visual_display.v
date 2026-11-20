`default_nettype none

/* Displays a background and a movable sprite on the VGA output.
 * Press KEY[0] to reset, then KEY[1] to draw the sprite.
 * Move the sprite left/right/up/down with the PS/2 keys a/s/w/z.
 */
module visual_display (CLOCK_50, SW, KEY,
				VGA_R, VGA_G, VGA_B,
				VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK, player_x, player_y);

    // specify the number of bits needed for an X (column) pixel coordinate on the VGA display
    parameter nX = 10;
    // specify the number of bits needed for a Y (row) pixel coordinate on the VGA display
    parameter nY = 9;

    // state names for the keyboard command FSM
    parameter A = 2'b00, B = 2'b01, C = 2'b10, D = 2'b11;

	input wire CLOCK_50;	
	input wire [9:0] SW;
	input wire [3:0] KEY;
	output wire [9:0] LEDR;
    output wire [6:0] HEX5, HEX4, HEX3, HEX2, HEX1, HEX0;
	output wire [7:0] VGA_R;
	output wire [7:0] VGA_G;
	output wire [7:0] VGA_B;
	output wire VGA_HS;
	output wire VGA_VS;
	output wire VGA_BLANK_N;
	output wire VGA_SYNC_N;
	output wire VGA_CLK;	
	
    wire [nX-1:0] O1_x;
    wire [nY-1:0] O1_y;

    input [8:0] player_x;
    input [7:0] player_y;

    wire [8:0] O1_color;
    wire O1_write;

    reg [3:0] Packet;               // used to know when 11 bits have been received
    wire [7:0] scancode;            // used to save the current ps2 scancode
    reg Esc;                        // enable scancode register
    reg step;                       // move an object
    wire O1_done;                   // sprite draw or move completed
    wire [1:0] O1_dir;
    wire move_key;                  // scan code is one of the movement keys
    reg [1:0] y_Q, Y_D;             // keyboard command FSM

    wire Resetn, KEY1;

    assign Resetn = KEY[0];
    sync S1 (~KEY[1], Resetn, CLOCK_50, KEY1);

    // instantiate the sprite
    object O1 (Resetn, CLOCK_50, KEY1, step, O1_dir, O1_x, O1_y,
               O1_color, O1_write, player_x, player_y, O1_done);
		  
	// instantiate the box
	wire [8:0] box_x, box_color;
	wire [7:0] box_y;
	wire box_write, box_done;
	
	/*
	draw_boxes Boxes (
		.Clock(CLOCK_50),
		.Resetn(Resetn),
		.x(box_x),
		.y(box_y),
		.color(box_color),
		.write(box_write),
		.done(boxes_done)
	);
	*/
		

    // display PS2 data

    // connect to VGA controller
    vga_adapter VGA (
			.resetn(Resetn),
			.clock(CLOCK_50),
			.color(O1_color),
			.x(O1_x),
			.y(O1_y),
			.write(O1_write),
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK_N(VGA_BLANK_N),
			.VGA_SYNC_N(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
			
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

// n-bit up/down-counter with reset, load, enable, and direction control
module upDn_count (R, Clock, Resetn, L, E, Dir, Q);
    parameter n = 8;
    input wire [n-1:0] R;
    input wire Clock, Resetn, E, L, Dir;
    output reg [n-1:0] Q;

    always @ (posedge Clock)
        if (Resetn == 0)
            Q <= {n{1'b0}};
        else if (L == 1)
            Q <= R;
        else if (E)
            if (Dir)
                Q <= Q + {{n-1{1'b0}},1'b1};
            else
                Q <= Q - {{n-1{1'b0}},1'b1};
endmodule

module hex7seg (hex, display);
    input wire [3:0] hex;
    output reg [6:0] display;

    /*
     *       0  
     *      ---  
     *     |   |
     *    5|   |1
     *     | 6 |
     *      ---  
     *     |   |
     *    4|   |2
     *     |   |
     *      ---  
     *       3  
     */
    always @ (hex)
        case (hex)
            4'h0: display = 7'b1000000;
            4'h1: display = 7'b1111001;
            4'h2: display = 7'b0100100;
            4'h3: display = 7'b0110000;
            4'h4: display = 7'b0011001;
            4'h5: display = 7'b0010010;
            4'h6: display = 7'b0000010;
            4'h7: display = 7'b1111000;
            4'h8: display = 7'b0000000;
            4'h9: display = 7'b0011000;
            4'hA: display = 7'b0001000;
            4'hB: display = 7'b0000011;
            4'hC: display = 7'b1000110;
            4'hD: display = 7'b0100001;
            4'hE: display = 7'b0000110;
            4'hF: display = 7'b0001110;
        endcase
endmodule

// implements a movable object
module object (Resetn, Clock, go, ps2_rec, dir, VGA_x, VGA_y, VGA_color, VGA_write, done, X, Y);
    // specify the number of bits needed for an X (column) pixel coordinate on the VGA display
    parameter nX = 9;
    // specify the number of bits needed for a Y (row) pixel coordinate on the VGA display
    parameter nY = 8;
    // by default, use offsets to center the object on the VGA display
    parameter XOFFSET = 0;
    parameter YOFFSET = 0;
    parameter LEFT = 2'b00 /*'a'*/, RIGHT = 2'b11/*'s'*/, UP = 2'b01/*'w'*/, DOWN = 2'b10/*'z'*/;
    parameter xOBJ = 4, yOBJ = 4;   // object size is 2^xOBJ x 2^yOBJ
    parameter BOX_SIZE_X = 1 << xOBJ;
    parameter BOX_SIZE_Y = 1 << yOBJ;
    parameter Mn = xOBJ + yOBJ; // address lines needed for the object memory
    parameter INIT_FILE = "./MIF/test_sprite2.mif";
	 parameter WORDS = 1 << Mn;

    // state names for the FSM that draws the object
    parameter A = 3'b000, B = 3'b001, C = 3'b010, D = 3'b011, E = 3'b100,
              F = 3'b101, G = 3'b110, H = 3'b111;
				  
    input wire Resetn, Clock;
    input wire go;                              // can be used to draw at initial position
    input wire ps2_rec;                         // PS2 data received
    input wire [1:0] dir;                       // movement direction
    input wire [8:0] X;
    input wire [7:0] Y;
	output wire [nX-1:0] VGA_x;                 // for syncing with object memory
	output wire [nY-1:0] VGA_y;                 // for syncing with object memory
	output wire [8:0] VGA_color;                // used to draw pixels
    output wire VGA_write;                      // pixel write control
    output reg done;                            // done drawing cycle

	wire [nX-1:0] X0;    // starting X location 
	wire [nY-1:0] Y0;    // starting Y location 
	wire [nX-1:0] size_x = BOX_SIZE_X;   // store the X size (must be power of 2)
	wire [nY-1:0] size_y = BOX_SIZE_Y;   // store the Y size
    wire [xOBJ-1:0] XC;                  // used to access object memory
    wire [yOBJ-1:0] YC;                  // used to access object memory
    reg write, Lxc, Lyc, Exc, Eyc;       // object control signals
    reg erase;                           // erase/draw object
    wire Right, Left, Up, Down;          // object direction
    reg Lx, Ly, Ex, Ey;                  // object counter controls
    reg [2:0] y_Q, Y_D;                  // FSM
    
	wire [8:0] obj_color;    // object pixel colors, read from memory
	
    // object (x,y) location. For x, counter will be enabled when moving L/R, increment
    // for R, decrement for L. For y, counter will be enabled when moving U/D, increment 
    // for D, decrement for U
    assign X0 = XOFFSET;
    assign Y0 = YOFFSET;

    // these counter are used to generate (x,y) coordinates to read the object's pixels
    upDn_count U3 ({xOBJ{1'd0}}, Clock, Resetn, Lxc, Exc, 1'b1, XC); // object column counter
        defparam U3.n = xOBJ;
    upDn_count U4 ({yOBJ{1'd0}}, Clock, Resetn, Lyc, Eyc, 1'b1, YC); // object row counter
        defparam U4.n = yOBJ;

    // these signals are used to enable the (x,y) object location counters and to make these 
    // counters increment or decrement
    assign Left = (dir == LEFT);
    assign Right = (dir == RIGHT);
    assign Up = (dir == UP);
    assign Down = (dir == DOWN);

    // FSM state table
    always @ (*)
        case (y_Q)
            A:  Y_D = B;                        // load (x,y) location counters
            B:  if (go) Y_D = F;                // pushbutton KEY pressed to show object
                else if (ps2_rec) Y_D = C;      // PS2 key received to move object
                else Y_D = B;                   // wait
            C:  if (XC != size_x-1) Y_D = C;    // erase row of object
                else Y_D = D;
            D:  if (YC != size_y-1) Y_D = C;    // next row of object to erase
                else Y_D = E;                   // done erase cycle
            E:  Y_D = F;                        // +/- (x,y)
            F:  if (XC != size_x-1) Y_D = F;    // draw row of object
                else Y_D = G;
            G:  if (YC != size_y-1) Y_D = F;    // next row of object to draw
                else Y_D = H;                   // done draw cycle
            H:  if (go) Y_D = H;                // wait for KEY press
                else Y_D = B;
            default: Y_D = A;
        endcase
    // FSM outputs
    always @ (*)
    begin
        // default assignments
        Lx = 1'b0; Ly = 1'b0; Ex = 1'b0; Ey = 1'b0; write = 1'b0; 
        Lxc = 1'b0; Lyc = 1'b0; Exc = 1'b0; Eyc = 1'b0; erase = 1'b0; done = 1'b0;
        case (y_Q)
            A:  begin Lx = 1'b1; Ly = 1'b1; end                   // load (X,Y) counters
            B:  begin Lxc = 1'b1; Lyc = 1'b1; end                 // load (XC,YC) counters
            C:  begin Exc = 1'b1; write = 1'b1; erase = 1'b1; end // enable XC, write pixel
            D:  begin Lxc = 1'b1; Eyc = 1'b1; erase = 1'b1; end   // load XC, enable YC
            // state E is reached after erasing the object. Now, move and draw the object
            E:  begin Ex = Right | Left; Ey = Up | Down; end      // move L/R or U/D
            F:  begin Exc = 1'b1; write = 1'b1; end               // enable XC, write pixel
            G:  begin Lxc = 1'b1; Eyc = 1'b1; end                 // load XC, enable YC
            H:  done = 1'b1;
        endcase
    end

    // FSM state FFs
    always @(posedge Clock)
        if (!Resetn)
            y_Q <= 3'b0;
        else
            y_Q <= Y_D;

    // read a pixel color from the object memory. We can use {YC,XC} because the x dimension
    // of the object memory is a power of 2
    object_mem U6 ({YC,XC}, Clock, obj_color);
        defparam U6.n = 9;
        defparam U6.Mn = xOBJ + yOBJ;
        defparam U6.INIT_FILE = INIT_FILE;

    // compute the (x,y) location of the current pixel to be drawn (or erased). We subtract
    // half the object's width and height because we want the objec to be centered at its 
    // original (x,y) location. We add (Xc,YC) to form the correct address of the pixel. The
    // object memory takes one clock cycle to provide data, so we register the computed (x,y)
    // location to remain synchronized
    regn U7 (X - (size_x >> 1) + XC, Resetn, 1'b1, Clock, VGA_x);
        defparam U7.n = nX;
    regn U8 (Y - (size_y >> 1) + YC, Resetn, 1'b1, Clock, VGA_y);
        defparam U8.n = nY;

    // synchronize write signal with VGA_x, VGA_y, VGA_color 
    regn U9 (write, Resetn, 1'b1, Clock, VGA_write);
        defparam U9.n = 1;

    // use the background color (when erasing), or the object color when drawing
    // (black background is assumed below)
    // assign VGA_color = erase ? {9{1'b0}} : obj_color;
	 
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
	 // assign VGA_color = erase_delay ? background_color : obj_color;
	 
	 wire transparent_pixel;
	 assign transparent_pixel = (obj_color == 9'b111000111);
	 
	 assign VGA_color = (erase_delay || transparent_pixel) ? background_color : obj_color;
	 
	 // use background when erasing by making background a read only inside ROM
	 
	 // screen coordinatesassign the background pixels
	 wire [nX-1:0] background_x;
	 wire [nY-1:0] background_y;
	 
	 assign background_x = X - (size_x >> 1) + XC;
	 assign background_y = Y - (size_y >> 1) + YC;
	 
	 wire [16:0] background_address;
	 
	 assign background_address = background_y * 17'd320 + background_x;

	 // read pixel from the background ROM
	 background_mem b0 (
		.address(background_address),
		.clock(Clock),
		.q(background_color)
	);
	 

endmodule


