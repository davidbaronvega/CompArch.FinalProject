module cpu_tb;

	wire[31:0] PC, IR, ALUOut, MDR, A, B, reg8, reg9;
	reg clock;
	
	CPU cpu1 (clock,PC, IR, ALUOut, MDR, A, B, reg8, reg9);// Instantiate CPU module  
	
	initial begin
		clock = 0;
		repeat (104) // 2*51 + padding needed
		  begin
			#10 clock = ~clock; //alternate clock signal
		  end
		$finish; 
	end
			
endmodule
