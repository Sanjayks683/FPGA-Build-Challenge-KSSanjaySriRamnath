`default_nettype none


module huffman_axi_wrapper (
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


    output logic        ctrl_reset,
    output logic        ctrl_flush,
    output logic [7:0]  char_out,
    output logic        char_valid,
    input  wire         status_busy,
    input  wire         status_done,
    input  wire         fifo_empty,
    input  wire         fifo_full,
    input  wire [15:0]  fifo_count,
    output wire         fifo_read_en,
    input  wire  [31:0] fifo_data,
    input  wire  [31:0] bytes_in,
    input  wire  [31:0] bits_out
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


    logic done_seen;

    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            s_axi_bvalid <= 1'b0;
            s_axi_bresp  <= 2'b00;
            ctrl_reset   <= 1'b0;
            ctrl_flush   <= 1'b0;
            char_out     <= 8'b0;
            char_valid   <= 1'b0;
            done_seen    <= 1'b0;
        end else begin

            ctrl_reset <= 1'b0;
            ctrl_flush <= 1'b0;
            char_valid <= 1'b0;

            if (status_done) begin
                done_seen <= 1'b1;
            end

            if (do_write) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00;
                case (wr_addr[7:0])
                    8'h00: begin
                        ctrl_reset <= wr_data[0];
                        ctrl_flush <= wr_data[1];
                        done_seen  <= 1'b0;
                    end
                    8'h08: begin
                        char_out   <= wr_data[7:0];
                        char_valid <= 1'b1;
                    end
                    default: ;
                endcase
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end


    assign s_axi_arready = aresetn && !s_axi_rvalid;
    wire   ar_accepted   = s_axi_arvalid && s_axi_arready;


    assign fifo_read_en = ar_accepted && (s_axi_araddr[7:0] == 8'h0C) && !fifo_empty;

    logic [31:0] read_data;
    always_comb begin
        case (s_axi_araddr[7:0])
            8'h00:   read_data = 32'b0;
            8'h04:   read_data = {fifo_count, 12'b0, fifo_full, fifo_empty, done_seen, status_busy};
            8'h0C:   read_data = fifo_empty ? 32'b0 : fifo_data;
            8'h10:   read_data = bytes_in;
            8'h14:   read_data = bits_out;
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
