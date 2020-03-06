##Below commands dump SDC file and netlist file

write_sdc ./dc_out/MSDAP.sdc
write -hierarchy -format verilog -output ./dc_out/MSDAP_NETLIST.v

