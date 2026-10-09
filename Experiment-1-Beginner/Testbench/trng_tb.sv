`default_nettype none
`timescale 1ns/1ps


module trng_tb;
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

    logic [3:0] btn = 4'b0;
    wire  [3:0] led;
    wire  [2:0] rgb_led0, rgb_led1;

    trng_top dut (.*);

    always #5 sys_clk = ~sys_clk;

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

    logic [31:0] value, word0, word1;

    initial begin
        #100 sys_rst_n = 1'b1;
        #100;


        axi_read(32'h0C, value);
        if (value != 32'd6) $fatal(1, "window register reset to %0d, expected 6", value);


        axi_write(32'h0C, 32'd0);
        axi_read(32'h0C, value);
        if (value != 32'd0) $fatal(1, "window register reads %0d after writing 0", value);


        axi_read(32'h08, value);
        if (value != 32'd0) $fatal(1, "empty FIFO returned %08h", value);

        axi_write(32'h00, 32'd1);
        #100000;

        axi_read(32'h04, value);
        $display("status = %08h (%0d words waiting)", value, value >> 16);
        if (value[0]) $fatal(1, "no random words were produced");
        if (!led[1])  $fatal(1, "LED1 should be lit while words are waiting");

        axi_read(32'h08, word0);
        axi_read(32'h08, word1);
        $display("random words: %08h %08h", word0, word1);
        if (word0 == word1) $fatal(1, "two reads gave the same word; generator looks stuck");

        $display("PASS: TRNG produced random words over AXI");
        $finish;
    end


    initial begin
        #2000000;
        $fatal(1, "TIMEOUT");
    end
endmodule
