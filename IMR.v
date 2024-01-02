module IMR(
  input wire [7:0] maskedInterrupts,
  output reg [7:0] disabledInterrupts
  );
  always @(maskedInterrupts)
  begin
    disabledInterrupts <= maskedInterrupts;
  end
  
endmodule
