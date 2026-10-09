
catch {close_project}

set project_name "neurocore_project"

set local_board_repo [file normalize ./board_files]
if {[file isdirectory $local_board_repo]} {
    set_param board.repoPaths [list $local_board_repo]
}
set board_part_name "tul.com.tw:pynq-z2:part0:1.0"

create_project $project_name ./vivado_proj -part xc7z020clg400-1 -force
set_property board_part $board_part_name [current_project]


add_files ../RTL/defines.sv
add_files ../RTL/branch_predictor.sv
add_files ../RTL/data_mem.sv
add_files ../RTL/debouncer.sv
add_files ../RTL/ex_stage.sv
add_files ../RTL/forwarding_unit.sv
add_files ../RTL/hazard_unit.sv
add_files ../RTL/id_stage.sv
add_files ../RTL/if_stage.sv
add_files ../RTL/instr_mem.sv
add_files ../RTL/mem_stage.sv
add_files ../RTL/perf_counters.sv
add_files ../RTL/pipeline_regs.sv
add_files ../RTL/wb_stage.sv
add_files ../RTL/riscv_core.sv
add_files ../RTL/neurocore_axi_wrapper.sv
add_files ../RTL/neurocore_top.sv


add_files -fileset constrs_1 ../RTL/pynq_z2.xdc


source ./create_bd.tcl

puts "==================================================================="
puts "PROJECT 4 (NEUROCORE-32 RISC-V) RESTORED SUCCESSFULLY!"
puts "You can now view the Block Design, Schematics, and RTL Analysis."
puts "==================================================================="
