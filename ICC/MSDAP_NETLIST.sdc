###################################################################

# Created by write_sdc on Thu Nov 22 18:42:34 2018

###################################################################
set sdc_version 2.0

set_units -time ns -resistance kOhm -capacitance pF -voltage V -current mA
create_clock [get_ports sclk]  -period 40  -waveform {0 20}
create_clock [get_ports dclk]  -period 1302  -waveform {0 651}
set_input_delay -clock sclk  1  [get_ports reset]
set_input_delay -clock sclk  1  [get_ports start]
set_input_delay -clock dclk  1  [get_ports inputL]
set_input_delay -clock dclk  1  [get_ports inputR]
set_input_delay -clock dclk  1  [get_ports frame]
set_output_delay -clock sclk  1  [get_ports outputL]
set_output_delay -clock sclk  1  [get_ports outputR]
set_output_delay -clock sclk  1  [get_ports inReady]
set_output_delay -clock dclk  1  [get_ports outReady]
set_input_transition -max 0.2  [get_ports sclk]
set_input_transition -min 0.2  [get_ports sclk]
set_input_transition -max 0.2  [get_ports dclk]
set_input_transition -min 0.2  [get_ports dclk]
