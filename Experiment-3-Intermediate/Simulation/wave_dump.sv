module wave_dump;
    initial begin
        $dumpfile("aes_wave.vcd");
        $dumpvars(0, aes_tb.sys_clk, aes_tb.sys_rst_n, aes_tb.led);
        $dumpvars(0, aes_tb.s_axi_awvalid, aes_tb.s_axi_awaddr, aes_tb.s_axi_wdata,
                     aes_tb.s_axi_arvalid, aes_tb.s_axi_araddr, aes_tb.s_axi_rvalid, aes_tb.s_axi_rdata);
        $dumpvars(0, aes_tb.dut.ctrl_load_key, aes_tb.dut.core_key_loaded,
                     aes_tb.dut.u_key_expansion.state, aes_tb.dut.u_key_expansion.round_idx);
        $dumpvars(0, aes_tb.dut.cipher_start, aes_tb.dut.ctrl_start_decrypt, aes_tb.dut.block_to_core,
                     aes_tb.dut.core_busy, aes_tb.dut.core_done, aes_tb.dut.block_from_core,
                     aes_tb.dut.total_blocks);
        $dumpvars(0, aes_tb.dut.u_cipher.gen_round[1].u_round.valid_out,
                     aes_tb.dut.u_cipher.gen_round[1].u_round.state_out,
                     aes_tb.dut.u_cipher.gen_round[2].u_round.state_out,
                     aes_tb.dut.u_cipher.gen_round[13].u_round.state_out,
                     aes_tb.dut.u_cipher.u_final_round.valid_out);
        $dumpvars(0, aes_tb.dut.u_axi_wrapper.done_seen,
                     aes_tb.dut.u_axi_wrapper.out_words[0], aes_tb.dut.u_axi_wrapper.out_words[1],
                     aes_tb.dut.u_axi_wrapper.out_words[2], aes_tb.dut.u_axi_wrapper.out_words[3]);
    end
endmodule
