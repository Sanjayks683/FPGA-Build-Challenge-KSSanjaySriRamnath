
if {[current_project -quiet] eq ""} {
    error "Open or create a Vivado project before sourcing create_bd.tcl."
}

create_bd_design "system"
update_compile_order -fileset sources_1


create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 \
    -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable"} \
    [get_bd_cells processing_system7_0]

set_property -dict [list \
    CONFIG.PCW_USE_M_AXI_GP0 {1} \
    CONFIG.PCW_EN_CLK0_PORT {1} \
    CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {100.000000}] \
    [get_bd_cells processing_system7_0]


create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_ps7_0_100M
set_property -dict [list CONFIG.C_EXT_RESET_HIGH {0}] [get_bd_cells rst_ps7_0_100M]


create_bd_cell -type module -reference huffman_top huffman_top_0


apply_bd_automation -rule xilinx.com:bd_rule:axi4 \
    -config {Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/processing_system7_0/M_AXI_GP0} Slave {/huffman_top_0/s_axi} ddr_seg {Auto} intc_ip {New AXI Interconnect} master_apm {0}} \
    [get_bd_intf_pins huffman_top_0/s_axi]


catch {
    connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] \
                   [get_bd_pins huffman_top_0/sys_clk] \
                   [get_bd_pins rst_ps7_0_100M/slowest_sync_clk] \
                   [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK]
}
catch {
    connect_bd_net [get_bd_pins processing_system7_0/FCLK_RESET0_N] \
                   [get_bd_pins rst_ps7_0_100M/ext_reset_in]
}
catch {
    connect_bd_net [get_bd_pins rst_ps7_0_100M/peripheral_aresetn] \
                   [get_bd_pins huffman_top_0/sys_rst_n]
}


create_bd_port -dir O -from 3 -to 0 led
create_bd_port -dir I -from 1 -to 0 sw
connect_bd_net [get_bd_pins huffman_top_0/led] [get_bd_ports led]
connect_bd_net [get_bd_ports sw] [get_bd_pins huffman_top_0/sw]


assign_bd_address
validate_bd_design
save_bd_design


set wrapper [make_wrapper -files [get_files system.bd] -top]
add_files -norecurse $wrapper
set_property top system_wrapper [current_fileset]
update_compile_order -fileset sources_1
puts "Created system_wrapper successfully."
