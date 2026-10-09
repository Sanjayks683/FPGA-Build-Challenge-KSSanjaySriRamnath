

catch {close_project}




set board_part_name "tul.com.tw:pynq-z2:part0:1.0"
set local_board_repo [file normalize ./board_files]
if {[file isdirectory $local_board_repo]} {
    set_param board.repoPaths [list $local_board_repo]
}
create_project trng_project ./vivado_proj -part xc7z020clg400-1 -force
set_property board_part $board_part_name [current_project]


add_files ../RTL/ring_oscillator.sv
add_files ../RTL/trng_sampler.sv
add_files ../RTL/trng_collector.sv
add_files ../RTL/trng_axi_wrapper.sv
add_files ../RTL/trng_top.sv


add_files -fileset constrs_1 ../RTL/pynq_z2.xdc


source ./create_bd.tcl


launch_runs synth_1 -jobs 4
wait_on_run synth_1
if {[get_property STATUS [get_runs synth_1]] ne "synth_design Complete!"} {
    error "Synthesis failed; see vivado_proj/trng_project.runs/synth_1/runme.log"
}
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
if {[get_property STATUS [get_runs impl_1]] ne "write_bitstream Complete!"} {
    error "Implementation failed; see vivado_proj/trng_project.runs/impl_1/runme.log"
}
open_run impl_1
file mkdir ./reports
report_timing_summary -file ./reports/timing_summary.rpt
report_utilization    -file ./reports/utilization.rpt
report_drc            -file ./reports/drc.rpt
set wns [get_property SLACK [lindex [get_timing_paths -delay_type max -max_paths 1] 0]]
set whs [get_property SLACK [lindex [get_timing_paths -delay_type min -max_paths 1] 0]]
puts "Timing Closure (STA): WNS = $wns ns | WHS = $whs ns"

if {$wns < 0 || $whs < 0} {
    error "Timing not met (WNS = $wns ns, WHS = $whs ns); nothing was staged."
}




set impl_dir [get_property DIRECTORY [get_runs impl_1]]
set bitstream [file join $impl_dir system_wrapper.bit]
set hwh_candidates [glob -nocomplain ./vivado_proj/trng_project.gen/sources_1/bd/system/hw_handoff/*.hwh]
if {[llength $hwh_candidates] != 1} {
    error "Build completed, but the generated system HWH file could not be located."
}
set pynq_hwh [file rootname $bitstream].hwh
file copy -force [lindex $hwh_candidates 0] $pynq_hwh


file mkdir ../Jupyter
file copy -force $bitstream ../Jupyter/
file copy -force $pynq_hwh ../Jupyter/
puts "Build complete: $bitstream"
puts "PYNQ hand-off:  $pynq_hwh"
puts "Staged in ../Jupyter/"
