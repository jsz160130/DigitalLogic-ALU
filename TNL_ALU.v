// todo: Do or/and/not/xor have to work with 16-bit inputs? It doesn't even work like that right?
//		 Subtract, Multiply, Divide

/**************************************************************
			MODULES
**************************************************************/

//////////////////////////////////////////////////////
//			Helper Modules - DO NOT USE
//////////////////////////////////////////////////////

//	Helper for the add module
module Add_half (input a, b, output c, s);
	xor (s, a, b);
	and (c, a, b);
endmodule

//	Helper for the add module
module Add_full (input a, b, c_in, output c_out, s);
	wire w1, w2, w3;
	Add_half M0(a, b, w1, w2);
	Add_half M1(w2, c_in, w3, s);
	or (c_out, w1, w3);
endmodule

//////////////////////////////////////////////////////
//			 Substantial Modules
//////////////////////////////////////////////////////

// OR two wires
module OR (input a, b, output c);
	or (c, a, b);
endmodule

// AND two wires
module AND (input a, b, output c);
	and (c, a, b);
endmodule

// Negate a wire
module NOT (input a, output b);
	not (b, a);
endmodule

// XOR two wires
module XOR (input a, b, output c);
	xor (c, a, b);
endmodule

// Add together two 16-bit numbers
// Input: 16-bit a, b
// Output: 16-bit s
module Add_16 (input [15:0] a, b, output [15:0] s);
	
	wire [15:0] carry;	//Stores intermediate carries
	genvar i;			//Loop variable
	//The first addition must be done with a static 0, so it can't be in the loop
	Add_full AF1(a[0], b[0], 1'b0, carry[0], s[0]);
	
	generate for (i = 1; i < 16; i = i + 1)			//Skip 0 because first addition was already done
		begin
			Add_full AF2(a[i], b[i], carry[i-1], carry[i], s[i]);
		end
	endgenerate
	
endmodule


/**************************************************************
			MAIN
**************************************************************/

module testbench();

	//Currently this code is for testing. a, b, and s are for addition and the rest are for the logical operations. 
	reg [15:0] a, b;
	reg [2:0] x, y;
	reg neg;
	wire [15:0] s;
	wire [3:0] z;
	Add_16 add(a, b, s);
	OR disj(x[0], y[0], z[0]);
	AND conj(x[1], y[1], z[1]);
	NOT negate(neg, z[2]);
	XOR notsame(x[2], y[2], z[3]);
	
	initial begin
	a = 16'd756;
	b = 16'd3080;
	x = 3'b000;
	y = 3'b111;
	neg = 0;
	#5;
	$display("\nDEMONSTRATION:\n");
	$display("0 OR 1: %d", z[0]);
	$display("0 AND 1: %d", z[1]);
	$display("NOT 0: %d", z[2]);
	$display("0 XOR 1: ", z[3]);
	$display("756 + 3080: %5d", s);
	
	$finish;	
	end
	
endmodule