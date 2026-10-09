`default_nettype wire

module neurocore_top (

    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME sys_clk, ASSOCIATED_BUSIF s_axi, ASSOCIATED_RESET sys_rst_n, FREQ_HZ 50000000" *)
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 sys_clk CLK" *)
    input  wire        sys_clk,
    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME sys_rst_n, POLARITY ACTIVE_LOW" *)
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 sys_rst_n RST" *)
    input  wire        sys_rst_n,


    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi AWADDR" *)  input  wire [31:0] s_axi_awaddr,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi AWPROT" *)  input  wire [2:0]  s_axi_awprot,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi AWVALID" *) input  wire        s_axi_awvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi AWREADY" *) output logic       s_axi_awready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi WDATA" *)   input  wire [31:0] s_axi_wdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi WSTRB" *)   input  wire [3:0]  s_axi_wstrb,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi WVALID" *)  input  wire        s_axi_wvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi WREADY" *)  output logic       s_axi_wready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi BRESP" *)   output logic [1:0] s_axi_bresp,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi BVALID" *)  output logic       s_axi_bvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi BREADY" *)  input  wire        s_axi_bready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi ARADDR" *)  input  wire [31:0] s_axi_araddr,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi ARPROT" *)  input  wire [2:0]  s_axi_arprot,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi ARVALID" *) input  wire        s_axi_arvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi ARREADY" *) output logic       s_axi_arready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi RDATA" *)   output logic [31:0] s_axi_rdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi RRESP" *)   output logic [1:0] s_axi_rresp,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi RVALID" *)  output logic       s_axi_rvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi RREADY" *)  input  wire        s_axi_rready,


    output logic [3:0] led,
    output logic [2:0] rgb_led0,
    input  wire  [1:0] btn
);


    logic btn0_debounced, btn1_debounced;
    logic btn0_d, btn1_d;
    logic btn_toggle_pulse, btn_rst_pulse;


    debouncer #(.COUNT_MAX(250_000)) u_deb_btn0 (
        .clk     (sys_clk),
        .rst_n   (sys_rst_n),
        .btn_in  (btn[0]),
        .btn_out (btn0_debounced)
    );

    debouncer #(.COUNT_MAX(250_000)) u_deb_btn1 (
        .clk     (sys_clk),
        .rst_n   (sys_rst_n),
        .btn_in  (btn[1]),
        .btn_out (btn1_debounced)
    );

    always_ff @(posedge sys_clk) begin
        if (!sys_rst_n) begin
            btn0_d           <= 1'b0;
            btn1_d           <= 1'b0;
            btn_toggle_pulse <= 1'b0;
            btn_rst_pulse    <= 1'b0;
        end else begin
            btn0_d           <= btn0_debounced;
            btn1_d           <= btn1_debounced;
            btn_toggle_pulse <= btn0_debounced && !btn0_d;
            btn_rst_pulse    <= btn1_debounced && !btn1_d;
        end
    end


    logic        cpu_clk_en;
    logic        cpu_rst;
    logic        cpu_running;
    logic        ebreak_latched;

    logic [31:0] arm_imem_addr;
    logic [31:0] arm_imem_wdata;
    logic        arm_imem_we;
    logic [31:0] arm_dmem_wr_addr;
    logic [31:0] arm_dmem_rd_addr;
    logic [31:0] arm_dmem_wdata;
    logic [3:0]  arm_dmem_we;
    logic [31:0] arm_dmem_rdata;

    logic [31:0] debug_pc;
    logic [31:0] debug_instr;
    logic [31:0] perf_cycles;
    logic [31:0] perf_instrs;
    logic [31:0] perf_stalls;
    logic [31:0] perf_branches;
    logic        ebreak_committed;


    neurocore_axi_wrapper u_axi_wrapper (
        .aclk                 (sys_clk),
        .aresetn              (sys_rst_n),

        .s_axi_awaddr         (s_axi_awaddr),
        .s_axi_awprot         (s_axi_awprot),
        .s_axi_awvalid        (s_axi_awvalid),
        .s_axi_awready        (s_axi_awready),
        .s_axi_wdata          (s_axi_wdata),
        .s_axi_wstrb          (s_axi_wstrb),
        .s_axi_wvalid         (s_axi_wvalid),
        .s_axi_wready         (s_axi_wready),
        .s_axi_bresp          (s_axi_bresp),
        .s_axi_bvalid         (s_axi_bvalid),
        .s_axi_bready         (s_axi_bready),
        .s_axi_araddr         (s_axi_araddr),
        .s_axi_arprot         (s_axi_arprot),
        .s_axi_arvalid        (s_axi_arvalid),
        .s_axi_arready        (s_axi_arready),
        .s_axi_rdata          (s_axi_rdata),
        .s_axi_rresp          (s_axi_rresp),
        .s_axi_rvalid         (s_axi_rvalid),
        .s_axi_rready         (s_axi_rready),

        .cpu_clk_en           (cpu_clk_en),
        .cpu_rst              (cpu_rst),
        .cpu_running          (cpu_running),
        .ebreak_latched       (ebreak_latched),

        .arm_imem_addr        (arm_imem_addr),
        .arm_imem_wdata       (arm_imem_wdata),
        .arm_imem_we          (arm_imem_we),
        .arm_dmem_wr_addr     (arm_dmem_wr_addr),
        .arm_dmem_rd_addr     (arm_dmem_rd_addr),
        .arm_dmem_wdata       (arm_dmem_wdata),
        .arm_dmem_we          (arm_dmem_we),
        .arm_dmem_rdata       (arm_dmem_rdata),

        .debug_pc             (debug_pc),
        .debug_instr          (debug_instr),
        .perf_cycles          (perf_cycles),
        .perf_instrs          (perf_instrs),
        .perf_stalls          (perf_stalls),
        .perf_branches        (perf_branches),
        .ebreak_committed     (ebreak_committed),

        .btn_toggle_pulse     (btn_toggle_pulse),
        .btn_rst_pulse        (btn_rst_pulse)
    );


    wire cpu_clk;
`ifdef SYNTHESIS
    BUFGCE u_cpu_clk_buf (
        .I  (sys_clk),
        .CE (cpu_clk_en),
        .O  (cpu_clk)
    );
