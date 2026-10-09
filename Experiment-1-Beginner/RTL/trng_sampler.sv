`default_nettype none


module trng_sampler (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [3:0] ro_in,
    input  wire [3:0] window_log2,
    output logic      valid,
    output logic      random_bit
);


    logic [3:0] ro_sync1, ro_sync2;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            ro_sync1 <= 4'b0;
            ro_sync2 <= 4'b0;
        end else begin
            ro_sync1 <= ro_in;
            ro_sync2 <= ro_sync1;
        end
    end

    wire raw_bit = ^ro_sync2;


    logic [15:0] count;
    logic        acc;
    logic        window_done;
    logic        window_bit;
    wire  [15:0] last_count = (16'd1 << window_log2) - 16'd1;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            count       <= 16'd0;
            acc         <= 1'b0;
            window_done <= 1'b0;
            window_bit  <= 1'b0;
        end else begin
            window_done <= 1'b0;
            if (count >= last_count) begin
                window_bit  <= acc ^ raw_bit;
                window_done <= 1'b1;
                acc         <= 1'b0;
                count       <= 16'd0;
            end else begin
                acc   <= acc ^ raw_bit;
                count <= count + 16'd1;
            end
        end
    end


    logic have_first, first_bit;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            have_first <= 1'b0;
            first_bit  <= 1'b0;
            valid      <= 1'b0;
            random_bit <= 1'b0;
        end else begin
            valid <= 1'b0;
            if (window_done) begin
                have_first <= ~have_first;
                if (!have_first) begin
                    first_bit <= window_bit;
                end else if (first_bit != window_bit) begin
                    valid      <= 1'b1;
                    random_bit <= first_bit;
                end
            end
        end
    end

endmodule
