////////////////////////////////////////////////////////////////////////////////
// Module: Cascademode
// Description: This module implements a cascade controller that operates in
// either MASTER or SLAVE mode. It takes input signals including the cascade
// control lines (CAS), the mode selector (SP), the 3-bit ID of the slave (ID),
// and a control signal (flag_compare_at_slave). The module compares the ID to
// the CAS in SLAVE mode and sets a flag (flag_ID_match) accordingly. In MASTER
// mode, it assigns the desired slave ID to CAS based on the internal signal.
////////////////////////////////////////////////////////////////////////////////

module Cascademode (
   inout [2:0] CAS,                      // Input/Output: Cascade control lines.
   input SP,                             // Input: Selects between MASTER and SLAVE modes (0=slave mode, 1=master mode).
   input wire [2:0] ID,                   // Input: 3-bit ID of the slave from control logic.
   input flag_compare_at_slave,          // Compare flag at slave mode.
   output reg flag_ID_match = 0,             // Flag to indicate ID match or not to send to control logic.
   output SP_output                      // Output: SP signal to control logic
);


parameter SLAVE = 1'b0;                  // Parameter representing the SLAVE mode.
parameter MASTER = 1'b1;                 // Parameter representing the MASTER mode.
reg [2:0] internal_desired_slave;       // Internal signal to store the desired_slave in MASTER mode.

//- Block triggered on the positive edge of the flag_compare_at_slave signal
always @(posedge flag_compare_at_slave) begin
    // Check if in SLAVE mode and if the ID matches CAS
    if (SP == SLAVE) begin
        if (ID == CAS) begin 
            flag_ID_match <= 1'b1;  // Set match flag to 1 if ID matches CAS
        end
        else begin
            flag_ID_match <= 1'b0;  // Reset match flag if ID doesn't match CAS
        end
    end
end

// Block triggered on any change in SP
always @(*) begin
    // Check mode and set internal_desired_slave accordingly
    if (SP == MASTER) begin
        internal_desired_slave <= ID;  // Set internal signal to the ID in MASTER mode
    end
end

// Assigns CAS based on the mode. If in MASTER mode,
// it takes the value from internal_desired_slave; otherwise, it's set to high impedance (3'bZ).
assign CAS = (SP == MASTER) ? internal_desired_slave : 3'bZ;  // Assign CAS based on the mode

// Assign SP_output
assign SP_output = SP;

endmodule


