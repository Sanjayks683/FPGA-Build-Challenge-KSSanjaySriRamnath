`default_nettype none


module rl_stats (
    input  wire                      clk,
    input  wire                      rst_n,
    input  wire                      clear_stats,


    input  wire                      step_pulse,
    input  wire signed [15:0]        step_reward,


    input  wire                      episode_end_pulse,
    input  wire                      goal_reached,


    output reg  [31:0]               episode_counter,
    output reg  [31:0]               step_counter,
    output reg  signed [31:0]        reward_total,
    output reg  [31:0]               best_steps,
    output reg  [31:0]               total_goals,


    input  wire [6:0]                axi_hist_addr,
    output wire [31:0]               axi_hist_data
);


    reg [31:0] hist_mem [0:99];
    reg [6:0]  hist_ptr;

    integer i;
    initial begin
        for (i = 0; i < 100; i = i + 1) begin
            hist_mem[i] = 32'd0;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            episode_counter <= 32'd0;
            step_counter    <= 32'd0;
            reward_total    <= 32'sd0;
            best_steps      <= 32'hFFFF_FFFF;
            total_goals     <= 32'd0;
            hist_ptr        <= 7'd0;
        end else if (clear_stats) begin
            episode_counter <= 32'd0;
            step_counter    <= 32'd0;
            reward_total    <= 32'sd0;
            best_steps      <= 32'hFFFF_FFFF;
            total_goals     <= 32'd0;
            hist_ptr        <= 7'd0;
        end else begin

            if (step_pulse) begin
                step_counter <= step_counter + 32'd1;
                reward_total <= reward_total + $signed({{16{step_reward[15]}}, step_reward});
            end


            if (episode_end_pulse) begin
                episode_counter <= episode_counter + 32'd1;


                hist_mem[hist_ptr] <= {goal_reached, 7'b0, step_counter[23:0]};
                hist_ptr <= (hist_ptr == 7'd99) ? 7'd0 : hist_ptr + 7'd1;


                if (goal_reached) begin
                    total_goals <= total_goals + 32'd1;
                    if (step_counter < best_steps) begin
                        best_steps <= step_counter;
                    end
                end


                step_counter <= 32'd0;
                reward_total <= 32'sd0;
            end
        end
    end


    assign axi_hist_data = (axi_hist_addr < 7'd100) ? hist_mem[axi_hist_addr] : 32'd0;

endmodule

`default_nettype wire
