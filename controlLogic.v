module ControlLogic (
  input wire interrupt_bet_2ack,
  input wire ID_match,
  input wire RD,            // Read control signal
  input wire WR,            // Write control signal
  input wire [2:0] Interrupt_number,
  input wire [7:0] IRR,
  input wire [7:0] ISR,
  input wire [1:0] ICW_RECEIVED_FLAG,
  input wire [1:0] OCW_RECEIVED, 
  input wire [7:0] in_Internal_bus ,
  output reg [7:0] out_Internal_bus = 0,
  //inout wire [7:0] Internal_bus,  // Data bus from other blocks
  input wire INT_request,    //Input from priority resolver
  input wire INTA,           //Acknowledge from processor
  input wire isMaster,
  output reg RESET,
  output reg [1:0] to_be_received,
  //output wire [7:0] IV,      // Interrupt Vector
  //output wire [1:0] CAS,     // Cascade Signals
  output reg EOI = 0,           // End of Interrupt
  output reg[7:0] IMR = 0,        // Interrupt Mask Register
  output reg INT = 0,            //Sent to processor
  output reg [1:0] INTA_count = 2'b11,   //Sent to IRR and ISR
  output wire LTIM,            //Sent to IRR to specify triggering mode
  output wire compare_IDs,    //Sent to cascade buffer in slave, at second acknowledge pulse
  output wire rotate,        //Send signal for automatic rotation to Priority resolver
  output reg [2:0] CAS_ID,
  output wire init_done
);

 localparam[2:0] GET_ICW1 = 3'b00,
  GET_ICW2 = 3'b01,
  GET_ICW3 = 3'b10,
  GET_ICW4 = 3'b11,
  INIT_DONE = 3'b111;
  
  localparam[1:0]   ICW1_RECEIVED = 2'b00,
  ICW2_RECEIVED = 2'b01,
  ICW3_RECEIVED = 2'b10,
  ICW4_RECEIVED = 2'b11;
  localparam[1:0]   OCW1_RECEIVED = 2'b01,
  OCW2_RECEIVED = 2'b10,
  OCW3_RECEIVED = 2'b11;

reg [7:0] ICW1;
reg [7:0] ICW2;
reg [7:0] ICW3;
reg [7:0] ICW4;
reg [7:0] OCW1;
reg [7:0] OCW2 = 8'b 00000000;
reg [7:0] OCW3 = 8'b00000010;
reg [2:0] init_command_state = 0;
reg [7:0] bus_out;
reg out_flag = 0;
wire OCW2_EOI = 0;

assign init_done = (init_command_state == INIT_DONE)? 1 : 0;
//assign Internal_bus = (out_flag == 1) ? bus_out : 8'bz;
//Reset and get ICW1
always @(ICW_RECEIVED_FLAG)
begin
  out_flag <=0;
  if(!WR)
    begin
  if(ICW_RECEIVED_FLAG == ICW1_RECEIVED)
    begin
    RESET <= 1;         //Flag to be sent to all blocks to execute the reset sequence
    IMR <= 8'b00000000;
    out_flag <= 0;
    ICW1 <= in_Internal_bus;
    init_command_state <= GET_ICW2;
    to_be_received <= GET_ICW2;
  end 
end
end
  
