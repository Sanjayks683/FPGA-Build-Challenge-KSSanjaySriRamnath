`default_nettype none

module huffman_encoder (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         mode_passthrough,


    input  wire [7:0]   char_in,
    input  wire         valid_in,
    input  wire         flush,
    output logic        busy,


    output logic [31:0] word_out,
    output logic        valid_out,
    output logic        done,
    output logic [4:0]  current_code_len_out
);


    logic [23:0] rom_code;
    logic [4:0]  rom_code_len;

    huffman_rom rom_inst (
        .clk(clk),
        .char_in(char_in),
        .code_out(rom_code),
        .code_len_out(rom_code_len)
    );


    logic valid_in_d1;
    logic [7:0] char_in_d1;
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            valid_in_d1 <= 1'b0;
            char_in_d1 <= 8'b0;
        end else begin
            valid_in_d1 <= valid_in;
            char_in_d1 <= char_in;
        end
    end

    logic [23:0] final_code;
    logic [4:0]  final_code_len;

    assign final_code = mode_passthrough ? {16'b0, char_in_d1} : rom_code;
    assign final_code_len = mode_passthrough ? 5'd8 : rom_code_len;
    assign current_code_len_out = final_code_len;


    logic [63:0] bit_buffer;
    logic [5:0]  bit_count;

    logic flush_pending;

    logic [63:0] shifted_code;
    logic [63:0] next_buffer;
    logic [5:0]  next_count;

    assign shifted_code = {40'b0, final_code} << bit_count;
    assign next_buffer = bit_buffer | shifted_code;
    assign next_count = bit_count + final_code_len;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            bit_buffer <= 64'b0;
            bit_count <= 6'b0;
            word_out <= 32'b0;
            valid_out <= 1'b0;
            done <= 1'b0;
            busy <= 1'b0;
            flush_pending <= 1'b0;
        end else begin
            valid_out <= 1'b0;
            done <= 1'b0;

            if (flush) begin
                flush_pending <= 1'b1;
            end


            busy <= valid_in || valid_in_d1 || flush || flush_pending || (bit_count > 0);

            if (valid_in_d1) begin


                if (next_count >= 32) begin

                    word_out <= next_buffer[31:0];
                    valid_out <= 1'b1;


                    bit_buffer <= (next_buffer >> 32);
                    bit_count <= next_count - 32;
                end else begin

                    bit_buffer <= next_buffer;
                    bit_count <= next_count;
                end


            end else if (flush_pending) begin

                if (bit_count > 0) begin

                    word_out <= bit_buffer[31:0];
                    valid_out <= 1'b1;
                end


                bit_buffer <= 64'b0;
                bit_count <= 6'b0;
                flush_pending <= flush;
                done <= 1'b1;
                busy <= flush;
            end
        end
    end

endmodule
