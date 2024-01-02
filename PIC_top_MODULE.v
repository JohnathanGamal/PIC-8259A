`include "ReadWriteLogic.v"
`include "priority_resolver.v"
`include "ISR.v"
`include "IRR.v"
`include "IMR.v"
`include "ControlLogic.v"
`include "Cascading.v"

module PIC_top_module(
  input CS,
  input WR,
  input RD,
  inout wire[7:0] data_bus,
  inout wire [2:0] CAS,
  input wire SP,
  input wire [7:0] IR,
  input INTA,
  input A0,
  output INT
  
  );
  
  wire init_done, compare_IDs,ID_match, SP_signal, LTIM, EOI, rotate,reset, RD_signal, WR_signal, interrupt_between_2ack ,interrupt_request;
  wire [1:0] icw_flag , ocw_flag, INTA_count, to_be_received;
  wire[7:0] internal_bus, IMR_input_content, IMR_status, IRR_status, ISR_status, ISR_set;
  wire [2:0] CAS_ID , Interrupt_number;
  ControlLogic  control_logic(
  .interrupt_bet_2ack(interrupt_between_2ack),
  .ID_match(ID_match),
  .RD(RD_signal),            // Read control signal
  .WR(WR_signal),            // Write control signal
  .Interrupt_number(Interrupt_number),
  .IRR(IRR_status),
  .ISR(ISR_status),
  .ICW_RECEIVED_FLAG(icw_flag),
  .OCW_RECEIVED(ocw_flag),  
  .Internal_bus(internal_bus),  // Data bus from other blocks
  .INT_request(interrupt_request),    //Input from priority resolver
  .INTA(INTA),           //Acknowledge from processor
  .isMaster(SP_signal),
  .RESET(reset),
  .to_be_received(to_be_received),
 //.CAS(),     // Cascade Signals
  .EOI(EOI),           // End of Interrupt
  .IMR(IMR_input_content),        // Interrupt Mask Register
  .INT(INT),            //Sent to processor
  .INTA_count(INTA_count),   //Sent to IRR and ISR
  .LTIM(LTIM),            //Sent to IRR to specify triggering mode
  .compare_IDs(compare_IDs),    //Sent to cascade buffer in slave(), at second acknowledge pulse
  .rotate(rotate),        //Send signal for automatic rotation to Priority resolver
  .CAS_ID(CAS_ID),
  .init_done(init_done)  
    
  
  );
  ReadWrite RW(
  .icw_to_be_sent(to_be_received),
  .init_done(init_done),
  .RD(RD),
  .WR(WR),
  .CS(CS),
  .A0(A0),
  .sys_bus(data_bus),
  .icw_flag(icw_flag),
  .ocw_flag(ocw_flag),
  .int_bus(internal_bus),
  .RD_output(RD_signal),
  .WR_output(WR_signal)
  );
  
  Cascademode cascade(
  .CAS(CAS),                      // Input/Output: Cascade control lines.
  .SP(SP),                             // Input: Selects between MASTER and SLAVE modes (0=slave mode(), 1=master mode).
  .ID(CAS_ID),                   // Input: 3-bit ID of the slave from control logic.
  .flag_compare_at_slave(compare_IDs),          // Compare flag at slave mode.
  .flag_ID_match(ID_match),             // Flag to indicate ID match or not to send to control logic.
  .SP_output(SP_signal)
  );
  
  IMR imr(
  .maskedInterrupts(IMR_input_content),
  .disabledInterrupts(IMR_status)
  
  );
  
  IRR irr(
  .IR(IR), // interrupt request
  .LT(LTIM),      // level triggred
 .INTA_count(INTA_count),
 .current_service_INT(Interrupt_number),
 .IRR_status(IRR_status)
 
   );
  
InServiceRegister ISR(
  .highestPriorityInterrupt(ISR_set) , //input from the priority resolver
  .EOI(EOI) ,                      //input from the control block module
  .INTA_count(INTA_count) ,               //input from the control block module 
  .inServiceInterruptNumber(ISR_status)
);

priorityResolver priorityRes(
.readyInterrupts(IRR_status) ,      //input from the IRR
.maskedRegister(IMR_status) ,       //input from the IMR
.ISR_number(ISR_status) ,           //input from the ISR
.rotate(rotate) ,               //input from the control unit
.reset(reset) ,                //input from the control unit
.INTA_count(INTA_count) ,           //input from the control unit
.servicedInterrupt(ISR_set) ,    //output to the ISR
.interruptNumber(Interrupt_number),       //output to the control unit 
//.servicedInt_flag(),      //output to the control unit
.intBetweenTwoAcks(interrupt_between_2ack),      //output to the control unit
.Interrupt_request(interrupt_request),
 .EOI(EOI)
  ) ;
endmodule