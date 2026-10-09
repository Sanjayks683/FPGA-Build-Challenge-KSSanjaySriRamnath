`default_nettype wire

module branch_predictor #(
    parameter BTB_ENTRIES = 16
)(
    input  logic        clk,
    input  logic        rst_n,
    input  logic [31:0] if_pc,
    output logic        btb_hit_out,
    output logic        predict_taken,
    output logic [31:0] predict_target,
    input  logic        ex_is_branch,
    input  logic        ex_branch_taken,
    input  logic [31:0] ex_branch_pc,
    input  logic [31:0] ex_branch_target
);

    localparam IDX_BITS = 4;
    localparam TAG_BITS = 26;

    logic                btb_valid  [BTB_ENTRIES];
    logic [TAG_BITS-1:0] btb_tag    [BTB_ENTRIES];
    logic [31:0]         btb_target [BTB_ENTRIES];
    logic [1:0]          bht        [BTB_ENTRIES];

    logic [IDX_BITS-1:0] pred_idx;
    logic [TAG_BITS-1:0] pred_tag;

    assign pred_idx = if_pc[IDX_BITS+1:2];
    assign pred_tag = if_pc[31:6];

    assign btb_hit_out    = btb_valid[pred_idx] && (btb_tag[pred_idx] == pred_tag);
    assign predict_taken  = btb_hit_out && bht[pred_idx][1];
    assign predict_target = btb_hit_out ? btb_target[pred_idx] : (if_pc + 32'd4);

    logic [IDX_BITS-1:0] train_idx;
    logic [TAG_BITS-1:0] train_tag;

    assign train_idx = ex_branch_pc[IDX_BITS+1:2];
    assign train_tag = ex_branch_pc[31:6];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < BTB_ENTRIES; i++) begin
                btb_valid[i]  <= 1'b0;
                btb_tag[i]    <= '0;
                btb_target[i] <= '0;
                bht[i]        <= 2'b10;
            end
        end else if (ex_is_branch) begin
            if (ex_branch_taken) begin
                if (bht[train_idx] != 2'b11)
                    bht[train_idx] <= bht[train_idx] + 2'b01;
            end else begin
                if (bht[train_idx] != 2'b00)
                    bht[train_idx] <= bht[train_idx] - 2'b01;
            end

            btb_valid[train_idx]  <= 1'b1;
            btb_tag[train_idx]    <= train_tag;
            btb_target[train_idx] <= ex_branch_target;
        end
    end

endmodule
