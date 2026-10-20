# Parameterized Synchronous FIFO Buffer (SystemVerilog)

A fully synthesizable, parameterized synchronous First-In First-Out (FIFO) memory queue implemented in **SystemVerilog (IEEE 1800-2012)**. Designed for on-chip buffering, cross-module pipeline decoupling, and rate-matching between synchronous digital IP blocks.

---

## 🏛️ Architecture & Microarchitecture

The core employs an internal SRAM register array configured with dual circular pointers. It resolves the classic FIFO boundary ambiguity (differentiating between full and empty states when write and read addresses match) by utilizing an **$(N+1)$-bit pointer rollover scheme**, where $N = \log_2(\text{FIFO\_DEPTH})$.

```
           +-------------------------------------------------------+
           |                   SYNCHRONOUS FIFO                    |
           |                                                       |
wr_data -->|  +-------------------------------------------------+  |--> rd_data
wr_en   -->|  |  Dual-Port Memory Storage [0 : FIFO_DEPTH - 1]  |  |
           |  +-------------------------------------------------+  |
           |           ^                               ^           |
           |           | wr_ptr[N-1:0]   rd_ptr[N-1:0] |           |
           |    [Write Pointer]                 [Read Pointer]     |
           |           |                               |           |
           |           +--------------+ +--------------+           |
           |                          | |                          |
           |                     [Comparator]                      |
           |                          | |                          |
           |                          v v                          |
           |                     empty   full                      |
           +-------------------------------------------------------+
```

### 1. Pointer Rollover Mathematics
For a FIFO depth of $2^N$:
- **Write Pointer (`wr_ptr`):** $(N+1)$ bits wide.
- **Read Pointer (`rd_ptr`):** $(N+1)$ bits wide.
- Lower $N$ bits index the physical memory array (`wr_ptr[N-1:0]`, `rd_ptr[N-1:0]`).
- The $(N+1)$-th bit represents the wrap-around/rollover status.

$$\text{empty} = (\text{wr\_ptr} == \text{rd\_ptr})$$

$$\text{full} = \left(\text{wr\_ptr}[N-1:0] == \text{rd\_ptr}[N-1:0]\right) \;\land\; \left(\text{wr\_ptr}[N] \neq \text{rd\_ptr}[N]\right)$$

This mathematical formulation guarantees zero-latency, combinational flag generation without needing an up/down counter that would introduce critical path timing bottlenecks.

---

## ⚙️ Parameters & Port Interface

### Module Parameters
| Parameter | Default | Description |
| :--- | :---: | :--- |
| `DATA_WIDTH` | `8` | Bit-width of data bus (`wr_data` and `rd_data`) |
| `FIFO_DEPTH` | `16` | Total storage capacity (must be a power of 2) |

### Signal Interface
| Signal | Direction | Width | Description |
| :--- | :---: | :---: | :--- |
| `clk` | Input | 1 | System clock (active high) |
| `rst_n` | Input | 1 | Asynchronous active-low system reset |
| `wr_en` | Input | 1 | Active-high write enable |
| `rd_en` | Input | 1 | Active-high read enable |
| `wr_data` | Input | `DATA_WIDTH` | Parallel write data bus |
| `full` | Output | 1 | Asserted when FIFO memory is completely full |
| `empty` | Output | 1 | Asserted when FIFO memory has zero valid elements |
| `rd_data` | Output | `DATA_WIDTH` | Synchronous registered read output |

---

## 🧪 Pre-Silicon Verification Suite

The repository includes a comprehensive, self-checking SystemVerilog testbench (`tb/tb_fifo.sv`) utilizing an interface (`tb/fifo_if.sv`) and an independent algorithmic reference scoreboard.

### Verified Scenarios:
1. **Power-on Reset:** Validates that `empty == 1` and `full == 0` upon active-low reset assertion.
2. **Single-Element Integrity:** Validates single write and read cycles, checking data retention and flag transitions.
3. **Burst Capacity Fill:** Drives $N$ consecutive write bursts to verify assertion of `full == 1` on the exact boundary cycle.
4. **Overflow Protection:** Attempts illegal writes when full; verifies write pointer holds and stored data is preserved.
5. **Burst Capacity Drain:** Drains all $N$ elements; verifies strict First-In First-Out ordering and transition to `empty == 1`.
6. **Underflow Protection:** Attempts illegal reads when empty; verifies read pointer holds without memory corruption.
7. **Simultaneous Read & Write Throughput:** Drives concurrent `wr_en` and `rd_en` in the same clock cycle, validating continuous pipeline throughput.

---

## 🚀 Simulation & Waveform Reproduction

### Prerequisites
- [Icarus Verilog](http://iverilog.icarus.com/) (`iverilog` $\ge$ v12.0)
- [GTKWave](http://gtkwave.sourceforge.net/) (for waveform viewing)

### Running Simulation via Command Line
```powershell
# Navigate to repository root
cd systemverilog-synchronous-fifo

# Compile RTL and Testbench using IEEE 1800-2012 mode
iverilog -g2012 -o sim.vvp rtl/fifo.sv tb/fifo_if.sv tb/tb_fifo.sv

# Execute simulation runtime
vvp sim.vvp
```

### Expected Output
```text
============================================================
[INFO] Starting Synchronous FIFO Self-Checking Testbench
============================================================
[PASS] Scenario 1: Power-on Reset verified (empty=1, full=0).
[PASS] Scenario 2: Single Write & Read data integrity verified.
[PASS] Scenario 3: Burst Write to Full capacity verified (full=1).
[PASS] Scenario 4: Overflow Protection verified (pointer held).
[PASS] Scenario 5: Burst Read to Empty verified (empty=1).
[PASS] Scenario 6: Underflow Protection verified.
[PASS] Scenario 7: Simultaneous Read & Write throughput verified.
============================================================
>>> ALL 7 FIFO VERIFICATION SCENARIOS PASSED WITH 0 ERRORS <<<
============================================================
```

### Inspecting Waveforms
```powershell
gtkwave sim_fifo.vcd
```

---

## 📂 Repository Structure
```
systemverilog-synchronous-fifo/
├── rtl/
│   └── fifo.sv          # Synthesizable FIFO core logic
├── tb/
│   ├── fifo_if.sv       # SystemVerilog verification interface
│   └── tb_fifo.sv       # 7-scenario self-checking testbench
├── sim/
│   └── run_sim.bat      # One-click Windows compilation script
├── .gitignore           # Ignores simulation binaries & VCD dumps
└── README.md            # Architectural documentation & test report
```

---

## 👤 Author
**Lee Ern De**  
Undergraduate, Bachelor of Electrical Engineering (Honours)  
Universiti Malaya (UM), Kuala Lumpur  
LinkedIn: [linkedin.com/in/ern-de-lee-106b953ab](https://linkedin.com/in/ern-de-lee-106b953ab)
