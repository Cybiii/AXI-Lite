# AXI-Lite

This AXI-Lite repository is a simplified subset of the ARM AMBA AXI protocol for memory-mapped register and control interfaces. It uses handshaking on each channel, supports only single-beat (non-burst) transactions.

Parameterizable AXI-Lite crossbar implementation. Building blocks (tentative to change):

- **1×1** - Passthrough
- **1×M** - One master, M slaves. Address decoding; DECERR for unmapped regions
- **N×1** - N masters, one slave. Round-robin arbitration
- **N×M** - Full crossbar (1×M + N×1 composed)

## XCelium testbenches

```bash
make xcelium_1xM    # 1 master, M slaves
make xcelium_Nx1    # N masters, 1 slave
make clean
```

Requires Cadence Xcelium.

## Formal verification (JasperGold)

**What JasperGold does:** It proves your **assertions** exhaustively (no test vectors). If a property passes, it holds for all possible inputs and states; if it fails, you get a **counterexample** (waveform/trace) showing why.

**Workflow:**

1. **Start JasperGold** (GUI or batch) and open or create a project (e.g. point project dir to this repo).
2. **Set project root** to the repo root (`/path/to/NoC-experiments`) so file paths in scripts resolve.
3. **Load and run the setup script**  
   In the GUI: run the TCL commands from `scripts/jaspergold/setup.tcl`, or **source** it:
   ```tcl
   cd /path/to/NoC-experiments
   source scripts/jaspergold/setup.tcl
   ```
   This reads the RTL, the SVA properties in `formal/axi_lite_props.sv`, binds them to `bridge_1xM`, and elaborates.
4. **Prove**  
   - **Prove all:** e.g. `prove` or use the “Prove” / “Run Proof” action.  
   - JasperGold will prove each assertion. Green = proven, red = failed (inspect counterexample).
5. **Interpret results**  
   - **Pass:** The AXI-Lite stability properties (valid/ready no combinational loop) hold for the design.  
   - **Fail:** Open the counterexample trace and fix the RTL or relax the property.

**What’s in this repo:**

- **Properties:** `formal/axi_lite_props.sv` — SVA rules that once valid, signals stay valid until handshake (no combinational dependency on ready).
- **Bind:** `scripts/jaspergold/bind_bridge_1xM.sv` — Binds those properties to the master port of `bridge_1xM`.
- **Script:** `scripts/jaspergold/setup.tcl` — Reads RTL + formal files and elaborates; run from project root.

**Tips:**

- Run JasperGold from the **project root** so paths in `setup.tcl` (e.g. `axi_lite/...`, `formal/...`) are correct.
- For **bridge_Nx1**, switch top in `setup.tcl` to `bridge_Nx1` and add a similar bind file for the arbiter/master ports if you want to check the same properties there.
- If the tool reports “Verilog 95” dialect errors, the RTL in `axi_lite/address_decoder.sv` is already written to be Verilog‑95 compatible.

## Structure

- `axi_lite/` — RTL (interfaces, bridges, arbiter)
- `tb/` — testbenches
- `scripts/` — Xcelium and JasperGold scripts
