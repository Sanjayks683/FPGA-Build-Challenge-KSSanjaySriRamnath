`default_nettype none


module bellman_update (
    input  wire                      clk,
    input  wire                      rst_n,

    input  wire                      start,
    input  wire signed [15:0]        q_old,
    input  wire signed [15:0]        q_max_next,
    input  wire signed [15:0]        reward,
    input  wire [7:0]                alpha,
    input  wire [7:0]                gamma,
    input  wire                      is_terminal,

    output reg  signed [15:0]        q_new,
    output reg                       done
);


    reg signed [15:0] q_old_s0;
    reg signed [15:0] q_max_next_s0;
    reg signed [15:0] reward_s0;
    reg [7:0]         alpha_s0;
    reg [7:0]         gamma_s0;
    reg               is_terminal_s0;
    reg               stage0_valid;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage0_valid   <= 1'b0;
            q_old_s0       <= 16'sh0;
            q_max_next_s0  <= 16'sh0;
            reward_s0      <= 16'sh0;
            alpha_s0       <= 8'h0;
            gamma_s0       <= 8'h0;
            is_terminal_s0 <= 1'b0;
        end else if (start) begin
            stage0_valid   <= 1'b1;
            q_old_s0       <= q_old;
            q_max_next_s0  <= q_max_next;
            reward_s0      <= reward;
            alpha_s0       <= alpha;
            gamma_s0       <= gamma;
            is_terminal_s0 <= is_terminal;
        end else begin
            stage0_valid   <= 1'b0;
        end
    end


    reg signed [17:0] td_error_s1;
    reg signed [15:0] q_old_s1;
    reg [7:0]         alpha_s1;
    reg               stage1_valid;


    wire signed [24:0] prod_gamma = q_max_next_s0 * $signed({1'b0, gamma_s0});

    wire signed [24:0] prod_gamma_shifted = prod_gamma >>> 8;
    wire signed [15:0] future_val = is_terminal_s0 ? 16'sh0000 : prod_gamma_shifted[15:0];


    wire signed [16:0] target = $signed({{1{reward_s0[15]}}, reward_s0}) +
                                $signed({{1{future_val[15]}}, future_val});


    wire signed [17:0] td_error = target - $signed({{2{q_old_s0[15]}}, q_old_s0});

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_valid <= 1'b0;
            td_error_s1  <= 18'sh0;
            q_old_s1     <= 16'sh0;
            alpha_s1     <= 8'h0;
        end else if (stage0_valid) begin
            stage1_valid <= 1'b1;
            td_error_s1  <= td_error;
            q_old_s1     <= q_old_s0;
            alpha_s1     <= alpha_s0;
        end else begin
            stage1_valid <= 1'b0;
        end
    end


    wire signed [26:0] prod_alpha = td_error_s1 * $signed({1'b0, alpha_s1});

    wire signed [26:0] prod_alpha_shifted = prod_alpha >>> 8;
    wire signed [17:0] scaled_delta = prod_alpha_shifted[17:0];


    wire signed [17:0] sum_q = $signed({{2{q_old_s1[15]}}, q_old_s1}) + scaled_delta;


    reg signed [15:0] clamped_q;
    always_comb begin
        if (sum_q > 18'sd32767) begin
            clamped_q = 16'sh7FFF;
        end else if (sum_q < -18'sd32768) begin
            clamped_q = 16'sh8000;
        end else begin
            clamped_q = sum_q[15:0];
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            done  <= 1'b0;
            q_new <= 16'sh0000;
        end else if (stage1_valid) begin
            q_new <= clamped_q;
            done  <= 1'b1;
        end else begin
            done  <= 1'b0;
        end
    end

endmodule

`default_nettype wire
