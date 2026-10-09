`default_nettype wire

module if_id_reg import riscv_pkg::*; (
    input  logic   clk, rst, flush, stall,
    input  if_id_t d,
    output if_id_t q
);
    always_ff @(posedge clk) begin
        if (rst || flush) begin
            q       <= '0;
            q.instr <= 32'h0;
        end else if (!stall) begin
            q <= d;
        end
    end
endmodule

module id_ex_reg import riscv_pkg::*; (
    input  logic   clk, rst, flush, stall,
    input  id_ex_t d,
    output id_ex_t q
);
    always_ff @(posedge clk) begin
        if (rst || flush) begin
            q <= '0;
        end else if (stall) begin
            q <= '0;
        end else begin
            q <= d;
        end
    end
endmodule

module ex_mem_reg import riscv_pkg::*; (
    input  logic    clk, rst, flush, stall,
    input  ex_mem_t d,
    output ex_mem_t q
);
    always_ff @(posedge clk) begin
        if (rst || flush) begin
            q <= '0;
        end else if (!stall) begin
            q <= d;
        end
    end
endmodule

module mem_wb_reg import riscv_pkg::*; (
    input  logic    clk, rst, flush, stall,
    input  mem_wb_t d,
    output mem_wb_t q
);
    always_ff @(posedge clk) begin
        if (rst || flush) begin
            q <= '0;
        end else if (!stall) begin
            q <= d;
        end
    end
endmodule
