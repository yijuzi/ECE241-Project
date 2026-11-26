// 320/16 = 20 col; 240/16 = 15 row; 300 tiles total
// 0 - empty; 1 - solid wall; 2 - obstacle  
// address = tile_row × 20 + tile_column
`default_nettype none


module tile_map (Clock, address, tile_id);
	input wire Clock;
	input wire [8:0] address;
	output reg [3:0] tile_id;
	
	reg [3:0] tiles [0:299]; // 300 4-bit tiles
	
	initial begin
		//$readmemh("./MIF/level1.mif", tiles); // read into tiles
		(* ram_init_file = "./MIF/level1.mif" *) reg [7:0] mem [0:255];
	end
	
	always @(*) begin
		if (address < 300)
			tile_id = tiles[address]; // return ID of requested tile at address
		else 
			tile_id = 4'd0;
	end
	
endmodule
	
	

 