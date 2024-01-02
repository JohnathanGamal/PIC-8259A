`include "PIC_top_MODULE.v"
`timescale 1ps/1ps
module PIC_tb();

  reg CS, WR, RD;
  wire[7:0] data_bus;
  wire [2:0] CAS;
  reg SP;
  reg [7:0] IR;
  reg INTA;
  reg A0;
  wire INT;

reg[2:0] CAS_reg;
reg [7:0] data_bus_reg;
reg CAS_out, data_bus_out;
assign CAS = (CAS_out == 1)? CAS_reg: 3'bz;
assign data_bus = (data_bus_out == 1)? data_bus_reg:8'bz;

PIC_top_module pic8259A(

   .CS(CS),
   .WR(WR),
   .RD(RD),
   .data_bus(data_bus),
   .CAS(CAS),
   .SP(SP),
   .IR(IR),
   .INTA(INTA),
   .A0(A0),
   .INT(INT)
  
  );

reg clk = 0;
always 
begin
#20 clk = ~ clk;
end
initial
begin
//$monitor("Bus Content: %b, INT : %b", data_bus, INT);
CS = 0;
WR = 0;
RD = 1;
data_bus_reg = 8'b00011010; //Single mode, No ICW4
data_bus_out = 1;
A0 = 0;

# 50
data_bus_reg = 8'b11000000; //Single mode, No ICW4
data_bus_out = 1;
A0 = 1;
#50
WR = 1;
IR = 8'b00011000;
#40
data_bus_out = 0;
if(INT == 1)
begin
#20
INTA = 1;
#40
  INTA = 0;
  #40
  INTA = 1;
data_bus_out = 0;
#40
INTA = 0;
#40
INTA = 1;
#10
$display("Vector address: %b", data_bus);
#10
data_bus_reg= 8'bzzzzzzzz;
#10
data_bus_reg = 8'b00100000;
data_bus_out = 1;
A0 = 0;
WR = 0;

end
end

//always @(posedge clk)
//begin



 
//end
endmodule