set_elaborate_option -top bridge_1xM
# Or for bridge_Nx1: set_elaborate_option -top bridge_Nx1

read_file -type systemverilog axi_lite/interface.sv
read_file -type systemverilog axi_lite/address_decoder.sv
read_file -type systemverilog axi_lite/rr_arbiter.sv
read_file -type systemverilog axi_lite/bridge_1x1.sv
read_file -type systemverilog axi_lite/bridge_1xM.sv
read_file -type systemverilog axi_lite/bridge_Nx1.sv

elaborate
