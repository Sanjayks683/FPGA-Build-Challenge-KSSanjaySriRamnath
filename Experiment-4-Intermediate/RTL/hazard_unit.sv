`default_nettype wire

module hazard_unit (
    input  logic        id_ex_mem_rd_en,
    input  logic [4:0]  id_ex_rd,
    input  logic [4:0]  if_id_rs1, if_id_rs2,
    input  logic        if_id_rs1_valid,
    input  logic        if_id_rs2_valid,

    input  logic        id_ex_branch,
    input  logic        id_ex_jump,
    input  logic        ex_branch_taken,
    input  logic        btb_hit,
    input  logic        btb_predicted_taken,
    input  logic [31:0] id_ex_predicted_pc,
    input  logic [31:0] ex_branch_target,

    output logic        if_id_stall,
    output logic        pc_stall,
    output logic        if_id_flush,
    output logic        id_ex_flush,
    output logic        mispredict_hazard
);

    logic load_use_hazard;

    always_comb begin
        load_use_hazard   = 1'b0;
        mispredict_hazard = 1'b0;

        if (id_ex_mem_rd_en && id_ex_rd != 5'b0 &&
            ((if_id_rs1_valid && id_ex_rd == if_id_rs1) ||
             (if_id_rs2_valid && id_ex_rd == if_id_rs2))) begin
            load_use_hazard = 1'b1;
        end

        if (id_ex_branch || id_ex_jump) begin
            logic direction_wrong;
            logic target_wrong;
            direction_wrong = (ex_branch_taken != (btb_hit && btb_predicted_taken));
            target_wrong    = ex_branch_taken && (id_ex_predicted_pc != ex_branch_target);
            if (direction_wrong || target_wrong)
                mispredict_hazard = 1'b1;
        end
    end

    always_comb begin
        pc_stall    = 1'b0;
        if_id_stall = 1'b0;
        id_ex_flush = 1'b0;
        if_id_flush = 1'b0;

        if (mispredict_hazard) begin
            if_id_flush = 1'b1;
            id_ex_flush = 1'b1;
        end else if (load_use_hazard) begin
            pc_stall    = 1'b1;
            if_id_stall = 1'b1;
            id_ex_flush = 1'b1;
        end
    end

endmodule
