`default_nettype none


module trng_axi_wrapper (
    input  wire         aclk,
    input  wire         aresetn,


    input  wire [31:0]  s_axi_awaddr,
    input  wire [2:0]   s_axi_awprot,
    input  wire         s_axi_awvalid,
    output logic        s_axi_awready,
    input  wire [31:0]  s_axi_wdata,
    input  wire [3:0]   s_axi_wstrb,
    input  wire         s_axi_wvalid,
    output logic        s_axi_wready,
    output logic [1:0]  s_axi_bresp,
    output logic        s_axi_bvalid,
    input  wire         s_axi_bready,
    input  wire [31:0]  s_axi_araddr,
    input  wire [2:0]   s_axi_arprot,
    input  wire         s_axi_arvalid,
    output logic        s_axi_arready,
    output logic [31:0] s_axi_rdata,
    output logic [1:0]  s_axi_rresp,
    output logic        s_axi_rvalid,
    input  wire         s_axi_rready,


    output logic        ctrl_enable,
    output logic [3:0]  ctrl_window_log2,
    input  wire  [31:0] fifo_word_count,
    input  wire         fifo_empty,
    input  wire         fifo_full,
    output wire         fifo_read_en,
    input  wire  [31:0] fifo_data
);


    logic [31:0] wr_addr, wr_data;
    logic        aw_taken, w_taken;

    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            aw_taken      <= 1'b0;
            w_taken       <= 1'b0;
            wr_addr       <= 32'b0;
            wr_data       <= 32'b0;
        end else begin
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;

            if (s_axi_awvalid && !aw_taken) begin
                s_axi_awready <= 1'b1;
                aw_taken      <= 1'b1;
                wr_addr       <= s_axi_awaddr;
            end
            if (s_axi_wvalid && !w_taken) begin
                s_axi_wready <= 1'b1;
                w_taken      <= 1'b1;
                wr_data      <= s_axi_wdata;
            end
            if (s_axi_bvalid && s_axi_bready) begin
                aw_taken <= 1'b0;
                w_taken  <= 1'b0;
            end
        end
    end


    wire do_write = aw_taken && w_taken && !s_axi_bvalid;

    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            s_axi_bvalid     <= 1'b0;
            s_axi_bresp      <= 2'b00;
            ctrl_enable      <= 1'b0;
            ctrl_window_log2 <= 4'd6;
        end else if (do_write) begin
            s_axi_bvalid <= 1'b1;
            s_axi_bresp  <= 2'b00;
            case (wr_addr[7:0])
                8'h00: ctrl_enable      <= wr_data[0];
                8'h0C: ctrl_window_log2 <= wr_data[3:0];
                default: ;
            endcase
        end else if (s_axi_bvalid && s_axi_bready) begin
            s_axi_bvalid <= 1'b0;
        end
    end


    assign s_axi_arready = aresetn && !s_axi_rvalid;
    wire   ar_accepted   = s_axi_arvalid && s_axi_arready;


    assign fifo_read_en = ar_accepted && (s_axi_araddr[7:0] == 8'h08) && !fifo_empty;

    logic [31:0] read_data;
    always_comb begin
        case (s_axi_araddr[7:0])
            8'h00:   read_data = {31'b0, ctrl_enable};
            8'h04:   read_data = {fifo_word_count[15:0], 14'b0, fifo_full, fifo_empty};
            8'h08:   read_data = fifo_empty ? 32'b0 : fifo_data;
            8'h0C:   read_data = {28'b0, ctrl_window_log2};
            default: read_data = 32'b0;
        endcase
    end

    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            s_axi_rvalid <= 1'b0;
            s_axi_rresp  <= 2'b00;
            s_axi_rdata  <= 32'b0;
        end else if (ar_accepted) begin
            s_axi_rvalid <= 1'b1;
            s_axi_rresp  <= 2'b00;
            s_axi_rdata  <= read_data;
        end else if (s_axi_rvalid && s_axi_rready) begin
            s_axi_rvalid <= 1'b0;
        end
    end

endmodule
