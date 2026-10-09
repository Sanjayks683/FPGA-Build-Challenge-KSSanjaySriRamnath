`default_nettype none


module rl_axi_wrapper (
    input  wire         clk,
    input  wire         rst_n,

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


    output logic        ctrl_start,
    output logic        ctrl_soft_reset,
    output logic        ctrl_slow_mode,
    output logic [7:0]  cfg_alpha,
    output logic [7:0]  cfg_gamma,
    output logic [7:0]  cfg_init_epsilon,
    output logic        cfg_load_epsilon,
    output logic [31:0] cfg_max_episodes,
    output logic [31:0] cfg_slow_mode_divider,
    output logic        cfg_maze_we,
    output logic [63:0] cfg_maze_data,
    input  wire  [63:0] current_maze_data,


    input  wire         status_training,
    input  wire         status_done,
    input  wire  [2:0]  status_agent_row,
    input  wire  [2:0]  status_agent_col,
    input  wire  [15:0] status_current_epsilon,
    input  wire  [31:0] stats_episode_counter,
    input  wire  [31:0] stats_step_counter,
    input  wire  signed [31:0] stats_reward_total,
    input  wire  [31:0] stats_best_steps,
    input  wire  [31:0] stats_total_goals,


    output wire  [6:0]  q_table_axi_rd_addr,
    input  wire  [31:0] q_table_axi_rd_data,
    output wire  [6:0]  hist_axi_rd_addr,
    input  wire  [31:0] hist_axi_rd_data
);

    logic [63:0] maze_reg;


    logic [31:0] wr_addr, wr_data;
    logic        aw_taken, w_taken;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
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

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            s_axi_bvalid          <= 1'b0;
            s_axi_bresp           <= 2'b00;
            ctrl_start            <= 1'b0;
            ctrl_soft_reset       <= 1'b0;
            ctrl_slow_mode        <= 1'b0;
            cfg_alpha             <= 8'h1A;
            cfg_gamma             <= 8'hF3;
            cfg_init_epsilon      <= 8'hE6;
            cfg_load_epsilon      <= 1'b0;
            cfg_max_episodes      <= 32'd2000;
            cfg_slow_mode_divider <= 32'd2_500_000;
            cfg_maze_we           <= 1'b0;
            cfg_maze_data         <= 64'd0;
            maze_reg              <= 64'd0;
        end else begin

            ctrl_start       <= 1'b0;
            ctrl_soft_reset  <= 1'b0;
            cfg_load_epsilon <= 1'b0;
            cfg_maze_we      <= 1'b0;

            if (do_write) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00;
                case (wr_addr[12:0])
                    13'h0000: begin
                        ctrl_start      <= wr_data[0];
                        ctrl_soft_reset <= wr_data[1];
                        ctrl_slow_mode  <= wr_data[2];
                        if (wr_data[1]) cfg_load_epsilon <= 1'b1;
                    end
                    13'h0008: cfg_alpha             <= wr_data[7:0];
                    13'h000C: cfg_gamma             <= wr_data[7:0];
                    13'h0010: begin
                        cfg_init_epsilon <= wr_data[7:0];
                        cfg_load_epsilon <= 1'b1;
                    end
                    13'h0014: cfg_max_episodes      <= wr_data;
                    13'h0018: cfg_slow_mode_divider <= wr_data;
                    13'h1000: maze_reg[31:0]        <= wr_data;
                    13'h1004: begin
                        maze_reg[63:32] <= wr_data;
                        cfg_maze_data   <= {wr_data, maze_reg[31:0]};
                        cfg_maze_we     <= 1'b1;
                    end
                    default: ;
                endcase
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end


    assign s_axi_arready = rst_n && !s_axi_rvalid;
    wire   ar_accepted   = s_axi_arvalid && s_axi_arready;


    wire [9:0] word_addr = s_axi_araddr[11:2];
    wire [9:0] q_index    = word_addr - 10'd64;
    wire [9:0] hist_index = word_addr - 10'd192;
    assign q_table_axi_rd_addr = q_index[6:0];
    assign hist_axi_rd_addr    = hist_index[6:0];

    logic [31:0] read_data;
    always_comb begin
        if (s_axi_araddr[12:0] >= 13'h0100 && s_axi_araddr[12:0] <= 13'h02FF) begin
            read_data = q_table_axi_rd_data;
        end else if (s_axi_araddr[12:0] >= 13'h0300 && s_axi_araddr[12:0] <= 13'h04FF) begin
            read_data = hist_axi_rd_data;
        end else begin
            case (s_axi_araddr[12:0])
                13'h0004: read_data = {stats_episode_counter[15:0], 14'b0, status_done, status_training};
                13'h0008: read_data = {24'b0, cfg_alpha};
                13'h000C: read_data = {24'b0, cfg_gamma};
                13'h0010: read_data = {24'b0, cfg_init_epsilon};
                13'h0014: read_data = cfg_max_episodes;
                13'h0018: read_data = cfg_slow_mode_divider;
                13'h001C: read_data = stats_episode_counter;
                13'h0020: read_data = stats_step_counter;
                13'h0024: read_data = stats_reward_total;
                13'h0028: read_data = {25'b0, status_agent_row, 1'b0, status_agent_col};
                13'h002C: read_data = stats_best_steps;
                13'h0030: read_data = {16'b0, status_current_epsilon};
                13'h0034: read_data = stats_total_goals;
                13'h1000: read_data = current_maze_data[31:0];
                13'h1004: read_data = current_maze_data[63:32];
                default:  read_data = 32'b0;
            endcase
        end
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
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

`default_nettype wire
