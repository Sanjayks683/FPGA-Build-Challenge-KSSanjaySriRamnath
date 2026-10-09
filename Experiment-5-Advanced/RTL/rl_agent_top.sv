`default_nettype none


module rl_agent_top (

    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME sys_clk, ASSOCIATED_BUSIF s_axi, ASSOCIATED_RESET sys_rst_n, FREQ_HZ 50000000" *)
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 sys_clk CLK" *)
    input  wire        sys_clk,
    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME sys_rst_n, POLARITY ACTIVE_LOW" *)
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 sys_rst_n RST" *)
    input  wire        sys_rst_n,


    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi AWADDR" *)  input  wire [31:0] s_axi_awaddr,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi AWPROT" *)  input  wire [2:0]  s_axi_awprot,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi AWVALID" *) input  wire        s_axi_awvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi AWREADY" *) output wire        s_axi_awready,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi WDATA" *)   input  wire [31:0] s_axi_wdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi WSTRB" *)   input  wire [3:0]  s_axi_wstrb,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi WVALID" *)  input  wire        s_axi_wvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi WREADY" *)  output wire        s_axi_wready,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi BRESP" *)   output wire [1:0]  s_axi_bresp,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi BVALID" *)  output wire        s_axi_bvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi BREADY" *)  input  wire        s_axi_bready,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi ARADDR" *)  input  wire [31:0] s_axi_araddr,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi ARPROT" *)  input  wire [2:0]  s_axi_arprot,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi ARVALID" *) input  wire        s_axi_arvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi ARREADY" *) output wire        s_axi_arready,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi RDATA" *)   output wire [31:0] s_axi_rdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi RRESP" *)   output wire [1:0]  s_axi_rresp,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi RVALID" *)  output wire        s_axi_rvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi RREADY" *)  input  wire        s_axi_rready,


    output wire [3:0]  led,
    output reg  [2:0]  rgb_led0,
    input  wire [1:0]  btn,
    input  wire [0:0]  sw
);


    wire [63:0] current_maze_data;

    wire        lfsr_step_en;
    wire [15:0] lfsr_rand_16;
    wire [1:0]  lfsr_rand_action;

    wire [5:0]  core_rd_state, core_wr_state;
    wire signed [15:0] q_up, q_down, q_left, q_right, core_wr_data;
    wire        core_wr_en, clear_q_table, q_table_clear_busy;
    wire [1:0]  core_wr_action;
    wire [6:0]  q_table_axi_rd_addr;
    wire [31:0] q_table_axi_rd_data;

    wire [1:0]  best_action, selected_action;
    wire signed [15:0] max_q, selected_q;
    wire        is_explore, decay_epsilon_pulse;
    wire [15:0] current_epsilon;

    wire [2:0]  env_current_row, env_current_col, env_next_row, env_next_col;
    wire [1:0]  env_action;
    wire signed [15:0] env_reward;
    wire        env_done, env_is_goal, env_hit_wall, env_hit_boundary;

    wire        bellman_start, bellman_is_terminal, bellman_done;
    wire signed [15:0] bellman_q_old, bellman_q_max_next, bellman_reward, bellman_q_new;

    wire        stats_clear, stats_step_pulse, stats_ep_end_pulse, stats_goal_reached;
    wire signed [15:0] stats_step_reward;
    wire [31:0] stats_episode_counter, stats_step_counter, stats_best_steps, stats_total_goals;
    wire signed [31:0] stats_reward_total;
    wire [6:0]  hist_axi_rd_addr;
    wire [31:0] hist_axi_rd_data;

    wire        training_active, training_done, goal_pulse;
    wire [2:0]  agent_row, agent_col;
    wire [1:0]  current_action;

    wire        axi_ctrl_start, axi_ctrl_soft_reset, axi_ctrl_slow_mode;
    wire [7:0]  cfg_alpha, cfg_gamma, cfg_init_epsilon;
    wire        cfg_load_epsilon;
    wire [31:0] cfg_max_episodes, cfg_slow_mode_divider;
    wire        cfg_maze_we;
    wire [63:0] cfg_maze_data;


    logic [1:0] btn_sync1, btn_sync2, btn_prev;

    always_ff @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            btn_sync1 <= 2'b00;
            btn_sync2 <= 2'b00;
            btn_prev  <= 2'b00;
        end else begin
            btn_sync1 <= btn;
            btn_sync2 <= btn_sync1;
            btn_prev  <= btn_sync2;
        end
    end

    wire start_agent = axi_ctrl_start      | (btn_sync2[0] & ~btn_prev[0]);
    wire reset_agent = axi_ctrl_soft_reset | (btn_sync2[1] & ~btn_prev[1]);
    wire slow_mode   = axi_ctrl_slow_mode  | sw[0];


    maze_rom u_maze_rom (
        .clk           (sys_clk),
        .rst_n         (sys_rst_n),
        .axi_we        (cfg_maze_we),
        .axi_maze_data (cfg_maze_data),
        .current_maze  (current_maze_data)
    );


    lfsr_prng u_lfsr_prng (
        .clk         (sys_clk),
        .rst_n       (sys_rst_n),
        .step_en     (lfsr_step_en),
        .rand_16     (lfsr_rand_16),
        .rand_action (lfsr_rand_action)
    );


    q_table u_q_table (
        .clk            (sys_clk),
        .rst_n          (sys_rst_n),
        .clear_table    (clear_q_table),
        .clear_busy     (q_table_clear_busy),
        .core_rd_state  (core_rd_state),
        .q_up           (q_up),
        .q_down         (q_down),
        .q_left         (q_left),
        .q_right        (q_right),
        .core_wr_en     (core_wr_en),
        .core_wr_state  (core_wr_state),
        .core_wr_action (core_wr_action),
        .core_wr_data   (core_wr_data),
        .axi_rd_addr    (q_table_axi_rd_addr),
        .axi_rd_data    (q_table_axi_rd_data)
    );


    action_selector u_action_selector (
        .clk               (sys_clk),
        .rst_n             (sys_rst_n),
        .q_up              (q_up),
        .q_down            (q_down),
        .q_left            (q_left),
        .q_right           (q_right),
        .rand_16           (lfsr_rand_16),
        .rand_action       (lfsr_rand_action),
        .cfg_init_epsilon  (cfg_init_epsilon),
        .load_init_epsilon (cfg_load_epsilon),
        .decay_pulse       (decay_epsilon_pulse),
        .best_action       (best_action),
        .max_q             (max_q),
        .selected_action   (selected_action),
        .selected_q        (selected_q),
        .is_explore        (is_explore),
        .current_epsilon   (current_epsilon)
    );


    environment u_environment (
        .current_row  (env_current_row),
        .current_col  (env_current_col),
        .action       (env_action),
        .maze_layout  (current_maze_data),
        .next_row     (env_next_row),
        .next_col     (env_next_col),
        .reward       (env_reward),
        .done         (env_done),
        .is_goal      (env_is_goal),
        .hit_wall     (env_hit_wall),
        .hit_boundary (env_hit_boundary)
    );


    bellman_update u_bellman_update (
        .clk         (sys_clk),
        .rst_n       (sys_rst_n),
        .start       (bellman_start),
        .q_old       (bellman_q_old),
        .q_max_next  (bellman_q_max_next),
        .reward      (bellman_reward),
        .alpha       (cfg_alpha),
        .gamma       (cfg_gamma),
        .is_terminal (bellman_is_terminal),
        .q_new       (bellman_q_new),
        .done        (bellman_done)
    );

    rl_stats u_rl_stats (
        .clk               (sys_clk),
        .rst_n             (sys_rst_n),
        .clear_stats       (stats_clear),
        .step_pulse        (stats_step_pulse),
        .step_reward       (stats_step_reward),
        .episode_end_pulse (stats_ep_end_pulse),
        .goal_reached      (stats_goal_reached),
        .episode_counter   (stats_episode_counter),
        .step_counter      (stats_step_counter),
        .reward_total      (stats_reward_total),
        .best_steps        (stats_best_steps),
        .total_goals       (stats_total_goals),
        .axi_hist_addr     (hist_axi_rd_addr),
        .axi_hist_data     (hist_axi_rd_data)
    );

    episode_controller u_episode_controller (
        .clk                   (sys_clk),
        .rst_n                 (sys_rst_n),
        .ctrl_start            (start_agent),
        .ctrl_soft_reset       (reset_agent),
        .ctrl_slow_mode        (slow_mode),
        .max_episodes          (cfg_max_episodes),
        .slow_mode_divider     (cfg_slow_mode_divider),
        .max_steps_per_episode (16'd256),
        .training_active       (training_active),
        .training_done         (training_done),
        .goal_pulse            (goal_pulse),
        .agent_row             (agent_row),
        .agent_col             (agent_col),
        .current_action        (current_action),
        .core_rd_state         (core_rd_state),
        .q_up                  (q_up),
        .q_down                (q_down),
        .q_left                (q_left),
        .q_right               (q_right),
        .core_wr_en            (core_wr_en),
        .core_wr_state         (core_wr_state),
        .core_wr_action        (core_wr_action),
        .core_wr_data          (core_wr_data),
        .clear_q_table         (clear_q_table),
        .q_table_clear_busy    (q_table_clear_busy),
        .lfsr_step_en          (lfsr_step_en),
        .decay_epsilon_pulse   (decay_epsilon_pulse),
        .selected_action       (selected_action),
        .selected_q            (selected_q),
        .max_q                 (max_q),
        .env_current_row       (env_current_row),
        .env_current_col       (env_current_col),
        .env_action            (env_action),
        .env_next_row          (env_next_row),
        .env_next_col          (env_next_col),
        .env_reward            (env_reward),
        .env_done              (env_done),
        .env_is_goal           (env_is_goal),
        .bellman_start         (bellman_start),
        .bellman_q_old         (bellman_q_old),
        .bellman_q_max_next    (bellman_q_max_next),
        .bellman_reward        (bellman_reward),
        .bellman_is_terminal   (bellman_is_terminal),
        .bellman_q_new         (bellman_q_new),
        .bellman_done          (bellman_done),
        .stats_clear           (stats_clear),
        .stats_step_pulse      (stats_step_pulse),
        .stats_step_reward     (stats_step_reward),
        .stats_ep_end_pulse    (stats_ep_end_pulse),
        .stats_goal_reached    (stats_goal_reached),
        .stats_episode_counter (stats_episode_counter),
        .stats_step_counter    (stats_step_counter)
    );

    rl_axi_wrapper u_rl_axi_wrapper (
        .clk                    (sys_clk),
        .rst_n                  (sys_rst_n),
        .s_axi_awaddr           (s_axi_awaddr),
        .s_axi_awprot           (s_axi_awprot),
        .s_axi_awvalid          (s_axi_awvalid),
        .s_axi_awready          (s_axi_awready),
        .s_axi_wdata            (s_axi_wdata),
        .s_axi_wstrb            (s_axi_wstrb),
        .s_axi_wvalid           (s_axi_wvalid),
        .s_axi_wready           (s_axi_wready),
        .s_axi_bresp            (s_axi_bresp),
        .s_axi_bvalid           (s_axi_bvalid),
        .s_axi_bready           (s_axi_bready),
        .s_axi_araddr           (s_axi_araddr),
        .s_axi_arprot           (s_axi_arprot),
        .s_axi_arvalid          (s_axi_arvalid),
        .s_axi_arready          (s_axi_arready),
        .s_axi_rdata            (s_axi_rdata),
        .s_axi_rresp            (s_axi_rresp),
        .s_axi_rvalid           (s_axi_rvalid),
        .s_axi_rready           (s_axi_rready),
        .ctrl_start             (axi_ctrl_start),
        .ctrl_soft_reset        (axi_ctrl_soft_reset),
        .ctrl_slow_mode         (axi_ctrl_slow_mode),
        .cfg_alpha              (cfg_alpha),
        .cfg_gamma              (cfg_gamma),
        .cfg_init_epsilon       (cfg_init_epsilon),
        .cfg_load_epsilon       (cfg_load_epsilon),
        .cfg_max_episodes       (cfg_max_episodes),
        .cfg_slow_mode_divider  (cfg_slow_mode_divider),
        .cfg_maze_we            (cfg_maze_we),
        .cfg_maze_data          (cfg_maze_data),
        .current_maze_data      (current_maze_data),
        .status_training        (training_active),
        .status_done            (training_done),
        .status_agent_row       (agent_row),
        .status_agent_col       (agent_col),
        .status_current_epsilon (current_epsilon),
        .stats_episode_counter  (stats_episode_counter),
        .stats_step_counter     (stats_step_counter),
        .stats_reward_total     (stats_reward_total),
        .stats_best_steps       (stats_best_steps),
        .stats_total_goals      (stats_total_goals),
        .q_table_axi_rd_addr    (q_table_axi_rd_addr),
        .q_table_axi_rd_data    (q_table_axi_rd_data),
        .hist_axi_rd_addr       (hist_axi_rd_addr),
        .hist_axi_rd_data       (hist_axi_rd_data)
    );


    logic       episode_led;
    logic [22:0] goal_flash;

    always_ff @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            episode_led <= 1'b0;
            goal_flash  <= 23'd0;
        end else begin
            if (stats_ep_end_pulse) episode_led <= ~episode_led;

            if (goal_pulse) begin
                goal_flash <= 23'd5_000_000;
            end else if (goal_flash != 23'd0) begin
                goal_flash <= goal_flash - 23'd1;
            end
        end
    end

    assign led[0] = training_active;
    assign led[1] = episode_led;
    assign led[2] = (goal_flash != 23'd0);
    assign led[3] = training_done;


    always_comb begin
        if (current_epsilon > 16'h9999)      rgb_led0 = 3'b001;
        else if (current_epsilon > 16'h3333) rgb_led0 = 3'b011;
        else                                 rgb_led0 = 3'b010;
    end

endmodule

`default_nettype wire
