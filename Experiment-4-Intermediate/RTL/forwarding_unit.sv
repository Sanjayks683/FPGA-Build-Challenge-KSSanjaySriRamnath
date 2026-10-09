`default_nettype wire

module forwarding_unit (
    input  logic [4:0]  id_ex_rs1, id_ex_rs2,
    input  logic        ex_mem_reg_wr_en,
    input  logic [4:0]  ex_mem_rd,
    input  logic        mem_wb_reg_wr_en,
    input  logic [4:0]  mem_wb_rd,
    output logic [1:0]  fwd_a_sel, fwd_b_sel
);

    always_comb begin
        if (ex_mem_reg_wr_en && ex_mem_rd != 5'b0 && ex_mem_rd == id_ex_rs1) begin
            fwd_a_sel = 2'b10;
        end else if (mem_wb_reg_wr_en && mem_wb_rd != 5'b0 && mem_wb_rd == id_ex_rs1 &&
                     !(ex_mem_reg_wr_en && ex_mem_rd == id_ex_rs1)) begin
            fwd_a_sel = 2'b01;
        end else begin
            fwd_a_sel = 2'b00;
        end
    end

    always_comb begin
        if (ex_mem_reg_wr_en && ex_mem_rd != 5'b0 && ex_mem_rd == id_ex_rs2) begin
            fwd_b_sel = 2'b10;
        end else if (mem_wb_reg_wr_en && mem_wb_rd != 5'b0 && mem_wb_rd == id_ex_rs2 &&
                     !(ex_mem_reg_wr_en && ex_mem_rd == id_ex_rs2)) begin
            fwd_b_sel = 2'b01;
        end else begin
            fwd_b_sel = 2'b00;
        end
    end

endmodule
