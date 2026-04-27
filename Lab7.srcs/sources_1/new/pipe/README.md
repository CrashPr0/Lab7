# Lab 8 – Pipelined MIPS (Week 2 Waveform Demo)

This folder contains a complete 5-stage pipelined 17-instruction MIPS
processor, wired up with a testbench that computes `4!` and stores `24`
(`0x18`) to data memory.  It is ready to simulate in Vivado's XSim so you
can show the TA waveforms.

## Files

| File                   | Role                                          |
|------------------------|-----------------------------------------------|
| `alu_pipe.v`           | 4-bit op ALU (AND, OR, ADD, SUB, SLT, SLL, SRL) |
| `regfile_pipe.v`       | Register file with WB→ID internal forwarding   |
| `signext_pipe.v`       | 16-bit sign extender                          |
| `controlunit_pipe.v`   | Opcode/funct decoder for all stages           |
| `forwarding_unit.v`    | EX-stage forwarding (EX/MEM and MEM/WB → EX)  |
| `hazard_unit.v`        | Load-use hazard (1-cycle stall)               |
| `multiplier_pipe.v`    | 32×32 unsigned multiplier                     |
| `hilo_reg_pipe.v`      | HI/LO register (written in MEM by MULTU)      |
| `imem_pipe.v`          | Instruction memory (reads `memfile_pipe.dat`) |
| `dmem_pipe.v`          | Data memory (64 words)                        |
| `datapath_pipe.v`      | Pipelined datapath + inline IF/ID/EX/MEM/WB registers |
| `mips_top_pipe.v`      | imem + datapath + dmem                        |
| `tb_mips_pipe.v`       | Testbench (factorial of 4)                    |
| `memfile_pipe.dat`     | Program hex                                   |
| `run.tcl`              | `run all; quit` script for batch XSim         |

## Instruction Support

All 17 Lab 8 instructions decode correctly:

- **R-type:** ADD, SUB, AND, OR, SLT, SLL, SRL, MULTU, MFHI, MFLO, JR
- **I-type:** LW, SW, BEQ, ADDI
- **J-type:** J, JAL

## Pipeline Highlights (points to mention to the TA)

- **IF → ID → EX → MEM → WB**, explicit pipeline registers in `datapath_pipe.v`.
- **Forwarding unit** (`forwarding_unit.v`) handles EX/MEM→EX and MEM/WB→EX.
- **Hazard unit** (`hazard_unit.v`) detects load-use and injects a bubble.
- **Branches (BEQ) and JR** resolve in EX (2-slot flush).
- **J / JAL** resolve in ID (1-slot flush).
- **HI/LO** is written in MEM by MULTU and read at WB by MFHI/MFLO – no
  forwarding required; the pipeline depth guarantees correct ordering.
- **Regfile** has built-in WB→ID forwarding so same-cycle writeback is
  visible to a concurrent ID read.

## Sample Program (`memfile_pipe.dat`)

Iterative factorial of 4 – final result `24` is stored in `dmem[0]`.

```
addi $t0, $0, 4      # $t0 = 4      (N)
addi $v0, $0, 1      # $v0 = 1      (result)
addi $t1, $0, 0      # $t1 = 0      (compare reg)
loop:
  beq $t0, $t1, done # if N == 0, jump to done
  multu $v0, $t0     # HI:LO = $v0 * $t0
  mflo $v0           # $v0 = LO
  addi $t0, $t0, -1  # N = N - 1
  j loop
done:
  sw $v0, 0($0)      # M[0] <= $v0 (final = 24)
end:
  j end              # park here
```

The program exercises ADDI, BEQ, MULTU, MFLO, J, SW, plus the pipeline's
forwarding (MULTU→MFLO, MFLO→MULTU, ADDI→BEQ) and branch/jump flushing.

## How to Run the Simulation in Vivado (GUI, step by step)

