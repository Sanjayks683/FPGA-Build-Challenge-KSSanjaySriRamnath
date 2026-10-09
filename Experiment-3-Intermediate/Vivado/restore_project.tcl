
catch {close_project}

set project_name "aes_project"

set local_board_repo [file normalize ./board_files]
if {[file isdirectory $local_board_repo]} {
    set_param board.repoPaths [list $local_board_repo]
}
set board_part_name "tul.com.tw:pynq-z2:part0:1.0"

create_project $project_name ./vivado_proj -part xc7z020clg400-1 -force
set_property board_part $board_part_name [current_project]


add_files ../RTL/aes_sbox.sv
add_files ../RTL/aes_sub_bytes.sv
add_files ../RTL/aes_shift_rows.sv
add_files ../RTL/aes_mix_columns.sv
add_files ../RTL/aes_add_round_key.sv
add_files ../RTL/aes_round.sv
add_files ../RTL/aes_key_expansion.sv
add_files ../RTL/aes_cipher.sv
add_files ../RTL/aes_axi_wrapper.sv
add_files ../RTL/aes_top.sv


add_files -fileset constrs_1 ../RTL/aes.xdc


source ./create_bd.tcl

puts "==================================================================="
puts "PROJECT 3 (AES-256 ACCELERATOR) RESTORED SUCCESSFULLY!"
puts "You can now view the Block Design, Schematics, and RTL Analysis."
puts "==================================================================="
