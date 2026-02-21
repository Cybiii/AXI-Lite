# AXI-Lite

AXI-Lite (Advanced eXtensible Interface Lite) is a simplified subset of the ARM AMBA AXI protocol for memory-mapped register and control interfaces. It uses valid/ready handshaking on each channel, supports only single-beat (non-burst) transactions, and omits features like QoS, locking, and caching. Its simplicity makes it well-suited for low-bandwidth control paths, peripheral configuration, and interconnect between masters (e.g. CPUs) and slaves (e.g. registers, memories).

Parameterizable AXI-Lite crossbar implementation. Building blocks:

- **1×1** — Passthrough.
- **1×M** — One master, M slaves. Address decoding; DECERR for unmapped regions.
- **N×1** — N masters, one slave. Round-robin arbitration.
- **N×M** — Full crossbar (1×M + N×1 composed).

## Run simulation

```bash
make xcelium_1xM    # 1 master, M slaves
make xcelium_Nx1    # N masters, 1 slave
make clean
```

Requires Cadence Xcelium.

## Formal verification

- SVA properties in `formal/axi_lite_props.sv`.
- JasperGold scripts in `scripts/jaspergold/`.

## Structure

- `axi_lite/` — RTL (interfaces, bridges, arbiter)
- `tb/` — testbenches
- `scripts/` — Xcelium and JasperGold scripts
