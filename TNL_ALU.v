//to-do: Implement divide by 0 error

/**************************************************************
			MODULES
**************************************************************/

///////////////////////////////////////////////////////////
//			Helper Modules - DO NOT USE
///////////////////////////////////////////////////////////

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

///////////////////////////////////////////////////////////
//			 Substantial Modules
///////////////////////////////////////////////////////////

/************ Logic Operations ***************************/

// OR two wires
module OR (input [15:0] a, b, output [15:0] c);

	genvar i;
	
	generate for (i = 0; i < 16; i = i + 1)
		begin
			or (c[i], a[i], b[i]);
		end
	endgenerate
	
endmodule

// AND two wires
module AND (input [15:0] a, b, output [15:0] c);

	genvar i;
	
	generate for (i = 0; i < 16; i = i + 1)
		begin
			and (c[i], a[i], b[i]);
		end
	endgenerate
	
endmodule

// Negate a wire
module NOT (input [15:0] a, output [15:0] b);

	genvar i;
	
	generate for (i = 0; i < 16; i = i + 1)
		begin
			not (b[i], a[i]);
		end
	endgenerate
	
endmodule

// XOR two wires
module XOR (input [15:0] a, b, output [15:0] c);

	genvar i;
	
	generate for (i = 0; i < 16; i = i + 1)
		begin
			xor (c[i], a[i], b[i]);
		end
	endgenerate
	
endmodule

//Shift Left Logical
module ShiftLeft (input[15:0] a, output[15:0] b);

	//Multiplication requires 32 bits so we use an intermediate variable then truncate.
	wire [31:0] raw_shifted;
	Multiply_16 shift(a, 16'b0000000000000010, raw_shifted);
	assign b = raw_shifted[15:0];

endmodule

//Shift Right Logical
module ShiftRight (input[15:0] a, output[15:0] b);

	Divide_16 shift(a, 16'b0000000000000010, b);
	
endmodule

/************ Arithmetic Operations **********************/

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

// **NOTE**: a must be less than b!
module Subtract_16 (input [15:0] a, b, output [15:0] s);
	
	wire [15:0] neg_b, inter_s;
	NOT n(b, neg_b);
	
	Add_16 A16(a, neg_b, inter_s);
	Add_16 A162(inter_s, 16'd1, s);
	
endmodule

module Multiply_16 (input [15:0] a, b, output [31:0] p);

	reg [31:0] p;
	always @(a, b, p) begin ;
		p = a*b;
	end
	
endmodule

//Divide a by b. b cannot be 0. 
module Divide_16 (input [15:0] a, b, output [15:0] q);

	reg [15:0] q;
	always @(a, b, q) begin;
		q = a / b;
	end

endmodule

/**************************************************************
			MAIN
**************************************************************/

module testbench();

	//Currently this code is for testing. a, b, and s are for arithmetic and the rest are for the logical operations. 
	reg [15:0] a, b, c, x, y;					//a and b are for testing arithmetic and c is for testing NOT. x and y are for AND, OR, and XOR.
	wire [15:0] s_add, s_sub, s_div, c_neg;		//s wires hold the output for arithmetic operations and c_neg negation.
	wire [31:0] s_mult;
	wire [4:0] [15:0] z;						//z holds the outputs for OR, AND, XOR, and the shift logicals.
	OR disj(x, y, z[0]);
	AND conj(x, y, z[1]);
	NOT negate(c, c_neg);
	XOR notsame(x, y, z[2]);
	ShiftLeft sll(x, z[3]);
	ShiftRight srl(x, z[4]);
	Add_16 add(a, b, s_add);
	Subtract_16 sub(a, b, s_sub);
	Multiply_16 mult(a, b, s_mult);
	Divide_16 div(a, b, s_div);
	
	initial begin
	a = 16'd3080;
	b = 16'd756;
	x = 16'd9568;
	y = 16'd29408;
	c = 16'd15894;
	#5;
	$display("\nDEMONSTRATION:\n");
	$display("\nOR:");
	$display("%16b\n%16b\n________________\n%16b", x, y, z[0]);
	$display("\nAND:");
	$display("%16b\n%16b\n________________\n%16b", x, y, z[1]);
	$display("\nNOT:");
	$display("%16b\n________________\n%16b", c, c_neg);
	$display("\nXOR:");
	$display("%16b\n%16b\n________________\n%16b", x, y, z[2]);
	$display("\nSHIFT LEFT:");
	$display("%16b\n________________\n%16b", x, z[3]);
	$display("\nSHIFT RIGHT:");
	$display("%16b\n________________\n%16b", x, z[4]);
	
	$display("\nADD:");
	$display("%4d\n%4d\n____\n%4d", a, b, s_add);
	$display("\nSUBTRACT:");
	$display("%4d\n%4d\n____\n%4d", a, b, s_sub);
	$display("\nMULTIPLY:");
	$display("   %4d\n   %4d\n_______\n%7d", a, b, s_mult);
	$display("\nDIVIDE:");
	$display("%4d\n%4d\n____\n%4d", a, b, s_div);
	$finish;	
	end
	
endmodule