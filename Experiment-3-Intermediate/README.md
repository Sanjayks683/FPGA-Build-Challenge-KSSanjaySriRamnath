# Experiment 3: Pipelined AES-256 Encryption Engine

**Level:** Intermediate | **Board:** PYNQ-Z2 (Zynq-7000 XC7Z020) | **Fabric clock:** 100 MHz

A 14-stage pipelined AES-256 cipher (encrypt and decrypt) with on-chip key expansion. The pipeline accepts one block per clock; the key registers are write-only. It is checked against the NIST FIPS-197 appendix C.3 test vector and the Python "cryptography" library.

The full report is [Documentation/Experiment3_AES256_Report.pdf](Documentation/Experiment3_AES256_Report.pdf).

## Folder contents

| Path | Contents |
| :--- | :--- |
| `Documentation/` | experiment report (PDF) and `hardware_results.txt` (recorded board test log) |
| `RTL/` | SystemVerilog modules (top module `aes_top.sv`) and the `.xdc` constraints file |
| `Testbench/` | self-checking testbench |
| `Simulation/` | `waveform.png`, `transcript.txt`, `simulation_report.pdf`, and `wave_dump.sv` (records a fresh VCD during simulation) |
| `Images/` | `block_diagram.png`, `rtl_schematic.png`, `board_setup.jpg`, `hardware_output.jpg` |
| `Vivado/` | `build.tcl`, `create_bd.tcl`, `restore_project.tcl`, `board_files/` (PYNQ-Z2 preset), and timing/utilization reports |
| `Jupyter/` | `aes_demo.ipynb`, `system_wrapper.bit` / `.hwh`, required support files, and `output/` (recorded board log and graphs) |
| `Images/rtl_schematic_round.png` | schematic of one AES round |
| `Video_Link.txt` | link to the demonstration video |

## Simulation

Run inside `Simulation/` (Icarus Verilog 12):

```powershell
iverilog -g2012 -o aes_sim.vvp -s aes_tb -s wave_dump ../RTL/*.sv ../Testbench/aes_tb.sv wave_dump.sv
vvp aes_sim.vvp
```

Result: `ALL AES-256 VERIFICATION TESTS PASSED SUCCESSFULLY`

## FPGA build

```powershell
cd Vivado
vivado -mode batch -source build.tcl
```

The script stops unless timing is met, writes `reports/` and copies the bitstream into `Jupyter/`.
Current build: WNS +0.273 ns, WHS +0.010 ns, 26,763 LUTs,
4,922 registers, 0 block RAM tiles.

## Running on the board

Copy the files in `Jupyter/` (not `output/`) into one folder on the PYNQ-Z2 and run `aes_demo.ipynb`
(**Kernel -> Restart & Run All**). See the [repository README](../README.md#run-on-the-pynq-z2) for board setup.

## Results on the board (2026-09-18)

* FIPS-197 C.3: ciphertext 8ea2b7ca516745bfeafc49904b496089 (correct), decryption returns the plaintext
* 48-byte message (3 blocks) encrypted and decrypted correctly; 40 random blocks and 32 avalanche blocks equal to software AES (JTAG test)
* Jupyter run: 0.27 ms per block including the Python register accesses (the cipher itself needs 14 clocks = 140 ns)
