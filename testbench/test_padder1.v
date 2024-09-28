




`timescale 1ns / 1ps
`define P 20

module test_padder1;

    // Inputs
    reg [31:0] in;
    reg [1:0] byte_num;

    // Outputs
    wire [31:0] out;
    
    reg [31:0] wish;

    // Instantiate the Unit Under Test (UUT)
    padder1 uut (
        .in(in),
        .byte_num(byte_num),
        .out(out)
    );

    initial begin
        // Initialize Inputs
        in = 0;
        byte_num = 0;

        // Wait 100 ns for global reset to finish
        #100;

        // Add stimulus here
        in = 32'h90ABCDEF;
        byte_num = 0;
        wish = 32'h06000000;
        check;
        byte_num = 1;
        wish = 32'h90060000;
        check;
        byte_num = 2;
        wish = 32'h90AB0600;
        check;
        byte_num = 3;
        wish = 32'h90ABCD06;
        check;
        $display("Good!");
        $finish;
    end

    task check;
      begin
        #(`P);
        if (out !== wish)
          begin
            $display("E");
            $finish;
          end
      end
    endtask
endmodule

`undef P
