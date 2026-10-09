`default_nettype wire

module debouncer #(
    parameter int COUNT_MAX = 500_000
)(
    input  wire  clk,
    input  wire  rst_n,
    input  wire  btn_in,
    output logic btn_out
);

    logic sync_0, sync_1;
    logic [$clog2(COUNT_MAX)-1:0] count;
    logic state;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            sync_0  <= 1'b0;
            sync_1  <= 1'b0;
            count   <= '0;
            state   <= 1'b0;
            btn_out <= 1'b0;
        end else begin
            sync_0 <= btn_in;
            sync_1 <= sync_0;

            if (sync_1 != state) begin
                if (count == COUNT_MAX - 1) begin
                    state   <= sync_1;
                    btn_out <= sync_1;
                    count   <= '0;
                end else begin
                    count <= count + 1'b1;
                end
            end else begin
                count <= '0;
            end
        end
    end

endmodule
