`default_nettype none

module aes_mix_columns (
    input  wire        is_decrypt,
    input  wire [127:0] state_in,
    output logic [127:0] state_out
);


    function automatic logic [7:0] xtime(input logic [7:0] a);
        xtime = {a[6:0], 1'b0} ^ (a[7] ? 8'h1b : 8'h00);
    endfunction

    function automatic logic [7:0] mul3(input logic [7:0] a);
        mul3 = xtime(a) ^ a;
    endfunction

    function automatic logic [7:0] mul9(input logic [7:0] a);
        logic [7:0] x2, x4, x8;
        x2 = xtime(a);
        x4 = xtime(x2);
        x8 = xtime(x4);
        mul9 = x8 ^ a;
    endfunction

    function automatic logic [7:0] mul11(input logic [7:0] a);
        logic [7:0] x2, x4, x8;
        x2 = xtime(a);
        x4 = xtime(x2);
        x8 = xtime(x4);
        mul11 = x8 ^ x2 ^ a;
    endfunction

    function automatic logic [7:0] mul13(input logic [7:0] a);
        logic [7:0] x2, x4, x8;
        x2 = xtime(a);
        x4 = xtime(x2);
        x8 = xtime(x4);
        mul13 = x8 ^ x4 ^ a;
    endfunction

    function automatic logic [7:0] mul14(input logic [7:0] a);
        logic [7:0] x2, x4, x8;
        x2 = xtime(a);
        x4 = xtime(x2);
        x8 = xtime(x4);
        mul14 = x8 ^ x4 ^ x2;
    endfunction


    logic [7:0] in_b [0:15];
    logic [7:0] out_b [0:15];

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : gen_unpack
            assign in_b[i] = state_in[127 - 8*i -: 8];
            assign state_out[127 - 8*i -: 8] = out_b[i];
        end
    endgenerate

    genvar c;
    generate
        for (c = 0; c < 4; c = c + 1) begin : gen_cols
            assign out_b[4*c + 0] = (!is_decrypt) ?
                (xtime(in_b[4*c + 0]) ^ mul3(in_b[4*c + 1]) ^ in_b[4*c + 2] ^ in_b[4*c + 3]) :
                (mul14(in_b[4*c + 0]) ^ mul11(in_b[4*c + 1]) ^ mul13(in_b[4*c + 2]) ^ mul9(in_b[4*c + 3]));

            assign out_b[4*c + 1] = (!is_decrypt) ?
                (in_b[4*c + 0] ^ xtime(in_b[4*c + 1]) ^ mul3(in_b[4*c + 2]) ^ in_b[4*c + 3]) :
                (mul9(in_b[4*c + 0]) ^ mul14(in_b[4*c + 1]) ^ mul11(in_b[4*c + 2]) ^ mul13(in_b[4*c + 3]));

            assign out_b[4*c + 2] = (!is_decrypt) ?
                (in_b[4*c + 0] ^ in_b[4*c + 1] ^ xtime(in_b[4*c + 2]) ^ mul3(in_b[4*c + 3])) :
                (mul13(in_b[4*c + 0]) ^ mul9(in_b[4*c + 1]) ^ mul14(in_b[4*c + 2]) ^ mul11(in_b[4*c + 3]));

            assign out_b[4*c + 3] = (!is_decrypt) ?
                (mul3(in_b[4*c + 0]) ^ in_b[4*c + 1] ^ in_b[4*c + 2] ^ xtime(in_b[4*c + 3])) :
                (mul11(in_b[4*c + 0]) ^ mul13(in_b[4*c + 1]) ^ mul9(in_b[4*c + 2]) ^ mul14(in_b[4*c + 3]));
        end
    endgenerate

endmodule
