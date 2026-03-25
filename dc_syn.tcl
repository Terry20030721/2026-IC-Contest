set DESIGN "REFRACT"
set_host_options -max_cores 16
##############
#Read All Files
##############
analyze -format verilog  ${DESIGN}.v
#analyze -format sverilog  ${DESIGN}.v
elaborate ${DESIGN}
link
current_design ${DESIGN}

set_operating_conditions -max_library slow -max slow
set_wire_load_model -name tsmc13_wl10 -library slow

#Setting Clock Constraints
source -echo -verbose ${DESIGN}.sdc
set_fix_hold                [all_clocks]
check_design
set high_fanout_net_threshold 0
uniquify
set_fix_multiple_port_nets -all -buffer_constants [get_designs *]
#set_max_area 0
#Synthesis all design
#compile -map_effort high -area_effort high
#compile -map_effort high -area_effort high -inc
compile_ultra

write -format ddc     -hierarchy -output "${DESIGN}_syn.ddc"
write_sdf -version 1.0  ${DESIGN}_syn.sdf
write -format verilog -hierarchy -output ${DESIGN}_syn.v
report_area > area.log
report_timing > timing.log
report_qor   >  ${DESIGN}_syn.qor
#write_parasitics -output ${DESIGN}_syn.spef
exit
