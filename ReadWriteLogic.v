module ReadWrite(
    input wire [1:0] icw_to_be_sent,
    input wire init_done,
    input wire CS,
    input wire RD,
    input wire WR,
    input wire A0,
    input wire[7:0] input_sys_bus ,
    input wire[7:0] input_int_bus ,
    output reg[7:0] output_sys_bus = 0 ,
    output reg[7:0]output_int_bus = 0 ,
    //inout wire [7:0] sys_bus,
   // inout wire [7:0] int_bus,
    output reg [1:0] icw_flag,
    output reg [1:0] ocw_flag,
    output wire RD_output,
    output wire WR_output
);

reg [7:0] data_reg;
reg icw3_bit, icw4_bit;
//reg [7:0] internal_bus;
//reg[7:0] system_bus;
//wire out_to_system = 0;

assign RD_output = RD;
assign WR_output = WR;
//assign int_bus = (out_to_system == 0 && internal_bus !== 8'bxxxxxxxx) ? internal_bus : 8'bz;
//assign sys_bus = (out_to_system == 1 && system_bus !== 8'bxxxxxxxx) ? system_bus : 8'bz;
//assign out_to_system = (WR === 1)? 1: 0; 

always@(negedge RD) begin
  if(CS == 0) begin
    data_reg <= input_int_bus;
    output_sys_bus <= input_int_bus;
  end
  
end

always @(input_sys_bus) begin
  if(CS == 0) begin
	 if (WR == 0) begin
	   if(A0 == 0 && init_done == 0 && input_sys_bus[4] == 1) begin //ICW1
		data_reg = input_sys_bus;
		output_int_bus = input_sys_bus;
		icw3_bit = input_sys_bus[1];	
		icw4_bit = input_sys_bus[0];
		icw_flag = 2'b00;
		end
           end
     end
end


always @( * ) begin
     if (CS == 0) begin
       
     if (WR == 0) begin // Write operation
     
	    if(A0 == 1 && input_sys_bus[2:0] == 3'b000 && init_done == 0 && icw_to_be_sent == 2'b01) begin //ICW2
	    
   	    data_reg = input_sys_bus;
		    output_int_bus = input_sys_bus;
		    icw_flag = 2'b01;
		    
		end
	    if(icw3_bit == 0 && init_done == 0 && icw_to_be_sent == 2'b10)begin //ICW3
	   
		data_reg = input_sys_bus;
		output_int_bus = input_sys_bus;
		icw_flag = 2'b10;
          end
	    if(icw4_bit ==1 && init_done == 0 && icw_to_be_sent == 2'b11 && input_sys_bus[7:5] == 3'b000)begin //ICW4
	        data_reg = input_sys_bus;
		      output_int_bus = input_sys_bus;
		      icw_flag = 2'b11;
		end
	    end
        end
end

always@(input_int_bus)
begin
	if(RD === 1 && WR === 1)				//In case the Interrupt vector is being sent
		output_sys_bus = input_int_bus;
end
always@(input_sys_bus) begin
if(input_sys_bus !== 8'bzzzzzzzz)
  begin
 if(CS == 0) begin
	if (WR == 0) begin
	 
	    if(A0 == 1 && init_done == 1)begin //OCW1
		data_reg <= input_sys_bus;
		output_int_bus <= input_sys_bus;
		ocw_flag <= 2'b01;
		end
	    if(A0 == 0 && input_sys_bus[4:3] == 2'b00 && init_done == 1)begin //OCW2
		data_reg <= input_sys_bus;
		output_int_bus <= input_sys_bus;
		ocw_flag <= 2'b10;
		end
	    if(A0 ==0 && input_sys_bus[4:3] == 2'b01 && input_sys_bus[7] == 0 && init_done ==1)begin //OCW3
		data_reg <= input_sys_bus;
		output_int_bus <= input_sys_bus;
		ocw_flag <= 2'b11;
		end
		      end
          end
      end
   end
endmodule


