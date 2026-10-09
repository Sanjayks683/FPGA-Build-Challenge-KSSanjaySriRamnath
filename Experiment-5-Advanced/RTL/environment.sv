`default_nettype none


module environment #(
    parameter signed [15:0] REWARD_GOAL = 16'sh6400,
    parameter signed [15:0] REWARD_WALL = 16'shF600,
    parameter signed [15:0] REWARD_STEP = 16'shFF00
)(
    input  wire [2:0]         current_row,
    input  wire [2:0]         current_col,
    input  wire [1:0]         action,
    input  wire [63:0]        maze_layout,

    output reg  [2:0]         next_row,
    output reg  [2:0]         next_col,
    output reg  signed [15:0] reward,
    output reg                done,
    output reg                is_goal,
    output reg                hit_wall,
    output reg                hit_boundary
);


    reg [2:0] cand_row;
    reg [2:0] cand_col;
    reg       boundary_hit;

    always_comb begin
        boundary_hit = 1'b0;
        cand_row     = current_row;
        cand_col     = current_col;

        case (action)
            2'b00: begin
                if (current_row == 3'd0) begin
                    boundary_hit = 1'b1;
                end else begin
                    cand_row = current_row - 3'd1;
                end
            end
            2'b01: begin
                if (current_row == 3'd7) begin
                    boundary_hit = 1'b1;
                end else begin
                    cand_row = current_row + 3'd1;
                end
            end
            2'b10: begin
                if (current_col == 3'd0) begin
                    boundary_hit = 1'b1;
                end else begin
                    cand_col = current_col - 3'd1;
                end
            end
            2'b11: begin
                if (current_col == 3'd7) begin
                    boundary_hit = 1'b1;
                end else begin
                    cand_col = current_col + 3'd1;
                end
            end
        endcase
    end


    wire [5:0] cand_idx = {cand_row, cand_col};
    wire       cand_is_wall = maze_layout[cand_idx] && !(cand_row == 3'd0 && cand_col == 3'd0) && !(cand_row == 3'd7 && cand_col == 3'd7);
    wire       cand_is_goal = (cand_row == 3'd7) && (cand_col == 3'd7);


    always_comb begin
        hit_boundary = 1'b0;
        hit_wall     = 1'b0;
        is_goal      = 1'b0;

        if (boundary_hit) begin

            next_row     = current_row;
            next_col     = current_col;
            reward       = REWARD_STEP;
            done         = 1'b0;
            hit_boundary = 1'b1;
        end else if (cand_is_goal) begin

            next_row     = cand_row;
            next_col     = cand_col;
            reward       = REWARD_GOAL;
            done         = 1'b1;
            is_goal      = 1'b1;
        end else if (cand_is_wall) begin

            next_row     = current_row;
            next_col     = current_col;
            reward       = REWARD_WALL;
            done         = 1'b1;
            hit_wall     = 1'b1;
        end else begin

            next_row     = cand_row;
            next_col     = cand_col;
            reward       = REWARD_STEP;
            done         = 1'b0;
        end
    end

endmodule

`default_nettype wire