//Receive ICW
always @(ICW_RECEIVED_FLAG)
begin
  out_flag <= 0;
  if(!WR)
  begin
  case(init_command_state)
    
    GET_ICW2:
        begin
      if(ICW_RECEIVED_FLAG == ICW2_RECEIVED)
        begin
          RESET <= 0; // end reset sequence as reset sequence happens with ICW 1
        //Clear ICW4 if IC4 bit in ICW1 is 0
        if(ICW1[0] == 0)
          ICW4 = 8'b00000001;
        ICW2 <= in_Internal_bus;
        if(ICW1[1] == 1'b0)
          begin
          init_command_state <= GET_ICW3;
          to_be_received <= GET_ICW3;
        end
        else if(ICW1[0] == 1'b1)
          begin
          init_command_state<= GET_ICW4;
          to_be_received <= GET_ICW4;
          end
        else
          init_command_state<= INIT_DONE;
      end        
    end
    GET_ICW3:
    begin
      ICW3 <= in_Internal_bus;
      if(ICW1[0] == 1'b1)
          begin
          init_command_state<= GET_ICW4;
          to_be_received <= GET_ICW4;
          end
        else
          init_command_state<= INIT_DONE;
        
    end
      
    GET_ICW4:
    begin
    ICW4 <= in_Internal_bus;
    init_command_state <= INIT_DONE;
    end
    
    endcase
  end
end

//Send LTIM bit to IRR
assign LTIM = ICW1[3];


//GET OCW
always @(OCW_RECEIVED)
begin
  out_flag <= 0;
if(init_command_state == INIT_DONE && !WR)
  begin
    case(OCW_RECEIVED)
    OCW1_RECEIVED:
    begin
      OCW1 <= in_Internal_bus;
      IMR <= in_Internal_bus;
    end
    OCW2_RECEIVED:
    begin
      OCW2 <= in_Internal_bus;
    end
    OCW3_RECEIVED:
    begin
      OCW3 <= in_Internal_bus;
    end   
    endcase
  end
end
//Interrupt sequence
localparam[1:0]
 WAIT_FOR_ACK1 = 2'b01,
 WAIT_FOR_ACK2 = 2'b10,
 DONE = 2'b11;
reg[1:0] sequence_state;
always @(posedge INT_request)  
begin
EOI <= 0;
//if(INTA_count != 1)         //Handling the case if an interrupt is triggered before the second ack.
if(init_command_state == INIT_DONE)
begin
  INT <= 1'b1;
  INTA_count <= 0;
  sequence_state <= WAIT_FOR_ACK1;
end
end

always @(negedge INTA)
begin
if(init_command_state == INIT_DONE)
begin
  case(sequence_state)
  WAIT_FOR_ACK1:
  begin
  INTA_count <= 1;
  sequence_state <= WAIT_FOR_ACK2;
  end
  WAIT_FOR_ACK2:
  begin
  INTA_count <= 2;
  if(ICW1[1] == 1)            //If 8259 is in single mode (Not Cascaded)
  begin 
  out_flag = 1;
  out_Internal_bus <= {ICW2[7:3], Interrupt_number};
  sequence_state <= DONE;
  end
  else if(isMaster == 1'b1 && ICW3[Interrupt_number] == 1)
    begin
    //The master will enable the corresponding slave to release the device routine address
    CAS_ID <= Interrupt_number;
    end
  else if(isMaster == 1'b0)
    CAS_ID <= ICW3[2:0];
   
  end
  default:
  sequence_state <= DONE;
  endcase
end
end
always@(posedge ID_match) // if the id recieved by master and current slave id are equal
begin
if(compare_IDs) // in case we recieved the second ack and it is in cascaded mode (slave)
begin
  if(interrupt_bet_2ack)
    begin
      INT <= 0;
      EOI <= 1;
    end
  else
    begin
  out_Internal_bus <= {ICW2[7:3] , Interrupt_number};
end
end
end
assign compare_IDs = ((INTA_count == 2) && (ICW1[1] == 0) && (isMaster == 0))? 1 :0;


//Reading from 8259
always @(negedge RD)
begin
  out_flag = 1;
  if(OCW3[1:0] == 2'b11)
    out_Internal_bus <= ISR;
else if(OCW3[1] == 1)
  out_Internal_bus <= IRR;
end


//AEOI - EOI
assign  OCW2_EOI = OCW2[5]; 
always@(OCW2_EOI)
begin
if((ICW4[1] == 0)&&OCW2[5] == 1)
begin
EOI <= 1;
INT <= 0;
OCW2[5] = 0;
end
end


always @(posedge INTA)
if((ICW4[1] == 1) && INTA_count == 2'b10) //If AEOI mode is selected and the second ack is received
begin
EOI <= 1;
INTA_count <= 0;
INT <= 0;
end 
assign rotate = OCW2[7];    //Send signal for automatic rotation to Priority resolver


endmodule


