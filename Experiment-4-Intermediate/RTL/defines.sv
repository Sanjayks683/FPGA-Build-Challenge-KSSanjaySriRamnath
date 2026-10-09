package riscv_pkg;

    localparam XLEN = 32;
    localparam REG_ADDR_WIDTH = 5;
    localparam IMEM_DEPTH = 1024;
    localparam DMEM_DEPTH = 1024;
    localparam BTB_ENTRIES = 16;
    localparam logic [31:0] PC_RESET = 32'h0000_0000;

    localparam logic [31:0] NOP_INSTR = 32'h0000_0013;

    localparam logic [6:0] OPC_LOAD   = 7'h03;
    localparam logic [6:0] OPC_STORE  = 7'h23;
    localparam logic [6:0] OPC_BRANCH = 7'h63;
    localparam logic [6:0] OPC_JAL    = 7'h6F;
    localparam logic [6:0] OPC_JALR   = 7'h67;
    localparam logic [6:0] OPC_LUI    = 7'h37;
    localparam logic [6:0] OPC_AUIPC  = 7'h17;
    localparam logic [6:0] OPC_OP     = 7'h33;
    localparam logic [6:0] OPC_OP_IMM = 7'h13;
    localparam logic [6:0] OPC_SYSTEM = 7'h73;

    localparam logic [2:0] F3_BEQ  = 3'h0;
    localparam logic [2:0] F3_BNE  = 3'h1;
    localparam logic [2:0] F3_BLT  = 3'h4;
    localparam logic [2:0] F3_BGE  = 3'h5;
    localparam logic [2:0] F3_BLTU = 3'h6;
    localparam logic [2:0] F3_BGEU = 3'h7;

    localparam logic [2:0] F3_LB  = 3'h0;
    localparam logic [2:0] F3_LH  = 3'h1;
    localparam logic [2:0] F3_LW  = 3'h2;
    localparam logic [2:0] F3_LBU = 3'h4;
    localparam logic [2:0] F3_LHU = 3'h5;

    localparam logic [6:0] ADD_F7 = 7'h00;
    localparam logic [6:0] SUB_F7 = 7'h20;

    localparam logic [3:0] ALU_ADD    = 4'd0;
    localparam logic [3:0] ALU_SUB    = 4'd1;
    localparam logic [3:0] ALU_AND    = 4'd2;
    localparam logic [3:0] ALU_OR     = 4'd3;
    localparam logic [3:0] ALU_XOR    = 4'd4;
    localparam logic [3:0] ALU_SLL    = 4'd5;
    localparam logic [3:0] ALU_SRL    = 4'd6;
    localparam logic [3:0] ALU_SRA    = 4'd7;
    localparam logic [3:0] ALU_SLT    = 4'd8;
    localparam logic [3:0] ALU_SLTU   = 4'd9;
    localparam logic [3:0] ALU_LUI    = 4'd10;
    localparam logic [3:0] ALU_PASS_B = 4'd11;

    localparam logic [1:0] WB_ALU = 2'b00;
    localparam logic [1:0] WB_MEM = 2'b01;
    localparam logic [1:0] WB_PC4 = 2'b10;

    typedef struct packed {
        logic [31:0] pc;
        logic [31:0] instr;
        logic [31:0] pc_plus4;
        logic [31:0] predicted_pc;
        logic        btb_hit;
        logic        btb_predicted_taken;
    } if_id_t;

    typedef struct packed {
        logic        valid;
        logic [31:0] pc;
        logic [31:0] rs1_data;
        logic [31:0] rs2_data;
        logic [31:0] imm_ext;
        logic [4:0]  rs1_addr;
        logic [4:0]  rs2_addr;
        logic [4:0]  rd_addr;
        logic [3:0]  alu_op;
        logic        alu_src;
        logic        mem_wr_en;
        logic        mem_rd_en;
        logic [2:0]  mem_funct3;
        logic        reg_wr_en;
        logic [1:0]  wb_sel;
        logic        branch;
        logic        jump;
        logic        is_jalr;
        logic        is_system;
        logic [2:0]  funct3;
        logic [31:0] pc_plus4;
        logic [31:0] predicted_pc;
        logic        btb_hit;
        logic        btb_predicted_taken;
    } id_ex_t;

    typedef struct packed {
        logic        valid;
        logic [31:0] alu_result;
        logic [31:0] rs2_data;
        logic [4:0]  rd_addr;
        logic        mem_wr_en;
        logic        mem_rd_en;
        logic [2:0]  mem_funct3;
        logic        reg_wr_en;
        logic        is_system;
        logic [1:0]  wb_sel;
        logic [31:0] pc_plus4;
        logic        branch_taken;
        logic [31:0] branch_target;
    } ex_mem_t;

    typedef struct packed {
        logic        valid;
        logic [31:0] alu_result;
        logic [31:0] mem_rd_data;
        logic [4:0]  rd_addr;
        logic        reg_wr_en;
        logic        is_system;
        logic [1:0]  wb_sel;
        logic [31:0] pc_plus4;
    } mem_wb_t;

endpackage
