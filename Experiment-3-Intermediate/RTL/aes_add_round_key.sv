`default_nettype none

module aes_add_round_key (
    input  wire [127:0] state_in,
    input  wire [127:0] round_key,
    output logic [127:0] state_out
);

    assign state_out = state_in ^ round_key;

endmodule
