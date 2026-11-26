// 320/16 = 20 col; 240/16 = 15 row; 300 tiles total
// 0 - empty; 1 - solid wall; 2 - obstacle  
// address = tile_row × 20 + tile_column
`default_nettype none


module tile_map (Clock, address, tile_ID);
	input wire Clock;
	input wire [8:0] address;
	output reg [3:0] title_ID;
	
	reg [3:0] tiles [0:299]; // 300 4-bit tiles
	
	initial begin
		$readmemh("./MIF/level1.mif", tiles); // read into tiles
	end
	
	always @(*) begin
		if (address < 300)
			tile_ID = titles[address]; // return ID of requested tile at address
		else 
			tile_ID = 4'd0;
	end
	
endmodule;
	
	

 