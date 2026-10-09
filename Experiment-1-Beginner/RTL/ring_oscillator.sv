`default_nettype none
`timescale 1ns/1ps

module ro_core #(
    parameter int STAGES = 13
) (
    input  wire ena,
    output wire ro_out
);

    (* keep = "true", dont_touch = "true" *) wire [STAGES-1:0] chain;


    (* keep = "true", dont_touch = "true" *)
`ifndef SYNTHESIS
    nand #1 nand_inst (chain[0], ena, chain[STAGES-1]);
`else
    nand nand_inst (chain[0], ena, chain[STAGES-1]);
`endif

    genvar i;
    generate
        for (i = 1; i < STAGES; i++) begin : gen_inv
            (* keep = "true", dont_touch = "true" *)
`ifndef SYNTHESIS
            not #1 inv_inst (chain[i], chain[i-1]);
`else
            not inv_inst (chain[i], chain[i-1]);
`endif
        end
    endgenerate

    assign ro_out = chain[STAGES-1];

endmodule

module ring_oscillator (
    input  wire ena,
    output wire [3:0] ro_out
);

    ro_core #(.STAGES(13)) ro_13 (.ena(ena), .ro_out(ro_out[0]));
    ro_core #(.STAGES(17)) ro_17 (.ena(ena), .ro_out(ro_out[1]));
    ro_core #(.STAGES(19)) ro_19 (.ena(ena), .ro_out(ro_out[2]));
    ro_core #(.STAGES(23)) ro_23 (.ena(ena), .ro_out(ro_out[3]));

endmodule
