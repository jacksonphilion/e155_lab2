/*
E155 Lab2 - Two 7-Segment Displays
Jackson Philion, Sep.10.2024, jphilion@g.hmc.edu. Harvey Mudd College for E155: Microprocessors, taught by Prof Josh Brake.

The following code is used to control two seven-segment displays simultaneously
by multiplexing between thier anodes and sending time-varying signals down the
same pin connections. More can be found on my github, including the code
from the previous lab which was used to copy the segment logic.
github.com/jacksonphilion/e155_lab2
*/

module top(
    input   logic   [7:0]   sw,
    input   logic           reset,
    output  logic   [4:0]   ledSig,
    output  logic   [6:0]   seg,
    output  logic           disL,
    output  logic           disR
    );

    ledLogic ledCall(sw,ledSig);
    displayMultiplexer displayCall(sw, reset, seg, disL, disR);

endmodule

module displayMultiplexer #(parameter displayFreqHz=1) (
    input   logic   [7:0]   switch,
    input   logic           reset,
    output  logic   [6:0]   segment,
    output  logic           displayL,
    output  logic           displayR
    );
    /* This modules calls the sevenSegLogic module from e155_lab1.
    This module uses the high speed oscillator on the UPduino v3.1
    board to multiplex between two 7 segment displays at a rate
    of #(displayFreqHz). It sends the signals out using the same 
    segment pins for both displays, then toggles between L and R
    display power to illuminate each of the two back and forth. 
    Note that the [7:4] bits of switch are L display, [3:0] are R.
    Note that toggle[1] corresponds to Display L, and [0] to R. */

    logic           toggleFreq;
    logic   [3:0]   intSwitch;
    logic   [1:0]   toggle;

    frequencyGenerator #(.divisionFactor(48000)) freqGenCall (reset, toggleFreq);

    always_ff @(posedge toggleFreq)
    // If reset is low (active low reset), or we were displaying the L screen, switch to R with toggle=01
    if ((~reset) | (toggle[1]&(~toggle[0]))) begin
        toggle <= 2'b01;
        intSwitch <= ~(switch[3:0]);
    end
	// Otherwise, if not reset and toggle is showing R screen, switch to L toggle=10
    else begin
        toggle <= 2'b10;
        intSwitch <= ~(switch[7:4]);
    end

    assign displayL = ~toggle[1];
    assign displayR = ~toggle[0];
	
	sevenSegLogic segLogicCall(intSwitch, segment);

endmodule

module frequencyGenerator #(parameter divisionFactor=24000000) (
    input   logic   reset,
    output  logic   desiredFreqOut
    );
    // This module is coded to output a default freq of 2.4Hz. The factors above
    // may be changed in the module call to adjust this.
    
    // High Frequency 48MHz Oscillator
    logic int_osc;
    HSOSC hf_osc (.CLKHFPU(1'b1), .CLKHFEN(1'b1), .CLKHF(int_osc));

    // Oscillator-based Counter which gets counter on desired frequency (48.0 MHz/divisionFactor)
    logic [31:0] counter = 0;
    always_ff @(posedge int_osc)
        if (~(reset)) counter <= 0;
        else if (counter < divisionFactor) counter <= counter + 1;
        else    counter <= 0;
    
    // Get desired one bit frequency output from counter
    always_ff @(posedge int_osc)
        if (counter > (divisionFactor/2)) desiredFreqOut <= 1;
        else desiredFreqOut <= 0;
endmodule

module ledLogic(
    input   logic   [7:0]   switch,
    output  logic   [4:0]   led
    );
    // This module encodes the 5 onboard LEDs to display the sum of
    // two hex numbers, encoded as 2 4-bit numbers by 8 total switches.
	logic [7:0] nSW;
	assign nSW = ~switch;
    assign led[4:0] = nSW[7:4] + nSW[3:0];
endmodule

module sevenSegLogic(
    input logic [3:0] switch,
    output logic [6:0] segment
    );
    // This module encodes the output for a seven segment display, given an input of four switches representing h0-hf.
    // NOTE: the ~ indicates that segment is illuminated logic low, off for logic high. Remove ~ to switch.
    always_comb
        case (switch)
            4'h0: segment <= ~7'b1111110;
            4'h1: segment <= ~7'b1001000;
            4'h2: segment <= ~7'b0111101;
            4'h3: segment <= ~7'b1101101;
            4'h4: segment <= ~7'b1001011;
            4'h5: segment <= ~7'b1100111;
            4'h6: segment <= ~7'b1110111;
            4'h7: segment <= ~7'b1001100;
            4'h8: segment <= ~7'b1111111;
            4'h9: segment <= ~7'b1001111;
            4'ha: segment <= ~7'b1011111;
            4'hb: segment <= ~7'b1110011;
            4'hc: segment <= ~7'b0110001;
            4'hd: segment <= ~7'b1111001;
            4'he: segment <= ~7'b0110111;
            4'hf: segment <= ~7'b0010111;
            default: segment <= ~7'b0000001;
        endcase
endmodule

module ledTestbench();

  // Instantiate variables from across the modules that you need to use in testbench
  logic [7:0]	s;
  logic [4:0]	led;
  logic		reset;
  logic		clk;

  logic [31:0] vectornum, errors;
  logic [12:0] testvectors[10000:0];
  
  logic        new_error;
  logic [4:0]  expected;

  // instantiate device to be tested
  ledLogic dut(~s, led);
  
  // generate clock
  always 
    begin
      clk = 1; #5; clk = 0; #5;
    end

  // at start of test, load vectors and pulse reset
  initial
    begin
      $readmemb("ledTest.tv", testvectors);
      vectornum = 0; errors = 0;
      reset = 1; #5; reset = 0;
    end
	 
  // apply test vectors on rising edge of clk
  always @(posedge clk)
    begin
      #1; {s, expected} = testvectors[vectornum];
    end

  // check results on falling edge of clk
  always @(negedge clk)
    if (~reset) begin // skip cycles during reset
      new_error=0; 

      if ((led!==expected[4:0])&&(expected[4:0]!==5'bxx)) begin
        $display("   led = %b     Expected %b", led,    expected[4:0]);
        new_error=1;
      end

      if (new_error) begin
        $display("Error on vector %d: inputs: s = %h led = %h", vectornum, s, led);
        errors = errors + 1;
      end
      vectornum = vectornum + 1;
      if (testvectors[vectornum] === 13'bx) begin 
        $display("%d tests completed with %d errors", vectornum, errors);
        $stop;
      end
    end
endmodule