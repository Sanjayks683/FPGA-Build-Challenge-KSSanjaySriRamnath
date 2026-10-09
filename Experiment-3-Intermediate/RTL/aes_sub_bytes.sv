`default_nettype none

module aes_sub_bytes (
    input  wire        is_decrypt,
    input  wire [127:0] state_in,
    output logic [127:0] state_out
);

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : gen_sbox
            aes_sbox u_sbox (
                .is_decrypt(is_decrypt),
                .byte_in(state_in[i*8 +: 8]),
                .byte_out(state_out[i*8 +: 8])
            );
        end
    endgenerate

endmodule
