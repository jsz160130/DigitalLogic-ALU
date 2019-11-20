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
module Or_16 (input [15:0] a, b, output [15:0] c);

	genvar i;
	
	generate for (i = 0; i < 16; i = i + 1)
		begin
			or (c[i], a[i], b[i]);
		end
	endgenerate
	
endmodule

// AND two wires
module And_16 (input [15:0] a, b, output [15:0] c);

	genvar i;
	
	generate for (i = 0; i < 16; i = i + 1)
		begin
			and (c[i], a[i], b[i]);
		end
	endgenerate
	
endmodule

// Negate a wire
module Not_16 (input [15:0] a, output [15:0] b);

	genvar i;
	
	generate for (i = 0; i < 16; i = i + 1)
		begin
			not (b[i], a[i]);
		end
	endgenerate
	
endmodule

// XOR two wires
module Xor_16 (input [15:0] a, b, output [15:0] c);

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

	wire err_placeholder;
	Divide_16 shift(a, 16'b0000000000000010, err_placeholder, b);
	
endmodule

/************ Arithmetic Operations **********************/

//Add a and b. Error bit is set to 1 if there is overflow.
module Add_16 (input [15:0] a, b, output err, output [15:0] s);
	
	wire [15:0] carry;	//Stores intermediate carries
	genvar i;			//Loop variable
	//The first addition must be done with a static 0, so it can't be in the loop
	Add_full AF1(a[0], b[0], 1'b0, carry[0], s[0]);
	
	generate for (i = 1; i < 16; i = i + 1)			//Skip 0 because first addition was already done
		begin
			Add_full AF2(a[i], b[i], carry[i-1], carry[i], s[i]);
		end
	endgenerate
	
	assign err = carry[15] & 1'b1;
	
endmodule

//Subtract a and b. Error bit is set to 1 if the result is negative (i.e. a < b)
module Subtract_16 (input [15:0] a, b, output err, output [15:0] s);
	
	reg err;
	always @(*) begin
		err = 1'b0;
		if (a < b)
			begin
				err = 1'b1;
			end
	end
	
	wire [15:0] neg_b, inter_s;
	wire err_placeholder;
	Not_16 n(b, neg_b);
	
	Add_16 A16(a, neg_b, err_placeholder, inter_s);
	Add_16 A162(inter_s, 16'd1, err_placeholder, s);
		
endmodule

module Multiply_16 (input [15:0] a, b, output [31:0] p);

	reg [31:0] p;
	always @(a, b, p) begin;
		p = a*b;
	end
	
endmodule

//Divide a by b. b cannot be 0. Error is 1 if b is 0.
module Divide_16 (input [15:0] a, b, output err, output [15:0] q);

	
	reg [15:0] q;
	reg [4:0] i;
	reg err;
	reg b_placeholder; //have to store current b bit because we have to invert it
	
	always @(a, b, q) begin;
		q = a / b;
		err = 1'b1;
		
		//Check if b is all 0's - start err at 1 (assume all 0's) then set to 0 if any bit is 1 (i.e. one of them is non-zero)
		for (i = 0; i < 15; i = i + 1)
		begin
			b_placeholder = b[i];
			b_placeholder = !b_placeholder;
			err = b_placeholder & err;	//ANDing err with b[i]' will result in err being 0 if it's a 1 and 1 otherwise
		end
		
	end

endmodule

//Returns the factorial of a in 32 bit output. The input must be a non-negative whole number no greater than 12. Error is set to 1 if it is greater than 12.
module Fact_16 (input [15:0] a, output err, output [31:0] o);

	reg err;
	reg [15:0] i;
	reg [31:0] o;	
	
	always @* begin
		o = 32'd1;		//Start with the output equal to 1.
		
		if (a > 12)
		begin
			err = 1'b1;
		end
		else if (a != 0)
		begin
			for (i = a; i != 1; i = i - 1)
				o = o * i;	
		end
	end

endmodule


//Returns e raised to the input. Whole numbers only. Output is 32-bit, so the maximum input is 22.
//Obviously there will be some error since we are using a power series approximation and there are
// no floating points. Err is set to 1 if input is greater than 22.
module Exp_16 (input [15:0] a, output err, output [31:0] o);

	reg err;
	reg [15:0] i;
	reg [31:0] o;
	reg [255:0] out, factorial;
	
	always @(*) begin
		
		err = 1'b0;
		out = 255'd1;
		factorial = 255'd1;
		if (a > 22) 
		begin
			err = 1'b1;
			assign o = 0;
		end
		else
		begin
			for (i = 1; i < ((a ** 2)/2); i = i + 1)
			begin
				factorial = factorial*i;		//Unfortunately our Fact_16 module cannot be used here. 
				out = out + ((a ** i)/factorial);
			end
			assign o = out;
		end
	end
	
endmodule

module DFF (input clock, input [15:0] in, output[15:0] out);
	reg [15:0] out;

	always @(posedge clock)
		out = in;
	
endmodule

//Mux with 1 bit selector for 16 bit input/output. If selector is 0, in1 is chosen. If 1, in2 is chosen.
module Mux_2 (input [15:0] in1, in2, input selector, output[15:0] out);

	reg [4:0] i;
	reg [15:0] out;
	always @(*) begin
		for (i = 0; i < 16; i = i + 1)
			out[i] = ~selector & in1[i] |
					selector & in2[i] ;
	end
		
endmodule


//ALU module inputs: 2 8-bit variables, and 3-bit opcode and reset but. output:8-bit result, 1-bit reset/error
module SixteenBit_ALU(input clk, input [15:0] a,b, acc, input [5:0] sel, output reg [31:0] out, output reset);

	wire [15:0] SR, SL, SUM, SUB, DIV, AND, OR, NOT, XOR;
	wire [31:0] MULT, EXP, FACT;
	wire [15:0] SR_ACC, SL_ACC, SUM_ACC, SUB_ACC, DIV_ACC, AND_ACC, OR_ACC, NOT_ACC, XOR_ACC;
	wire [31:0] MULT_ACC, EXP_ACC, FACT_ACC;
	wire err;
	reg reset;
	
	Not_16 n(a, NOT);
	Or_16 o(a, b, OR);
	And_16 andy(a, b, AND);
	Xor_16 xory(a, b, XOR);
	ShiftLeft sl(a, SL);
	ShiftRight sr (a, SR);
	Add_16 add(a,b,err,SUM);
	Subtract_16 sub(a,b,err,SUB);
	Multiply_16 mult(a,b,MULT);
	Divide_16 div(a,b,err,DIV);
	Fact_16 fact(a, err, FACT);
	Exp_16 exp(a, err, EXP);
	
	
	Not_16 n_acc(acc, NOT_ACC);
	Or_16 o_acc(acc, b, OR_ACC);
	And_16 andy_acc(acc, b, AND_ACC);
	Xor_16 xory_acc(acc, b, XOR_ACC);
	ShiftLeft sl_acc(acc, SL_ACC);
	ShiftRight sr_acc (acc, SR_ACC);
	Add_16 add_acc(acc,b,err,SUM_ACC);
	Subtract_16 sub_acc(acc,b,err,SUB_ACC);
	Multiply_16 mult_acc(acc,b,MULT_ACC);
	Divide_16 div_acc(acc,b,err,DIV_ACC);
	Fact_16 fact_acc(acc, err, FACT_ACC);
	Exp_16 exp_acc(acc, err, EXP_ACC);
	
	
	always @(*) begin
		reset = 0; out = 31'b0;
		case(sel)
			//clear
			5'd0 : reset = 1; 
			//not
			5'd1 : out = NOT;
			//>>
			5'd2 : out = SR;
			//<<
			5'd3 : out = SL;
			//!
			5'd4 : out = FACT;
			//e^x
			5'd5 : out = EXP;
			//+
			5'd6 : out = SUM;
			//-
			5'd7 : out = SUB;
			//x
			5'd8 : out = MULT;
			//divide
			5'd9 : out = DIV;
			//and
			5'd10 : out = AND;
			//or
			5'd11 : out = OR;
			//xor
			5'd12 : out = XOR;
			//Accumulator opcodes
			//not
			5'd13 : out = NOT_ACC;
			//>>
			5'd14 : out = SR_ACC;
			//<<
			5'd15 : out = SL_ACC;
			//!
			5'd16 : out = FACT_ACC;
			//e^x
			5'd17 : out = EXP_ACC;
			//+
			5'd18 : out = SUM_ACC;
			//-
			5'd19 : out = SUB_ACC;
			//x
			5'd20 : out = MULT_ACC;
			//divide
			5'd21 : out = DIV_ACC;
			//and
			5'd22 : out = AND_ACC;
			//or
			5'd23 : out = OR_ACC;
			//xor
			5'd24 : out = XOR_ACC;
		endcase
	end
endmodule

/**************************************************************
			MAIN
**************************************************************/

module testbench();

	reg [15:0] inA, inB, inAcc;
	wire [15:0] outA, outB, outAcc, MuxOutA, MuxOutB, MuxOutAcc;

	reg [5:0] selector;
	
 	wire [31:0] out;
	reg clock;
	wire reset;

	Mux_2 MuxA(inA, 16'b0, reset, MuxOutA);
	Mux_2 MuxB(inB, 16'b0, reset, MuxOutB);
	Mux_2 MuxAcc(out, 16'b0, reset, MuxOutAcc);
	DFF a(clock, MuxOutA, outA);
	DFF b(clock, MuxOutB, outB);
	DFF acc(clock, MuxOutAcc, outAcc);

	SixteenBit_ALU ALU(clock,outA,outB,outAcc,selector,out,reset);
	
	initial begin
		forever begin
			#5
			clock = 1'b0;
			#5
			clock = 1'b1;
		end
	end		
	
	//Reset is handled by the ALU. No need to have it as a stimulus!
	//When you set the input for an operation, the input MUST be set the clock cycle BEFORE to give the clocks a chance to set them.
	initial begin
		#1
		#10
		selector = 5'd0;	//Clear
		inA = 16'd2;		//Set A to 5 a full cycle before we take its factorial below
		
		#10
		selector = 5'd3;	//5 factorial
		inB = 16'd20;
		
		#10
		selector = 5'd19;	//5 factorial - 20
		
		#10
		selector = 5'd13;	//Negate the result
		
		#10
		selector = 5'd0;	//Clear
		inA = 16'd2;
		inB = 16'd20;
		
		#10
		selector = 5'd12;	//Bitwise XOR 2 and 20
		
		#10
		$finish;
	end

	initial begin
		#2
		forever begin
			#10
			$display("Output: %16b", out);
		end
	end
endmodule