`else
    assign cpu_clk = sys_clk & cpu_clk_en;
`endif


    riscv_core u_riscv_core (
        .clk                  (cpu_clk),
        .rst                  (cpu_rst),
        .cpu_clk_en           (cpu_clk_en),
        .arm_clk              (sys_clk),

        .arm_imem_addr        (arm_imem_addr),
        .arm_imem_wdata       (arm_imem_wdata),
        .arm_imem_we          (arm_imem_we),
        .arm_dmem_wr_addr     (arm_dmem_wr_addr),
        .arm_dmem_rd_addr     (arm_dmem_rd_addr),
        .arm_dmem_wdata       (arm_dmem_wdata),
        .arm_dmem_we          (arm_dmem_we),
        .arm_dmem_rdata       (arm_dmem_rdata),

        .debug_pc             (debug_pc),
        .debug_instr          (debug_instr),
        .perf_cycles          (perf_cycles),
        .perf_instrs          (perf_instrs),
        .perf_stalls          (perf_stalls),
        .perf_branches        (perf_branches),
        .ebreak_committed     (ebreak_committed)
    );


    assign led[0] = cpu_running;
    assign led[1] = perf_instrs[17];
    assign led[2] = perf_stalls[17];
    assign led[3] = ebreak_latched;


    assign rgb_led0[2] = 1'b0;
    assign rgb_led0[1] = cpu_running;
    assign rgb_led0[0] = !cpu_running || ebreak_latched;

endmodule
