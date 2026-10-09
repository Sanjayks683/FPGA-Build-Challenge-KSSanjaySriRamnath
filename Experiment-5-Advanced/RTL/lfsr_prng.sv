`default_nettype none


module lfsr_prng #(
    parameter logic [31:0] DEFAULT_SEED = 32'h5A8E_1247
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        step_en,

    output wire [15:0] rand_16,
    output wire [1:0]  rand_action
);

    reg [31:0] lfsr_reg;


    wire feedback = lfsr_reg[31] ^ lfsr_reg[21] ^ lfsr_reg[1] ^ lfsr_reg[0];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr_reg <= DEFAULT_SEED;
        end else if (step_en) begin
            lfsr_reg <= {lfsr_reg[30:0], feedback};
        end
    end

    assign rand_16     = lfsr_reg[15:0];
    assign rand_action = lfsr_reg[17:16];

endmodule

`default_nettype wire
