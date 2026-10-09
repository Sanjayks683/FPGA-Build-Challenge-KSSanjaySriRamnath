module wave_dump;
    initial begin
        $dumpfile("trng_wave.vcd");
        $dumpvars(0, trng_tb.sys_clk, trng_tb.sys_rst_n);
        $dumpvars(0, trng_tb.s_axi_awvalid, trng_tb.s_axi_awready, trng_tb.s_axi_awaddr,
                     trng_tb.s_axi_wdata, trng_tb.s_axi_bvalid);
        $dumpvars(0, trng_tb.s_axi_arvalid, trng_tb.s_axi_arready, trng_tb.s_axi_araddr,
                     trng_tb.s_axi_rvalid, trng_tb.s_axi_rdata, trng_tb.led);
        $dumpvars(0, trng_tb.dut.enable_trng, trng_tb.dut.ro_out, trng_tb.dut.window_log2);
        $dumpvars(0, trng_tb.dut.sampler_inst.raw_bit, trng_tb.dut.sampler_inst.window_done,
                     trng_tb.dut.sampler_inst.window_bit);
        $dumpvars(0, trng_tb.dut.bit_valid, trng_tb.dut.random_bit);
        $dumpvars(0, trng_tb.dut.collector_inst.bit_count, trng_tb.dut.collector_inst.word_ready,
                     trng_tb.dut.collector_inst.assembled_word);
        $dumpvars(0, trng_tb.dut.fifo_empty, trng_tb.dut.fifo_full, trng_tb.dut.fifo_word_count);
    end
endmodule
