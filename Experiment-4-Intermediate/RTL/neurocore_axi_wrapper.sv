`default_nettype wire

module neurocore_axi_wrapper (

    input  wire        aclk,
    input  wire        aresetn,


    input  wire [31:0] s_axi_awaddr,
    input  wire [2:0]  s_axi_awprot,
    input  wire        s_axi_awvalid,
    output logic       s_axi_awready,
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output logic       s_axi_wready,
    output logic [1:0] s_axi_bresp,
    output logic       s_axi_bvalid,
    input  wire        s_axi_bready,
    input  wire [31:0] s_axi_araddr,
    input  wire [2:0]  s_axi_arprot,
    input  wire        s_axi_arvalid,
    output logic       s_axi_arready,
    output logic [31:0] s_axi_rdata,
    output logic [1:0] s_axi_rresp,
    output logic       s_axi_rvalid,
    input  wire        s_axi_rready,


    output logic       cpu_clk_en,
    output logic       cpu_rst,
    output logic       cpu_running,
    output logic       ebreak_latched,


    output logic [31:0] arm_imem_addr,
    output logic [31:0] arm_imem_wdata,
    output logic        arm_imem_we,
    output logic [31:0] arm_dmem_wr_addr,
    output logic [31:0] arm_dmem_rd_addr,
    output logic [31:0] arm_dmem_wdata,
    output logic [3:0]  arm_dmem_we,
    input  wire  [31:0] arm_dmem_rdata,


    input  wire  [31:0] debug_pc,
    input  wire  [31:0] debug_instr,
    input  wire  [31:0] perf_cycles,
    input  wire  [31:0] perf_instrs,
    input  wire  [31:0] perf_stalls,
    input  wire  [31:0] perf_branches,
    input  wire         ebreak_committed,


    input  wire         btn_toggle_pulse,
    input  wire         btn_rst_pulse
);


    logic aw_en;
    logic [31:0] axi_awaddr;
    logic [31:0] axi_araddr;

    wire [15:0] waddr = axi_awaddr[15:0];
    wire [15:0] raddr = axi_araddr[15:0];


    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            aw_en         <= 1'b1;
            axi_awaddr    <= 32'b0;
        end else begin
            if (~s_axi_awready && s_axi_awvalid && s_axi_wvalid && aw_en) begin
                s_axi_awready <= 1'b1;
                s_axi_wready  <= 1'b1;
                aw_en         <= 1'b0;
                axi_awaddr    <= s_axi_awaddr;
            end else begin
                s_axi_awready <= 1'b0;
                s_axi_wready  <= 1'b0;
            end

            if (s_axi_bready && s_axi_bvalid) begin
                aw_en <= 1'b1;
            end
        end
    end


    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            s_axi_bvalid <= 1'b0;
            s_axi_bresp  <= 2'b0;
        end else begin
            if (s_axi_awready && s_axi_awvalid && s_axi_wready && s_axi_wvalid && ~s_axi_bvalid) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b0;
            end else if (s_axi_bready && s_axi_bvalid) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end

    wire slv_reg_wren = s_axi_wready && s_axi_wvalid && s_axi_awready && s_axi_awvalid;


    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            s_axi_arready <= 1'b0;
            axi_araddr    <= 32'b0;
        end else begin
            if (~s_axi_arready && s_axi_arvalid) begin
                s_axi_arready <= 1'b1;
                axi_araddr    <= s_axi_araddr;
            end else begin
                s_axi_arready <= 1'b0;
            end
        end
    end


    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            s_axi_rvalid <= 1'b0;
            s_axi_rresp  <= 2'b0;
        end else begin
            if (s_axi_arready && s_axi_arvalid && ~s_axi_rvalid) begin
                s_axi_rvalid <= 1'b1;
                s_axi_rresp  <= 2'b0;
            end else if (s_axi_rready && s_axi_rvalid) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end


    logic step_pulse;
    logic [4:0] reset_counter;
    wire in_reset = (!aresetn) || btn_rst_pulse || (reset_counter != 5'd0);

    always_ff @(posedge aclk) begin
        if (!aresetn || btn_rst_pulse) begin
            cpu_running    <= 1'b0;
            ebreak_latched <= 1'b0;
            step_pulse     <= 1'b0;
            reset_counter  <= 5'd16;
        end else begin
            step_pulse <= 1'b0;

            if (reset_counter != 5'd0) begin
                reset_counter  <= reset_counter - 1'b1;
                ebreak_latched <= 1'b0;
                cpu_running    <= 1'b0;
            end


            if (btn_toggle_pulse && (reset_counter == 5'd0)) begin
                if (cpu_running) begin
                    cpu_running <= 1'b0;
                end else if (!ebreak_latched) begin
                    cpu_running <= 1'b1;
                end
            end


            if (ebreak_committed && !in_reset && cpu_running) begin
                cpu_running    <= 1'b0;
                ebreak_latched <= 1'b1;
            end


            if (slv_reg_wren && (waddr == 16'h0000)) begin

                if (s_axi_wdata[1]) begin
                    cpu_running    <= 1'b0;
                    ebreak_latched <= 1'b0;
                    reset_counter  <= 5'd16;
                end else begin

                    if (s_axi_wdata[0]) begin
                        cpu_running    <= 1'b1;
                        ebreak_latched <= 1'b0;
                    end else begin
                        cpu_running    <= 1'b0;
                    end


                    if (s_axi_wdata[2] && !cpu_running && !ebreak_latched) begin
                        step_pulse <= 1'b1;
                    end
                end
            end
        end
    end


    assign cpu_rst    = in_reset;
    assign cpu_clk_en = in_reset | ((cpu_running | step_pulse) & !ebreak_latched);


    wire is_imem_write = slv_reg_wren && (waddr[15:12] == 4'h1) && (!cpu_running);
    wire is_dmem_write = slv_reg_wren && (waddr[15:12] == 4'h2) && (!cpu_running);

    assign arm_imem_addr  = {20'h0, axi_awaddr[11:0]};
    assign arm_imem_wdata = s_axi_wdata;
    assign arm_imem_we    = is_imem_write;


    assign arm_dmem_wr_addr = {20'h0, axi_awaddr[11:0]};
    assign arm_dmem_rd_addr = {20'h0, axi_araddr[11:0]};
    assign arm_dmem_wdata = s_axi_wdata;
    assign arm_dmem_we    = is_dmem_write ? s_axi_wstrb : 4'b0000;


    always_comb begin
        if (raddr[15:12] == 4'h2) begin

            s_axi_rdata = arm_dmem_rdata;
        end else begin
            case (raddr[7:0])
                8'h00: s_axi_rdata = {29'h0, step_pulse, in_reset, cpu_running};
                8'h04: s_axi_rdata = {30'h0, ebreak_latched, cpu_running};
                8'h08: s_axi_rdata = debug_pc;
                8'h0C: s_axi_rdata = debug_instr;


                8'h10: s_axi_rdata = perf_cycles;
                8'h14: s_axi_rdata = perf_instrs;
                8'h18: s_axi_rdata = perf_stalls;
                8'h1C: s_axi_rdata = perf_branches;

                default: s_axi_rdata = 32'h0;
            endcase
        end
    end

endmodule
