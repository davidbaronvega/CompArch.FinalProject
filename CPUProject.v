//Created by David Baron-Vega, Daniel Forta, and Alexander Toghe
module CPU (clock,PC, IR, ALUOut, MDR, A, B, reg8);
	parameter R_FORMAT = 6'b000000;
	parameter LW  	   = 6'b100011;
	parameter SW  	   = 6'b101011;
	parameter BEQ 	   = 6'b000100;
	parameter BNE      = 6'b000101;
	parameter ADDI     = 6'b001000;
	parameter JM       = 6'b111011;			//Value seems to be unused
	// other opcodes go here
	//....
	
	input clock;  //the clock is an external input
	//Make these datapath registers available outside the module in order to do the testing
	output PC, IR, ALUOut, MDR, A, B;
	reg[31:0] PC, IR, ALUOut, MDR, A, B;

	
	// The architecturally visible registers and scratch registers for implementation
	reg [31:0] Regs[0:31], Memory [0:1023];
	reg [2:0] state; // processor state
	wire [5:0] opcode; //use to get opcode easily
	wire [31:0] SignExtend, PCOffset; //used to get sign extended offset field
	
	assign opcode = IR[31:26]; //opcode is upper 6 bits
		//sign extension of lower 16-bits of instruction
	assign SignExtend = {{16{IR[15]}},IR[15:0]}; 
	assign PCOffset = SignExtend << 2; //PC offset is shifted
	
	
	wire [31:0] reg8;
	output [31:0] reg8; //output reg 8 for testing
	assign reg8 = Regs[8]; //output reg 8 (i.e. $t0)
	
	
	initial begin  	//Load a MIPS test program and data into Memory
		
		//Memory[2] =  ...place binary instruction...  ;       //  show the actual MIPS assembly instruction as a comment
		//Memory[3] =  ...place binary instruction...  ;       //  show the actual MIPS assembly instruction as a comment
 
		//Memory[30] = ...place binary instruction...  ;       //  show the actual MIPS assembly instruction as a comment

	end
	
	
	initial  begin  // set the PC to 8 and start the control in state 1 to start fetch instructions from Memory[2] (byte 8)
		PC = 8; 
		state = 1; 
	end
	
	always @(posedge clock) begin
		//make R0 0 
		//short-cut way to make sure R0 is always 0
		Regs[0] = 0; 
		
		case (state) //action depends on the state
		
			1: begin     //first step: fetch the instruction, increment PC, go to next state	
				IR <= Memory[PC>>2]; //changed
				PC <= PC + 4;        //changed
				state = 2; //next state
			end
				
			2: begin     //second step: Instruction decode, register fetch, also compute branch address
				A <= Regs[IR[25:21]];	//rs register
				state = 3;
			end
			
			3: begin	//third step: Only runs if rt read is required
				B <= Regs[IR[20:16]];		//rt register
				ALUOut <= PC + PCOffset; 	// compute PC-relative branch target
				state = 4;
			end
			
			4: begin     //fourth step:  Load/Store execution, ALU execution, Branch completion
				state = 5; // default next state
				if (opcode == R_FORMAT) 
					case (IR[5:0]) //case for the various R-type instructions
						32: ALUOut = A + B; //add operation
						34: ALUOut = A - B; //sub operation
						39: ALUOut = ~(A | B); //nor operation  (MAYBE FIX)
						57: begin								//57 = (0x38 + 1)
								A <= B;		//Non-blocking setting A = B  (MAYBE FIX)
								B <= A;		//Non-blocking setting B = A  (MAYBE FIX)
							end
						// other function fields for R-Format instructions go here
						//  
						// 
						default: ALUOut = A; //other R-type operations
					endcase
				else if ((opcode == LW) | (opcode==SW) | (opcode==JM)) 
					ALUOut <= A + SignExtend; //compute effective address
				else if (opcode == BEQ) begin
					if (A==B)  
						PC <= ALUOut; // branch taken--update PC
					state = 1;  //  BEQ finished, return to first state
				end
				else if (opcode == BNE) begin
					if (A!=B)  
						PC <= ALUOut; // branch taken--update PC
					state = 1;  //  BEQ finished, return to first state
				end
				else if (opcode == ADDI) begin
					ALUOut <= A + SignExtend;
				end
				// implementations of other instructions (such bne, addi, etc.) as go here
				// else if ... 
				// ...
				// else if ...
				// ...
			end
		
			5: begin	//fifth step
				if (opcode == R_FORMAT) begin //ALU Operation (SPLIT INTO 2 STEPS)
					if (IR[5:0] == 57) begin	//if SWAP operation value
						Regs[IR[25:21]] <= A;	//rs = A which is now equal to original rt (from B)
						state = 6;
					end
					else begin
						Regs[IR[15:11]] <= ALUOut; // write the result
						state = 1;
					end
				end //R-type finishes
				
				else if ((opcode == LW) | (opcode == JM)) begin // load instruction
					MDR <= Memory[ALUOut>>2]; // read the memory
					state = 6; // next state
				end
				
				else if (opcode == SW) begin
					Memory[ALUOut>>2] <= B; // write the memory
					state = 1; // return to state 1
				end //store finishes
				
				else if (opcode == ADDI) begin
					Regs[IR[20:16]] <= ALUOut; // write the result to rt
					state = 1;
				end
				
				// implementations of other instructions (such as addi, etc.) go here
				// else if ...
				// ...
				// else if ...
				// ...
	
			end
		
			6: begin     //LW or JM write the MDR value
				if (opcode == R_FORMAT) begin //ALU Operation (SPLIT INTO 2 STEPS) (only swap R format makes it here)
						Regs[IR[20:16]] <= B;	//rt = B which is now equal to original rs (from A)
						state = 1;
				end //R-type finishes
				
				if (opcode == LW) begin
					Regs[IR[20:16]] = MDR; 		// write the MDR to the register
					state = 1;
				end
				
				else if (opcode == JM) begin
					PC = MDR;					// write the MDR to the PC
					state = 1;
				end
			end //complete a LW instruction
				
		endcase
		
	end // always
	
endmodule

