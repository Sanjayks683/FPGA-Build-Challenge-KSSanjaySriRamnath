`default_nettype none

module aes_shift_rows (
    input  wire        is_decrypt,
    input  wire [127:0] state_in,
    output logic [127:0] state_out
);


    logic [7:0] in_b [0:15];
    logic [7:0] out_b [0:15];

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : gen_unpack
            assign in_b[i] = state_in[127 - 8*i -: 8];
            assign state_out[127 - 8*i -: 8] = out_b[i];
        end
    endgenerate


    assign out_b[0]  = in_b[0];
    assign out_b[4]  = in_b[4];
    assign out_b[8]  = in_b[8];
    assign out_b[12] = in_b[12];


    assign out_b[1]  = (!is_decrypt) ? in_b[5]  : in_b[13];
    assign out_b[5]  = (!is_decrypt) ? in_b[9]  : in_b[1];
    assign out_b[9]  = (!is_decrypt) ? in_b[13] : in_b[5];
    assign out_b[13] = (!is_decrypt) ? in_b[1]  : in_b[9];


    assign out_b[2]  = in_b[10];
    assign out_b[6]  = in_b[14];
    assign out_b[10] = in_b[2];
    assign out_b[14] = in_b[6];


    assign out_b[3]  = (!is_decrypt) ? in_b[15] : in_b[7];
    assign out_b[7]  = (!is_decrypt) ? in_b[3]  : in_b[11];
    assign out_b[11] = (!is_decrypt) ? in_b[7]  : in_b[15];
    assign out_b[15] = (!is_decrypt) ? in_b[11] : in_b[3];

endmodule
