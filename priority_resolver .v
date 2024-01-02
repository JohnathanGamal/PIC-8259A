
`timescale 1ns/1ps
module priorityResolver (
  input wire EOI,
  input wire [7:0] readyInterrupts ,      //input from the IRR
  input wire [7:0] maskedRegister ,       //input from the IMR
  input wire [7:0] ISR_number ,           //input from the ISR
  input wire       rotate ,               //input from the control unit
  input wire       reset ,                //input from the control unit
  input wire [1:0] INTA_count ,           //input from the control unit
  output reg [7:0] servicedInterrupt ,    //output to the ISR
  output reg [2:0] interruptNumber,       //output to the control unit 
  // output reg       servicedInt_flag,   //output to the control unit
  output reg       intBetweenTwoAcks = 1'b0,     //output to the control unit
  output reg       Interrupt_request      // output to control unit
  );
  reg[31:0] counter = 0;
  reg[3:0] i = 0 ;
  reg[3:0] j = 0 ;
  reg[3:0] lowestPriority = 0 ;
  reg[3:0] rotateFlag = 0 ;
  reg f_ack = 0 ;
  reg trigger_flag = 0;
  reg [7:0] temp = 0;
  always @(posedge reset) begin
    lowestPriority = 7;
  end
  always @(INTA_count)begin
    if(f_ack)
	begin
	if(INTA_count == 1) begin
      Interrupt_request = 0; // reset the interrupt request
    end
     // servicedInterrupt <= temp ;
	end
  end
  
  always @(trigger_flag) begin
  if(f_ack ==0) begin
    if(!rotate)
      begin
        if(ISR_number == 0) begin
          //loop from the higher priority to lower priority devices
          for(i= 0; i<8 ; i= i+1) begin
            //check if the current device requested an interrupt or no
            if(readyInterrupts[i] &((~maskedRegister)>>i))
              begin
              //if the current device requested interrupt and not masked
              interruptNumber = i ;            // will be sent to the control unit
              servicedInterrupt = (1<<i) ;     // will be sent to the ISR to set the currently serviced interrupt by the cpu
              lowestPriority = i ;             // to be used if the controller send command to operate in the rotating mode
              i = 8 ;                            //to exit the loop immediatly
              Interrupt_request = 1;
            end
          end
        end
        
      /***************
       * if there is interrupt is serviced now *
       **************/
       else begin
         if(INTA_count == 1)
           begin
           //loop from the higher priority to lower priority devices
           for(i= 0; i<8 ; i= i+1) begin
            //check if the current device requested an interrupt or no
            if(readyInterrupts[i] &((~maskedRegister)>>i))
              begin
                temp = (1<<i) ;
                if(ISR_number > temp)
                  begin
                   intBetweenTwoAcks = 1 ;
                   f_ack = 1 ;
                end
              i =8 ;           //to exit the loop immediatly
            end
          end
        end
      end
    end
    /*************
     * if operating in the rotating mode *
     *************/
    else begin
         i = lowestPriority + 1 ;
        for(rotateFlag = 0  ; rotateFlag < 8 ; rotateFlag = rotateFlag + 1) begin
              
          //check if the current index to be checked is less than 8
          if(i == 8) begin
            i = 0 ;
          end
          //check if the current device requested an interrupt or no
          if(readyInterrupts[i] &((~maskedRegister)>>i))
            begin
            //if the current device requested interrupt and not masked
            Interrupt_request = 1;
            interruptNumber = i ;          // will be sent to the control unit
            servicedInterrupt = (1<<i) ;   // will be sent to the ISR to set the currently serviced interrupt by the cpu
            lowestPriority = i ;           // to be used if the controller send command to operate in the rotating mode
            rotateFlag = 8 ;                 //to exit the loop immediatly 
            
          end
          i = i + 1;
        end
      end
    end    
  end
  
always@(readyInterrupts)
  trigger_flag = ~trigger_flag;
  
always@(INTA_count)
  trigger_flag = ~trigger_flag;
reg internal_clk = 0;
always@(posedge internal_clk)
trigger_flag = ~trigger_flag;

always @(posedge EOI) begin 
  
Interrupt_request<= 0;
end
always @(counter) begin
  if(counter == 10 && INTA_count ==  2)begin
    f_ack = 0;
  end
end
always @(internal_clk) begin
  if(f_ack && counter <= 10)
    counter = counter + 1;
end
always
#80 internal_clk = ~ internal_clk;
  
endmodule