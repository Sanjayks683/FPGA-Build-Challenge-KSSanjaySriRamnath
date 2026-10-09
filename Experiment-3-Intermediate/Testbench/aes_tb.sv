`default_nettype none
`timescale 1ns/1ps


module aes_tb;
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

    aes_top dut (.*);

    always #5 sys_clk = ~sys_clk;


    localparam logic [255:0] KEY        = 256'h000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f;
    localparam logic [127:0] PLAINTEXT  = 128'h00112233445566778899aabbccddeeff;
    localparam logic [127:0] CIPHERTEXT = 128'h8ea2b7ca516745bfeafc49904b496089;

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


    task automatic write_block(input logic [127:0] block);
        int i;
        begin
            for (i = 0; i < 4; i = i + 1)
                axi_write(32'h20 + 4 * i, block[127 - 32 * i -: 32]);
        end
    endtask


    task automatic read_block(output logic [127:0] block);
        logic [31:0] word;
        int i;
        begin
            for (i = 0; i < 4; i = i + 1) begin
                axi_read(32'h30 + 4 * i, word);
                block[127 - 32 * i -: 32] = word;
            end
        end
    endtask


    task automatic run_block(input logic is_decrypt);
        logic [31:0] status;
        int guard;
        begin
            axi_write(32'h00, is_decrypt ? 32'h2 : 32'h1);
            status = 0;
            guard = 0;
            while (!status[1] && guard < 100) begin
                axi_read(32'h04, status);
                guard = guard + 1;
            end
            if (!status[1]) $fatal(1, "the engine never reported done");
        end
    endtask

    logic [31:0]  value;
    logic [127:0] result;
    int i;

    initial begin
        #100 sys_rst_n = 1'b1;
        #100;


        for (i = 0; i < 8; i = i + 1)
            axi_write(32'h50 + 4 * i, KEY[255 - 32 * i -: 32]);
        axi_write(32'h00, 32'h4);

        value = 0;
        while (!value[2]) axi_read(32'h04, value);
        $display("key schedule ready (status = %08h)", value);


        write_block(PLAINTEXT);
        run_block(1'b0);
        read_block(result);
        $display("plaintext  %032h", PLAINTEXT);
        $display("ciphertext %032h", result);
        if (result !== CIPHERTEXT)
            $fatal(1, "encryption gave %032h, expected %032h", result, CIPHERTEXT);
        $display("[PASS] encryption matches the FIPS-197 test vector");


        write_block(CIPHERTEXT);
        run_block(1'b1);
        read_block(result);
        $display("decrypted  %032h", result);
        if (result !== PLAINTEXT)
            $fatal(1, "decryption gave %032h, expected %032h", result, PLAINTEXT);
        $display("[PASS] decryption recovered the original block");


        for (i = 0; i < 8; i = i + 1) begin
            axi_read(32'h50 + 4 * i, value);
            if (value != 32'h0) $fatal(1, "key word %0d read back as %08h", i, value);
        end
        $display("[PASS] the key registers read back as zero");

        axi_read(32'h40, value);
        $display("blocks processed: %0d", value);
        if (value != 32'd2) $fatal(1, "block counter is %0d, expected 2", value);

        $display("ALL AES-256 VERIFICATION TESTS PASSED SUCCESSFULLY");
        $finish;
    end

    initial begin
        #500000;
        $fatal(1, "TIMEOUT");
    end
endmodule
