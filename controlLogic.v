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
  inout wire [7:0] Internal_bus,  // Data bus from other blocks
  input wire INT_request,    //Input from priority resolver
  input wire INTA,           //Acknowledge from processor
  input wire isMaster,
  output reg RESET,
  output reg [1:0] to_be_received,
  //output reg IV,      // Interrupt Vector
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
assign Internal_bus = (out_flag == 1) ? bus_out : 8'bz;
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
    ICW1 <= Internal_bus;
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
        ICW2 <= Internal_bus;
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
      ICW3 <= Internal_bus;
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
    ICW4 <= Internal_bus;
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
  out_flag = 0;
if(init_command_state == INIT_DONE && !WR)
  begin
    case(OCW_RECEIVED)
    OCW1_RECEIVED:
    begin
      OCW1 = Internal_bus;
      IMR = Internal_bus;
    end
    OCW2_RECEIVED:
    begin
      OCW2 = Internal_bus;
    end
    OCW3_RECEIVED:
    begin
      OCW3 = Internal_bus;
    end   
    endcase
  end
end