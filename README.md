# AXI-Lite

This AXI-Lite repository is a simplified subset of the ARM AMBA AXI protocol for memory-mapped register and control interfaces. It uses handshaking on each channel, supports only single-beat (non-burst) transactions.

## XCelium testbenches

```bash
make xcelium_1xM    # 1 master, M slaves
make xcelium_Nx1    # N masters, 1 slave
make clean
```

## Structure

- `axi_lite/` — RTL (interfaces, bridges, arbiter)
- `tb/` — testbenches
- `scripts/` — Xcelium and JasperGold scripts
