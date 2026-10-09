# FPGA-Build-Challenge-KSSanjaySriRamnath

V-SPACE FPGA Build Challenge 2026 submission: five SystemVerilog experiments on the AMD PYNQ-Z2, comprising two beginner, two intermediate, and one advanced experiment.

## Team Information

**Team name:** Semicons

| Team member | Role | Registration number |
| :--- | :--- | :--- |
| K S Sanjay Sri Ramnath | Team leader | 24BEC0209 |

**Selected FPGA board:** AMD (TUL) PYNQ-Z2  
**FPGA:** Zynq-7000 XC7Z020, package CLG400, speed grade -1  
**Tools:** Vivado 2026.1, Icarus Verilog 12, PYNQ Linux / Jupyter, Python 3

## Project Summary

| Experiment | Difficulty | What it demonstrates | Report | Video |
| :--- | :--- | :--- | :--- | :--- |
| [1: Hardware True Random Number Generator](Experiment-1-Beginner/) | Beginner | Ring-oscillator timing jitter, XOR sampling, Von Neumann filtering, FIFO collection, and statistical analysis of 100,000 bytes. | [PDF](Experiment-1-Beginner/Documentation/Experiment1_TRNG_Report.pdf) | [Link](Experiment-1-Beginner/Video_Link.txt) |
| [2: Huffman Compression Accelerator](Experiment-2-Beginner/) | Beginner | A canonical Huffman ROM and variable-length bit packer compress text; software decoding verifies lossless recovery. | [PDF](Experiment-2-Beginner/Documentation/Experiment2_Huffman_Report.pdf) | [Link](Experiment-2-Beginner/Video_Link.txt) |
| [3: Pipelined AES-256 Encryption Engine](Experiment-3-Intermediate/) | Intermediate | AES-256 key expansion and a 14-stage encryption/decryption pipeline, checked with the FIPS-197 vector and message round trips. | [PDF](Experiment-3-Intermediate/Documentation/Experiment3_AES256_Report.pdf) | [Link](Experiment-3-Intermediate/Video_Link.txt) |
| [4: NeuroCore-32 RISC-V Processor](Experiment-4-Intermediate/) | Intermediate | A five-stage RV32I processor with forwarding, hazard handling, branch prediction, memories, and performance counters. | [PDF](Experiment-4-Intermediate/Documentation/Experiment4_NeuroCore32_Report.pdf) | [Link](Experiment-4-Intermediate/Video_Link.txt) |
| [5: Hardware Q-Learning Agent](Experiment-5-Advanced/) | Advanced | An FPGA Q-table, epsilon-greedy action selector, Bellman update, maze environment, and episode controller learn an 8x8 maze. | [PDF](Experiment-5-Advanced/Documentation/Experiment5_QLearning_Report.pdf) | [Link](Experiment-5-Advanced/Video_Link.txt) |

The combined documentation is [Semicons_Final_Report.pdf](Final_Report/Semicons_Final_Report.pdf). Each experiment report contains the objective, block diagram, module hierarchy and RTL explanation, simulation waveform and testbench results, hardware implementation evidence, applications, and conclusion.

## Repository Structure

```text
FPGA-Build-Challenge-KSSanjaySriRamnath/
|-- README.md
|-- Experiment-1-Beginner/
|-- Experiment-2-Beginner/
|-- Experiment-3-Intermediate/
|-- Experiment-4-Intermediate/
|-- Experiment-5-Advanced/
|   |-- Documentation/       experiment report PDF and recorded hardware results
|   |-- RTL/                 SystemVerilog modules and XDC constraints
|   |-- Testbench/           self-checking testbench and required program/table files
|   |-- Simulation/          waveform.png, transcript.txt, simulation_report.pdf,
|   |                        and wave_dump.sv
|   |-- Images/              block_diagram.png, rtl_schematic.png,
|   |                        board_setup.jpg, hardware_output.jpg
|   |-- Vivado/              build/restore/block-design TCL, board preset, reports
|   |-- Jupyter/             notebook, matching bitstream/handoff, support files,
|   |                        and recorded outputs
|   |-- README.md
|   +-- Video_Link.txt
+-- Final_Report/
    +-- Semicons_Final_Report.pdf
```

