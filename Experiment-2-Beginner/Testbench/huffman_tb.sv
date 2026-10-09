`default_nettype none
`timescale 1ns/1ps


module huffman_tb;
    logic sys_clk = 1'b0;
    logic sys_rst_n = 1'b0;

    logic [31:0] s_axi_awaddr = 0, s_axi_wdata = 0, s_axi_araddr = 0;
    logic [2:0]  s_axi_awprot = 0, s_axi_arprot = 0;
    logic [3:0]  s_axi_wstrb = 0;
    logic        s_axi_awvalid = 0, s_axi_wvalid = 0, s_axi_bready = 0;
    logic        s_axi_arvalid = 0, s_axi_rready = 0;
    wire         s_axi_awready, s_axi_wready, s_axi_bvalid;
    wire         s_axi_arready, s_axi_rvalid;
    wire  [1:0]  s_axi_bresp, s_axi_rresp;
    wire  [31:0] s_axi_rdata;

    wire  [3:0]  led;
    logic [1:0]  sw = 2'b00;

    huffman_top dut (.*);

    always #5 sys_clk = ~sys_clk;


    logic [23:0] code_tab [0:255];
    logic [4:0]  len_tab  [0:255];
    `include "huffman_codes.svh"

    task automatic axi_write(input logic [31:0] addr, input logic [31:0] data);
        begin
            @(posedge sys_clk);
            s_axi_awaddr  <= addr;
            s_axi_awvalid <= 1'b1;
            s_axi_wdata   <= data;
            s_axi_wstrb   <= 4'hF;
            s_axi_wvalid  <= 1'b1;
            s_axi_bready  <= 1'b1;
            @(posedge sys_clk);
            while (!s_axi_awready) @(posedge sys_clk);
            s_axi_awvalid <= 1'b0;
            s_axi_wvalid  <= 1'b0;
            while (!s_axi_bvalid) @(posedge sys_clk);
            @(posedge sys_clk);
            s_axi_bready <= 1'b0;
        end
    endtask

    task automatic axi_read(input logic [31:0] addr, output logic [31:0] data);
        begin
            @(posedge sys_clk);
            s_axi_araddr  <= addr;
            s_axi_arvalid <= 1'b1;
            s_axi_rready  <= 1'b1;
            @(posedge sys_clk);
            while (!s_axi_arready) @(posedge sys_clk);
            s_axi_arvalid <= 1'b0;
            while (!s_axi_rvalid) @(posedge sys_clk);
            data = s_axi_rdata;
            @(posedge sys_clk);
            s_axi_rready <= 1'b0;
        end
    endtask


    localparam int MSG_LEN = 32;
    localparam logic [8*MSG_LEN-1:0] MESSAGE = "hello world, huffman on a pynq!!";


    logic [63:0] expect_buffer;
    logic [6:0]  expect_count;
    logic [31:0] expect_word [0:15];
    int          expect_words;
    int          expect_bits;

    task automatic add_code(input logic [7:0] character);
        int i;
        begin
            for (i = len_tab[character] - 1; i >= 0; i = i - 1) begin
                expect_buffer[expect_count] = code_tab[character][i];
                expect_count = expect_count + 1;
                expect_bits  = expect_bits + 1;
                if (expect_count == 32) begin
                    expect_word[expect_words] = expect_buffer[31:0];
                    expect_words = expect_words + 1;
                    expect_buffer = 64'b0;
                    expect_count = 0;
                end
            end
        end
    endtask

    logic [31:0] value;
    logic [7:0]  character;
    int i;

    initial begin
        expect_buffer = 64'b0;
        expect_count = 0;
        expect_words = 0;
        expect_bits = 0;

        #100 sys_rst_n = 1'b1;
        #100;

        axi_write(32'h00, 32'h1);
        #50;

        for (i = 0; i < MSG_LEN; i = i + 1) begin
            character = MESSAGE[8*(MSG_LEN-1-i) +: 8];
            axi_write(32'h08, {24'b0, character});
            add_code(character);
        end

        axi_write(32'h00, 32'h2);
        #500;


        if (expect_count > 0) begin
            expect_word[expect_words] = expect_buffer[31:0];
            expect_words = expect_words + 1;
        end

        axi_read(32'h10, value);
        $display("bytes in  = %0d (expected %0d)", value, MSG_LEN);
        if (value != MSG_LEN) $fatal(1, "wrong byte count");

        axi_read(32'h14, value);
        $display("bits out  = %0d (expected %0d)", value, expect_bits);
        if (value != expect_bits) $fatal(1, "wrong bit count");

        axi_read(32'h04, value);
        $display("status    = %08h, %0d words waiting", value, value >> 16);
        if ((value >> 16) != expect_words)
            $fatal(1, "FIFO holds %0d words, expected %0d", value >> 16, expect_words);

        for (i = 0; i < expect_words; i = i + 1) begin
            axi_read(32'h0C, value);
            if (value != expect_word[i])
                $fatal(1, "word %0d is %08h, expected %08h", i, value, expect_word[i]);
        end

        $display("compressed %0d bytes (%0d bits) into %0d words, all correct",
                 MSG_LEN, expect_bits, expect_words);
        $display("compression ratio: %0d bits out for %0d bits in", expect_bits, 8 * MSG_LEN);
        $display("PASS: all Huffman accelerator checks passed");
        $finish;
    end

    initial begin
        #500000;
        $fatal(1, "TIMEOUT");
    end
endmodule
