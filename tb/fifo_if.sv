// =============================================================================
// File: tb/fifo_if.sv
// Interface: fifo_if
// Description: Standard SystemVerilog Verification Interface
// Standard: SystemVerilog IEEE 1800-2012
// =============================================================================

`timescale 1ns / 1ps

interface fifo_if #(
    parameter int DATA_WIDTH = 8
)(
    input logic clk
);

    logic                  rst_n;
    logic                  wr_en;
    logic                  rd_en;
    logic [DATA_WIDTH-1:0] wr_data;
    logic                  full;
    logic                  empty;
    logic [DATA_WIDTH-1:0] rd_data;

    // Design Under Test (DUT) Modport
    modport dut (
        input  clk,
        input  rst_n,
        input  wr_en,
        input  rd_en,
        input  wr_data,
        output full,
        output empty,
        output rd_data
    );

    // Testbench Modport
    modport tb (
        input  clk,
        output rst_n,
        output wr_en,
        output rd_en,
        output wr_data,
        input  full,
        input  empty,
        input  rd_data
    );

endinterface
