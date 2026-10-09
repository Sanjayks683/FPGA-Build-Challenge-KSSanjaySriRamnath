
catch {close_project}

set project_name "huffman_project"
create_project $project_name ./vivado_proj -part xc7z020clg400-1 -force

set board_part_name "tul.com.tw:pynq-z2:part0:1.0"
set local_board_repo [file normalize ./board_files]
if {[file isdirectory $local_board_repo]} {
    set_param board.repoPaths [list $local_board_repo]
}
set_property board_part $board_part_name [current_project]


add_files ../RTL/huffman_rom.sv
add_files ../RTL/huffman_encoder.sv
add_files ../RTL/huffman_axi_wrapper.sv
add_files ../RTL/huffman_top.sv


add_files -fileset constrs_1 ../RTL/huffman.xdc


source ./create_bd.tcl

puts "==================================================================="
puts "PROJECT 2 RESTORED SUCCESSFULLY!"
puts "You can now view the Block Design, Schematics, and RTL Analysis."
puts "==================================================================="
