module wave_dump;
    initial begin
        $dumpfile("huffman_wave.vcd");
        $dumpvars(0, huffman_tb.sys_clk, huffman_tb.sys_rst_n);
        $dumpvars(0, huffman_tb.s_axi_awvalid, huffman_tb.s_axi_awaddr, huffman_tb.s_axi_wdata,
                     huffman_tb.s_axi_bvalid);
        $dumpvars(0, huffman_tb.s_axi_arvalid, huffman_tb.s_axi_araddr, huffman_tb.s_axi_rvalid,
                     huffman_tb.s_axi_rdata, huffman_tb.led);
        $dumpvars(0, huffman_tb.dut.ctrl_reset, huffman_tb.dut.ctrl_flush, huffman_tb.dut.char_in,
                     huffman_tb.dut.char_valid);
        $dumpvars(0, huffman_tb.dut.encoder.rom_code, huffman_tb.dut.encoder.rom_code_len,
                     huffman_tb.dut.encoder.valid_in_d1, huffman_tb.dut.encoder.bit_count,
                     huffman_tb.dut.encoder.bit_buffer, huffman_tb.dut.encoder.flush_pending,
                     huffman_tb.dut.encoder.busy, huffman_tb.dut.encoder.done);
        $dumpvars(0, huffman_tb.dut.encoder_word, huffman_tb.dut.encoder_valid_out,
                     huffman_tb.dut.fifo_count, huffman_tb.dut.bytes_in, huffman_tb.dut.bits_out);
    end
endmodule
