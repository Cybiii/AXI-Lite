# AXI-Lite testbench Makefile
# Xcelium simulation

.PHONY: xcelium_1xM xcelium_Nx1 clean

xcelium_1xM:
	xrun -64bit -sv -timescale 1ns/1ps -f scripts/xcelium/files.f -top tb_bridge_1xM -input scripts/xcelium/run_1xM.tcl

xcelium_Nx1:
	xrun -64bit -sv -timescale 1ns/1ps -f scripts/xcelium/files.f -top tb_bridge_Nx1 -input scripts/xcelium/run_Nx1.tcl

clean:
	rm -rf INCA_libs xcelium.log xcelium.key
