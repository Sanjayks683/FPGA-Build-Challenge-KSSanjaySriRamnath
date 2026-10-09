
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
    CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {50.000000}] \
    [get_bd_cells processing_system7_0]


create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_ps7_0_50M
set_property -dict [list CONFIG.C_EXT_RESET_HIGH {0}] [get_bd_cells rst_ps7_0_50M]


create_bd_cell -type module -reference neurocore_top neurocore_top_0


apply_bd_automation -rule xilinx.com:bd_rule:axi4 \
    -config {Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/processing_system7_0/M_AXI_GP0} Slave {/neurocore_top_0/s_axi} ddr_seg {Auto} intc_ip {New AXI Interconnect} master_apm {0}} \
    [get_bd_intf_pins neurocore_top_0/s_axi]


catch {
    connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] \
                   [get_bd_pins neurocore_top_0/sys_clk] \
                   [get_bd_pins rst_ps7_0_50M/slowest_sync_clk] \
                   [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK]
}
catch {
    connect_bd_net [get_bd_pins processing_system7_0/FCLK_RESET0_N] \
                   [get_bd_pins rst_ps7_0_50M/ext_reset_in]
}
catch {
    connect_bd_net [get_bd_pins rst_ps7_0_50M/peripheral_aresetn] \
                   [get_bd_pins neurocore_top_0/sys_rst_n]
}



create_bd_port -dir O -from 3 -to 0 led
connect_bd_net [get_bd_pins neurocore_top_0/led] [get_bd_ports led]


create_bd_port -dir O -from 2 -to 0 rgb_led0
connect_bd_net [get_bd_pins neurocore_top_0/rgb_led0] [get_bd_ports rgb_led0]


create_bd_port -dir I -from 1 -to 0 btn
connect_bd_net [get_bd_pins neurocore_top_0/btn] [get_bd_ports btn]


assign_bd_address
catch {
    set seg [get_bd_addr_segs {processing_system7_0/Data/SEG_neurocore_top_0_reg0}]
    set_property offset 0x40000000 $seg
    set_property range 64K $seg
}
validate_bd_design
save_bd_design


set wrapper [make_wrapper -files [get_files system.bd] -top]
add_files -norecurse $wrapper
set_property top system_wrapper [current_fileset]
update_compile_order -fileset sources_1
puts "Created system_wrapper successfully for NeuroCore-32."
