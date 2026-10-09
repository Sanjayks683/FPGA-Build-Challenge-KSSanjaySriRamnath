`default_nettype none


module huffman_top (

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


    output logic [3:0] led,
    input  wire  [1:0] sw
);


    wire        ctrl_reset, ctrl_flush;
    wire [7:0]  char_in;
    wire        char_valid;
    wire        encoder_busy, encoder_done, encoder_valid_out;
    wire [31:0] encoder_word;
    wire [4:0]  code_len;
    wire        fifo_read_en;

    logic [31:0] fifo_data;
    logic        fifo_empty, fifo_full;
    logic [15:0] fifo_count;
    logic [31:0] bytes_in, bits_out;


    wire rst_n = sys_rst_n & ~ctrl_reset;

    huffman_axi_wrapper axi_wrapper (
        .aclk           (sys_clk),
        .aresetn        (sys_rst_n),
        .s_axi_awaddr   (s_axi_awaddr),
        .s_axi_awprot   (s_axi_awprot),
        .s_axi_awvalid  (s_axi_awvalid),
        .s_axi_awready  (s_axi_awready),
        .s_axi_wdata    (s_axi_wdata),
        .s_axi_wstrb    (s_axi_wstrb),
        .s_axi_wvalid   (s_axi_wvalid),
        .s_axi_wready   (s_axi_wready),
        .s_axi_bresp    (s_axi_bresp),
        .s_axi_bvalid   (s_axi_bvalid),
        .s_axi_bready   (s_axi_bready),
        .s_axi_araddr   (s_axi_araddr),
        .s_axi_arprot   (s_axi_arprot),
        .s_axi_arvalid  (s_axi_arvalid),
        .s_axi_arready  (s_axi_arready),
        .s_axi_rdata    (s_axi_rdata),
        .s_axi_rresp    (s_axi_rresp),
        .s_axi_rvalid   (s_axi_rvalid),
        .s_axi_rready   (s_axi_rready),
        .ctrl_reset     (ctrl_reset),
        .ctrl_flush     (ctrl_flush),
        .char_out       (char_in),
        .char_valid     (char_valid),
        .status_busy    (encoder_busy),
        .status_done    (encoder_done),
        .fifo_empty     (fifo_empty),
        .fifo_full      (fifo_full),
        .fifo_count     (fifo_count),
        .fifo_read_en   (fifo_read_en),
        .fifo_data      (fifo_data),
        .bytes_in       (bytes_in),
        .bits_out       (bits_out)
    );

    huffman_encoder encoder (
        .clk                  (sys_clk),
        .rst_n                (rst_n),
        .mode_passthrough     (sw[0]),
        .char_in              (char_in),
        .valid_in             (char_valid),
        .flush                (ctrl_flush),
        .busy                 (encoder_busy),
        .word_out             (encoder_word),
        .valid_out            (encoder_valid_out),
        .done                 (encoder_done),
        .current_code_len_out (code_len)
    );


    logic char_valid_d;

    always_ff @(posedge sys_clk) begin
        if (!rst_n) begin
            char_valid_d <= 1'b0;
            bytes_in     <= 32'd0;
            bits_out     <= 32'd0;
        end else begin
            char_valid_d <= char_valid;
            if (char_valid)   bytes_in <= bytes_in + 32'd1;
            if (char_valid_d) bits_out <= bits_out + code_len;
        end
    end


    (* ram_style = "distributed" *)
    logic [31:0] fifo_mem [0:255];
    logic [7:0]  wr_ptr, rd_ptr;
    wire         fifo_write = encoder_valid_out && !fifo_full;

    always_ff @(posedge sys_clk) begin
        if (!rst_n) begin
            wr_ptr     <= 8'd0;
            rd_ptr     <= 8'd0;
            fifo_count <= 16'd0;
        end else begin
            if (fifo_write) begin
                fifo_mem[wr_ptr] <= encoder_word;
                wr_ptr <= wr_ptr + 8'd1;
            end
            if (fifo_read_en) begin
                rd_ptr <= rd_ptr + 8'd1;
            end
            case ({fifo_write, fifo_read_en})
                2'b10:   fifo_count <= fifo_count + 16'd1;
                2'b01:   fifo_count <= fifo_count - 16'd1;
                default: ;
            endcase
        end
    end

    assign fifo_data  = fifo_mem[rd_ptr];
    assign fifo_empty = (fifo_count == 16'd0);
    assign fifo_full  = (fifo_count == 16'd256);


    logic blink_in, blink_out;

    always_ff @(posedge sys_clk) begin
        if (!rst_n) begin
            blink_in  <= 1'b0;
            blink_out <= 1'b0;
        end else begin
            if (char_valid)        blink_in  <= ~blink_in;
            if (encoder_valid_out) blink_out <= ~blink_out;
        end
    end

    assign led[0] = encoder_busy;
    assign led[1] = blink_in;
    assign led[2] = blink_out;
    assign led[3] = ~fifo_empty;

endmodule
