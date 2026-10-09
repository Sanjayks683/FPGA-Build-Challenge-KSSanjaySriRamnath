`default_nettype wire

module ex_stage import riscv_pkg::*; (
    input  logic [31:0] rs1_data, rs2_data, imm_ext, pc,
    input  logic [3:0]  alu_op,
    input  logic        alu_src, branch, jump, is_jalr,
    input  logic [2:0]  funct3,
    input  logic [1:0]  fwd_a_sel, fwd_b_sel,
    input  logic [31:0] ex_mem_result, mem_wb_result,
    output logic [31:0] alu_result,
    output logic [31:0] branch_target,
    output logic        branch_taken,
    output logic [31:0] pc_plus4,
    output logic [31:0] rs2_data_out
);

    logic [31:0] alu_op_a;
    logic [31:0] alu_op_b_raw;
    logic [31:0] alu_op_b;

    assign alu_op_a = (fwd_a_sel == 2'b10) ? ex_mem_result :
                      (fwd_a_sel == 2'b01) ? mem_wb_result : rs1_data;

    assign alu_op_b_raw = (fwd_b_sel == 2'b10) ? ex_mem_result :
                          (fwd_b_sel == 2'b01) ? mem_wb_result : rs2_data;

    assign alu_op_b = alu_src ? imm_ext : alu_op_b_raw;
    assign rs2_data_out = alu_op_b_raw;

    always_comb begin
        case (alu_op)
            ALU_ADD:    alu_result = alu_op_a + alu_op_b;
            ALU_SUB:    alu_result = alu_op_a - alu_op_b;
            ALU_AND:    alu_result = alu_op_a & alu_op_b;
            ALU_OR:     alu_result = alu_op_a | alu_op_b;
            ALU_XOR:    alu_result = alu_op_a ^ alu_op_b;
            ALU_SLL:    alu_result = alu_op_a << alu_op_b[4:0];
            ALU_SRL:    alu_result = alu_op_a >> alu_op_b[4:0];
            ALU_SRA:    alu_result = $signed(alu_op_a) >>> alu_op_b[4:0];
            ALU_SLT:    alu_result = ($signed(alu_op_a) < $signed(alu_op_b)) ? 32'd1 : 32'd0;
            ALU_SLTU:   alu_result = (alu_op_a < alu_op_b) ? 32'd1 : 32'd0;
            ALU_LUI:    alu_result = alu_op_b;
            ALU_PASS_B: alu_result = alu_op_b;
            default:    alu_result = 32'h0;
        endcase
    end

    logic eval_result;
    always_comb begin
        case (funct3)
            F3_BEQ:  eval_result = (alu_op_a == alu_op_b_raw);
            F3_BNE:  eval_result = (alu_op_a != alu_op_b_raw);
            F3_BLT:  eval_result = ($signed(alu_op_a) < $signed(alu_op_b_raw));
            F3_BGE:  eval_result = ($signed(alu_op_a) >= $signed(alu_op_b_raw));
            F3_BLTU: eval_result = (alu_op_a < alu_op_b_raw);
            F3_BGEU: eval_result = (alu_op_a >= alu_op_b_raw);
            default: eval_result = 1'b0;
        endcase
    end

    assign branch_taken = (branch & eval_result) | jump;

    always_comb begin
        if (is_jalr) begin
            branch_target = (alu_op_a + imm_ext) & ~32'h1;
        end else begin
            branch_target = pc + imm_ext;
        end
    end

    assign pc_plus4 = pc + 32'd4;

endmodule
