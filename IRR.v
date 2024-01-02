module IRR(
  input wire [7:0] IR, // interrupt request
  input wire LT,      // level triggred
  input wire[1:0] INTA_count,
  input wire [2:0] current_service_INT,
  output reg [7:0] IRR_status= 8'b0
   );

always@(*)
begin
if(LT) 
  IRR_status = IRR_status | IR; //If level triggered, the interrupt will be set to 1 as long as the device is sending an interrupt
end
   
always@(posedge IR[0])
    IRR_status[0] <= 1;
always@(posedge IR[1])
    IRR_status[1] <= 1;
always@(posedge IR[2])
    IRR_status[2] <= 1;
always@(posedge IR[3])
    IRR_status[3] <= 1;
    
always@(posedge IR[4])
    IRR_status[4] <= 1;
always@(posedge IR[5])
    IRR_status[5] <= 1;

always@(posedge IR[6])
    IRR_status[6] <= 1;
always@(posedge IR[7])
    IRR_status[7] <= 1;
    
    
    

 always@(INTA_count)
 begin
   if(INTA_count == 1 )
   IRR_status[current_service_INT] <= 0;
 end
 endmodule
