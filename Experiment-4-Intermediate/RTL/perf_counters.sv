`default_nettype wire


module perf_counters (
    input  logic        clk,
    input  logic        rst,
    input  logic        instr_retired,
    input  logic        stall_pulse,
    input  logic        branch_pulse,
    output logic [31:0] cycle_count,
    output logic [31:0] instr_count,
    output logic [31:0] stall_count,
    output logic [31:0] branch_count
);

    always_ff @(posedge clk) begin
        if (rst) begin
            cycle_count  <= 32'd0;
            instr_count  <= 32'd0;
            stall_count  <= 32'd0;
            branch_count <= 32'd0;
        end else begin
            cycle_count <= cycle_count + 32'd1;
            if (instr_retired) instr_count  <= instr_count  + 32'd1;
            if (stall_pulse)   stall_count  <= stall_count  + 32'd1;
            if (branch_pulse)  branch_count <= branch_count + 32'd1;
        end
    end

endmodule