1. **Open the project** `Lab7.xpr` in Vivado 2025.1.
2. In the *Sources* panel, right-click **Design Sources** → **Add Sources…**
   - Choose **Add or create design sources**.
   - Click **Add Files**, navigate to
     `Lab7\Lab7.srcs\sources_1\new\pipe\`, and add **every `.v` file
     EXCEPT `tb_mips_pipe.v`** (that one is a testbench).
     - `alu_pipe.v`
     - `regfile_pipe.v`
     - `signext_pipe.v`
     - `controlunit_pipe.v`
     - `forwarding_unit.v`
     - `hazard_unit.v`
     - `multiplier_pipe.v`
     - `hilo_reg_pipe.v`
     - `imem_pipe.v`
     - `dmem_pipe.v`
     - `datapath_pipe.v`
     - `mips_top_pipe.v`
   - Do **not** tick "Copy sources into project" (keeps the files in
     `Lab7.srcs\sources_1\new\pipe\`).
   - Click **Finish**.
3. Right-click **Simulation Sources** → **Add Sources…**
   - Choose **Add or create simulation sources**.
   - Click **Add Files** and select **only** `tb_mips_pipe.v`.
   - Click **Finish**.
4. In the *Sources* panel, under **Simulation Sources → sim_1**, right-click
   `tb_mips_pipe` and **Set as Top**.
5. Click **Run Simulation → Run Behavioral Simulation**.
6. When the waveform window opens, either:
   - Let it auto-run (the testbench calls `$finish` when PC reaches `0x24`),
     or
   - Click **Run All** (⏯) if it stopped at the default 1 us.
7. Zoom out so the first ~400 ns are visible.

### Signals to Add to the Waveform

In the *Scope* panel select `tb_mips_pipe → DUT → dp` (the `datapath_pipe`
instance).  From the *Objects* panel drag these into the waveform:

- `clk`, `rst`
- `PC`
- `instrD`, `instrE`, `instrM`, `instrW`   (the instruction living in each stage)
- `pc_plus4E`, `bta_E`
- `alu_yE`, `alu_outM`, `alu_outW`
- `rd1D`, `rd2D`, `alu_src_a_fwd`, `alu_src_b_fwd`  (to see forwarding at work)
- `fwd_a`, `fwd_b`, `stall`, `ex_redirect`, `id_redirect`, `flush_ifid`, `bubble_idex`
- `hilo_weM_reg`, `mult_outM`, `hi_out`, `lo_out`
- `we_regW_final`, `rf_waW`, `wd_rfW`

Also from `tb_mips_pipe` itself: `we_dm`, `wd_dm`, `rd3` (live `$v0`).

### What the Waveform Should Show

- Reset asserted, then deasserted around 22 ns.
- PC marches 0 → 4 → 8 → 0x0C → 0x10 → …
- At the **BEQ** (when `$t0` finally equals 0) `ex_redirect` pulses and PC
  jumps to `0x20`; watch `flush_ifid` and `bubble_idex` go high for 1 cycle.
- At every **J loop** you see a single-cycle `id_redirect` pulse; IF/ID is
  squashed for one cycle.
- **MULTU** pulses `hilo_weM_reg` in its MEM cycle and `hi_out/lo_out`
  latch the product two cycles before the next **MFLO** commits.
- **SW** at the end puts `0x00000018` (24) on `wd_dm` while `we_dm = 1`.
- `$v0` (signal `rd3` in the testbench) converges to `24` before `$finish`
  is called.

The TCL console should print:

```
[cycle 32]  SW  dmem[0] <= 0x00000018
...
PASS: $v0 == 24
```

## Command-Line Sanity Check (optional)

You can also run everything without the GUI.  From a terminal with the
Vivado 2025.1 `bin` directory on `PATH`:

```
cd Lab7\Lab7.srcs\sources_1\new\pipe
xvlog alu_pipe.v regfile_pipe.v signext_pipe.v controlunit_pipe.v ^
      forwarding_unit.v hazard_unit.v imem_pipe.v dmem_pipe.v ^
      multiplier_pipe.v hilo_reg_pipe.v datapath_pipe.v ^
      mips_top_pipe.v tb_mips_pipe.v
xelab tb_mips_pipe -s tb_snap --debug typical
xsim tb_snap -tclbatch run.tcl
```

You should see the same `PASS: $v0 == 24` message in ~7 seconds.
