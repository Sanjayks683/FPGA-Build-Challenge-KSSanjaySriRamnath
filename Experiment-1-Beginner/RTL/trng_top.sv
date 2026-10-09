`default_nettype none


module trng_top (

    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME sys_clk, ASSOCIATED_BUSIF s_axi, ASSOCIATED_RESET sys_rst_n, FREQ_HZ 100000000" *)
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 sys_clk CLK" *)
    input  wire sys_clk,
    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME sys_rst_n, POLARITY ACTIVE_LOW" *)
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 sys_rst_n RST" *)
    input  wire sys_rst_n,


    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi AWADDR" *) input  wire [31:0] s_axi_awaddr,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi AWPROT" *) input  wire [2:0]  s_axi_awprot,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi AWVALID" *) input  wire        s_axi_awvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi AWREADY" *) output wire        s_axi_awready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi WDATA" *) input  wire [31:0] s_axi_wdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi WSTRB" *) input  wire [3:0]  s_axi_wstrb,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi WVALID" *) input  wire        s_axi_wvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi WREADY" *) output wire        s_axi_wready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi BRESP" *) output wire [1:0]  s_axi_bresp,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi BVALID" *) output wire        s_axi_bvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi BREADY" *) input  wire        s_axi_bready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi ARADDR" *) input  wire [31:0] s_axi_araddr,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi ARPROT" *) input  wire [2:0]  s_axi_arprot,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi ARVALID" *) input  wire        s_axi_arvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi ARREADY" *) output wire        s_axi_arready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi RDATA" *) output wire [31:0] s_axi_rdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi RRESP" *) output wire [1:0]  s_axi_rresp,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi RVALID" *) output wire        s_axi_rvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi RREADY" *) input  wire        s_axi_rready,


    input  wire [3:0]  btn,
    output logic [3:0] led,
    output logic [2:0] rgb_led0,
    output logic [2:0] rgb_led1
);


    wire [3:0]  ro_out;
    wire        bit_valid;
    wire        random_bit;
    wire        ctrl_enable;
    wire [3:0]  window_log2;
    wire [31:0] random_word;
    wire        fifo_empty, fifo_full, fifo_read_en;
    wire [31:0] fifo_word_count;
    wire        enable_trng;


    logic btn0_sync1, btn0_sync2;
    always_ff @(posedge sys_clk) begin
        if (!sys_rst_n) begin
            btn0_sync1 <= 1'b0;
            btn0_sync2 <= 1'b0;
        end else begin
            btn0_sync1 <= btn[0];
            btn0_sync2 <= btn0_sync1;
        end
    end
    assign enable_trng = ctrl_enable | btn0_sync2;

    ring_oscillator ro_inst (
        .ena    (enable_trng),
        .ro_out (ro_out)
    );

    trng_sampler sampler_inst (
        .clk         (sys_clk),
        .rst_n       (sys_rst_n),
        .ro_in       (ro_out),
        .window_log2 (window_log2),
        .valid       (bit_valid),
        .random_bit  (random_bit)
    );

    trng_collector collector_inst (
        .clk             (sys_clk),
        .rst_n           (sys_rst_n),
        .valid_bit       (bit_valid),
        .random_bit      (random_bit),
        .read_en         (fifo_read_en),
        .random_word     (random_word),
        .fifo_empty      (fifo_empty),
        .fifo_full       (fifo_full),
        .fifo_word_count (fifo_word_count)
    );

    trng_axi_wrapper axi_inst (
        .aclk             (sys_clk),
        .aresetn          (sys_rst_n),
        .s_axi_awaddr     (s_axi_awaddr),
        .s_axi_awprot     (s_axi_awprot),
        .s_axi_awvalid    (s_axi_awvalid),
        .s_axi_awready    (s_axi_awready),
        .s_axi_wdata      (s_axi_wdata),
        .s_axi_wstrb      (s_axi_wstrb),
        .s_axi_wvalid     (s_axi_wvalid),
        .s_axi_wready     (s_axi_wready),
        .s_axi_bresp      (s_axi_bresp),
        .s_axi_bvalid     (s_axi_bvalid),
        .s_axi_bready     (s_axi_bready),
        .s_axi_araddr     (s_axi_araddr),
        .s_axi_arprot     (s_axi_arprot),
        .s_axi_arvalid    (s_axi_arvalid),
        .s_axi_arready    (s_axi_arready),
        .s_axi_rdata      (s_axi_rdata),
        .s_axi_rresp      (s_axi_rresp),
        .s_axi_rvalid     (s_axi_rvalid),
        .s_axi_rready     (s_axi_rready),
        .ctrl_enable      (ctrl_enable),
        .ctrl_window_log2 (window_log2),
        .fifo_word_count  (fifo_word_count),
        .fifo_empty       (fifo_empty),
        .fifo_full        (fifo_full),
        .fifo_read_en     (fifo_read_en),
        .fifo_data        (random_word)
    );


    logic [19:0] blink;
    always_ff @(posedge sys_clk) begin
        if (!sys_rst_n) begin
            blink <= 20'd0;
        end else if (bit_valid) begin
            blink <= blink + 20'd1;
        end
    end

    assign led[0] = blink[19];
    assign led[1] = ~fifo_empty;
    assign led[2] = fifo_full;
    assign led[3] = enable_trng;


    assign rgb_led0 = enable_trng ? 3'b010 : 3'b000;
    assign rgb_led1 = rgb_led0;

endmodule
