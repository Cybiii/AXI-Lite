#!/bin/bash
# Xcelium simulation - bridge_Nx1
# Run from project root: ./scripts/xcelium/run_Nx1.sh

xrun -64bit -sv -f scripts/xcelium/files.f -top tb_bridge_Nx1 -input scripts/xcelium/run_Nx1.tcl
