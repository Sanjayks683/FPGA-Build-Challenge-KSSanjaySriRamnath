`default_nettype wire

module if_stage import riscv_pkg::*; (
    input  wire         clk, rst,
    input  wire         stall,
    input  wire         flush,
    input  wire         branch_taken,
    input  wire  [31:0] branch_target,
    input  wire  [31:0] recovery_pc,
    input  wire         btb_hit,
    input  wire         predicted_taken,
    input  wire  [31:0] predicted_pc,

    input  wire         arm_clk,
    input  wire  [31:0] arm_imem_addr,
    input  wire  [31:0] arm_imem_wdata,
    input  wire         arm_imem_we,

    output logic [31:0] pc_out,
    output logic [31:0] instr_out,
    output logic [31:0] pc_plus4_out
);

    logic [31:0] pc_reg;
    logic [31:0] next_pc;
    logic [31:0] imem_data;

    assign pc_plus4_out = pc_reg + 32'd4;

    always_comb begin
        if (flush) begin
            next_pc = recovery_pc;
        end else if (btb_hit && predicted_taken) begin
            next_pc = predicted_pc;
        end else begin
            next_pc = pc_plus4_out;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            pc_reg <= PC_RESET;
        end else if (!stall) begin
            pc_reg <= next_pc;
        end
    end

    assign pc_out = pc_reg;

    instr_mem u_instr_mem (
        .clk       (clk),
        .addr      (pc_reg),
        .rdata     (imem_data),
        .arm_clk   (arm_clk),
        .arm_addr  (arm_imem_addr),
        .arm_wdata (arm_imem_wdata),
        .arm_we    (arm_imem_we)
    );

    assign instr_out = flush ? 32'h0 : imem_data;

endmodule
