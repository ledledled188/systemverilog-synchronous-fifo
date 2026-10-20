// =============================================================================
// File: rtl/fifo.sv
// Module: fifo
// Description: Parameterized Synchronous FIFO Buffer with Circular Pointer Rollover
// Standard: SystemVerilog IEEE 1800-2012 / 2017
// =============================================================================

`timescale 1ns / 1ps

module fifo #(
    parameter int DATA_WIDTH = 8,
    parameter int FIFO_DEPTH = 16
)(
    input  logic                   clk,
    input  logic                   rst_n,
    input  logic                   wr_en,
    input  logic                   rd_en,
    input  logic [DATA_WIDTH-1:0]  wr_data,

    output logic                   full,
    output logic                   empty,
    output logic [DATA_WIDTH-1:0]  rd_data
);

    // Ensure power-of-two depth for clean pointer rollover
    localparam int PTR_WIDTH = $clog2(FIFO_DEPTH);

    // Memory array storage
    logic [DATA_WIDTH-1:0] mem [0:FIFO_DEPTH-1];

    // (PTR_WIDTH + 1) bit pointers to distinguish full from empty
    logic [PTR_WIDTH:0] wr_ptr;
    logic [PTR_WIDTH:0] rd_ptr;

    // -------------------------------------------------------------------------
    // Synchronous Write Logic
    // -------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= '0;
        end else if (wr_en && !full) begin
            mem[wr_ptr[PTR_WIDTH-1:0]] <= wr_data;
            wr_ptr <= wr_ptr + 1'b1;
        end
    end

    // -------------------------------------------------------------------------
    // Synchronous Read Logic
    // -------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr  <= '0;
            rd_data <= '0;
        end else if (rd_en && !empty) begin
            rd_data <= mem[rd_ptr[PTR_WIDTH-1:0]];
            rd_ptr  <= rd_ptr + 1'b1;
        end
    end

    // -------------------------------------------------------------------------
    // Status Flags Generation
    // Empty: Read pointer equals Write pointer
    // Full:  Lower address bits match, but MSB (wrap-around bit) differs
    // -------------------------------------------------------------------------
    assign empty = (wr_ptr == rd_ptr);
    assign full  = ((wr_ptr[PTR_WIDTH-1:0] == rd_ptr[PTR_WIDTH-1:0]) &&
                    (wr_ptr[PTR_WIDTH]     != rd_ptr[PTR_WIDTH]));

endmodule
