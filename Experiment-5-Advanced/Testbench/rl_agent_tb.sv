`default_nettype none
`timescale 1ns/1ps


module rl_agent_tb;
    logic sys_clk = 1'b0;
    logic sys_rst_n = 1'b0;

    logic [31:0] s_axi_awaddr = 0, s_axi_wdata = 0, s_axi_araddr = 0;
    logic [2:0]  s_axi_awprot = 0, s_axi_arprot = 0;
    logic [3:0]  s_axi_wstrb = 0;
    logic        s_axi_awvalid = 0, s_axi_wvalid = 0, s_axi_bready = 0;
    logic        s_axi_arvalid = 0, s_axi_rready = 0;
    wire         s_axi_awready, s_axi_wready, s_axi_bvalid;
    wire         s_axi_arready, s_axi_rvalid;
    wire  [1:0]  s_axi_bresp, s_axi_rresp;
    wire  [31:0] s_axi_rdata;

    wire  [3:0]  led;
    wire  [2:0]  rgb_led0;
    logic [1:0]  btn = 2'b00;
    logic [0:0]  sw  = 1'b0;

    rl_agent_top dut (.*);

    always #10 sys_clk = ~sys_clk;

    task automatic axi_write(input logic [31:0] addr, input logic [31:0] data);
        begin
            @(posedge sys_clk);
            s_axi_awaddr  <= addr;
            s_axi_awvalid <= 1'b1;
            s_axi_wdata   <= data;
            s_axi_wstrb   <= 4'hF;
            s_axi_wvalid  <= 1'b1;
            s_axi_bready  <= 1'b1;
            @(posedge sys_clk);
            while (!s_axi_awready) @(posedge sys_clk);
            s_axi_awvalid <= 1'b0;
            s_axi_wvalid  <= 1'b0;
            while (!s_axi_bvalid) @(posedge sys_clk);
            @(posedge sys_clk);
            s_axi_bready <= 1'b0;
        end
    endtask

    task automatic axi_read(input logic [31:0] addr, output logic [31:0] data);
        begin
            @(posedge sys_clk);
            s_axi_araddr  <= addr;
            s_axi_arvalid <= 1'b1;
            s_axi_rready  <= 1'b1;
            @(posedge sys_clk);
            while (!s_axi_arready) @(posedge sys_clk);
            s_axi_arvalid <= 1'b0;
            while (!s_axi_rvalid) @(posedge sys_clk);
            data = s_axi_rdata;
            @(posedge sys_clk);
            s_axi_rready <= 1'b0;
        end
    endtask

    logic [31:0] value, episodes, goals, best;
    logic signed [15:0] q_right;

    initial begin
        #200 sys_rst_n = 1'b1;
        #2000;


        axi_read(32'h08, value);
        if (value[7:0] != 8'h1A) $fatal(1, "alpha reads %02h, expected 1A", value[7:0]);
        axi_read(32'h0C, value);
        if (value[7:0] != 8'hF3) $fatal(1, "gamma reads %02h, expected F3", value[7:0]);
        axi_read(32'h14, value);
        if (value != 32'd2000) $fatal(1, "max episodes reads %0d, expected 2000", value);
        $display("[PASS] default settings: alpha 0x1A, gamma 0xF3, 2000 episodes");


        $display("training on the maze built into the hardware...");
        axi_write(32'h00, 32'h1);

        value = 0;
        while (!value[1]) begin
            #200000;
            axi_read(32'h04, value);
            axi_read(32'h1C, episodes);
            axi_read(32'h34, goals);
            $display("  episode %0d, %0d goals reached", episodes, goals);
        end

        axi_read(32'h1C, episodes);
        axi_read(32'h34, goals);
        axi_read(32'h2C, best);
        $display("finished: %0d episodes, %0d goals, best path %0d steps", episodes, goals, best);

        if (episodes != 32'd2000) $fatal(1, "expected 2000 episodes, got %0d", episodes);
        if (goals == 0)           $fatal(1, "the agent never reached the goal");
        if (best != 32'd14)       $fatal(1, "best path is %0d steps, the shortest is 14", best);
        $display("[PASS] the agent found the shortest path through the maze");


        axi_read(32'h100 + 125 * 4, value);
        q_right = value[31:16];
        $display("Q((7,6), RIGHT) = %0.2f", $itor(q_right) / 256.0);
        if (q_right < 16'sd20480)
            $fatal(1, "the move into the goal was not learned");
        $display("[PASS] the value of stepping into the goal was learned");


        axi_read(32'h300, value);
        $display("history entry 0: goal %0d, %0d steps", value[31], value[23:0]);
        if (value[23:0] == 0) $fatal(1, "the history buffer is empty");

        $display("PASS: the hardware agent learned to solve the maze");
        $finish;
    end

    initial begin
        #100_000_000;
        $fatal(1, "TIMEOUT");
    end
endmodule

`default_nettype wire
