/*
Draft 2 - Separated Modules
Jackson Philion, Sep.7.2024, jphilion@g.hmc.edu. Harvey Mudd College for E155: Microprocessors, taught by Prof Josh Brake.

The following code is used to run a 7 segment display with an FPGA. It is intended
to take in 4 switch inputs and output two things. Firstly, a string of 3 LEDs that
do xor and and functions on the inputs and has an extra one that runs at 2.4 Hz off
of the internal high speed oscillator (48MHz HSOSC). Secondly, signals to the 7
segments of the display, which light up all 16 hex numbers which are expressable by
a 4 bit binary number.
*/

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

module ledLogic(
    input logic [3:0] switch,
    input logic       reset,
    output logic [2:0] led
    );
    // Module which encodes the output LED logic from Lab 1 based on 4 bit switch input.
    assign led[0] = switch[1] ^ switch[0];
    assign led[1] = switch[3] & switch[2];
    logic freqOut;
    frequencyGenerator frequencyGeneratorCall(reset, freqOut);
    assign led[2] = freqOut;
endmodule

module frequencyGenerator #(parameter divisionFactor=20000000, parameter halfFactor=10000000, parameter counterBits=25) (
    input   logic   reset,
    output  logic   desiredFreqOut
    );
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

module top(
    input   logic           reset,
    input   logic   [3:0]   s,
    output  logic   [6:0]   seg,
    output  logic   [2:0]   led
    );

    // LED Output Logic
    ledLogic ledLocigCall(s,reset,led);
    
    // Segment Output Logic
    sevenSegLogic sevenSegLogicCall(s,seg);
endmodule