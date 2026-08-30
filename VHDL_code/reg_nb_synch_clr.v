`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company:   Cal poly SLO
// Engineer:  Rishub Patel
// 
// Create Date: 01/24/2026 at 2pm
// Design Name: 
// Module Name: reg_nb
// Project Name: 
// Target Devices: 
// Tool  Versions: 
// Description: Modified reg_nb to have synchronous clear, as the
//              lab instructions ask for: This register is a model
//              for a generic loadable register (defaults to 8
//              bits) with synchronous positive logic clear.
//
//      //- Usage example for instantiating 16-bit register
//      reg_nb_synch_clr #(.n(16)) MY_REG (
//          .data_in  (xxxx), 
//          .ld       (xxxx), 
//          .clk      (xxxx), 
//          .clr      (xxxx), 
//          .data_out (xxxx) );  
// 
//////////////////////////////////////////////////////////////////////////////////

module reg_nb_synch_clr #(parameter n=8) (
    input wire [n-1:0] data_in,
    input wire clk, 
	input wire clr, 
	input wire ld, 
    output reg [n-1:0] data_out  ); 
    
    always @(posedge clk)
    begin
       if (clr == 1)       //synch clear
          data_out <= 0;
       else if (ld == 1)   // synch load
          data_out <= data_in; 
    end
    
endmodule

`default_nettype wire