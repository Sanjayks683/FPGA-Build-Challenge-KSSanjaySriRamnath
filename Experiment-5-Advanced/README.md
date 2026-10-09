# Experiment 5: Hardware Q-Learning Agent

**Level:** Advanced | **Board:** PYNQ-Z2 (Zynq-7000 XC7Z020) | **Fabric clock:** 50 MHz

A reinforcement-learning agent built entirely in the FPGA fabric learns to solve an 8x8 maze: the maze, the Q-table (64 states x 4 actions, 8.8 fixed point), the 3-stage Bellman update, the epsilon-greedy action selector with a 32-bit LFSR, and the training state machine are all hardware. The ARM only sets the parameters, starts training and reads the results.

The full report is [Documentation/Experiment5_QLearning_Report.pdf](Documentation/Experiment5_QLearning_Report.pdf).

## Folder contents

| Path | Contents |
| :--- | :--- |
| `Documentation/` | experiment report (PDF) and `hardware_results.txt` (recorded board test log) |
| `RTL/` | SystemVerilog modules (top module `rl_agent_top.sv`) and the `.xdc` constraints file |
| `Testbench/` | self-checking testbench |
| `Simulation/` | `waveform.png`, `transcript.txt`, `simulation_report.pdf`, and `wave_dump.sv` (records a fresh VCD during simulation) |
| `Images/` | `block_diagram.png`, `rtl_schematic.png`, `board_setup.jpg`, `hardware_output.jpg` |
| `Vivado/` | `build.tcl`, `create_bd.tcl`, `restore_project.tcl`, `board_files/` (PYNQ-Z2 preset), and timing/utilization reports |
| `Jupyter/` | `rl_demo.ipynb`, `system_wrapper.bit` / `.hwh`, required support files, and `output/` (recorded board log and graphs) |
| `Jupyter/ethernet_visualizer.py` | live view of the learning streamed into the notebook |
| `Video_Link.txt` | link to the demonstration video |

## Simulation

Run inside `Simulation/` (Icarus Verilog 12):

```powershell
iverilog -g2012 -o rl_sim.vvp -s rl_agent_tb -s wave_dump ../RTL/*.sv ../Testbench/rl_agent_tb.sv wave_dump.sv
vvp rl_sim.vvp
```

Result: `PASS: the hardware agent learned to solve the maze` (2000 episodes, 1335 goals, best path 14 steps, Q((7,6), RIGHT) = 96.37)

## FPGA build

```powershell
cd Vivado
vivado -mode batch -source build.tcl
```

The script stops unless timing is met, writes `reports/` and copies the bitstream into `Jupyter/`.
Current build: WNS +2.473 ns, WHS +0.049 ns, 6,576 LUTs,
7,876 registers, 0 block RAM tiles.

## Running on the board

Copy the files in `Jupyter/` (not `output/`) into one folder on the PYNQ-Z2 and run `rl_demo.ipynb`
(**Kernel -> Restart & Run All**). See the [repository README](../README.md#run-on-the-pynq-z2) for board setup.

## Results on the board (2026-09-18)

* 2000 episodes in 4.9 ms (measured from Python), 1335 goals, best path 14 steps (the shortest possible), final epsilon 0.050: identical to the simulation
* Live run in slow mode reached the goal in 14 steps
* Three new mazes loaded over AXI (Corridor Detour, Center Barrier, Zig-Zag Staircase): 14-step path found in each

**Note:** The RGB LED pins were first mapped to LD5; they were corrected to LD4 (N15 / G17 / L15) and the bitstream was rebuilt on 2026-09-19. The board results above were taken on 2026-09-18 with the earlier bitstream (report, section 4.4).
