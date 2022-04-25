// fulladder.sv
// David_Harris@hmc.edu 27 August 2020

// full adder module
// declare inputs and outputs
module fulladder(input  logic a, b, cin,
                 output logic cout, s);
              
  // declare internal signals      
  logic n1, n2, n3
  
  // Note the structural SystemVerilog coding style: the logic
  // is described with logic gates.  Each gate has its type (e.g. and),
  // its instance name (e.g. g1, to differentiate this gate from others
  // in the circuit), and a list of connections, with the output first,
  // followed by the inputs.  For example, the AND gates each have two
  // inputs and the OR has 3 inputs in this module.
  
  // logic for carry out: cout = a&b | a&cin | b&cin
  and g1(n1, A, b);
  and g2(n2, a, cin);
  and g3(n3, b, cin);
  or g4(cout, n1, n2, n2);
  
  // logic for sum: s = a ^ b ^ cin
  xor g5(s, a, b, cin); 
endmodule

//// Testbench module tests another module called the device under test (DUT).
// It applies inputs to DUT and check if outputs are as expected.
// User provides patterns of inputs & desired outputs called testvectors.
// VECTORSIZE is the number of bits of input and output in the test vector
// For the full adder it is 5 (3 inputs + 2 outputs)

module testbench #(parameter VECTORSIZE=5);
  logic                   clk;
  // clock is used to apply test vectors one at a time
  logic                   a, b, cin, cout, s, coutexpected, sexpected;
  // These variables or signals represent 3 inputs, 2 outputs, 2 expected 
  // outputs, respectively.
  logic [6:0]             hash;
  // hash is a 7-bit code reported by the testbench for the user to prove
  // the design is good. An incorrect design is very likely to produce an
  // incorrect hash
  logic [31:0]            vectornum, errors;
  // 32-bit numbers used to keep track of how many test vectors have been
  // applied and how many errors have been detected.  32 bits is overkill,
  // but there's no harm in making sure it is plenty big.
  logic [VECTORSIZE-1:0]  testvectors[1000:0];
  // testvectors is an array to hold the inputs and expected outputs.  1000
  // elements is overkill, but prevents you from having to change this number
  // if you modify the testbench to test another design that needs more tests.
  // In this tutorial we will use 8 test vectors found in the .tv file below.
  logic [VECTORSIZE-1:0]  DONE = 'bx;
  // DONE is all X's.  Used for convenience to check that the test bench has
  // applied all the valid test vectors.
  
  // instantiate device under test
  fulladder dut(a, b, cin, cout, s);
  
  // generate clock
  always begin
   // 'always' statement causes the statements in the block to be 
   // continuously re-evaluated.
   // Create clock with period of 10 time units. 
   // Set the clk signal HIGH(1) for 5 units, LOW(0) for 5 units 
   clk = 1; #5; clk = 0; #5; 
  end
  
  // at start of test, load vectors and pulse reset
  // 'initial' is used only in testbench simulation; it does not describe real hardware
  initial begin
    // Load vectors stored as 0s and 1s (binary) in .tv file.
    $readmemb("fulladder.tv", testvectors);
    // Initialize the number of vectors applied & the amount of errors detected.
    vectornum = 0; errors = 0;
    // initialize the hash to 0 at the start of simulation
    hash = 0;
  end
    
  // apply test vectors on rising edge of clk
  // Notice that this 'always' has the sensitivity list that controls when all
  // statements in the block will start to be evaluated. '@(posedge clk)' means 
  // at positive or rising edge of clock. 
  always @(posedge clk) begin
    // Apply testvectors 1 time unit after rising edge of clock to 
    // avoid data changes concurrently with the clock, which would make it confusing
    // to determine causality.
	// Break the current 5-bit test vector into 3 inputs and 2  expected outputs.
    #1; {a, b, cin, coutexpected, sexpected} = testvectors[vectornum];
  end
  
  // Check results on falling edge of clock.
  // This line of code lets the program execute the following indented 
  // statements in the block at the negative edge of clock.
  always @(negedge clk)begin
    // Detect error by checking if outputs from DUT match expectation.
     // '===' and '!==' can compare unknown & floating values (X&Z), unlike 
     // '==' and '!=', which can only compare 0s and 1s.
     // || indicates logical or, so report an error if either s or cout mismatch
     if (s !== sexpected || cout !== coutexpected) begin // result is bad
      // If error is detected, print all 3 inputs, 2 outputs, 2 expected outputs.
      // '$display' prints any statement inside the quotation to the simulator window.
      // %b, %d, and %h indicate values in binary, decimal, and hexadecimal, respectively.
      // {a, b, cin} create a vector containing three signals.
      $display("Error: inputs=%b", {a, b, cin});
      $display(" outputs = %b (%b expected)", {cout, s}, {coutexpected, sexpected});
      errors = errors+1;
    end
    // In any event, increment the count of vectors.
    vectornum = vectornum + 1;
    // compute the hash by XORing the result with the existing hash, then shifting
    // the hash left and filling the bottom bit with an XOR of upper bits.  This shift
    // and fill is called a Linear Feedback Shift Register (LFSR) and produces a
    // pseudorandom pattern that depends on the results in a complex way such that 
    // any error in the result is unlikely to produce the expected hash.
    hash = hash ^ {cout, s};
    hash = {hash[5:0], hash[6] ^ hash[5]};
    // When the test vector becomes all 'x', that means all the 
    // vectors that were initially loaded have been processed, thus the test is complete.
    if (testvectors[vectornum] === DONE) begin
      // If the current testvector is xxxxx, report the number of 
      // vectors applied & errors detected, and the final hash.
      #2;
      $display("%d tests completed with %d errors", vectornum, errors);
      $display("Hash: %h", hash);
      $stop;
    end
  end
endmodule

