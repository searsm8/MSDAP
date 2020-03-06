##Below commands connect power and ground pins
derive_pg_connection -power_net VDD -ground_net VSS
derive_pg_connection -power_net VDD -ground_net VSS -tie

##Create VSS ring
create_rectangular_rings -nets {VSS} \
-left_offset 5 -left_segment_layer METAL5 -left_segment_width 2.0 -extend_ll -extend_lh \
-right_offset 5 -right_segment_layer METAL5 -right_segment_width 2.0 -extend_rl -extend_rh \
-bottom_offset 5 -bottom_segment_layer METAL6 -bottom_segment_width 2.0 -extend_bl -extend_bh \
-top_offset 5 -top_segment_layer METAL6 -top_segment_width 2.0 -extend_tl -extend_th

##Create VDD ring
create_rectangular_rings -nets {VDD} \
-left_offset 12 -left_segment_layer METAL5 -left_segment_width 2.0 -extend_ll -extend_lh \
-right_offset 12 -right_segment_layer METAL5 -right_segment_width 2.0 -extend_rl -extend_rh \
-bottom_offset 12 -bottom_segment_layer METAL6 -bottom_segment_width 2.0 -extend_bl -extend_bh \
-top_offset 12 -top_segment_layer METAL6 -top_segment_width 2.0 -extend_tl -extend_th


##Below commands connect power strap for VDD
create_power_straps  -direction vertical  -start_at 271.25 -num_placement_strap 51 -increment_x_or_y 30 -nets  {VDD}  -layer METAL5 -width 1
##Below commands connect power strap for VSS
create_power_straps  -direction vertical  -start_at 286.25 -num_placement_strap 50 -increment_x_or_y 30 -nets  {VSS}  -layer METAL5 -width 1

##Create pad filler
insert_pad_filler -cell "PFILL50 PFILL5 PFILL20 PFILL2 PFILL10 PFILL1 PFILL01 PFILL001" \
-overlap_cell "PFILL001"

##Create pad rings
create_pad_rings -create pg \
-route_pins_on_layer METAL6




