



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

puts "========================================================================"
puts " Project Restored! Open ./vivado_proj/${project_name}.xpr in Vivado GUI."
puts "========================================================================"
