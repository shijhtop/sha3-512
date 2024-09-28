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

/* test "f permutation".
 * write a block, wait 3 cycles, write another block, do not wait, write the third block */

`define low_pos(w,b)      ((w)*64 + (b)*8)
`define low_pos2(w,b)     `low_pos(w,7-b)
`define high_pos(w,b)     (`low_pos(w,b) + 7)
`define high_pos2(w,b)    (`low_pos2(w,b) + 7)

`timescale 1ns / 1ps
`define P 20

module test_f_permutation;

    // Inputs
    reg clk;
    reg reset;
    reg [575:0] in;
    reg in_ready;

    // Outputs
    wire ack;
    wire [1599:0] out, rout;
    wire [511:0] final_out;
    reg [1599:0] round1_check_out;
    reg [511:0] check_hash_val;
    wire out_ready;

    integer i;

    // Instantiate the Unit Under Test (UUT)
    f_permutation uut (
        .clk(clk),
        .reset(reset),
        .in(in),
        .in_ready(in_ready),
        .ack(ack),
        .out(out),
        .out_ready(out_ready)
    );

    genvar w, b;
    /* reorder byte ~ ~ */
    generate
      for(w=0; w<25; w=w+1)
        begin : L2
          for(b=0; b<8; b=b+1)
            begin : L3
              assign rout[`high_pos(w,b):`low_pos(w,b)] = out[`high_pos2(w,b):`low_pos2(w,b)];
            end
        end
    endgenerate

    assign final_out = rout[1599 : 1599-511];

    initial begin
        // Initialize Inputs
        clk = 0;
        reset = 1;
        in = 0;
        in_ready = 0;

        // Wait 100 ns for global reset to finish
        #100;

        // Add stimulus here
        @ (negedge clk);
        if (out !== 0) error; /* should be 0 */
        if (ack !== 0) error; /* should be 0 */
        if (out_ready !== 0) error; /* should be 0 */

        #(`P);
        reset = 0;
        //消息为空时的，加上填充的576bit输入
        in = 576'h000000000000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000000000000000;
        // 第一轮输出
        round1_check_out = 1600'h0700000000080000000000000060000000200300000800000600000000000000002003000060000000000000000000000000C80000C0000000000000000000200000000000C000000000C800000000200C00000000000000C00C00000000000000000000000000008C0C00000000000040000000000000000018006400000000008000000000000000180000000000000080006400000000000000000000000000000000400600400000000000004000180000004006000000000000000000401800000000004000;
        //消息为空时的哈希值
        check_hash_val = 512'hA69F73CCA23A9AC5C8B567DC185A756E97C982164FE25859E0D1DCC1475C80A615B2123AF1F5F94C11E3E9402C3AC558F500199D95B6D3E301758586281DCD26;
        in_ready = 1;
        #(`P);
        if (out_ready !== 0) error; /* should be 0 */
        in_ready = 0;

        $display("%h", rout);
        if (rout == round1_check_out) begin
          $display("round 1 Good!");
          // $finish;
        end
        else error;

        /* check 1~22-th cycles */
        for(i=0; i<22; i=i+1)
          begin
            if (out === 0) error; /* should not be 0 */
            if (ack !== 0) error; /* should be 0 */
            if (out_ready !== 0) error; /* should be 0 */
            #(`P);
          end

        /* check the 23-th cycle */
        if (out === 0) error; /* should not be 0 */
        if (ack !== 0) error; /* should be 0 */
        if (out_ready !== 0) error; /* should be 0 */
        #(`P);#(`P);

        $display("%h", final_out);
        if (final_out == check_hash_val) begin
          $display("hash value Good!");
          $finish;
        end
        else error;

    end

    always #(`P/2) clk = ~ clk;

    task error;
      begin
        $display("Error!");
        $finish;
      end
    endtask
endmodule

`undef P
