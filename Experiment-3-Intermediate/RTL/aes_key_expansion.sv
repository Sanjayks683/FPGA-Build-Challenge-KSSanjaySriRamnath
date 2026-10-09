`default_nettype none

module aes_key_expansion (
    input  wire          clk,
    input  wire          rst_n,
    input  wire          load_key,
    input  wire  [255:0] cipher_key,
    output logic         key_ready,
    output logic [1919:0] round_keys_bus
);


    logic [127:0] round_keys [0:14];

    genvar k;
    generate
        for (k = 0; k < 15; k = k + 1) begin : gen_flat_bus
            assign round_keys_bus[k*128 +: 128] = round_keys[k];
        end
    endgenerate


    typedef enum logic [1:0] {
        IDLE   = 2'd0,
        EXPAND = 2'd1,
        READY  = 2'd2
    } state_t;

    state_t state;
    logic [3:0] round_idx;


    function automatic logic [7:0] get_rcon(input logic [3:0] r);
        case (r)
            4'd2:  get_rcon = 8'h01;
            4'd4:  get_rcon = 8'h02;
            4'd6:  get_rcon = 8'h04;
            4'd8:  get_rcon = 8'h08;
            4'd10: get_rcon = 8'h10;
            4'd12: get_rcon = 8'h20;
            4'd14: get_rcon = 8'h40;
            default: get_rcon = 8'h00;
        endcase
    endfunction


    logic [31:0] prev_last_word;

    assign prev_last_word = round_keys[(round_idx == 0) ? 0 : round_idx - 1'b1][31:0];


    logic [31:0] rot_word;
    assign rot_word = {prev_last_word[23:0], prev_last_word[31:24]};


    logic [31:0] subword_in;
    assign subword_in = round_idx[0] ? prev_last_word : rot_word;


    logic [31:0] subword_out;
    genvar b;
    generate
        for (b = 0; b < 4; b = b + 1) begin : gen_subword_sbox
            aes_sbox u_sb (
                .is_decrypt(1'b0),
                .byte_in(subword_in[31 - 8*b -: 8]),
                .byte_out(subword_out[31 - 8*b -: 8])
            );
        end
    endgenerate


    logic [31:0] temp_word;
    assign temp_word = round_idx[0] ? subword_out : (subword_out ^ {get_rcon(round_idx), 24'h000000});


    logic [31:0] w_prev0, w_prev1, w_prev2, w_prev3;
    assign w_prev0 = round_keys[round_idx - 2'd2][127:96];
    assign w_prev1 = round_keys[round_idx - 2'd2][95:64];
    assign w_prev2 = round_keys[round_idx - 2'd2][63:32];
    assign w_prev3 = round_keys[round_idx - 2'd2][31:0];

    logic [31:0] w_new0, w_new1, w_new2, w_new3;
    assign w_new0 = w_prev0 ^ temp_word;
    assign w_new1 = w_prev1 ^ w_new0;
    assign w_new2 = w_prev2 ^ w_new1;
    assign w_new3 = w_prev3 ^ w_new2;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            state <= IDLE;
            key_ready <= 1'b0;
            round_idx <= 4'd0;
            for (integer i = 0; i < 15; i = i + 1) begin
                round_keys[i] <= 128'h0;
            end
        end else begin
            case (state)
                IDLE: begin
                    if (load_key) begin


                        round_keys[0] <= cipher_key[255:128];
                        round_keys[1] <= cipher_key[127:0];
                        round_idx <= 4'd2;
                        key_ready <= 1'b0;
                        state <= EXPAND;
                    end
                end

                EXPAND: begin
                    round_keys[round_idx] <= {w_new0, w_new1, w_new2, w_new3};
                    if (round_idx == 4'd14) begin
                        key_ready <= 1'b1;
                        state <= READY;
                    end else begin
                        round_idx <= round_idx + 1'b1;
                    end
                end

                READY: begin
                    key_ready <= 1'b1;
                    if (load_key) begin
                        round_keys[0] <= cipher_key[255:128];
                        round_keys[1] <= cipher_key[127:0];
                        round_idx <= 4'd2;
                        key_ready <= 1'b0;
                        state <= EXPAND;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
