`default_nettype none


module aes_top (

    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME sys_clk, ASSOCIATED_BUSIF s_axi, ASSOCIATED_RESET sys_rst_n, FREQ_HZ 100000000" *)
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


    output logic [3:0] led
);


    wire          ctrl_start_encrypt, ctrl_start_decrypt, ctrl_load_key;
    wire  [255:0] key_to_core;
    wire  [127:0] block_to_core, block_from_core;
    wire          core_busy, core_done, core_key_loaded;
    wire  [1919:0] round_keys_bus;
    logic [31:0]  total_blocks;

    aes_axi_wrapper u_axi_wrapper (
        .aclk               (sys_clk),
        .aresetn            (sys_rst_n),
        .s_axi_awaddr       (s_axi_awaddr),
        .s_axi_awprot       (s_axi_awprot),
        .s_axi_awvalid      (s_axi_awvalid),
        .s_axi_awready      (s_axi_awready),
        .s_axi_wdata        (s_axi_wdata),
        .s_axi_wstrb        (s_axi_wstrb),
        .s_axi_wvalid       (s_axi_wvalid),
        .s_axi_wready       (s_axi_wready),
        .s_axi_bresp        (s_axi_bresp),
        .s_axi_bvalid       (s_axi_bvalid),
        .s_axi_bready       (s_axi_bready),
        .s_axi_araddr       (s_axi_araddr),
        .s_axi_arprot       (s_axi_arprot),
        .s_axi_arvalid      (s_axi_arvalid),
        .s_axi_arready      (s_axi_arready),
        .s_axi_rdata        (s_axi_rdata),
        .s_axi_rresp        (s_axi_rresp),
        .s_axi_rvalid       (s_axi_rvalid),
        .s_axi_rready       (s_axi_rready),
        .ctrl_start_encrypt (ctrl_start_encrypt),
        .ctrl_start_decrypt (ctrl_start_decrypt),
        .ctrl_load_key      (ctrl_load_key),
        .key_to_core        (key_to_core),
        .block_to_core      (block_to_core),
        .block_from_core    (block_from_core),
        .core_busy          (core_busy),
        .core_done          (core_done),
        .core_key_loaded    (core_key_loaded),
        .stat_total_blocks  (total_blocks)
    );


    aes_key_expansion u_key_expansion (
        .clk            (sys_clk),
        .rst_n          (sys_rst_n),
        .load_key       (ctrl_load_key),
        .cipher_key     (key_to_core),
        .key_ready      (core_key_loaded),
        .round_keys_bus (round_keys_bus)
    );


    wire cipher_start = (ctrl_start_encrypt | ctrl_start_decrypt) & core_key_loaded;

    aes_cipher u_cipher (
        .clk            (sys_clk),
        .rst_n          (sys_rst_n),
        .is_decrypt     (ctrl_start_decrypt),
        .valid_in       (cipher_start),
        .data_in        (block_to_core),
        .round_keys_bus (round_keys_bus),
        .valid_out      (core_done),
        .data_out       (block_from_core),
        .busy           (core_busy),
        .done           ()
    );


    logic [22:0] busy_stretch, done_stretch;

    always_ff @(posedge sys_clk) begin
        if (!sys_rst_n) begin
            total_blocks <= 32'd0;
            busy_stretch <= 23'd0;
            done_stretch <= 23'd0;
        end else begin
            if (core_done) begin
                total_blocks <= total_blocks + 32'd1;
                done_stretch <= '1;
            end else if (done_stretch != 23'd0) begin
                done_stretch <= done_stretch - 23'd1;
            end

            if (core_busy) begin
                busy_stretch <= '1;
            end else if (busy_stretch != 23'd0) begin
                busy_stretch <= busy_stretch - 23'd1;
            end
        end
    end

    assign led[0] = core_key_loaded;
    assign led[1] = (busy_stretch != 23'd0);
    assign led[2] = (done_stretch != 23'd0);
    assign led[3] = (total_blocks != 32'd0);

endmodule
