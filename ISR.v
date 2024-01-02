/*******************************************************************
* File Description: source file that contain the implementation
*                   of the in service register module in the
*                   8259 PIC
*
* Author: Andrew Hany
*******************************************************************/
module InServiceRegister (
  input wire [7:0] highestPriorityInterrupt , //input from the priority resolver
  input wire       EOI ,                      //input from the control block module
  input wire [1:0] INTA_count ,               //input from the control block module 
  output reg [7:0] inServiceInterruptNumber = 0
  ) ;
  
  
  /************************************************************
   *            End of interrupt procedural block             *
   ************************************************************/
  always @(posedge EOI) begin
    //if the controler send the end of interrupt signal -> clear the isr
    inServiceInterruptNumber = 0 ;
  end
  
  
  /**************************************************************
   * triggering interrupt and start serving it procedural block *
   **************************************************************/
  always @(INTA_count) begin
    if(INTA_count == 1)
      begin
        //set interrupt bit sent by the priority resolver to be served
        inServiceInterruptNumber <= highestPriorityInterrupt ;
      end
    end
endmodule