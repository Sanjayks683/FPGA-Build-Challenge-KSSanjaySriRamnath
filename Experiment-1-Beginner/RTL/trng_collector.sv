`default_nettype none

module trng_collector (
    input  wire clk,
    input  wire rst_n,

    input  wire valid_bit,
    input  wire random_bit,

    input  wire read_en,
    output wire [31:0] random_word,
    output wire fifo_empty,
    output wire fifo_full,
    output wire [31:0] fifo_word_count
);

    logic [31:0] shift_reg;
    logic [4:0] bit_count;
    logic word_ready;
    logic [31:0] assembled_word;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            shift_reg <= 32'b0;
            bit_count <= 5'b0;
            word_ready <= 1'b0;
            assembled_word <= 32'b0;
        end else begin
            word_ready <= 1'b0;
            if (valid_bit) begin
                shift_reg <= {shift_reg[30:0], random_bit};
                if (bit_count == 5'd31) begin
                    bit_count <= 5'b0;
                    assembled_word <= {shift_reg[30:0], random_bit};
                    word_ready <= 1'b1;
                end else begin
                    bit_count <= bit_count + 1'b1;
                end
            end
        end
    end


    (* ram_style = "block" *) logic [31:0] fifo_mem [0:1023];
    logic [10:0] write_ptr;
    logic [10:0] read_ptr;
    logic [31:0] dout;


    logic [10:0] visible_ptr;

    assign fifo_empty = (visible_ptr == read_ptr);
    assign fifo_full = (write_ptr[10] != read_ptr[10]) && (write_ptr[9:0] == read_ptr[9:0]);
    assign fifo_word_count = visible_ptr - read_ptr;
    assign random_word = dout;

    logic do_read;
    assign do_read = read_en && !fifo_empty;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            write_ptr <= 11'b0;
            read_ptr <= 11'b0;
            dout <= 32'b0;
            visible_ptr <= 11'b0;
        end else begin
            visible_ptr <= write_ptr;
            if (word_ready && (!fifo_full || do_read)) begin
                fifo_mem[write_ptr[9:0]] <= assembled_word;
                write_ptr <= write_ptr + 1'b1;
            end


            if (do_read) begin
                read_ptr <= read_ptr + 1'b1;
                dout <= fifo_mem[(read_ptr[9:0] + 10'd1)];
            end else begin
                dout <= fifo_mem[read_ptr[9:0]];
            end
        end
    end

endmodule
