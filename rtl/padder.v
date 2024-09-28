



module padder(clk, reset, in, in_ready, is_last, byte_num, buffer_full, out, out_ready, f_ack);
    input              clk, reset;
    input      [31:0]  in;
    input              in_ready, is_last;
    input      [1:0]   byte_num;
    output             buffer_full; /* to "user" module */
    output reg [575:0] out;         /* to "f_permutation" module */
    output             out_ready;   /* to "f_permutation" module */
    input              f_ack;       /* from "f_permutation" module */
    
    reg                state;       /* state == 0: user will send more input data
                                     * state == 1: user will not send any data */
    reg                done;        /* == 1: out_ready should be 0 */
    reg        [17:0]  i;           /* length of "out" buffer */
    wire       [31:0]  v0;          /* output of module "padder1" */
    reg        [31:0]  v1;          /* to be shifted into register "out" */
    wire               accept,      /* accept user input? */
                       update;
    
    assign buffer_full = i[17];
    assign out_ready = buffer_full;
    assign accept = (~ state) & in_ready & (~ buffer_full); // if state == 1, do not eat input
    assign update = (accept | (state & (~ buffer_full))) & (~ done); // don't fill buffer if done

    always @ (posedge clk)
      if (reset)
        out <= 0;
      else if (update)
        out <= {out[575-32:0], v1};

    always @ (posedge clk)
      if (reset)
        i <= 0;
      else if (f_ack | update)
        i <= {i[16:0], 1'b1} & {18{~ f_ack}};
/*    if (f_ack)  i <= 0; */
/*    if (update) i <= {i[16:0], 1'b1}; // increase length */

    always @ (posedge clk)
      if (reset)
        state <= 0;
      else if (is_last)
        state <= 1;

    always @ (posedge clk)
      if (reset)
        done <= 0;
      else if (state & out_ready)
        done <= 1;

    padder1 p0 (in, byte_num, v0);
    
    always @ (*)
      begin
        if (state)
          begin
            v1 = 0;
            v1[7] = v1[7] | i[16]; // "v1[7]" is the MSB of the last byte of "v1"
          end
        else if (is_last == 0)
          v1 = in;
        else
          begin
            v1 = v0;
            v1[7] = v1[7] | i[16];
          end
      end
endmodule