All five experiment folders follow this structure. The `.sv` files are SystemVerilog sources; their descriptive filenames are retained rather than replacing them with the guideline's illustrative `top_module.v` / `tb_top.v` names. `Vivado/` and `Jupyter/` contain the FPGA build and board-deployment deliverables. There are no old `project` folders, generated Vivado projects, simulator caches, report-generation helpers, video-editing assets, or temporary files in this submission.

## Run on the PYNQ-Z2

1. Power the board, boot its PYNQ Linux image from the SD card, and connect the board and computer by Ethernet. Open the board's Jupyter interface using its configured network address.
2. Upload the selected experiment's files from `Jupyter/` into one folder on the board. Keep `system_wrapper.bit` and `system_wrapper.hwh` together with the notebook. The saved `output/` folder is evidence and need not be uploaded to execute the experiment.
3. For Experiment 4, include the `.hex` programs. For Experiment 5, include `ethernet_visualizer.py`.
4. Open the experiment's notebook and choose **Kernel -> Restart & Run All**. Run one experiment at a time; loading another bitstream replaces the current FPGA design. For Experiment 2, keep SW0 down for compression rather than pass-through.
5. Observe the displayed results, graphs, and board LEDs. Experiment 1 values vary with each entropy sample; software test results are demonstrations, not cryptographic certification. Experiment 5's slow mode displays the board-reported maze positions and goal confirmation.

All designs expose an AXI4-Lite register interface at `0x40000000`. The notebooks resolve the IP through the overlay metadata. Fabric clocks are 100 MHz for Experiments 1-3 and 50 MHz for Experiments 4-5.

## Simulation and FPGA Rebuild

Each experiment README contains its simulation command. Run it from that experiment's `Simulation/` folder with Icarus Verilog 12. The self-checking testbench must report PASS and return successfully. `wave_dump.sv` records a fresh VCD file, which can be opened in a waveform viewer. The supplied PNG, transcript, and simulation report preserve the recorded simulation results.

To rebuild an FPGA design, open a Vivado 2026.1 command prompt and run these commands from the selected experiment folder:

```powershell
cd Vivado
vivado -mode batch -source build.tcl
```

Each `Vivado/` folder includes the PYNQ-Z2 board definition; no files from the original development repository are needed. The build checks setup and hold timing before copying new `.bit` and `.hwh` files into `Jupyter/`. To open the design without a full rebuild, run `restore_project.tcl` from the same `Vivado/` directory.

The Huffman table generator and small RISC-V assembler are retained because they are part of those experiment designs. Development-only report builders and waveform plotting helpers are not included.

## Recorded Results and Videos

| Experiment | Recorded functional outcome |
| :--- | :--- |
| 1 | 100,000 hardware-generated bytes; byte distribution, bit balance, autocorrelation, entropy, and frequency/runs tests shown. |
| 2 | 600 input bytes compressed to 2764 bits and decoded back byte-for-byte. |
| 3 | FIPS-197 ciphertext matches; decryption recovers the original plaintext and message. |
| 4 | Fibonacci and bubble sort results are correct; simulation also covers sensor threshold and the post-EBREAK store regression. |
| 5 | 2000 episodes, 1335 goals, best path 14 steps; goal-reaching slow-mode visualization and three additional maze results shown. |

The PDFs and saved logs retain the dates and results of their original runs. The final demonstration videos use separately recorded board and notebook footage with the presenter's own voice; the captures are not claimed to be synchronized. Runtime and TRNG sample statistics may differ between runs. Each video's Google Drive URL is in its experiment's `Video_Link.txt`.
