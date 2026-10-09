# Experiment 1: Hardware True Random Number Generator

**Level:** Beginner | **Board:** PYNQ-Z2 (Zynq-7000 XC7Z020) | **Fabric clock:** 100 MHz

Four free-running ring oscillators give random bits from their timing jitter. A sampler XORs them over a window of 2^k clocks, a Von Neumann filter removes bias, and a 1024-word FIFO hands 32-bit random words to the ARM processor over AXI4-Lite. The notebook reads 100,000 bytes and runs the NIST frequency and runs tests.

The full report is [Documentation/Experiment1_TRNG_Report.pdf](Documentation/Experiment1_TRNG_Report.pdf).

## Folder contents

| Path | Contents |
| :--- | :--- |
| `Documentation/` | experiment report (PDF) and `hardware_results.txt` (recorded board test log) |
| `RTL/` | SystemVerilog modules (top module `trng_top.sv`) and the `.xdc` constraints file |
| `Testbench/` | self-checking testbench |
| `Simulation/` | `waveform.png`, `transcript.txt`, `simulation_report.pdf`, and `wave_dump.sv` (records a fresh VCD during simulation) |
| `Images/` | `block_diagram.png`, `rtl_schematic.png`, `board_setup.jpg`, `hardware_output.jpg` |
| `Vivado/` | `build.tcl`, `create_bd.tcl`, `restore_project.tcl`, `board_files/` (PYNQ-Z2 preset), and timing/utilization reports |
| `Jupyter/` | `trng_demo.ipynb`, `system_wrapper.bit` / `.hwh`, required support files, and `output/` (recorded board log and graphs) |
| `Video_Link.txt` | link to the demonstration video |

## Simulation

Run inside `Simulation/` (Icarus Verilog 12):

```powershell
iverilog -g2012 -o trng_sim.vvp -s trng_tb -s wave_dump ../RTL/*.sv ../Testbench/trng_tb.sv wave_dump.sv
vvp trng_sim.vvp
```

Result: `PASS: TRNG produced random words over AXI`

## FPGA build

```powershell
cd Vivado
vivado -mode batch -source build.tcl
```

The script stops unless timing is met, writes `reports/` and copies the bitstream into `Jupyter/`.
Current build: WNS +0.530 ns, WHS +0.033 ns, 571 LUTs,
669 registers, 1 block RAM tiles.

## Running on the board

Copy the files in `Jupyter/` (not `output/`) into one folder on the PYNQ-Z2 and run `trng_demo.ipynb`
(**Kernel -> Restart & Run All**). See the [repository README](../README.md#run-on-the-pynq-z2) for board setup.

## Results on the board (2026-09-18)

* JTAG test, 100,000 bytes (k = 6): 50.07 % ones, entropy 7.9979 bits per byte, NIST frequency p = 0.2386 and runs p = 0.2600 (both pass)
* Jupyter run, 100,000 bytes (k = 6) in 2.0 s: 50.02 % ones, entropy 7.9982 bits per byte, NIST frequency p = 0.7628 and runs p = 0.5506 (both pass)
