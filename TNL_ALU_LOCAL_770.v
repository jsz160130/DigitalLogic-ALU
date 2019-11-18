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
	always @(a, b, p) begin;
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

//Returns the factorial of a in 32 bit output. The input must be a positive whole number no greater than 12.
module Fact_16 (input [15:0] a, output [31:0] o);

	reg [15:0] i;
	reg [31:0] o;	//Start with the output equal to 1.
	
	always @* begin
			
		o = 32'd1;
		for (i = a; i != 1; i = i - 1)
			o = o * i;	
		
	end

endmodule

//Returns e raised to the input. Whole numbers only. Output is 32-bit, so the maximum input is 22.
//Obviously there will be some error since we are using a power series approximation and there are
// no floating points.
module Exp_16 (input [15:0] a, output [31:0] o);

	reg [15:0] i;
	reg [31:0] o;
	reg [255:0] out, factorial;
	
	always @* begin
		
		out = 255'd1;
		factorial = 255'd1;
		for (i = 1; i < ((a ** 2)/2); i = i + 1)
		begin
			factorial = factorial*i;		//Unfortunately our Fact_16 module cannot be used here. 
			out = out + ((a ** i)/factorial);
		end
		assign o = out;
	end
	
endmodule


module Arithmetic(a,b,l_in,L_result);

	wire [15:0] SUM1, [15:0] SUB1], [15:0] MULT1, [15:0] DIV1;
	wire [15:0] A_result
		
	Add_16 add(a,b,C_in1,C_out1,SUM1);
	Subtract_16 sub((a,b,C_in1,C_out1,SUB1);
	Multiply_16 mult((a,b,C_in1,C_out1,MULT1);
	Divide_16 div((a,b,C_in1,C_out1,DIV1);

	// ...

endmodule

module Logic(a,b,l_in,L_result);

	wire [15:0] L_result

	always @(*) begin
		//detection of operation code
		case(sel)
			//and
			2'b00 : out = a & b;
			//or
			2'b01 : out = a | b;
			//xor
			2'b10 : out = a ^ b;
			//not
			2'b11 : out = ~a;
		endcase
	end
	
endmodule

module Shifter(a,b,l_in,L_result);

	wire [15:0] S_result

	always @(*) begin
		//detection of operation code
		case(sel)
			//and
			1'b0 : out = a<<1;
			//or
			1'b1 : out = a>>1;
		endcase
	end
	
endmodule

//ALU module inputs: 2 8-bit variables, and 3-bit opcode and reset but. output:8-bit result, 1-bit reset/error
module SixteenBit_ALU(input clk,reset, input [15:0] a,b, input [2:0] sel, output reg [15:0] out, output reg rst);
	
	wire C_in1 = sel[0];
  	wire  S_in = sel[0];
  	wire [1:0]l_in = sel[1:0];
    wire C_out1;

	Arithmetic(a, b, C_int1, C_out1);
	Logic(a, b, C_int1, C_out1);
	Shifter(a, b, C_int1, C_out1);
	
endmodule


/**************************************************************
			MAIN
**************************************************************/

module testbench();

	//Currently this code is for testing. a, b, and s are for arithmetic and the rest are for the logical operations. 
	reg [15:0] a, b, c, x, y, f, e;					//a and b are for testing arithmetic and c is for testing NOT. x and y are for AND, OR, and XOR. f and e are for factorial/exponentiation.
	reg r;
	reg [2:0] s;
	
// 	wire [15:0] s_add, s_sub, s_div, c_neg;		//s wires hold the output for arithmetic operations and c_neg negation.
// 	wire [31:0] s_mult, s_fact, s_exp;
// 	wire [4:0] [15:0] z;						//z holds the outputs for OR, AND, XOR, and the shift logicals.
// 	OR disj(x, y, z[0]);
// 	AND conj(x, y, z[1]);
// 	NOT negate(c, c_neg);
// 	XOR notgsame(x, y, z[2]);
// 	ShiftLeft sll(x, z[3]);
// 	ShiftRight srl(x, z[4]);
// 	Add_16 add(a, b, s_add);
// 	Subtract_16 sub(a, b, s_sub);
// 	Multiply_16 mult(a, b, s_mult);
// 	Divide_16 div(a, b, s_div);
// 	Fact_16 fact(f, s_fact);
// 	Exp_16 exp(e, s_exp);
	
	wire carry, ovf;
  	wire [15:0] out, prevR;
  	wire clock, prevReset;
  	wire reset;
	Clock c0(clock);

	SixteenBit_ALU ALU(clock,r,a,b,s,out,reset);
	
// 	initial begin
// 	a = 16'd3080;
// 	b = 16'd756;
// 	x = 16'd9568;
// 	y = 16'd29408;
// 	c = 16'd15894;
// 	f = 16'd12;
// 	e = 16'd22;
// 	#50;
// 	$display("\nDEMONSTRATION:\n");
// 	$display("\nOR:");
// 	$display("%16b\n%16b\n________________\n%16b", x, y, z[0]);
// 	$display("\nAND:");
// 	$display("%16b\n%16b\n________________\n%16b", x, y, z[1]);
// 	$display("\nNOT:");
// 	$display("%16b\n________________\n%16b", c, c_neg);
// 	$display("\nXOR:");
// 	$display("%16b\n%16b\n________________\n%16b", x, y, z[2]);
// 	$display("\nSHIFT LEFT:");
// 	$display("%16b\n________________\n%16b", x, z[3]);
// 	$display("\nSHIFT RIGHT:");
// 	$display("%16b\n________________\n%16b", x, z[4]);
// 	
// 	$display("\nADD:");
// 	$display("%4d\n%4d\n____\n%4d", a, b, s_add);
// 	$display("\nSUBTRACT:");
// 	$display("%4d\n%4d\n____\n%4d", a, b, s_sub);
// 	$display("\nMULTIPLY:");
// 	$display("   %4d\n   %4d\n_______\n%7d", a, b, s_mult);
// 	$display("\nDIVIDE:");
// 	$display("%4d\n%4d\n____\n%4d", a, b, s_div);
// 	$display("\nFACTORIAL:");
// 	$display("%2d! = %5d", f, s_fact);
// 	$display("\nEXPONENTIATION:");
// 	$display("e^%2d ~= %5d", e, s_exp);
// 	$finish;	
// 	end
	
endmodule