@echo off
setlocal
echo ============================================================
echo Compiling SystemVerilog Synchronous FIFO...
echo ============================================================
iverilog -g2012 -o sim.vvp rtl/fifo.sv tb/fifo_if.sv tb/tb_fifo.sv
if %errorlevel% neq 0 (
    echo [ERROR] Compilation failed!
    exit /b %errorlevel%
)

echo.
echo Running VVP Simulation...
echo ============================================================
vvp sim.vvp
if %errorlevel% neq 0 (
    echo [ERROR] Simulation failed!
    exit /b %errorlevel%
)

echo.
echo Simulation completed successfully. VCD waveform saved to sim_fifo.vcd.
