set timing_enable_multiple_clocks_per_reg  true
set clk_margin 1.0
set max_fanout 10
create_clock -period 40 -waveform {0 20} [get_ports {sclk}]
create_clock -period 1302 -waveform {0 651} [get_ports {dclk}]
set_input_transition 0.2 [get_ports sclk]
set_input_transition 0.2 [get_ports dclk]
set_input_delay 1.0 -clock sclk  [get_ports reset]
set_input_delay 1.0 -clock sclk  [get_ports start]
set_input_delay 1.0 -clock dclk  [get_ports inputL]
set_input_delay 1.0 -clock dclk  [get_ports inputR]
set_input_delay 1.0 -clock dclk  [get_ports frame]
set_output_delay 1.0  -clock sclk [get_ports outputL]
set_output_delay 1.0  -clock sclk [get_ports outputR]
set_output_delay 1.0  -clock sclk [get_ports inReady]
set_output_delay 1.0  -clock dclk [get_ports outReady]
