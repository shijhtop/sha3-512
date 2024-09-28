   




   

module padder1(in, byte_num, out);
    input      [31:0] in;
    input      [1:0]  byte_num;
    output reg [31:0] out;
    
    always @ (*)
      case (byte_num)
        0: out = 32'h06000000;
        1: out = {in[31:24], 24'h060000};
        2: out = {in[31:16], 16'h0600};
        3: out = {in[31:8],   8'h06};
      endcase
endmodule
