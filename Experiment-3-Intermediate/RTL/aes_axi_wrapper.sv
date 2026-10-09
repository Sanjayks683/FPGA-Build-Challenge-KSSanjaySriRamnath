`default_nettype none


module aes_axi_wrapper (
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


    output logic         ctrl_start_encrypt,
    output logic         ctrl_start_decrypt,
    output logic         ctrl_load_key,
    output wire  [255:0] key_to_core,
    output wire  [127:0] block_to_core,
    input  wire  [127:0] block_from_core,
    input  wire          core_busy,
    input  wire          core_done,
    input  wire          core_key_loaded,
    input  wire  [31:0]  stat_total_blocks
);

    logic [31:0] key_words [0:7];
    logic [31:0] in_words  [0:3];
    logic [31:0] out_words [0:3];
    logic        done_seen;

    assign key_to_core   = {key_words[0], key_words[1], key_words[2], key_words[3],
                            key_words[4], key_words[5], key_words[6], key_words[7]};
    assign block_to_core = {in_words[0], in_words[1], in_words[2], in_words[3]};


    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            done_seen <= 1'b0;
            for (int k = 0; k < 4; k++) out_words[k] <= 32'b0;
        end else if (core_done) begin
            done_seen    <= 1'b1;
            out_words[0] <= block_from_core[127:96];
            out_words[1] <= block_from_core[95:64];
            out_words[2] <= block_from_core[63:32];
            out_words[3] <= block_from_core[31:0];
        end else if (ctrl_start_encrypt || ctrl_start_decrypt) begin
            done_seen <= 1'b0;
        end
    end


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
            s_axi_bvalid       <= 1'b0;
            s_axi_bresp        <= 2'b00;
            ctrl_start_encrypt <= 1'b0;
            ctrl_start_decrypt <= 1'b0;
            ctrl_load_key      <= 1'b0;
            for (int k = 0; k < 8; k++) key_words[k] <= 32'b0;
            for (int k = 0; k < 4; k++) in_words[k]  <= 32'b0;
        end else begin

            ctrl_start_encrypt <= 1'b0;
            ctrl_start_decrypt <= 1'b0;
            ctrl_load_key      <= 1'b0;

            if (do_write) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00;
                case (wr_addr[7:0])
                    8'h00: begin
                        ctrl_start_encrypt <= wr_data[0];
                        ctrl_start_decrypt <= wr_data[1];
                        ctrl_load_key      <= wr_data[2];
                    end
                    8'h20: in_words[0]  <= wr_data;
                    8'h24: in_words[1]  <= wr_data;
                    8'h28: in_words[2]  <= wr_data;
                    8'h2C: in_words[3]  <= wr_data;
                    8'h50: key_words[0] <= wr_data;
                    8'h54: key_words[1] <= wr_data;
                    8'h58: key_words[2] <= wr_data;
                    8'h5C: key_words[3] <= wr_data;
                    8'h60: key_words[4] <= wr_data;
                    8'h64: key_words[5] <= wr_data;
                    8'h68: key_words[6] <= wr_data;
                    8'h6C: key_words[7] <= wr_data;
                    default: ;
                endcase
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end


    assign s_axi_arready = aresetn && !s_axi_rvalid;
    wire   ar_accepted   = s_axi_arvalid && s_axi_arready;

    logic [31:0] read_data;
    always_comb begin
        case (s_axi_araddr[7:0])
            8'h04:   read_data = {29'b0, core_key_loaded, done_seen, core_busy};
            8'h20:   read_data = in_words[0];
            8'h24:   read_data = in_words[1];
            8'h28:   read_data = in_words[2];
            8'h2C:   read_data = in_words[3];
            8'h30:   read_data = out_words[0];
            8'h34:   read_data = out_words[1];
            8'h38:   read_data = out_words[2];
            8'h3C:   read_data = out_words[3];
            8'h40:   read_data = stat_total_blocks;
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
