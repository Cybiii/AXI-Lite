set_elaborate_option -top bridge_1xM
# Or for bridge_Nx1: set_elaborate_option -top bridge_Nx1

# RTL (paths relative to project root; run jasper from project root)
read_file -type systemverilog axi_lite/interface.sv
read_file -type systemverilog axi_lite/address_decoder.sv
read_file -type systemverilog axi_lite/rr_arbiter.sv
read_file -type systemverilog axi_lite/bridge_1x1.sv
read_file -type systemverilog axi_lite/bridge_1xM.sv
read_file -type systemverilog axi_lite/bridge_Nx1.sv

# Formal properties and bind to DUT
read_file -type systemverilog formal/axi_lite_props.sv
read_file -type systemverilog scripts/jaspergold/bind_bridge_1xM.sv

elaborate

# Clock and reset for proof (required; bridge_1xM master port)
clock m_axi.clk
reset -expression "!m_axi.rst_n"

# Run formal proof on all assertions (after elaborate)
# prove -all
# Or in GUI: Proof Setup -> Run Proof / Prove All
