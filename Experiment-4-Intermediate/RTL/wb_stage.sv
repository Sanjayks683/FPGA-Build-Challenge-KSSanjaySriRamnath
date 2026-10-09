`default_nettype wire

module wb_stage import riscv_pkg::*; (
    input  logic [31:0] alu_result, mem_rd_data, pc_plus4,
    input  logic [1:0]  wb_sel,
    input  logic        reg_wr_en,
    input  logic [4:0]  rd_addr,
    output logic [31:0] wb_data,
    output logic        reg_wr_en_out,
    output logic [4:0]  rd_addr_out
);

    always_comb begin
        if (wb_sel == WB_ALU) begin
            wb_data = alu_result;
        end else if (wb_sel == WB_MEM) begin
            wb_data = mem_rd_data;
        end else if (wb_sel == WB_PC4) begin
            wb_data = pc_plus4;
        end else begin
            wb_data = 32'h0;
        end
    end

    assign reg_wr_en_out = reg_wr_en;
    assign rd_addr_out   = rd_addr;

endmodule
