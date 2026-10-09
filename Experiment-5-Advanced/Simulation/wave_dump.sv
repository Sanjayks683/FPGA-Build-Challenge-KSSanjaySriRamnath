module wave_dump;
    initial begin
        $dumpfile("rl_wave.vcd");
        $dumpvars(0, rl_agent_tb.sys_clk, rl_agent_tb.s_axi_awvalid, rl_agent_tb.s_axi_awaddr,
                     rl_agent_tb.s_axi_wdata, rl_agent_tb.led, rl_agent_tb.rgb_led0);
        $dumpvars(0, rl_agent_tb.dut.training_active, rl_agent_tb.dut.training_done,
                     rl_agent_tb.dut.goal_pulse, rl_agent_tb.dut.agent_row, rl_agent_tb.dut.agent_col,
                     rl_agent_tb.dut.selected_action, rl_agent_tb.dut.is_explore,
                     rl_agent_tb.dut.env_reward, rl_agent_tb.dut.env_done,
                     rl_agent_tb.dut.bellman_q_old, rl_agent_tb.dut.bellman_q_new,
                     rl_agent_tb.dut.current_epsilon, rl_agent_tb.dut.stats_episode_counter,
                     rl_agent_tb.dut.stats_total_goals);
        $dumpvars(0, rl_agent_tb.dut.u_episode_controller.state);
        #8000 $dumpoff;
        wait (rl_agent_tb.dut.stats_episode_counter == 32'd1999);
        $dumpon;
        wait (rl_agent_tb.dut.training_done);
        #500 $dumpoff;
    end
endmodule
