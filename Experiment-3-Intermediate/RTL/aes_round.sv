`default_nettype none

module aes_round #(
    parameter bit IS_FINAL_ROUND = 1'b0
)(
    input  wire          clk,
    input  wire          rst_n,
    input  wire          is_decrypt,
    input  wire          valid_in,
    input  wire  [127:0] state_in,
    input  wire  [127:0] round_key,
    output logic         valid_out,
    output logic [127:0] state_out
);


    logic [127:0] enc_sb;
    logic [127:0] enc_sr;
    logic [127:0] enc_mc;
    logic [127:0] enc_out;

    aes_sub_bytes u_enc_sub_bytes (
        .is_decrypt(1'b0),
        .state_in(state_in),
        .state_out(enc_sb)
    );

    aes_shift_rows u_enc_shift_rows (
        .is_decrypt(1'b0),
        .state_in(enc_sb),
        .state_out(enc_sr)
    );

    generate
        if (IS_FINAL_ROUND) begin : gen_enc_final
            assign enc_mc = enc_sr;
        end else begin : gen_enc_normal
            aes_mix_columns u_enc_mix_columns (
                .is_decrypt(1'b0),
                .state_in(enc_sr),
                .state_out(enc_mc)
            );
        end
    endgenerate

    assign enc_out = enc_mc ^ round_key;


    logic [127:0] dec_sr;
    logic [127:0] dec_sb;
    logic [127:0] dec_ark;
    logic [127:0] dec_out;

    aes_shift_rows u_dec_shift_rows (
        .is_decrypt(1'b1),
        .state_in(state_in),
        .state_out(dec_sr)
    );

    aes_sub_bytes u_dec_sub_bytes (
        .is_decrypt(1'b1),
        .state_in(dec_sr),
        .state_out(dec_sb)
    );

    assign dec_ark = dec_sb ^ round_key;

    generate
        if (IS_FINAL_ROUND) begin : gen_dec_final
            assign dec_out = dec_ark;
        end else begin : gen_dec_normal
            aes_mix_columns u_dec_mix_columns (
                .is_decrypt(1'b1),
                .state_in(dec_ark),
                .state_out(dec_out)
            );
        end
    endgenerate


    wire [127:0] next_state = (!is_decrypt) ? enc_out : dec_out;


    always_ff @(posedge clk) begin
        if (!rst_n) begin
            valid_out <= 1'b0;
            state_out <= 128'h0;
        end else begin
            valid_out <= valid_in;
            state_out <= next_state;
        end
    end

endmodule
