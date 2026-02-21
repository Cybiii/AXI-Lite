@echo off
REM Xcelium simulation - bridge_Nx1
REM Run from project root: scripts\xcelium\run_Nx1.bat

xrun -64bit -sv -f scripts/xcelium/files.f -top tb_bridge_Nx1 -input scripts/xcelium/run_Nx1.tcl
