



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


create_bd_cell -type module -reference rl_agent_top rl_agent_top_0


apply_bd_automation -rule xilinx.com:bd_rule:axi4 \
    -config {Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/processing_system7_0/M_AXI_GP0} Slave {/rl_agent_top_0/s_axi} ddr_seg {Auto} intc_ip {New AXI Interconnect} master_apm {0}} \
    [get_bd_intf_pins rl_agent_top_0/s_axi]






create_bd_port -dir O -from 3 -to 0 led
connect_bd_net [get_bd_pins rl_agent_top_0/led] [get_bd_ports led]


create_bd_port -dir O -from 2 -to 0 rgb_led0
connect_bd_net [get_bd_pins rl_agent_top_0/rgb_led0] [get_bd_ports rgb_led0]


create_bd_port -dir I -from 1 -to 0 btn
connect_bd_net [get_bd_pins rl_agent_top_0/btn] [get_bd_ports btn]


create_bd_port -dir I -from 0 -to 0 sw
connect_bd_net [get_bd_pins rl_agent_top_0/sw] [get_bd_ports sw]


assign_bd_address [get_bd_addr_segs {rl_agent_top_0/s_axi/reg0}]


validate_bd_design
save_bd_design

set bd_file [get_files system.bd]
set wrapper_file [make_wrapper -files $bd_file -top]
add_files -norecurse $wrapper_file
update_compile_order -fileset sources_1
set_property top system_wrapper [current_fileset]
