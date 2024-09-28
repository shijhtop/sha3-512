/*
 * Copyright 2013, Homer Hsing <homer.hsing@gmail.com>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

`timescale 1ns / 1ps
`define P 20

module test_keccak;

    // Inputs
    reg clk;
    reg reset;
    reg [31:0] in;
    reg in_ready;
    reg is_last;
    reg [1:0] byte_num;

    // Outputs
    wire buffer_full;
    wire [511:0] out;
    wire out_ready;

    // Var
    integer i;

    // Instantiate the Unit Under Test (UUT)
    keccak uut (
        .clk(clk),
        .reset(reset),
        .in(in),
        .in_ready(in_ready),
        .is_last(is_last),
        .byte_num(byte_num),
        .buffer_full(buffer_full),
        .out(out),
        .out_ready(out_ready)
    );

    initial begin
        // Initialize Inputs
        clk = 0;
        reset = 0;
        in = 0;
        in_ready = 0;
        is_last = 0;
        byte_num = 0;

        // Wait 100 ns for global reset to finish
        #100;

        // Add stimulus here
        @ (negedge clk);

        // SHA3-512（32'hA1A2A3A4）
        reset = 1; #(`P); reset = 0;
        in_ready = 1; is_last = 0;
        in = 32'hA1A2A3A4; #(`P);
        in = 0;
        byte_num = 0; is_last = 1; #(`P);
        in_ready = 0; is_last = 0;
        while (out_ready !== 1)
            #(`P);
        check(512'h83562a44a0b12db01a4ff2cd92598866230a62c380c7e21b91c435814fd8311a875e20e43d648208480df21cea1df27c141bdccd45a32fcb60596786c7276ec0);

        // SHA3-512("The quick brown fox jumps over the lazy dog.")
        reset = 1; #(`P); reset = 0;
        in_ready = 1; is_last = 0;
        in = "The "; #(`P);
        in = "quic"; #(`P);
        in = "k br"; #(`P);
        in = "own "; #(`P);
        in = "fox "; #(`P);
        in = "jump"; #(`P);
        in = "s ov"; #(`P);
        in = "er t"; #(`P);
        in = "he l"; #(`P);
        in = "azy "; #(`P);
        in = "dog."; #(`P);
        in = 0; byte_num = 0; is_last = 1; #(`P); /* !!! */
        in_ready = 0; is_last = 0;
        while (out_ready !== 1)
            #(`P);
        check(512'h18f4f4bd419603f95538837003d9d254c26c23765565162247483f65c50303597bc9ce4d289f21d1c2f1f458828e33dc442100331b35e7eb031b5d38ba6460f8);

        // 48'hB1B2B3B4B5
        reset = 1; #(`P); reset = 0;
        #(7*`P); // wait some cycles
        in_ready = 1; is_last = 0; byte_num = 1;
        in = 32'hB1B2B3B4;
        #(`P);
        is_last = 1; byte_num = 1;
        in = 32'hB5000000;
        #(`P);
        in = 32'h12345678; // should not be eat
        in_ready = 1;
        is_last = 1;
        #(`P/2);
        if (buffer_full === 1) error; // should be 0
        #(`P/2);
        in_ready = 0;
        is_last = 0;
        while (out_ready !== 1)
            #(`P);
        check(512'hd67ccc5ed4e03c7904b49ac21b977ee0838c98b103cf92009e2ba0fc96674a6d29b3c3685adac535f26d42866175e7f5548501e6555bd3bcc5275922d72b59ed);
        for(i=0; i<5; i=i+1)
          begin
            #(`P);
            if (buffer_full !== 0) error; // should keep 0
          end

        // hash an empty string, should not eat next input
        reset = 1; #(`P); reset = 0;
        #(7*`P); // wait some cycles
        in = 32'h12345678; // should not be eat
        byte_num = 0;
        in_ready = 1;
        is_last = 1;
        #(`P);
        in = 32'hddddd; // should not be eat
        in_ready = 1; // next input
        is_last = 1;
        #(`P);
        in_ready = 0;
        is_last = 0;
        while (out_ready !== 1)
            #(`P);
        check(512'hA69F73CCA23A9AC5C8B567DC185A756E97C982164FE25859E0D1DCC1475C80A615B2123AF1F5F94C11E3E9402C3AC558F500199D95B6D3E301758586281DCD26);
        for(i=0; i<5; i=i+1)
          begin
            #(`P);
            if (buffer_full !== 0) error; // should keep 0
          end

/////////////////////////////////////////////////////////////////////
        // pad an (576*2-64) bit string
        reset = 1; #(`P); reset = 0;
        in_ready = 1;
        byte_num = 1; /* should have no effect */
        is_last = 0;
        for (i=0; i<9; i=i+1)
          begin
            in = 32'h12345678; #(`P);
            in = 32'h90abcdef; #(`P);
          end
        #(`P/2);
        if (buffer_full !== 1) error; // should not eat
        #(`P/2);
        in = 32'h999; // should not eat this
        in_ready = 0;
        #(`P/2);
        if (buffer_full !== 0) error; // should not eat, but buffer should not be full
        #(`P/2);
        #(`P);
        // feed next (576-16) bit
        in_ready = 1;
        for (i=0; i<8; i=i+1)
          begin
            in = 32'h12345678; #(`P);
            in = 32'h90abcdef; #(`P);
          end
        in = 32'h0;
        byte_num = 0;
        is_last = 1;
        #(`P);
        is_last = 0;
        in_ready = 0;
        while (out_ready !== 1)
            #(`P);
        check(512'hBBEB03062FDB8B7227718FF62DA57194DA43AAB7977DD660CDCEC36886E3573B02CB9728C236548E968F1AE632E381B3AFE6D95E427788CF2A3B3FE9B8090B05);

        $display("Good!");
        $finish;
    end

    always #(`P/2) clk = ~ clk;

    task error;
        begin
              $display("E");
              $finish;
        end
    endtask

    task check;
        input [511:0] wish;
        begin
          if (out !== wish)
            begin
              $display("%h %h", out, wish); error;
            end
        end
    endtask
endmodule

`undef P
