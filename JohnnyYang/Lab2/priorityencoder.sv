module priorityencoder(input  logic [7:1] a,
                       output logic [2:0] y);
              
    // For Lab 2, write a structural Verilog model 
    // use and, or, not
    // do not use assign statements, always blocks, or other behavioral Verilog
    
    logic a6n,a5n,a4n,a2n;
    logic n1,n2,n3,n4;
    
    not g1(a6n,a[6]);
    not g2(a5n,a[5]);
    not g3(a4n,a[4]);
    not g11(a2n,a[2]);
    
    and g4(n1,a6n,a4n,a2n,a[1]);
    and g5(n2,a6n,a4n,a[3]);
    and g6(n3,a5n,a4n,a[2]);
    and g7(n4,a6n,a[5]);
    and g12(n5,a5n,a4n,a[3]);
    
    or g8(y[2],a[4],a[5],a[6],a[7]);
    or g9(y[1],n3,n5,a[6],a[7]);
    or g10(y[0],n1,n2,n4,a[7]);
  
 
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

