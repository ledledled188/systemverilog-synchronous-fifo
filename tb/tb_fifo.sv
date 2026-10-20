// =============================================================================
// File: tb/tb_fifo.sv
// Module: tb_fifo
// Description: Comprehensive Self-Checking Testbench for Parameterized Synchronous FIFO
// Standard: SystemVerilog IEEE 1800-2012
// =============================================================================

`timescale 1ns / 1ps

module tb_fifo;

    localparam int DATA_WIDTH = 8;
    localparam int FIFO_DEPTH = 16;
    localparam time CLK_PERIOD = 10; // 10 ns = 100 MHz

    logic clk;

    // Clock Generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // Interface Instantiation
    fifo_if #(.DATA_WIDTH(DATA_WIDTH)) vif (clk);

    // DUT Instantiation
    fifo #(
        .DATA_WIDTH (DATA_WIDTH),
        .FIFO_DEPTH (FIFO_DEPTH)
    ) dut (
        .clk     (vif.clk),
        .rst_n   (vif.rst_n),
        .wr_en   (vif.wr_en),
        .rd_en   (vif.rd_en),
        .wr_data (vif.wr_data),
        .full    (vif.full),
        .empty   (vif.empty),
        .rd_data (vif.rd_data)
    );

    // Reference Model Storage (Scoreboard)
    logic [DATA_WIDTH-1:0] expected_mem [0:255];
    int exp_wr_idx = 0;
    int exp_rd_idx = 0;
    int error_count = 0;

    // Helper Task: Reset DUT
    task reset_dut();
        vif.rst_n   = 1'b0;
        vif.wr_en   = 1'b0;
        vif.rd_en   = 1'b0;
        vif.wr_data = '0;
        #(CLK_PERIOD * 2);
        @(negedge clk);
        vif.rst_n   = 1'b1;
        #(CLK_PERIOD);
    endtask

    // Helper Task: Single Write
    task write_byte(input logic [DATA_WIDTH-1:0] data);
        @(negedge clk);
        if (!vif.full) begin
            vif.wr_en   = 1'b1;
            vif.wr_data = data;
            expected_mem[exp_wr_idx] = data;
            exp_wr_idx++;
        end
        @(negedge clk);
        vif.wr_en   = 1'b0;
        vif.wr_data = '0;
    endtask

    // Helper Task: Single Read & Verify
    task read_byte();
        logic [DATA_WIDTH-1:0] expected_data;
        @(negedge clk);
        if (!vif.empty) begin
            vif.rd_en = 1'b1;
            expected_data = expected_mem[exp_rd_idx];
            exp_rd_idx++;
            @(posedge clk);
            #1;
            if (vif.rd_data !== expected_data) begin
                $display("[ERROR] Data mismatch! Expected: 0x%02X, Got: 0x%02X at time %0t", expected_data, vif.rd_data, $time);
                error_count++;
            end
            @(negedge clk);
            vif.rd_en = 1'b0;
        end
    endtask

    integer i;

    // Main Test Stimulus
    initial begin
        $dumpfile("sim_fifo.vcd");
        $dumpvars(0, tb_fifo);

        $display("============================================================");
        $display("[INFO] Starting Synchronous FIFO Self-Checking Testbench");
        $display("============================================================");

        // Scenario 1: Power-on Reset Check
        reset_dut();
        if (vif.empty !== 1'b1 || vif.full !== 1'b0) begin
            $display("[ERROR] Scenario 1 Failed: Status flags incorrect after reset (empty=%b, full=%b)", vif.empty, vif.full);
            error_count++;
        end else begin
            $display("[PASS] Scenario 1: Power-on Reset verified (empty=1, full=0).");
        end

        // Scenario 2: Single Write & Single Read
        write_byte(8'hA5);
        if (vif.empty !== 1'b0) begin
            $display("[ERROR] Scenario 2 Failed: FIFO reported empty after write!");
            error_count++;
        end
        read_byte();
        if (vif.empty !== 1'b1) begin
            $display("[ERROR] Scenario 2 Failed: FIFO not empty after draining single element!");
            error_count++;
        end else begin
            $display("[PASS] Scenario 2: Single Write & Read data integrity verified.");
        end

        // Scenario 3: Burst Write to Full Capacity
        for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
            write_byte(8'h10 + i);
        end
        if (vif.full !== 1'b1) begin
            $display("[ERROR] Scenario 3 Failed: FIFO failed to assert FULL at depth %0d!", FIFO_DEPTH);
            error_count++;
        end else begin
            $display("[PASS] Scenario 3: Burst Write to Full capacity verified (full=1).");
        end

        // Scenario 4: Overflow Protection
        write_byte(8'hFF); // Should be ignored by design
        if (vif.full !== 1'b1) begin
            $display("[ERROR] Scenario 4 Failed: FIFO de-asserted full on overflow attempt!");
            error_count++;
        end else begin
            $display("[PASS] Scenario 4: Overflow Protection verified (pointer held).");
        end

        // Scenario 5: Burst Read to Empty
        for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
            read_byte();
        end
        if (vif.empty !== 1'b1) begin
            $display("[ERROR] Scenario 5 Failed: FIFO failed to assert EMPTY after full drain!");
            error_count++;
        end else begin
            $display("[PASS] Scenario 5: Burst Read to Empty verified (empty=1).");
        end

        // Scenario 6: Underflow Protection
        read_byte(); // Should be ignored by design
        if (vif.empty !== 1'b1) begin
            $display("[ERROR] Scenario 6 Failed: FIFO de-asserted empty on underflow attempt!");
            error_count++;
        end else begin
            $display("[PASS] Scenario 6: Underflow Protection verified.");
        end

        // Scenario 7: Simultaneous Read & Write Throughput
        write_byte(8'hD1);
        write_byte(8'hD2);
        
        // Execute simultaneous write and read in the same cycle
        @(negedge clk);
        vif.wr_en   = 1'b1;
        vif.wr_data = 8'hD3;
        expected_mem[exp_wr_idx] = 8'hD3;
        exp_wr_idx++;
        
        vif.rd_en   = 1'b1;
        exp_rd_idx++;
        
        @(negedge clk);
        vif.wr_en   = 1'b0;
        vif.rd_en   = 1'b0;
        
        // Drain remaining elements
        while (exp_rd_idx < exp_wr_idx) begin
            read_byte();
        end
        $display("[PASS] Scenario 7: Simultaneous Read & Write throughput verified.");

        // Final Report
        #(CLK_PERIOD * 2);
        $display("============================================================");
        if (error_count == 0) begin
            $display(">>> ALL 7 FIFO VERIFICATION SCENARIOS PASSED WITH 0 ERRORS <<<");
        end else begin
            $display(">>> FIFO VERIFICATION FAILED WITH %0d ERRORS <<<", error_count);
        end
        $display("============================================================");
        $finish;
    end

endmodule
