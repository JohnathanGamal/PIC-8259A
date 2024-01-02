module ReadWrite(
    input wire [1:0] icw_to_be_sent,
    input wire init_done,
    input wire CS,
    input wire RD,
    input wire WR,
    input wire A0,
    inout wire [7:0] sys_bus,
    inout wire [7:0] int_bus,
    output reg [1:0] icw_flag,
    output reg [1:0] ocw_flag,
    output wire RD_output,
    output wire WR_output
);

reg [7:0] data_reg;
reg icw3_bit, icw4_bit;
reg [7:0] internal_bus;
reg[7:0] system_bus;
reg out_to_system = 0;

assign RD_output = RD;
assign WR_output = WR;
assign int_bus = (out_to_system  == 0) ? internal_bus : 8'bz;
assign sys_bus = (out_to_system == 1) ? system_bus : 8'bz;
//assign out_to_system = (WR === 1)? 1: 0; 
always@(WR)
begin
if(WR === 0)
  out_to_system = 0;
else
  if(WR === 1)
    out_to_system = 1;
end
always@(negedge RD) begin
  if(CS == 0) begin
    data_reg <= int_bus;
    system_bus <= int_bus;
  end
  
end

always @(sys_bus) begin
  if(CS == 0) begin
	 if (WR == 0) begin
	   if(A0 == 0 && init_done == 0 && sys_bus[4] == 1) begin //ICW1
		data_reg <= sys_bus;
		internal_bus <= sys_bus;
		icw3_bit <= sys_bus[1];	
		icw4_bit <= sys_bus[0];
		icw_flag <= 2'b00;
		end
           end
     end
end
always@(int_bus)
begin
	if(RD === 1 && WR === 1)				//In case the Interrupt vector is being sent
		system_bus = int_bus;
end

always @( * ) begin
     if (CS == 0) begin
       
     if (WR == 0) begin // Write operation
     
	    if(A0 == 1 && sys_bus[2:0] == 3'b000 && init_done == 0 && icw_to_be_sent == 2'b01) begin //ICW2
	    
   	    data_reg <= sys_bus;
		    internal_bus <= sys_bus;
		    icw_flag <= 2'b01;
		    
		end
	    if(icw3_bit == 0 && init_done == 0 && icw_to_be_sent == 2'b10)begin //ICW3
	   
		data_reg <= sys_bus;
		internal_bus <= sys_bus;
		icw_flag <= 2'b10;
          end
	    if(icw4_bit ==1 && init_done == 0 && icw_to_be_sent == 2'b11)begin //ICW4
	        data_reg <= sys_bus;
		      internal_bus <= sys_bus;
		      icw_flag <= 2'b11;
		end
	    end
        end
end


always@(sys_bus) begin
if(WR 	== 0 && sys_bus !== 8'bzzzzzzzz)
  begin
 if(CS == 0) begin
	if (WR == 0) begin
	 
	    if(A0 == 1 && init_done == 1)begin //OCW1
		data_reg <= sys_bus;
		internal_bus <= sys_bus;
		ocw_flag <= 2'b01;
		end
	    if(A0 == 0 && sys_bus[4:3] == 2'b00 && init_done == 1)begin //OCW2
		data_reg <= sys_bus;
		internal_bus <= sys_bus;
		ocw_flag <= 2'b10;
		end
	    if(A0 ==0 && sys_bus[4:3] == 2'b01 && sys_bus[7] == 0 && init_done ==1)begin //OCW3
		data_reg <= sys_bus;
		internal_bus <= sys_bus;
		ocw_flag <= 2'b11;
		end
		      end
          end
      end
   end
endmodule

