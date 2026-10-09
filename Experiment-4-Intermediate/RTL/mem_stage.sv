`default_nettype wire

module mem_stage import riscv_pkg::*; (
    input  wire         clk, rst,
    input  wire         cpu_clk_en,
    input  wire  [31:0] alu_result,
    input  wire  [31:0] rs2_data,
    input  wire         mem_wr_en, mem_rd_en,
    input  wire  [2:0]  mem_funct3,
    output logic [31:0] mem_rd_data,

    input  wire         arm_clk,
    input  wire  [31:0] arm_dmem_wr_addr,
    input  wire  [31:0] arm_dmem_rd_addr,
    input  wire  [31:0] arm_dmem_wdata,
    input  wire  [3:0]  arm_dmem_we,
    output logic [31:0] arm_dmem_rdata
);

    logic [3:0]  be;
    logic [31:0] store_data;
    logic [31:0] mem_q;

    always_comb begin
        be = 4'b0000;
        if (mem_wr_en) begin
            case (mem_funct3)
                F3_LB:   be = 4'b0001 << alu_result[1:0];
                F3_LH:   be = alu_result[1] ? 4'b1100 : 4'b0011;
                F3_LW:   be = 4'b1111;
                default: be = 4'b0000;
            endcase
        end
    end

    always_comb begin
        case (mem_funct3)
            F3_LB:   store_data = {4{rs2_data[7:0]}};
            F3_LH:   store_data = {2{rs2_data[15:0]}};
            F3_LW:   store_data = rs2_data;
            default: store_data = rs2_data;
        endcase
    end

    data_mem u_data_mem (
        .clk       (clk),
        .rst       (rst),
        .cpu_clk_en(cpu_clk_en),
        .addr      (alu_result),
        .wdata     (store_data),
        .we        (be),
        .rdata     (mem_q),
        .arm_clk   (arm_clk),
        .arm_wr_addr(arm_dmem_wr_addr),
        .arm_rd_addr(arm_dmem_rd_addr),
        .arm_wdata (arm_dmem_wdata),
        .arm_we    (arm_dmem_we),
        .arm_rdata (arm_dmem_rdata)
    );

    logic [7:0]  mem_byte;
    logic [15:0] mem_half;

    always_comb begin
        case (alu_result[1:0])
            2'b00: mem_byte = mem_q[7:0];
            2'b01: mem_byte = mem_q[15:8];
            2'b10: mem_byte = mem_q[23:16];
            2'b11: mem_byte = mem_q[31:24];
        endcase

        case (alu_result[1])
            1'b0: mem_half = mem_q[15:0];
            1'b1: mem_half = mem_q[31:16];
        endcase

        case (mem_funct3)
            F3_LB:  mem_rd_data = {{24{mem_byte[7]}}, mem_byte};
            F3_LH:  mem_rd_data = {{16{mem_half[15]}}, mem_half};
            F3_LW:  mem_rd_data = mem_q;
            F3_LBU: mem_rd_data = {24'd0, mem_byte};
            F3_LHU: mem_rd_data = {16'd0, mem_half};
            default: mem_rd_data = mem_q;
        endcase
    end

endmodule
