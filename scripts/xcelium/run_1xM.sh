#!/bin/bash
# Xcelium simulation - bridge_1xM
# Run from project root: ./scripts/xcelium/run_1xM.sh

xrun -64bit -sv -timescale 1ns/1ps -f scripts/xcelium/files.f -top tb_bridge_1xM -input scripts/xcelium/run_1xM.tcl
