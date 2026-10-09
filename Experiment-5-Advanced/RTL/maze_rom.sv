`default_nettype none


module maze_rom #(


    parameter logic [63:0] DEFAULT_MAZE = {
        8'b00011000,
        8'b00000010,
        8'b10111110,
        8'b00000000,
        8'b01101111,
        8'b01000000,
        8'b01010110,
        8'b00010000
    }
)(
    input  wire        clk,
    input  wire        rst_n,


    input  wire        axi_we,
    input  wire [63:0] axi_maze_data,

    output wire [63:0] current_maze
);

    reg [63:0] maze_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            maze_reg <= DEFAULT_MAZE;
        end else if (axi_we) begin
            maze_reg <= axi_maze_data;
        end
    end

    assign current_maze = maze_reg;

endmodule

`default_nettype wire
