##Below commands create ICC's design library
lappend search_path "/home/eng/z/zxb107020/synopsys"
set target_library "ss_1v62_125c.db ff_1v98_0c.db io_max.db io_min.db"
set link_library "$target_library tt_1v8_25c.db io_typ.db"
set mw_logic0_net VSS
set mw_logic1_net VDD
set_tlu_plus_files -max_tluplus /home/eng/x/xxw122030/starrc/SmicSP4R_018_epm_p2mt6_cell_max.tlup -min_tluplus /home/eng/x/xxw122030/starrc/SmicSP4R_018_epm_p2mt6_cell_min.tlup -tech2itf_map /home/eng/x/xxw122030/starrc/SmicSP4R_018_epm_p2mt6_cell_18335155.map

##Below commands create Milkway database
create_mw_lib -technology "/home/eng/z/zxb107020/astro/tf/smic18m_6lm.tf" -mw_reference_library "/home/eng/z/zxb107020/astro/smic18m /home/eng/z/zxb107020/std-io/SP018EE_V0p5/apollo/SP018EE_V0p5_6MT" MSDAP.mw 

##Open new created library
open_mw_lib MSDAP.mw

