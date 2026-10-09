`default_nettype none


module episode_controller (
    input  wire                      clk,
    input  wire                      rst_n,


    input  wire                      ctrl_start,
    input  wire                      ctrl_soft_reset,
    input  wire                      ctrl_slow_mode,


    input  wire [31:0]               max_episodes,
    input  wire [31:0]               slow_mode_divider,
    input  wire [15:0]               max_steps_per_episode,


    output reg                       training_active,
    output reg                       training_done,
    output reg                       goal_pulse,
    output reg  [2:0]                agent_row,
    output reg  [2:0]                agent_col,
    output reg  [1:0]                current_action,


    output reg  [5:0]                core_rd_state,
    input  wire signed [15:0]        q_up,
    input  wire signed [15:0]        q_down,
    input  wire signed [15:0]        q_left,
    input  wire signed [15:0]        q_right,
    output reg                       core_wr_en,
    output reg  [5:0]                core_wr_state,
    output reg  [1:0]                core_wr_action,
    output reg  signed [15:0]        core_wr_data,
    output reg                       clear_q_table,
    input  wire                      q_table_clear_busy,


    output reg                       lfsr_step_en,
    output reg                       decay_epsilon_pulse,
    input  wire [1:0]                selected_action,
    input  wire signed [15:0]        selected_q,
    input  wire signed [15:0]        max_q,


    output reg  [2:0]                env_current_row,
    output reg  [2:0]                env_current_col,
    output reg  [1:0]                env_action,
    input  wire [2:0]                env_next_row,
    input  wire [2:0]                env_next_col,
    input  wire signed [15:0]        env_reward,
    input  wire                      env_done,
    input  wire                      env_is_goal,


    output reg                       bellman_start,
    output reg  signed [15:0]        bellman_q_old,
    output reg  signed [15:0]        bellman_q_max_next,
    output reg  signed [15:0]        bellman_reward,
    output reg                       bellman_is_terminal,
    input  wire signed [15:0]        bellman_q_new,
    input  wire                      bellman_done,


    output reg                       stats_clear,
    output reg                       stats_step_pulse,
    output reg  signed [15:0]        stats_step_reward,
    output reg                       stats_ep_end_pulse,
    output reg                       stats_goal_reached,
    input  wire [31:0]               stats_episode_counter,
    input  wire [31:0]               stats_step_counter
);

    typedef enum logic [3:0] {
        ST_RESET_ALL     = 4'd0,
        ST_IDLE          = 4'd1,
        ST_RESET_EPISODE = 4'd2,
        ST_WAIT_SLOW     = 4'd3,
        ST_READ_Q        = 4'd4,
        ST_EXECUTE       = 4'd5,
        ST_READ_NEXT_Q   = 4'd6,
        ST_BELLMAN_WAIT  = 4'd7,
        ST_WRITE_Q       = 4'd8,
        ST_CHECK_DONE    = 4'd9,
        ST_DONE          = 4'd10
    } state_t;

    state_t state;

    reg [31:0]        slow_div_cnt;
    reg [5:0]         saved_state;
    reg [1:0]         saved_action;
    reg signed [15:0] saved_q;
    reg [2:0]         saved_next_row;
    reg [2:0]         saved_next_col;
    reg signed [15:0] saved_reward;
    reg               saved_done;
    reg               saved_is_goal;


    reg  clear_started;
    reg  start_req;
    reg  reset_req;
    wire start_now = ctrl_start | start_req;
    wire reset_now = ctrl_soft_reset | reset_req;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state           <= ST_RESET_ALL;
            slow_div_cnt    <= 32'd0;
            agent_row       <= 3'd0;
            agent_col       <= 3'd0;
            current_action  <= 2'b00;
            training_active <= 1'b0;
            training_done   <= 1'b0;
            goal_pulse      <= 1'b0;
            saved_state     <= 6'd0;
            saved_action    <= 2'b00;
            saved_q         <= 16'sh0;
            saved_next_row  <= 3'd0;
            saved_next_col  <= 3'd0;
            saved_reward    <= 16'sh0;
            saved_done      <= 1'b0;
            saved_is_goal   <= 1'b0;
            clear_started   <= 1'b0;
            start_req       <= 1'b0;
            reset_req       <= 1'b0;
        end else begin
            goal_pulse <= 1'b0;
            if (ctrl_soft_reset) reset_req <= 1'b1;
            if (ctrl_start && state == ST_RESET_ALL) start_req <= 1'b1;

            case (state)
                ST_RESET_ALL: begin
                    agent_row       <= 3'd0;
                    agent_col       <= 3'd0;
                    slow_div_cnt    <= 32'd0;
                    training_active <= 1'b0;
                    training_done   <= 1'b0;
                    reset_req       <= 1'b0;
                    if (q_table_clear_busy) begin
                        clear_started <= 1'b1;
                    end else if (clear_started) begin
                        clear_started <= 1'b0;
                        state         <= ST_IDLE;
                    end
                end

                ST_IDLE: begin
                    training_active <= 1'b0;
                    start_req       <= 1'b0;
                    if (reset_now) begin
                        state <= ST_RESET_ALL;
                    end else if (start_now) begin
                        training_active <= 1'b1;
                        training_done   <= 1'b0;
                        state           <= ST_RESET_EPISODE;
                    end
                end

                ST_RESET_EPISODE: begin
                    training_active <= 1'b1;
                    agent_row       <= 3'd0;
                    agent_col       <= 3'd0;
                    slow_div_cnt    <= 32'd0;
                    if (reset_now) begin
                        state <= ST_RESET_ALL;
                    end else if (stats_episode_counter >= max_episodes) begin
                        training_active <= 1'b0;
                        training_done   <= 1'b1;
                        state           <= ST_DONE;
                    end else begin
                        state <= ctrl_slow_mode ? ST_WAIT_SLOW : ST_READ_Q;
                    end
                end

                ST_WAIT_SLOW: begin
                    if (reset_now) begin
                        state <= ST_RESET_ALL;
                    end else if (slow_div_cnt >= slow_mode_divider) begin
                        slow_div_cnt <= 32'd0;
                        state        <= ST_READ_Q;
                    end else begin
                        slow_div_cnt <= slow_div_cnt + 32'd1;
                    end
                end

                ST_READ_Q: begin
                    saved_state    <= {agent_row, agent_col};
                    saved_action   <= selected_action;
                    saved_q        <= selected_q;
                    current_action <= selected_action;
                    state          <= ST_EXECUTE;
                end

                ST_EXECUTE: begin
                    saved_next_row <= env_next_row;
                    saved_next_col <= env_next_col;
                    saved_reward   <= env_reward;
                    saved_done     <= env_done;
                    saved_is_goal  <= env_is_goal;
                    state          <= ST_READ_NEXT_Q;
                end

                ST_READ_NEXT_Q: state <= ST_BELLMAN_WAIT;

                ST_BELLMAN_WAIT: if (bellman_done) state <= ST_WRITE_Q;

                ST_WRITE_Q: begin
                    agent_row <= saved_next_row;
                    agent_col <= saved_next_col;
                    state     <= ST_CHECK_DONE;
                end

                ST_CHECK_DONE: begin
                    if (saved_is_goal) goal_pulse <= 1'b1;

                    if (reset_now) begin
                        state <= ST_RESET_ALL;
                    end else if (saved_done || (stats_step_counter >= max_steps_per_episode)) begin
                        state <= ST_RESET_EPISODE;
                    end else begin
                        slow_div_cnt <= 32'd0;
                        state <= ctrl_slow_mode ? ST_WAIT_SLOW : ST_READ_Q;
                    end
                end

                ST_DONE: begin
                    training_active <= 1'b0;
                    training_done   <= 1'b1;
                    if (reset_now) begin
                        state <= ST_RESET_ALL;
                    end else if (start_now) begin
                        training_done <= 1'b0;
                        state         <= ST_RESET_EPISODE;
                    end
                end

                default: state <= ST_RESET_ALL;
            endcase
        end
    end


    always_comb begin
        core_rd_state       = {agent_row, agent_col};
        core_wr_en          = 1'b0;
        core_wr_state       = saved_state;
        core_wr_action      = saved_action;
        core_wr_data        = bellman_q_new;
        clear_q_table       = 1'b0;
        lfsr_step_en        = 1'b0;
        decay_epsilon_pulse = 1'b0;
        env_current_row     = agent_row;
        env_current_col     = agent_col;
        env_action          = saved_action;
        bellman_start       = 1'b0;
        bellman_q_old       = saved_q;
        bellman_q_max_next  = max_q;
        bellman_reward      = saved_reward;
        bellman_is_terminal = saved_done;
        stats_clear         = 1'b0;
        stats_step_pulse    = 1'b0;
        stats_step_reward   = saved_reward;
        stats_ep_end_pulse  = 1'b0;
        stats_goal_reached  = saved_is_goal;

        case (state)
            ST_RESET_ALL: begin
                clear_q_table = !q_table_clear_busy && !clear_started;
                stats_clear   = 1'b1;
            end

            ST_READ_Q: begin
                lfsr_step_en = 1'b1;
            end

            ST_EXECUTE: begin
                stats_step_pulse  = 1'b1;
                stats_step_reward = env_reward;
            end

            ST_READ_NEXT_Q: begin
                core_rd_state = {saved_next_row, saved_next_col};
                bellman_start = 1'b1;
            end

            ST_WRITE_Q: begin
                core_wr_en = 1'b1;
            end

            ST_CHECK_DONE: begin
                if (saved_done || (stats_step_counter >= max_steps_per_episode)) begin
                    stats_ep_end_pulse  = 1'b1;
                    decay_epsilon_pulse = 1'b1;
                end
            end

            default: ;
        endcase
    end

endmodule

`default_nettype wire
