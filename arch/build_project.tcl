
# Build a PHANTOM hardware design
#
# This script constructs a Vivado project that implements a PHANTOM-compatible FPGA design.
# Should be executed from the command line using Vivado in batch mode as follows:
#    vivado -mode batch -source build_project.tcl -quiet -notrace -tclargs proj ~ xilinx.com:zc706:part0:1.3 ip1 ip2 ip3
#
#  argv[0] = project name
#  argv[1] = path in which to create project
#  argv[2] = Board part to target
#  all subsequent arguments are the IP cores to add to the project.
#
# IP cores should be placed in the phantom_ip directory.
# 

# Read command line arguments
if {[llength $argv] < 3} {
	puts "Warning: Required arguments <project name> <project path> <board part> \[<ip core>\]"
	puts "Using default values."

	set proj_name "testing"
	set proj_path "~"
	set brd_part "xilinx.com:zc706:part0:1.3"
	set ips [list phantom_dummy_2 phantom_dummy_4]
} else {
	set proj_name [lindex $argv 0]
	set proj_path [lindex $argv 1]
	set brd_part [lindex $argv 2]
	
	set ips ""
	for { set i 3 } { $i < [llength $argv] } { incr i } {
		lappend ips [lindex $argv $i]
	}
}

puts "Creating PHANTOM project $proj_path/$proj_name"
puts "Target board $brd_part"
puts "IPs to include:"
foreach ipname $ips {
	puts "    $ipname"
}


#Determine path to IP cores
set script_path [ file dirname [ file normalize [ info script ] ] ]
set repo_path $script_path/phantom_ip

#Create project
puts "Creating project $proj_path/$proj_name"
create_project -force $proj_name $proj_path/$proj_name
set_property board_part $brd_part [current_project]

set_property ip_repo_paths "$repo_path" [current_project]
update_ip_catalog

create_bd_design "design_1"
update_compile_order -fileset sources_1

#Add the Zynq IP
puts "Adding fixed IP cores"
create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable" }  [get_bd_cells processing_system7_0]

#Enable HP connections
set_property -dict [list CONFIG.PCW_USE_S_AXI_HP0 {1} CONFIG.PCW_USE_S_AXI_HP1 {1} CONFIG.PCW_USE_S_AXI_HP2 {1} CONFIG.PCW_USE_S_AXI_HP3 {1}] [get_bd_cells processing_system7_0]

set current_hp_port 0
set current_num 0

foreach ipname $ips {
	puts "Processing IP $ipname"

	set ip [get_ipdefs -quiet -name $ipname*]
	set num_found [llength $ip]

	if { $num_found == 0 } {
		error "Specified IP $ipname not found in IP repository."
	}
	if { $num_found > 1 } {
		error "Specified IP $ipname not specific enough. $num_found matching IP cores found."
	}

	#Add the PHANTOM core
	set core_name phantom_$current_num
	set current_num [expr $current_num + 1]
	create_bd_cell -type ip -vlnv $ip $core_name

	#Connect slaves
	set slave [get_bd_intf_pins $core_name/S*_AXI]
	if { [llength $slave] != 1 } {
		error "Specified IP $ipname must have exactly one AXI slave connection."
	}
	apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/processing_system7_0/M_AXI_GP0" Clk "Auto" }  $slave

	#Connect masters
	foreach master [get_bd_intf_pins $core_name/M*_AXI] {
		apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config "Master \"$master\" Clk \"Auto\""  [get_bd_intf_pins processing_system7_0/S_AXI_HP$current_hp_port]

		#Round robin connect to the HP ports
		set current_hp_port [expr $current_hp_port + 1]
		if { $current_hp_port == 4 } {
			set current_hp_port 0
		}
	}
}

regenerate_bd_layout
save_bd_design

puts "Project created."


