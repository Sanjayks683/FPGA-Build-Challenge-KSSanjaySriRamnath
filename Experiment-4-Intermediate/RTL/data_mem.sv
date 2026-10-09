`default_nettype wire

module data_mem import riscv_pkg::*; (
    input  wire         clk,
    input  wire         rst,
    input  wire         cpu_clk_en,

    input  wire  [31:0] addr,
    input  wire  [31:0] wdata,
    input  wire  [3:0]  we,
    output logic [31:0] rdata,

    input  wire         arm_clk,
    input  wire  [31:0] arm_wr_addr,
    input  wire  [31:0] arm_rd_addr,
    input  wire  [31:0] arm_wdata,
    input  wire  [3:0]  arm_we,
    output logic [31:0] arm_rdata
);

    (* ram_style = "distributed" *)
    logic [7:0] mem0 [0:DMEM_DEPTH-1];
    (* ram_style = "distributed" *)
    logic [7:0] mem1 [0:DMEM_DEPTH-1];
    (* ram_style = "distributed" *)
    logic [7:0] mem2 [0:DMEM_DEPTH-1];
    (* ram_style = "distributed" *)
    logic [7:0] mem3 [0:DMEM_DEPTH-1];


    wire cpu_active_write = cpu_clk_en && !rst && (we != 4'b0000);
    wire [9:0]  wr_addr = cpu_active_write ? addr[11:2] : arm_wr_addr[11:2];
    wire [31:0] wr_data = cpu_active_write ? wdata       : arm_wdata;
    wire [3:0]  wr_en   = cpu_active_write ? we          : arm_we;

    always_ff @(posedge arm_clk) begin
        if (wr_en[0]) mem0[wr_addr] <= wr_data[7:0];
        if (wr_en[1]) mem1[wr_addr] <= wr_data[15:8];
        if (wr_en[2]) mem2[wr_addr] <= wr_data[23:16];
        if (wr_en[3]) mem3[wr_addr] <= wr_data[31:24];
    end


    assign rdata     = {mem3[addr[11:2]],     mem2[addr[11:2]],     mem1[addr[11:2]],     mem0[addr[11:2]]};
    assign arm_rdata = {mem3[arm_rd_addr[11:2]], mem2[arm_rd_addr[11:2]], mem1[arm_rd_addr[11:2]], mem0[arm_rd_addr[11:2]]};

    initial begin
        for (int i = 0; i < DMEM_DEPTH; i++) begin
            mem0[i] = 8'd0;
            mem1[i] = 8'd0;
            mem2[i] = 8'd0;
            mem3[i] = 8'd0;
        end
    end

endmodule
