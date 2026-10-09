`default_nettype wire

module riscv_core import riscv_pkg::*; (
    input  logic        clk, rst,
    input  logic        cpu_clk_en,

    input  wire         arm_clk,
    input  wire  [31:0] arm_imem_addr,
    input  wire  [31:0] arm_imem_wdata,
    input  wire         arm_imem_we,
    input  wire  [31:0] arm_dmem_wr_addr,
    input  wire  [31:0] arm_dmem_rd_addr,
    input  wire  [31:0] arm_dmem_wdata,
    input  wire  [3:0]  arm_dmem_we,
    output logic [31:0] arm_dmem_rdata,

    output logic [31:0] debug_pc, debug_instr,
    output logic [31:0] perf_cycles, perf_instrs,
    output logic [31:0] perf_stalls, perf_branches,
    output logic        ebreak_committed
);

    logic [31:0] if_pc_out;
    logic [31:0] if_instr_out;
    logic [31:0] if_pc_plus4_out;

    if_id_t if_id_in;
    if_id_t if_id_out;

    logic [4:0]  id_rs1_addr, id_rs2_addr, id_rd_addr;
    logic        id_rs1_valid, id_rs2_valid;
    logic [31:0] id_rs1_data, id_rs2_data;
    logic [31:0] id_imm_ext;
    logic [3:0]  id_alu_op;
    logic        id_alu_src, id_mem_wr_en, id_mem_rd_en;
    logic [2:0]  id_mem_funct3;
    logic        id_reg_wr_en;
    logic [1:0]  id_wb_sel;
    logic        id_branch, id_jump, id_is_jalr;
    logic [6:0]  id_opcode, id_funct7;
    logic [2:0]  id_funct3;

    id_ex_t id_ex_in;
    id_ex_t id_ex_out;

    logic [1:0] fwd_a_sel, fwd_b_sel;

    logic [31:0] ex_alu_result;
    logic [31:0] ex_branch_target;
    logic        ex_branch_taken;
    logic [31:0] ex_pc_plus4;
    logic [31:0] ex_rs2_data_out;

    ex_mem_t ex_mem_in;
    ex_mem_t ex_mem_out;

    logic [31:0] mem_rd_data;

    mem_wb_t mem_wb_in;
    mem_wb_t mem_wb_out;

    logic [31:0] wb_data;
    logic        wb_reg_wr_en_out;
    logic [4:0]  wb_rd_addr_out;

    logic pc_stall;
    logic if_id_stall;
    logic if_id_flush;
    logic id_ex_flush;
    logic branch_mispredict;
    logic [31:0] recovery_pc;
    assign recovery_pc = ex_branch_taken ? ex_branch_target : id_ex_out.pc_plus4;

    logic        btb_hit;
    logic        predicted_taken;
    logic [31:0] predicted_pc;

    if_stage if_stage_inst (
        .clk            (clk),
        .rst            (rst),
        .stall          (pc_stall),
        .flush          (branch_mispredict),
        .branch_taken   (ex_branch_taken),
        .branch_target  (ex_branch_target),
        .recovery_pc    (recovery_pc),
        .btb_hit        (btb_hit),
        .predicted_taken(predicted_taken),
        .predicted_pc   (predicted_pc),
        .pc_out         (if_pc_out),
        .instr_out      (if_instr_out),
        .pc_plus4_out   (if_pc_plus4_out),
        .arm_clk        (arm_clk),
        .arm_imem_addr  (arm_imem_addr),
        .arm_imem_wdata (arm_imem_wdata),
        .arm_imem_we    (arm_imem_we)
    );

    always_comb begin
        if_id_in.pc                  = if_pc_out;
        if_id_in.instr               = if_instr_out;
        if_id_in.pc_plus4            = if_pc_plus4_out;
        if_id_in.predicted_pc        = predicted_taken ? predicted_pc : if_pc_plus4_out;
        if_id_in.btb_hit             = btb_hit;
        if_id_in.btb_predicted_taken = predicted_taken;
    end

    if_id_reg if_id_reg_inst (
        .clk   (clk),
        .rst   (rst),
        .flush (if_id_flush),
        .stall (if_id_stall),
        .d     (if_id_in),
        .q     (if_id_out)
    );

    id_stage id_stage_inst (
        .clk            (clk),
        .rst            (rst),
        .instr          (if_id_out.instr),
        .pc             (if_id_out.pc),
        .reg_wr_en      (wb_reg_wr_en_out),
        .reg_wr_addr    (wb_rd_addr_out),
        .reg_wr_data    (wb_data),
        .rs1_addr       (id_rs1_addr),
        .rs2_addr       (id_rs2_addr),
        .rd_addr        (id_rd_addr),
        .rs1_valid      (id_rs1_valid),
        .rs2_valid      (id_rs2_valid),
        .rs1_data       (id_rs1_data),
        .rs2_data       (id_rs2_data),
        .imm_ext        (id_imm_ext),
        .alu_op         (id_alu_op),
        .alu_src        (id_alu_src),
        .mem_wr_en      (id_mem_wr_en),
        .mem_rd_en      (id_mem_rd_en),
        .mem_funct3     (id_mem_funct3),
        .reg_wr_en_out  (id_reg_wr_en),
        .wb_sel         (id_wb_sel),
        .branch         (id_branch),
        .jump           (id_jump),
        .is_jalr        (id_is_jalr),
        .opcode         (id_opcode),
        .funct7         (id_funct7),
        .funct3         (id_funct3)
    );

    always_comb begin
        id_ex_in.valid               = (id_opcode != 7'b0);
        id_ex_in.pc                  = if_id_out.pc;
        id_ex_in.rs1_data            = id_rs1_data;
        id_ex_in.rs2_data            = id_rs2_data;
        id_ex_in.imm_ext             = id_imm_ext;
        id_ex_in.rs1_addr            = id_rs1_addr;
        id_ex_in.rs2_addr            = id_rs2_addr;
        id_ex_in.rd_addr             = id_rd_addr;
        id_ex_in.alu_op              = id_alu_op;
        id_ex_in.alu_src             = id_alu_src;
        id_ex_in.mem_wr_en           = id_mem_wr_en;
        id_ex_in.mem_rd_en           = id_mem_rd_en;
        id_ex_in.mem_funct3          = id_mem_funct3;
        id_ex_in.reg_wr_en           = id_reg_wr_en;
        id_ex_in.wb_sel              = id_wb_sel;
        id_ex_in.branch              = id_branch;
        id_ex_in.jump                = id_jump;
        id_ex_in.is_jalr             = id_is_jalr;
        id_ex_in.is_system           = (id_opcode == OPC_SYSTEM);
        id_ex_in.funct3              = id_funct3;
        id_ex_in.pc_plus4            = if_id_out.pc_plus4;
        id_ex_in.predicted_pc        = if_id_out.predicted_pc;
        id_ex_in.btb_hit             = if_id_out.btb_hit;
        id_ex_in.btb_predicted_taken = if_id_out.btb_predicted_taken;
    end

    id_ex_reg id_ex_reg_inst (
        .clk   (clk),
        .rst   (rst),
        .flush (id_ex_flush),
        .stall (1'b0),
        .d     (id_ex_in),
        .q     (id_ex_out)
    );

    forwarding_unit forwarding_unit_inst (
        .id_ex_rs1        (id_ex_out.rs1_addr),
        .id_ex_rs2        (id_ex_out.rs2_addr),
        .ex_mem_rd        (ex_mem_out.rd_addr),
        .ex_mem_reg_wr_en (ex_mem_out.reg_wr_en),
        .mem_wb_rd        (mem_wb_out.rd_addr),
        .mem_wb_reg_wr_en (mem_wb_out.reg_wr_en),
        .fwd_a_sel        (fwd_a_sel),
        .fwd_b_sel        (fwd_b_sel)
    );

    logic [31:0] mem_fwd_data;
    always_comb begin
        case (ex_mem_out.wb_sel)
            WB_PC4:  mem_fwd_data = ex_mem_out.pc_plus4;
            WB_ALU:  mem_fwd_data = ex_mem_out.alu_result;
            default: mem_fwd_data = ex_mem_out.alu_result;
        endcase
    end

    ex_stage ex_stage_inst (
        .rs1_data      (id_ex_out.rs1_data),
        .rs2_data      (id_ex_out.rs2_data),
        .imm_ext       (id_ex_out.imm_ext),
        .pc            (id_ex_out.pc),
        .alu_op        (id_ex_out.alu_op),
        .alu_src       (id_ex_out.alu_src),
        .branch        (id_ex_out.branch),
        .jump          (id_ex_out.jump),
        .is_jalr       (id_ex_out.is_jalr),
        .funct3        (id_ex_out.funct3),
        .fwd_a_sel     (fwd_a_sel),
        .fwd_b_sel     (fwd_b_sel),
        .ex_mem_result (mem_fwd_data),
        .mem_wb_result (wb_data),
        .alu_result    (ex_alu_result),
        .branch_target (ex_branch_target),
        .branch_taken  (ex_branch_taken),
        .pc_plus4      (ex_pc_plus4),
        .rs2_data_out  (ex_rs2_data_out)
    );

    always_comb begin
        ex_mem_in.valid         = id_ex_out.valid;
        ex_mem_in.alu_result    = ex_alu_result;
        ex_mem_in.rs2_data      = ex_rs2_data_out;
        ex_mem_in.rd_addr       = id_ex_out.rd_addr;
        ex_mem_in.mem_wr_en     = id_ex_out.mem_wr_en;
        ex_mem_in.mem_rd_en     = id_ex_out.mem_rd_en;
        ex_mem_in.mem_funct3    = id_ex_out.mem_funct3;
        ex_mem_in.reg_wr_en     = id_ex_out.reg_wr_en;
        ex_mem_in.is_system     = id_ex_out.is_system;
        ex_mem_in.wb_sel        = id_ex_out.wb_sel;
        ex_mem_in.pc_plus4      = ex_pc_plus4;
        ex_mem_in.branch_taken  = ex_branch_taken;
        ex_mem_in.branch_target = ex_branch_target;
    end

    ex_mem_reg ex_mem_reg_inst (
        .clk   (clk),
        .rst   (rst),
        .flush (1'b0),
        .stall (1'b0),
        .d     (ex_mem_in),
        .q     (ex_mem_out)
    );


    wire ebreak_in_wb = mem_wb_out.valid & mem_wb_out.is_system;

    mem_stage mem_stage_inst (
        .clk         (clk),
        .rst         (rst),
        .cpu_clk_en  (cpu_clk_en),
        .alu_result  (ex_mem_out.alu_result),
        .rs2_data    (ex_mem_out.rs2_data),
        .mem_wr_en   (ex_mem_out.mem_wr_en & ~ebreak_in_wb),
        .mem_rd_en   (ex_mem_out.mem_rd_en),
        .mem_funct3     (ex_mem_out.mem_funct3),
        .mem_rd_data    (mem_rd_data),
        .arm_clk        (arm_clk),
        .arm_dmem_wr_addr (arm_dmem_wr_addr),
        .arm_dmem_rd_addr (arm_dmem_rd_addr),
        .arm_dmem_wdata (arm_dmem_wdata),
        .arm_dmem_we    (arm_dmem_we),
        .arm_dmem_rdata (arm_dmem_rdata)
    );

    always_comb begin
        mem_wb_in.valid       = ex_mem_out.valid;
        mem_wb_in.alu_result  = ex_mem_out.alu_result;
        mem_wb_in.mem_rd_data = mem_rd_data;
        mem_wb_in.rd_addr     = ex_mem_out.rd_addr;
        mem_wb_in.reg_wr_en   = ex_mem_out.reg_wr_en;
        mem_wb_in.is_system   = ex_mem_out.is_system;
        mem_wb_in.wb_sel      = ex_mem_out.wb_sel;
        mem_wb_in.pc_plus4    = ex_mem_out.pc_plus4;
    end

    mem_wb_reg mem_wb_reg_inst (
        .clk   (clk),
        .rst   (rst),
        .flush (1'b0),
        .stall (1'b0),
        .d     (mem_wb_in),
        .q     (mem_wb_out)
    );

    wb_stage wb_stage_inst (
        .alu_result    (mem_wb_out.alu_result),
        .mem_rd_data   (mem_wb_out.mem_rd_data),
        .pc_plus4      (mem_wb_out.pc_plus4),
        .wb_sel        (mem_wb_out.wb_sel),
        .reg_wr_en     (mem_wb_out.reg_wr_en),
        .rd_addr       (mem_wb_out.rd_addr),
        .wb_data       (wb_data),
        .reg_wr_en_out (wb_reg_wr_en_out),
        .rd_addr_out   (wb_rd_addr_out)
    );

    hazard_unit hazard_unit_inst (
        .id_ex_mem_rd_en     (id_ex_out.mem_rd_en),
        .id_ex_rd            (id_ex_out.rd_addr),
        .if_id_rs1           (if_id_out.instr[19:15]),
        .if_id_rs2           (if_id_out.instr[24:20]),
        .if_id_rs1_valid     (id_rs1_valid),
        .if_id_rs2_valid     (id_rs2_valid),
        .id_ex_branch        (id_ex_out.branch),
        .id_ex_jump          (id_ex_out.jump),
        .ex_branch_taken     (ex_branch_taken),
        .btb_hit             (id_ex_out.btb_hit),
        .btb_predicted_taken (id_ex_out.btb_predicted_taken),
        .id_ex_predicted_pc  (id_ex_out.predicted_pc),
        .ex_branch_target    (ex_branch_target),
        .if_id_stall         (if_id_stall),
        .pc_stall            (pc_stall),
        .if_id_flush         (if_id_flush),
        .id_ex_flush         (id_ex_flush),
        .mispredict_hazard   (branch_mispredict)
    );

    branch_predictor branch_predictor_inst (
        .clk             (clk),
        .rst_n           (~rst),
        .if_pc           (if_pc_out),
        .btb_hit_out     (btb_hit),
        .predict_taken   (predicted_taken),
        .predict_target  (predicted_pc),
        .ex_is_branch    (id_ex_out.branch | id_ex_out.jump),
        .ex_branch_taken (ex_branch_taken),
        .ex_branch_pc    (id_ex_out.pc),
        .ex_branch_target(ex_branch_target)
    );


    logic instr_retired;
    assign instr_retired = mem_wb_out.valid;

    perf_counters perf_counters_inst (
        .clk           (clk),
        .rst           (rst),
        .instr_retired (instr_retired),
        .stall_pulse   (pc_stall),
        .branch_pulse  (id_ex_out.branch | id_ex_out.jump),
        .cycle_count   (perf_cycles),
        .instr_count   (perf_instrs),
        .stall_count   (perf_stalls),
        .branch_count  (perf_branches)
    );

    assign debug_pc    = if_id_out.pc;
    assign debug_instr = if_id_out.instr;
    assign ebreak_committed = mem_wb_out.valid & mem_wb_out.is_system;

endmodule
