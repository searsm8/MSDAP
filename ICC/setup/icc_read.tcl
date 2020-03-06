##Below command read in verilog file
read_verilog MSDAP_NETLIST.v
##Below command uniquify the design to remove multiple instances
uniquify_fp_mw_cel
##Below command link the design to libraries`
link
##Below command read in sdc file
read_sdc MSDAP_NETLIST.sdc

