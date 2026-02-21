@echo off
REM Xcelium simulation - bridge_1xM
REM Run from project root: scripts\xcelium\run_1xM.bat

xrun -64bit -sv -timescale 1ns/1ps -f scripts/xcelium/files.f -top tb_bridge_1xM -input scripts/xcelium/run_1xM.tcl
