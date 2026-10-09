`default_nettype none
`timescale 1ns/1ps


module neurocore_pynq_tb;
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

    neurocore_top dut (.*);

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


    logic [31:0] program_words [0:1023];
    string       prog_dir;
    logic [31:0] value;
    logic [31:0] cycles, instrs, stalls, branches;
    int          words, i;


    task automatic run_program(input string name);
        begin
            for (i = 0; i < 1024; i = i + 1) program_words[i] = 32'h0;
            $readmemh({prog_dir, name}, program_words);

            words = 0;
            for (i = 0; i < 1024; i = i + 1)
                if (program_words[i] !== 32'hx && program_words[i] !== 32'h0) words = i + 1;

            axi_write(32'h0000, 32'h2);
            #100;
            for (i = 0; i < words; i = i + 1)
                axi_write(32'h1000 + i * 4, program_words[i]);
            $display("loaded %s (%0d instructions)", name, words);

            axi_write(32'h0000, 32'h1);
            value = 0;
            while ((value & 32'h2) == 0) begin
                repeat (20) @(posedge sys_clk);
                axi_read(32'h0004, value);
            end
            $display("program stopped at EBREAK (status %08h)", value);
        end
    endtask

    initial begin
        if (!$value$plusargs("PROG_DIR=%s", prog_dir)) prog_dir = "programs/";

        #100 sys_rst_n = 1'b1;
        #100;


        run_program("fibonacci.hex");


        begin
            logic [31:0] a, b, expected;
            a = 0;
            b = 1;
            for (i = 0; i < 20; i = i + 1) begin
                expected = a;
                axi_read(32'h2100 + i * 4, value);
                if (value !== expected)
                    $fatal(1, "Fibonacci number %0d is %0d, expected %0d", i, value, expected);
                a = b;
                b = expected + b;
            end
        end
        $display("[PASS] the first 20 Fibonacci numbers are correct");

        axi_read(32'h0010, cycles);
        axi_read(32'h0014, instrs);
        axi_read(32'h0018, stalls);
        axi_read(32'h001C, branches);
        $display("  cycles %0d, instructions %0d, stalls %0d, branches %0d",
                 cycles, instrs, stalls, branches);
        $display("  IPC: %0.3f", real'(instrs) / real'(cycles));
        if (instrs == 0 || cycles == 0) $fatal(1, "the performance counters did not count");


        run_program("bubble_sort.hex");

        for (i = 0; i < 16; i = i + 1) begin
            axi_read(32'h2000 + i * 4, value);
            if (value !== i)
                $fatal(1, "sorted array position %0d holds %0d, expected %0d", i, value, i);
        end
        $display("[PASS] the array was sorted into 0 to 15");


        axi_write(32'h0000, 32'h2);
        #100;
        axi_write(32'h2000,  38); axi_write(32'h2004,  41); axi_write(32'h2008,  47); axi_write(32'h200C,  52);
        axi_write(32'h2010,  44); axi_write(32'h2014,  45); axi_write(32'h2018,  39); axi_write(32'h201C,  60);
        axi_write(32'h2020,  33); axi_write(32'h2024,  46); axi_write(32'h2028,  50); axi_write(32'h202C,  42);
        axi_write(32'h2030,  40); axi_write(32'h2034,  55); axi_write(32'h2038,  36); axi_write(32'h203C,  49);
        run_program("sensor_threshold.hex");


        begin
            logic [31:0] expected_flags [0:15];
            expected_flags[0]  = 0; expected_flags[1]  = 0; expected_flags[2]  = 1; expected_flags[3]  = 1;
            expected_flags[4]  = 0; expected_flags[5]  = 1; expected_flags[6]  = 0; expected_flags[7]  = 1;
            expected_flags[8]  = 0; expected_flags[9]  = 1; expected_flags[10] = 1; expected_flags[11] = 0;
            expected_flags[12] = 0; expected_flags[13] = 1; expected_flags[14] = 0; expected_flags[15] = 1;
            for (i = 0; i < 16; i = i + 1) begin
                axi_read(32'h2100 + i * 4, value);
                if (value !== expected_flags[i])
                    $fatal(1, "sensor flag[%0d] is %0d, expected %0d", i, value, expected_flags[i]);
            end
        end
        $display("[PASS] sensor alarm flags are correct");


        run_program("fibonacci.hex");

        axi_read(32'h213C, value);
        if (value !== 610)
            $fatal(1, "EBREAK regression FAIL: F15 is %0d after running sensor_threshold first, expected 610", value);
        $display("[PASS] EBREAK regression: F15 = 610 (post-sensor store was correctly suppressed)");

        $display("PASS: NeuroCore-32 ran all programs correctly");
        $finish;
    end

    initial begin
        #50000000;
        $fatal(1, "TIMEOUT");
    end
endmodule
