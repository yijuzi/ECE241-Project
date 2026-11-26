// 320/16 = 20 col; 240/16 = 15 row; 300 tiles total
// 0 - empty; 1 - solid wall; 2 - obstacle  
// address = tile_row × 20 + tile_column
`default_nettype none


module tile_map (Clock, render_address, render_tile_id, logic_address, logic_tile_id);
	input wire Clock;
	input wire [8:0] render_address, logic_address;
	output wire [3:0] render_tile_id, logic_tile_id;
	
	// reg [3:0] tiles [0:299]; // 300 4-bit tiles
	
	wire [9:0] r_a, l_a;
	
	assign r_a[8:0] = render_address;
	assign r_a[9] = 1'b0;
	
	assign l_a[8:0] = logic_address;
	assign l_a[9] = 1'b0;
	
	rom1024x4 rom (.address_a(r_a), .address_b(l_a), .q_a(render_tile_id), .q_b(logic_tile_id), .clock(Clock));
	
	//initial begin
		//$readmemh("./MIF/level1.mif", tiles); // read into tiles
		//(* ram_init_file = "./MIF/level1.mif" *);
	//end

/*	
	always @(*) begin
		if (address < 300)
			tile_id = tiles[address]; // return ID of requested tile at address
		else 
			tile_id = 4'd0;
	end
	*/
endmodule
	
	

 