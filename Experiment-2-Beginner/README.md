# Experiment 2: Huffman Compression Accelerator

**Level:** Beginner | **Board:** PYNQ-Z2 (Zynq-7000 XC7Z020) | **Fabric clock:** 100 MHz

A Huffman code table in ROM and a bit packer compress text byte by byte into 32-bit words (codes of 3 to 18 bits, 256-word output FIFO). The ARM writes bytes over AXI4-Lite, reads the packed words back and decodes them in Python to prove nothing was lost.

The full report is [Documentation/Experiment2_Huffman_Report.pdf](Documentation/Experiment2_Huffman_Report.pdf).

## Folder contents

| Path | Contents |
| :--- | :--- |
| `Documentation/` | experiment report (PDF) and `hardware_results.txt` (recorded board test log) |
| `RTL/` | SystemVerilog modules (top module `huffman_top.sv`) and the `.xdc` constraints file |
| `Testbench/` | self-checking testbench |
| `Simulation/` | `waveform.png`, `transcript.txt`, `simulation_report.pdf`, and `wave_dump.sv` (records a fresh VCD during simulation) |
| `Images/` | `block_diagram.png`, `rtl_schematic.png`, `board_setup.jpg`, `hardware_output.jpg` |
| `Vivado/` | `build.tcl`, `create_bd.tcl`, `restore_project.tcl`, `board_files/` (PYNQ-Z2 preset), and timing/utilization reports |
| `Jupyter/` | `huffman_demo.ipynb`, `system_wrapper.bit` / `.hwh`, required support files, and `output/` (recorded board log and graphs) |
| `RTL/generate_huffman_table.py` | writes the code table (huffman_table.json) and the ROM contents |
| `Video_Link.txt` | link to the demonstration video |

## Simulation

Run inside `Simulation/` (Icarus Verilog 12):

```powershell
iverilog -g2012 -I ../Testbench -o huffman_sim.vvp -s huffman_tb -s wave_dump ../RTL/*.sv ../Testbench/huffman_tb.sv wave_dump.sv
vvp huffman_sim.vvp
```

Result: `PASS: all Huffman accelerator checks passed`

## FPGA build

```powershell
cd Vivado
vivado -mode batch -source build.tcl
```

The script stops unless timing is met, writes `reports/` and copies the bitstream into `Jupyter/`.
Current build: WNS +2.934 ns, WHS +0.087 ns, 928 LUTs,
746 registers, 0 block RAM tiles.

## Running on the board

Copy the files in `Jupyter/` (not `output/`) into one folder on the PYNQ-Z2 and run `huffman_demo.ipynb`
(**Kernel -> Restart & Run All**). See the [repository README](../README.md#run-on-the-pynq-z2) for board setup.

## Results on the board (2026-09-18)

* 600-byte text: 2764 bits in 87 words, 57.6 % of the original size (1.74 to 1), decoded back exactly (JTAG test and Jupyter run give the same result)
* 897-byte English paragraph (JTAG test): 56.7 % of the original size, decoded back exactly
