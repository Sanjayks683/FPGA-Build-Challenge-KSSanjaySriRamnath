`default_nettype none

module aes_cipher (
    input  wire          clk,
    input  wire          rst_n,
    input  wire          is_decrypt,
    input  wire          valid_in,
    input  wire  [127:0] data_in,
    input  wire [1919:0] round_keys_bus,
    output logic         valid_out,
    output logic [127:0] data_out,
    output logic         busy,
    output logic         done
);


    logic [127:0] round_keys [0:14];
    genvar k;
    generate
        for (k = 0; k < 15; k = k + 1) begin : gen_unpack_rk
            assign round_keys[k] = round_keys_bus[k*128 +: 128];
        end
    endgenerate


    logic [127:0] stage_state [0:14];
    logic         stage_valid [0:14];
    logic         stage_decrypt [0:14];


    logic [127:0] init_round_key;
    assign init_round_key = (!is_decrypt) ? round_keys[0] : round_keys[14];

    assign stage_state[0]   = data_in ^ init_round_key;
    assign stage_valid[0]   = valid_in;
    assign stage_decrypt[0] = is_decrypt;


    logic [13:0] decrypt_pipe;
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            decrypt_pipe <= 14'b0;
        end else begin
            decrypt_pipe <= {decrypt_pipe[12:0], is_decrypt};
        end
    end


    genvar r;
    generate
        for (r = 1; r <= 13; r = r + 1) begin : gen_round
            logic [127:0] current_rk;
            wire stage_dec = (r == 1) ? stage_decrypt[0] : decrypt_pipe[r-2];
            assign current_rk = (!stage_dec) ? round_keys[r] : round_keys[14 - r];

            aes_round #(
                .IS_FINAL_ROUND(1'b0)
            ) u_round (
                .clk(clk),
                .rst_n(rst_n),
                .is_decrypt(stage_dec),
                .valid_in(stage_valid[r-1]),
                .state_in(stage_state[r-1]),
                .round_key(current_rk),
                .valid_out(stage_valid[r]),
                .state_out(stage_state[r])
            );
        end
    endgenerate


    logic [127:0] final_rk;
    wire final_dec = decrypt_pipe[12];
    assign final_rk = (!final_dec) ? round_keys[14] : round_keys[0];

    aes_round #(
        .IS_FINAL_ROUND(1'b1)
    ) u_final_round (
        .clk(clk),
        .rst_n(rst_n),
        .is_decrypt(final_dec),
        .valid_in(stage_valid[13]),
        .state_in(stage_state[13]),
        .round_key(final_rk),
        .valid_out(stage_valid[14]),
        .state_out(stage_state[14])
    );


    assign data_out  = stage_state[14];
    assign valid_out = stage_valid[14];
    assign done      = stage_valid[14];


    logic [14:0] all_valids;
    assign all_valids = {stage_valid[14], stage_valid[13], stage_valid[12], stage_valid[11],
                         stage_valid[10], stage_valid[9],  stage_valid[8],  stage_valid[7],
                         stage_valid[6],  stage_valid[5],  stage_valid[4],  stage_valid[3],
                         stage_valid[2],  stage_valid[1],  valid_in};
    assign busy = |all_valids;

endmodule
