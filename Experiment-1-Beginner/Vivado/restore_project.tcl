
catch {close_project}
set project_name "trng_project"
set local_board_repo [file normalize ./board_files]
set_param board.repoPaths [list $local_board_repo]
create_project $project_name ./vivado_proj -part xc7z020clg400-1 -force
set_property board_part "tul.com.tw:pynq-z2:part0:1.0" [current_project]


add_files ../RTL/ring_oscillator.sv
add_files ../RTL/trng_sampler.sv
add_files ../RTL/trng_collector.sv
add_files ../RTL/trng_axi_wrapper.sv
add_files ../RTL/trng_top.sv


add_files -fileset constrs_1 ../RTL/pynq_z2.xdc


source ./create_bd.tcl

puts "==================================================================="
puts "PROJECT RESTORED SUCCESSFULLY! You can now view the Block Design,"
puts "Schematics, and RTL Analysis for your presentation."
puts "==================================================================="
