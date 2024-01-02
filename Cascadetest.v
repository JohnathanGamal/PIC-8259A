`include "Cascademode.v"
`timescale 1ns/1ps

module Cascademode_tb;

  // Parameters
  parameter SLAVE = 1'b0;
  parameter MASTER = 1'b1;

  // Signals
  reg [2:0] CAS;
  reg SP;
  reg [2:0] ID;
  reg flag_compare_at_slave;
  wire flag_ID_match;
  wire SP_output;

  // Instantiate the module under test
  Cascademode uut (
    .CAS(CAS),
    .SP(SP),
    .ID(ID),
    .flag_compare_at_slave(flag_compare_at_slave),
    .flag_ID_match(flag_ID_match),
    .SP_output(SP_output)
  );

  // Initial block for test scenario
  initial begin
    // Test 1: SLAVE mode, ID matches CAS
    $display("Test 1: SLAVE mode, ID matches CAS");
    SP = SLAVE;
    ID = 3'b101;
    CAS = 3'b101;
    flag_compare_at_slave = 1'b1;
    #10; // Wait for some time

    // Test 2: SLAVE mode, ID doesn't match CAS
    $display("Test 2: SLAVE mode, ID doesn't match CAS");
    SP = SLAVE;
    ID = 3'b010;
    CAS = 3'b101;
    flag_compare_at_slave = 1'b1;
    #10; // Wait for some time
    // Test 3: MASTER mode
    $display("Test 3: MASTER mode");
    SP = MASTER;
    ID = 3'b110;
    flag_compare_at_slave = 1'b0;
    #10; // Wait for some time
    $stop; // Stop simulation
  end

endmodule

