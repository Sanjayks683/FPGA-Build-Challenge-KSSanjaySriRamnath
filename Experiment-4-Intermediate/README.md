# Experiment 4: NeuroCore-32 RISC-V Processor

**Level:** Intermediate | **Board:** PYNQ-Z2 (Zynq-7000 XC7Z020) | **Fabric clock:** 50 MHz

A 5-stage pipelined RV32I processor with forwarding, a hazard unit, a 16-entry branch target buffer with 2-bit counters, 4 KB instruction and data memories and four performance counters. The ARM loads a program over AXI4-Lite, starts the core, waits for EBREAK and reads the results.

The full report is [Documentation/Experiment4_NeuroCore32_Report.pdf](Documentation/Experiment4_NeuroCore32_Report.pdf).

## Folder contents

| Path | Contents |
| :--- | :--- |
| `Documentation/` | experiment report (PDF) and `hardware_results.txt` (recorded board test log) |
| `RTL/` | SystemVerilog modules (top module `neurocore_top.sv`) and the `.xdc` constraints file |
| `Testbench/` | self-checking testbench |
| `Simulation/` | `waveform.png`, `transcript.txt`, `simulation_report.pdf`, and `wave_dump.sv` (records a fresh VCD during simulation) |
| `Images/` | `block_diagram.png`, `rtl_schematic.png`, `board_setup.jpg`, `hardware_output.jpg` |
| `Vivado/` | `build.tcl`, `create_bd.tcl`, `restore_project.tcl`, `board_files/` (PYNQ-Z2 preset), and timing/utilization reports |
| `Jupyter/` | `neurocore_demo.ipynb`, `system_wrapper.bit` / `.hwh`, required support files, and `output/` (recorded board log and graphs) |
| `Testbench/programs/` | asm.py (small assembler) and the three .hex programs |
| `Images/rtl_schematic_core.png` | schematic inside riscv_core |
| `Video_Link.txt` | link to the demonstration video |

## Simulation

Run inside `Simulation/` (Icarus Verilog 12):

```powershell
iverilog -g2012 -o core_sim.vvp -s neurocore_pynq_tb -s wave_dump ../RTL/defines.sv ../RTL/branch_predictor.sv ../RTL/data_mem.sv ../RTL/debouncer.sv ../RTL/ex_stage.sv ../RTL/forwarding_unit.sv ../RTL/hazard_unit.sv ../RTL/id_stage.sv ../RTL/if_stage.sv ../RTL/instr_mem.sv ../RTL/mem_stage.sv ../RTL/perf_counters.sv ../RTL/pipeline_regs.sv ../RTL/wb_stage.sv ../RTL/riscv_core.sv ../RTL/neurocore_axi_wrapper.sv ../RTL/neurocore_top.sv ../Testbench/neurocore_pynq_tb.sv wave_dump.sv
vvp core_sim.vvp +PROG_DIR=../Testbench/programs/
```

Result: `PASS: NeuroCore-32 ran all programs correctly` (Fibonacci, bubble sort, sensor threshold and the EBREAK regression test)

## FPGA build

```powershell
cd Vivado
vivado -mode batch -source build.tcl
```

The script stops unless timing is met, writes `reports/` and copies the bitstream into `Jupyter/`.
Current build: WNS +4.104 ns, WHS +0.022 ns, 4,801 LUTs,
2,347 registers, 0 block RAM tiles.

## Running on the board

Copy the files in `Jupyter/` (not `output/`) into one folder on the PYNQ-Z2 and run `neurocore_demo.ipynb`
(**Kernel -> Restart & Run All**). See the [repository README](../README.md#run-on-the-pynq-z2) for board setup.

## Results on the board (2026-09-18)

* Fibonacci: first 20 numbers correct, 171 instructions in 179 cycles (IPC 0.955), same as simulation
* Bubble sort: array sorted 0 to 15, 1411 instructions in 1575 cycles, 120 stalls, 439 branches
* Sensor threshold (JTAG test): 16 alarm flags correct, 8 readings >= 45 C

**Note:** A store that could still complete after EBREAK was found on the board. It is fixed in `RTL/riscv_core.sv`, checked by test 4 of the testbench, and the bitstream was rebuilt on 2026-09-19. The board results above were taken on 2026-09-18 with the earlier bitstream (report, section 5.3).
