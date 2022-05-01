// controller.sv
//
// This file is for HMC E85A Lab 5.
// Place controller.tv in same computer directory as this file to test your multicycle controller.
//
// Starter code last updated by Ben Bracker (bbracker@hmc.edu) 1/14/21
// - added opcodetype enum
// - updated testbench and hash generator to accomodate don't cares as expected outputs
// Solution code by ________ (________) ________

typedef enum logic[6:0] {r_type_op=7'b0110011, i_type_alu_op=7'b0010011, lw_op=7'b0000011, sw_op=7'b0100011, beq_op=7'b1100011, jal_op=7'b1101111} opcodetype;

module controller(input  logic       clk,
                  input  logic       reset,  
                  input  opcodetype  op,
                  input  logic [2:0] funct3,
                  input  logic       funct7b5,
                  input  logic       Zero,
                  output logic [1:0] ImmSrc,
                  output logic [1:0] ALUSrcA, ALUSrcB,
                  output logic [1:0] ResultSrc, 
                  output logic       AdrSrc,
                  output logic [2:0] ALUControl,
                  output logic       IRWrite, PCWrite, 
                  output logic       RegWrite, MemWrite);
                  
  // Define the states                
  typedef enum logic[3:0] {S0,S1,S2,S3,S4,S5,S6,S7,S8,S9,S10} State;
  State state, nextState;  // define state as current sate and nextState
  logic Branch, PCUpdate;  // define them in order to get the PCWrite output
  logic [1:0] ALUOp;
  
  always @ (posedge clk, posedge reset)
    if (reset) state <= S0;
    else       state <= nextState; 
  
  // next state logic (based on the FSM)  
  always @ (*)
    case(state)
      S0: nextState = S1;
      S1: if(lw_op | sw_op) nextState = S2;
          else if(r_type_op)     nextState = S6;
          else if(i_type_alu_op) nextState = S8;
          else if(jal_op)        nextState = S9;
          else if(beq_op)        nextState = S10;
      S2: if(lw_op)              nextState = S3;
          else if(sw_op)         nextState = S5;
      S6: nextState = S7;
      S8: nextState = S7;
      S9: nextState = S7;
      S10: nextState = S4;
      S3: nextState = S4;
      S5: nextState = S4;
      S7: nextState = S4;
      S4: nextState = S0;
      default: nextState = S0;
  endcase
  
  // output logic
  assign Branch = (state==S10);
  assign PCUpdate = (state==S0 | state==S9);
  assign PCWrite = ((Zero & Branch) | PCUpdate);
  assign RegWrite = (state==S4 | state==S7);
  assign MemWrite = (state==S5);
  assign IRWrite = (state==S0);
  assign ResultSrc[1] = (state==S0);
  assign ResultSrc[0] = (state==S4);
  assign ALUSrcA[1] = (state==S2 | state==S6 | state==S8 | state==S10);
  assign ALUSrcA[0] = (state==S1 | state==S9);
  assign ALUSrcB[1] = (state==S0 | state==S9);
  assign ALUSrcB[0] = (state==S1 | state==S2 | state==S8);
  assign ALUOp[1] = (state==S6 | state==S8);
  assign ALUOp[0] = (state==S10);
  assign AdrSrc = (state==S3 | state==S5);

  // Connect to ALU
  logic x6n,x5n,x4n,x2n;
  logic n1,n2,n3;

  not g1(x5n,ALUOp[0]);
  not g2(x4n,funct3[2]);
  not g3(x2n,funct3[0]);
    
  and g4(ALUControl[2],ALUOp[1],x5n,x4n,funct3[1],x2n);
    
  and g5(ALUControl[1],ALUOp[1],x5n,funct3[2],funct3[1]);
    
  not g6(x6n,ALUOp[1]);
  and g7(n1,x6n,ALUOp[0]);
  and g8(n2,ALUOp[1],x5n,x4n,x2n,op[5],funct7b5);
  and g9(n3,ALUOp[1],x5n,funct3[1],x2n);
  or g10(ALUControl[0],n1,n2,n3);
  
  
  // Instruction decoder
  assign ImmSrc[1] = (beq_op | jal_op);
  assign ImmSrc[0] = (sw_op | jal_op);

endmodule

