`default_nettype none


module action_selector #(
    parameter logic [15:0] MIN_EPSILON = 16'h0CD0,
    parameter logic [15:0] DECAY_MULT  = 16'hFEB8
)(
    input  wire                      clk,
    input  wire                      rst_n,


    input  wire signed [15:0]        q_up,
    input  wire signed [15:0]        q_down,
    input  wire signed [15:0]        q_left,
    input  wire signed [15:0]        q_right,


    input  wire [15:0]               rand_16,
    input  wire [1:0]                rand_action,


    input  wire [7:0]                cfg_init_epsilon,
    input  wire                      load_init_epsilon,
    input  wire                      decay_pulse,


    output wire [1:0]                best_action,
    output wire signed [15:0]        max_q,
    output wire [1:0]                selected_action,
    output reg  signed [15:0]        selected_q,
    output wire                      is_explore,
    output wire [15:0]               current_epsilon
);


    reg [15:0] epsilon_reg;


    wire [31:0] decayed_val = epsilon_reg * DECAY_MULT;
    wire [15:0] next_decayed_eps = decayed_val[31:16];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin

            epsilon_reg <= 16'hE666;
        end else if (load_init_epsilon) begin
            epsilon_reg <= {cfg_init_epsilon, 8'h00};
        end else if (decay_pulse) begin
            if (next_decayed_eps < MIN_EPSILON) begin
                epsilon_reg <= MIN_EPSILON;
            end else begin
                epsilon_reg <= next_decayed_eps;
            end
        end
    end

    assign current_epsilon = epsilon_reg;


    wire signed [15:0] max_01 = (q_up >= q_down) ? q_up : q_down;
    wire [1:0]         act_01 = (q_up >= q_down) ? 2'b00 : 2'b01;


    wire signed [15:0] max_23 = (q_left >= q_right) ? q_left : q_right;
    wire [1:0]         act_23 = (q_left >= q_right) ? 2'b10 : 2'b11;


    assign max_q       = (max_01 >= max_23) ? max_01 : max_23;
    assign best_action = (max_01 >= max_23) ? act_01 : act_23;


    assign is_explore = (rand_16 < epsilon_reg);
    assign selected_action = is_explore ? rand_action : best_action;

    always_comb begin
        case (selected_action)
            2'b00: selected_q = q_up;
            2'b01: selected_q = q_down;
            2'b10: selected_q = q_left;
            2'b11: selected_q = q_right;
        endcase
    end

endmodule

`default_nettype wire
