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

module displayMultiplexer #(parameter displayFreqHz=1000) (
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
    logic   [6:0]   intSegL;
    logic   [6:0]   intSegR;
    logic   [1:0]   toggle;

    sevenSegLogic   segRightCall (switch[3:0], intSegR);
    sevenSegLogic   segLeftCall  (switch[7:4], intSegL);

    frequencyGenerator #(.divisionFactor(48000), .halfFactor(24000), .counterBits(20)) freqGenCall (reset, toggleFreq);

    always_ff @(posedge toggleFreq)
    // If reset is high (active low reset), and we were displaying the R screen with toggle=01
    // The switch to display things on the left
    if (reset & (~toggle[1]) & toggle[0]) begin
        toggle <= 2'b10;
        segment <= intSegL;
    end
    else begin
        toggle <= 2'b01;
        segment <= intSegR;
    end

    assign displayL = ~toggle[1];
    assign displayR = ~toggle[0];

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

module frequencyGenerator #(parameter divisionFactor=20000000, parameter halfFactor=10000000, parameter counterBits=25) (
    input   logic   reset,
    output  logic   desiredFreqOut
    );
    // This module is coded to output a default freq of 2.4Hz. The factors above
    // may be changed in the module call to adjust this.
    
    // High Frequency 48MHz Oscillator
    logic int_osc;
    HSOSC hf_osc (.CLKHFPU(1'b1), .CLKHFEN(1'b1), .CLKHF(int_osc));

    // Oscillator-based Counter which gets counter on desired frequency (48.0 MHz/divisionFactor)
    logic [(counterBits-1):0] counter = 0;
    always_ff @(posedge int_osc)
        if (~(reset)) counter <= 0;
        else if (counter < divisionFactor) counter <= counter + 1;
        else    counter <= 0;
    
    // Get desired one bit frequency output from counter
    always_comb
        if (counter > halfFactor) desiredFreqOut = 1;
        else desiredFreqOut = 0;
endmodule

module ledLogic(
    input   logic   [7:0]   switch,
    output  logic   [4:0]   led
    );
    // This module encodes the 5 onboard LEDs to display the sum of
    // two hex numbers, encoded as 2 4-bit numbers by 8 total switches.

    assign led[4:0] = switch[7:4] + switch[3:0];
endmodule