`default_nettype wire

module instr_mem import riscv_pkg::*; (
    input  wire         clk,

    input  wire  [31:0] addr,
    output logic [31:0] rdata,

    input  wire         arm_clk,
    input  wire  [31:0] arm_addr,
    input  wire  [31:0] arm_wdata,
    input  wire         arm_we
);

    logic [31:0] mem [0:IMEM_DEPTH-1];


    always_ff @(posedge arm_clk) begin
        if (arm_we) begin
            mem[arm_addr[11:2]] <= arm_wdata;
        end
    end


    assign rdata = mem[addr[11:2]];

    initial begin
        for (int i = 0; i < IMEM_DEPTH; i++) begin
            mem[i] = NOP_INSTR;
        end
        // synthesis translate_off
        if ($test$plusargs("LOAD_HEX")) begin
            $readmemh("program.hex", mem);
        end
        // synthesis translate_on
    end

endmodule
