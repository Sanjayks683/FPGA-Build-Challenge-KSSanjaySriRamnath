`default_nettype none


module q_table (
    input  wire        clk,
    input  wire        rst_n,


    input  wire        clear_table,
    output reg         clear_busy,


    input  wire [5:0]  core_rd_state,
    output wire signed [15:0] q_up,
    output wire signed [15:0] q_down,
    output wire signed [15:0] q_left,
    output wire signed [15:0] q_right,


    input  wire        core_wr_en,
    input  wire [5:0]  core_wr_state,
    input  wire [1:0]  core_wr_action,
    input  wire signed [15:0] core_wr_data,


    input  wire [6:0]  axi_rd_addr,
    output wire [31:0] axi_rd_data
);


    reg [63:0] q_mem [0:63];


    reg [6:0] clear_cnt;


    integer init_i;
    initial begin
        for (init_i = 0; init_i < 64; init_i = init_i + 1) begin
            q_mem[init_i] = 64'h0000_0000_0000_0000;
        end
    end


    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clear_busy <= 1'b1;
            clear_cnt  <= 7'd0;
        end else if (clear_table && !clear_busy) begin
            clear_busy <= 1'b1;
            clear_cnt  <= 7'd0;
        end else if (clear_busy) begin
            q_mem[clear_cnt[5:0]] <= 64'h0000_0000_0000_0000;
            if (clear_cnt == 7'd63) begin
                clear_busy <= 1'b0;
            end else begin
                clear_cnt <= clear_cnt + 7'd1;
            end
        end else if (core_wr_en) begin
            case (core_wr_action)
                2'b00: q_mem[core_wr_state][15:0]  <= core_wr_data;
                2'b01: q_mem[core_wr_state][31:16] <= core_wr_data;
                2'b10: q_mem[core_wr_state][47:32] <= core_wr_data;
                2'b11: q_mem[core_wr_state][63:48] <= core_wr_data;
            endcase
        end
    end


    wire [63:0] current_state_q = q_mem[core_rd_state];
    assign q_up    = $signed(current_state_q[15:0]);
    assign q_down  = $signed(current_state_q[31:16]);
    assign q_left  = $signed(current_state_q[47:32]);
    assign q_right = $signed(current_state_q[63:48]);


    wire [5:0]  axi_state   = axi_rd_addr[6:1];
    wire        axi_pair    = axi_rd_addr[0];
    wire [63:0] axi_state_q = q_mem[axi_state];

    assign axi_rd_data = (!axi_pair) ?
                         {axi_state_q[31:16], axi_state_q[15:0]} :
                         {axi_state_q[63:48], axi_state_q[47:32]};

endmodule

`default_nettype wire
