






catch {close_project}

set project_name "rl_agent_project"
set top_module "system_wrapper"


set local_board_repo [file normalize ./board_files]
if {[file isdirectory $local_board_repo]} {
    set_param board.repoPaths [list $local_board_repo]
}
set board_part_name "tul.com.tw:pynq-z2:part0:1.0"


create_project $project_name ./vivado_proj -part xc7z020clg400-1 -force
set_property board_part $board_part_name [current_project]




add_files ../RTL/maze_rom.sv
add_files ../RTL/lfsr_prng.sv
add_files ../RTL/q_table.sv
add_files ../RTL/bellman_update.sv
add_files ../RTL/action_selector.sv
add_files ../RTL/environment.sv
add_files ../RTL/episode_controller.sv
add_files ../RTL/rl_stats.sv
add_files ../RTL/rl_axi_wrapper.sv
add_files ../RTL/rl_agent_top.sv




add_files -fileset constrs_1 ../RTL/pynq_z2.xdc




source ./create_bd.tcl




launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1




set run_status [get_property STATUS [get_runs impl_1]]
if {$run_status ne "write_bitstream Complete!"} {
    error "Implementation did not complete ($run_status); nothing was staged."
}
open_run impl_1
file mkdir ./reports
report_timing_summary -file ./reports/timing_summary.rpt
report_utilization    -file ./reports/utilization.rpt
report_drc            -file ./reports/drc.rpt
set wns [get_property SLACK [lindex [get_timing_paths -delay_type max -max_paths 1] 0]]
set whs [get_property SLACK [lindex [get_timing_paths -delay_type min -max_paths 1] 0]]

puts "========================================================================"
puts " Implementation Status: $run_status"
puts " Timing Closure (STA) : WNS = $wns ns | WHS = $whs ns"
puts "========================================================================"



if {$wns < 0 || $whs < 0} {
    error "Timing not met (WNS = $wns ns, WHS = $whs ns); nothing was staged."
}




file mkdir ../Jupyter


file copy -force ./vivado_proj/${project_name}.runs/impl_1/system_wrapper.bit ../Jupyter/
file copy -force ./vivado_proj/${project_name}.gen/sources_1/bd/system/hw_handoff/system.hwh ../Jupyter/system_wrapper.hwh

puts "========================================================================"
puts " Build Complete! Artifacts staged in ../Jupyter/"
puts "========================================================================"