module testbench();

  logic        clk;
  logic        reset;
  
  opcodetype  op;
  logic [2:0] funct3;
  logic       funct7b5;
  logic       Zero;
  logic [1:0] ImmSrc;
  logic [1:0] ALUSrcA, ALUSrcB;
  logic [1:0] ResultSrc;
  logic       AdrSrc;
  logic [2:0] ALUControl;
  logic       IRWrite, PCWrite;
  logic       RegWrite, MemWrite;
  
  logic [31:0] vectornum, errors;
  logic [39:0] testvectors[10000:0];
  
  logic        new_error;
  logic [15:0] expected;
  logic [6:0]  hash;


  // instantiate device to be tested
  controller dut(clk, reset, op, funct3, funct7b5, Zero,
                 ImmSrc, ALUSrcA, ALUSrcB, ResultSrc, AdrSrc, ALUControl, IRWrite, PCWrite, RegWrite, MemWrite);
  
  // generate clock
  always 
    begin
      clk = 1; #5; clk = 0; #5;
    end

  // at start of test, load vectors and pulse reset
  initial
    begin
      $readmemb("controller.tv", testvectors);
      vectornum = 0; errors = 0; hash = 0;
      reset = 1; #22; reset = 0;
    end
	 
  // apply test vectors on rising edge of clk
  always @(posedge clk)
    begin
      #1; {op, funct3, funct7b5, Zero, expected} = testvectors[vectornum];
    end

  // check results on falling edge of clk
  always @(negedge clk)
    if (~reset) begin // skip cycles during reset
      new_error=0; 

      if ((ImmSrc!==expected[15:14])&&(expected[15:14]!==2'bxx))  begin
        $display("   ImmSrc = %b      Expected %b", ImmSrc,     expected[15:14]);
        new_error=1;
      end
      if ((ALUSrcA!==expected[13:12])&&(expected[13:12]!==2'bxx)) begin
        $display("   ALUSrcA = %b     Expected %b", ALUSrcA,    expected[13:12]);
        new_error=1;
      end
      if ((ALUSrcB!==expected[11:10])&&(expected[11:10]!==2'bxx)) begin
        $display("   ALUSrcB = %b     Expected %b", ALUSrcB,    expected[11:10]);
        new_error=1;
      end
      if ((ResultSrc!==expected[9:8])&&(expected[9:8]!==2'bxx))   begin
        $display("   ResultSrc = %b   Expected %b", ResultSrc,  expected[9:8]);
        new_error=1;
      end
      if ((AdrSrc!==expected[7])&&(expected[7]!==1'bx))           begin
        $display("   AdrSrc = %b       Expected %b", AdrSrc,     expected[7]);
        new_error=1;
      end
      if ((ALUControl!==expected[6:4])&&(expected[6:4]!==3'bxxx)) begin
        $display("   ALUControl = %b Expected %b", ALUControl, expected[6:4]);
        new_error=1;
      end
      if ((IRWrite!==expected[3])&&(expected[3]!==1'bx))          begin
        $display("   IRWrite = %b      Expected %b", IRWrite,    expected[3]);
        new_error=1;
      end
      if ((PCWrite!==expected[2])&&(expected[2]!==1'bx))          begin
        $display("   PCWrite = %b      Expected %b", PCWrite,    expected[2]);
        new_error=1;
      end
      if ((RegWrite!==expected[1])&&(expected[1]!==1'bx))         begin
        $display("   RegWrite = %b     Expected %b", RegWrite,   expected[1]);
        new_error=1;
      end
      if ((MemWrite!==expected[0])&&(expected[0]!==1'bx))         begin
        $display("   MemWrite = %b     Expected %b", MemWrite,   expected[0]);
        new_error=1;
      end

      if (new_error) begin
        $display("Error on vector %d: inputs: op = %h funct3 = %h funct7b5 = %h", vectornum, op, funct3, funct7b5);
        errors = errors + 1;
      end
      vectornum = vectornum + 1;
      hash = hash ^ {ImmSrc&{2{expected[15:14]!==2'bxx}}, ALUSrcA&{2{expected[13:12]!==2'bxx}}} ^ {ALUSrcB&{2{expected[11:10]!==2'bxx}}, ResultSrc&{2{expected[9:8]!==2'bxx}}} ^ {AdrSrc&{expected[7]!==1'bx}, ALUControl&{3{expected[6:4]!==3'bxxx}}} ^ {IRWrite&{expected[3]!==1'bx}, PCWrite&{expected[2]!==1'bx}, RegWrite&{expected[1]!==1'bx}, MemWrite&{expected[0]!==1'bx}};
      hash = {hash[5:0], hash[6] ^ hash[5]};
      if (testvectors[vectornum] === 40'bx) begin 
        $display("%d tests completed with %d errors", vectornum, errors);
	      $display("hash = %h", hash);
        $stop;
      end
    end
endmodule

