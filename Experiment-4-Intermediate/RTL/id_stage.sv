`default_nettype wire

module id_stage import riscv_pkg::*; (
    input  logic        clk, rst,
    input  logic [31:0] instr, pc,
    input  logic        reg_wr_en,
    input  logic [4:0]  reg_wr_addr,
    input  logic [31:0] reg_wr_data,
    output logic [4:0]  rs1_addr, rs2_addr, rd_addr,
    output logic        rs1_valid, rs2_valid,
    output logic [31:0] rs1_data, rs2_data,
    output logic [31:0] imm_ext,
    output logic [3:0]  alu_op,
    output logic        alu_src, mem_wr_en, mem_rd_en,
    output logic [2:0]  mem_funct3,
    output logic        reg_wr_en_out,
    output logic [1:0]  wb_sel,
    output logic        branch, jump, is_jalr,
    output logic [6:0]  opcode, funct7,
    output logic [2:0]  funct3
);

    logic [6:0] raw_opcode;
    assign raw_opcode = instr[6:0];
    assign opcode     = raw_opcode;
    assign rd_addr    = instr[11:7];
    assign funct3     = instr[14:12];
    assign funct7     = instr[31:25];
    assign mem_funct3 = funct3;

    logic is_rtype, is_itype, is_stype, is_btype, is_utype, is_jtype, is_jalr_type;
    assign is_rtype     = (raw_opcode == OPC_OP);
    assign is_itype     = (raw_opcode == OPC_OP_IMM) || (raw_opcode == OPC_LOAD);
    assign is_jalr_type = (raw_opcode == OPC_JALR);
    assign is_stype     = (raw_opcode == OPC_STORE);
    assign is_btype     = (raw_opcode == OPC_BRANCH);
    assign is_utype     = (raw_opcode == OPC_LUI) || (raw_opcode == OPC_AUIPC);
    assign is_jtype     = (raw_opcode == OPC_JAL);

    assign rs1_valid = is_rtype | is_itype | is_jalr_type | is_stype | is_btype;
    assign rs2_valid = is_rtype | is_stype | is_btype;

    assign rs1_addr = rs1_valid ? instr[19:15] : 5'd0;
    assign rs2_addr = rs2_valid ? instr[24:20] : 5'd0;

    logic [31:0] reg_file [32];

    always_ff @(posedge clk) begin
        if (reg_wr_en && reg_wr_addr != 5'd0) begin
            reg_file[reg_wr_addr] <= reg_wr_data;
        end
    end

    logic [31:0] rf_rs1_data, rf_rs2_data;
    assign rf_rs1_data = (rs1_addr == 5'd0) ? 32'h0 :
                         (reg_wr_en && reg_wr_addr == rs1_addr) ? reg_wr_data :
                         reg_file[rs1_addr];

    assign rf_rs2_data = (rs2_addr == 5'd0) ? 32'h0 :
                         (reg_wr_en && reg_wr_addr == rs2_addr) ? reg_wr_data :
                         reg_file[rs2_addr];

    assign rs1_data = (opcode == OPC_AUIPC) ? pc : rf_rs1_data;
    assign rs2_data = rf_rs2_data;

    logic [31:0] imm_i, imm_s, imm_b, imm_u, imm_j;

    assign imm_i = {{20{instr[31]}}, instr[31:20]};
    assign imm_s = {{20{instr[31]}}, instr[31:25], instr[11:7]};
    assign imm_b = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
    assign imm_u = {instr[31:12], 12'b0};
    assign imm_j = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};

    always_comb begin
        alu_src       = 1'b0;
        mem_wr_en     = 1'b0;
        mem_rd_en     = 1'b0;
        reg_wr_en_out = 1'b0;
        wb_sel        = WB_ALU;
        branch        = 1'b0;
        jump          = 1'b0;
        is_jalr       = 1'b0;
        imm_ext       = 32'h0;

        case (opcode)
            OPC_OP: begin
                alu_src       = 1'b0;
                reg_wr_en_out = 1'b1;
                wb_sel        = WB_ALU;
            end

            OPC_OP_IMM: begin
                alu_src       = 1'b1;
                reg_wr_en_out = 1'b1;
                wb_sel        = WB_ALU;
                imm_ext       = imm_i;
            end

            OPC_LOAD: begin
                alu_src       = 1'b1;
                mem_rd_en     = 1'b1;
                reg_wr_en_out = 1'b1;
                wb_sel        = WB_MEM;
                imm_ext       = imm_i;
            end

            OPC_STORE: begin
                alu_src       = 1'b1;
                mem_wr_en     = 1'b1;
                imm_ext       = imm_s;
            end

            OPC_BRANCH: begin
                branch        = 1'b1;
                imm_ext       = imm_b;
            end

            OPC_JAL: begin
                jump          = 1'b1;
                reg_wr_en_out = 1'b1;
                wb_sel        = WB_PC4;
                imm_ext       = imm_j;
            end

            OPC_JALR: begin
                jump          = 1'b1;
                is_jalr       = 1'b1;
                alu_src       = 1'b1;
                reg_wr_en_out = 1'b1;
                wb_sel        = WB_PC4;
                imm_ext       = imm_i;
            end

            OPC_LUI: begin
                alu_src       = 1'b1;
                reg_wr_en_out = 1'b1;
                wb_sel        = WB_ALU;
                imm_ext       = imm_u;
            end

            OPC_AUIPC: begin
                alu_src       = 1'b1;
                reg_wr_en_out = 1'b1;
                wb_sel        = WB_ALU;
                imm_ext       = imm_u;
            end

            OPC_SYSTEM: begin

            end

            default: begin

            end
        endcase
    end

    always_comb begin
        alu_op = ALU_ADD;

        case (opcode)
            OPC_OP: begin
                case (funct3)
                    3'b000:  alu_op = (funct7 == SUB_F7) ? ALU_SUB : ALU_ADD;
                    3'b001:  alu_op = ALU_SLL;
                    3'b010:  alu_op = ALU_SLT;
                    3'b011:  alu_op = ALU_SLTU;
                    3'b100:  alu_op = ALU_XOR;
                    3'b101:  alu_op = (funct7[5]) ? ALU_SRA : ALU_SRL;
                    3'b110:  alu_op = ALU_OR;
                    3'b111:  alu_op = ALU_AND;
                    default: alu_op = ALU_ADD;
                endcase
            end

            OPC_OP_IMM: begin
                case (funct3)
                    3'b000:  alu_op = ALU_ADD;
                    3'b001:  alu_op = ALU_SLL;
                    3'b010:  alu_op = ALU_SLT;
                    3'b011:  alu_op = ALU_SLTU;
                    3'b100:  alu_op = ALU_XOR;
                    3'b101:  alu_op = (funct7[5]) ? ALU_SRA : ALU_SRL;
                    3'b110:  alu_op = ALU_OR;
                    3'b111:  alu_op = ALU_AND;
                    default: alu_op = ALU_ADD;
                endcase
            end

            OPC_LUI:   alu_op = ALU_LUI;
            OPC_AUIPC: alu_op = ALU_ADD;
            default:   alu_op = ALU_ADD;
        endcase
    end

endmodule
