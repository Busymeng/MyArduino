module priorityencoder(input  logic [7:1] a,
                       output logic [2:0] y);
              
    // For Lab 2, write a structural Verilog model 
    // use and, or, not
    // do not use assign statements, always blocks, or other behavioral Verilog
 
endmodule

module testbench #(parameter VECTORSIZE=10);
  logic                   clk;
  logic [7:1]             a;
  logic [2:0]             y, yexpected;
  logic [6:0]             hash;
  logic [31:0]            vectornum, errors;
  // 32-bit numbers used to keep track of how many test vectors have been
  logic [VECTORSIZE-1:0]  testvectors[1000:0];
  logic [VECTORSIZE-1:0]  DONE = 'bx;
  
  // instantiate device under test
  priorityencoder dut(a, y);
  
  // generate clock
  always begin
   clk = 1; #5; clk = 0; #5; 
  end
  
  // at start of test, load vectors and pulse reset
  initial begin
    $readmemb("priorityencoder.tv", testvectors);
    vectornum = 0; errors = 0;
    hash = 0;
  end
    
  // apply test vectors on rising edge of clk
  always @(posedge clk) begin
    #1; {a, yexpected} = testvectors[vectornum];
  end
  
  // Check results on falling edge of clock.
  always @(negedge clk)begin
      if (y !== yexpected) begin // result is bad
      $display("Error: inputs=%b", a);
      $display(" outputs = %b (%b expected)", y, yexpected);
      errors = errors+1;
    end
    vectornum = vectornum + 1;
    hash = hash ^ y;
    hash = {hash[5:0], hash[6] ^ hash[5]};
    if (testvectors[vectornum] === DONE) begin
      #2;
      $display("%d tests completed with %d errors", vectornum, errors);
      $display("Hash: %h", hash);
      $stop;
    end
  end
endmodule

