module wave_dump;
    initial begin
        $dumpfile("core_wave.vcd");
        $dumpvars(0, neurocore_pynq_tb.sys_clk, neurocore_pynq_tb.led, neurocore_pynq_tb.rgb_led0);
        $dumpvars(0, neurocore_pynq_tb.s_axi_awvalid, neurocore_pynq_tb.s_axi_awaddr, neurocore_pynq_tb.s_axi_wdata,
                     neurocore_pynq_tb.s_axi_arvalid, neurocore_pynq_tb.s_axi_araddr, neurocore_pynq_tb.s_axi_rdata);
        $dumpvars(0, neurocore_pynq_tb.dut.cpu_running);
        $dumpvars(0, neurocore_pynq_tb.dut.u_riscv_core.if_pc_out, neurocore_pynq_tb.dut.u_riscv_core.if_instr_out,
                     neurocore_pynq_tb.dut.u_riscv_core.pc_stall, neurocore_pynq_tb.dut.u_riscv_core.branch_mispredict,
                     neurocore_pynq_tb.dut.u_riscv_core.ex_branch_taken, neurocore_pynq_tb.dut.u_riscv_core.btb_hit,
                     neurocore_pynq_tb.dut.u_riscv_core.predicted_taken, neurocore_pynq_tb.dut.u_riscv_core.fwd_a_sel,
                     neurocore_pynq_tb.dut.u_riscv_core.fwd_b_sel);
        $dumpvars(0, neurocore_pynq_tb.dut.u_riscv_core.wb_reg_wr_en_out, neurocore_pynq_tb.dut.u_riscv_core.wb_rd_addr_out,
                     neurocore_pynq_tb.dut.u_riscv_core.wb_data, neurocore_pynq_tb.dut.u_riscv_core.instr_retired,
                     neurocore_pynq_tb.dut.u_riscv_core.perf_cycles, neurocore_pynq_tb.dut.u_riscv_core.perf_instrs,
                     neurocore_pynq_tb.dut.u_riscv_core.ebreak_committed);
    end
endmodule
