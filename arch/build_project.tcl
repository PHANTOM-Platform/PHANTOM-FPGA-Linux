
# Build a PHANTOM hardware design
#
# This script constructs a Vivado project that implements a PHANTOM-compatible FPGA design.
# Should be executed from the command line using Vivado in batch mode as follows:
#    vivado -mode batch -source build_project.tcl -quiet -notrace -tclargs proj ~ xilinx.com:zc706:part0:1.3 ip1 mem_size1 ip2 mem_size2 ip3 mem_size3
#
#  argv[0] = project name
#  argv[1] = path in which to create project
#  argv[2] = Board part to target
#  all subsequent arguments are the IP cores to add to the project, and their shared memory allocations.
#
# IP cores should be placed in the phantom_ip directory.
#

set log_buffer ""
proc log {text} {
	upvar log_buffer x
	append x $text "\n"
}

# Read command line arguments
if {[llength $argv] < 3} {
	puts "Warning: Required arguments <project name> <project path> <board part> \[<ip core> <memory size>\] \[<ip core> <memory size>\] ..."
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
	for { set i 3 } { $i < [llength $argv] } { set i [expr $i + 2] } {
		lappend ips [list [lindex $argv $i] [lindex $argv [expr $i + 1]]]
	}
}

if {[llength $ips] > 16} {
	error "Maximum number of IP cores exceeded ([llength $ips] greater than 16)"
}

puts "Creating PHANTOM project $proj_path/$proj_name"
puts "Target board $brd_part"
puts ""
puts "IPs to include:"
foreach ip $ips {
	set ipname [lindex $ip 0]
	set ipmemsize [lindex $ip 1]
	puts "    $ipname ($ipmemsize bytes)"
}
puts ""

puts "Looking up board part '$brd_part'..."
set board_parts [get_board_parts $brd_part]
set num_board_parts_found [llength $board_parts]
if { $num_board_parts_found == 0 } {
	error "    Specified board part '$brd_part' not found in Xilinx tools installation."
}
if { $num_board_parts_found > 1 } {
	error "    Specified board part '$brd_part' not specific enough. $num_board_parts_found matching board parts found."
}
set board_display_name [get_property DISPLAY_NAME $board_parts]
set board_part_name [get_property PART_NAME $board_parts]
puts "    Found board: $board_display_name ($board_part_name)"
puts ""


# Determine path to IP cores
set script_path [ file dirname [ file normalize [ info script ] ] ]
set repo_path $script_path/phantom_ip

# Create project
puts "Creating project $proj_path/$proj_name"
create_project -force $proj_name $proj_path/$proj_name
set_property board_part $brd_part [current_project]

set_property ip_repo_paths "$repo_path" [current_project]
update_ip_catalog

create_bd_design "design_1"
update_compile_order -fileset sources_1

# Create output XML
# Ideally a module like tDOM would be used for this, but no such modules are available in Xilinx's TCL distribution.
set xml_path $proj_path/$proj_name/phantom_fpga_conf.xml
set fp [open $xml_path w]
puts $fp "<?xml version=\"1.0\" encoding=\"utf-8\"?>"
puts $fp "<?phantom conf file version=\"0.1\"?>"
puts $fp ""
puts $fp "<phantom_fpga>"

# Either zynq_apsoc (Zynq 7000) or zynq_mpsoc (Zynq Ultrascale+)
puts $fp "\t<fpga_type>zynq_apsoc</fpga_type>"
puts $fp "\t<target_device>$board_part_name</target_device>"
puts $fp "\t<target_board>$brd_part</target_board>"
puts $fp "\t<target_board_display_name>$board_display_name</target_board_display_name>"
puts $fp "\t<design_name>$proj_name</design_name>"
puts $fp "\t<design_bitfile>bitstream.bit</design_bitfile>"

# Add the Zynq IP
puts "Adding fixed IP cores"
set zynq_ps7 [create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7 processing_system7_0]
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable" } $zynq_ps7

set current_hp_port 0
set current_num 0
set mastermode 1

# Get the size of DDR from the Processing System parameters
set ddrsize [expr [get_property "CONFIG.PCW_DDR_RAM_HIGHADDR" $zynq_ps7] + 1]
puts $fp "\t<ddr_size>$ddrsize</ddr_size>"

set membase $ddrsize

foreach ip $ips {
	set ipname [lindex $ip 0]
	set ipmemsize [lindex $ip 1]
	puts "Processing IP $ipname"

	set ip [get_ipdefs -quiet *$ipname*]
	set num_found [llength $ip]

	if { $num_found == 0 } {
		error "Specified IP $ipname not found in IP repository."
	}
	if { $num_found > 1 } {
		error "Specified IP $ipname not specific enough. $num_found matching IP cores found."
	}

	# Calculate base master interface memory address for this IP core
	set membase [expr $membase - $ipmemsize]

	# Add the PHANTOM core
	set core_name phantom_$current_num
	create_bd_cell -type ip -vlnv $ip $core_name
	
	# Connect slaves
	set slave [get_bd_intf_pins -filter {MODE == Slave} $core_name/*]
	if { [llength $slave] != 1 } {
		error "Specified IP $ipname must have exactly one AXI slave connection."
	}
	apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config "Master \"$zynq_ps7/M_AXI_GP0\" Clk \"Auto\""  $slave

	# Connect masters
	# The block automation rule is different depending on whether we are creating a new connection, or sharing an existing one:
	#	This creates a new connection:
	#		apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config "Master \"/phantom_dummy_4_0/M01_AXI\" Clk \"Auto\" intc_ip \"New AXI SmartConnect\""  [get_bd_intf_pins processing_system7_0/S_AXI_HP3]
	#	This shares an existing one:
	#		apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Slave "/processing_system7_0/S_AXI_HP0" Clk "Auto" }  [get_bd_intf_pins phantom_dummy_4_0/M02_AXI]
	set masters [get_bd_intf_pins -filter {MODE == Master} $core_name/*]
	foreach master $masters {

		# Enable HP connections
		if { $mastermode } {
			set_property -dict [list CONFIG.PCW_USE_S_AXI_HP${current_hp_port} {1}] $zynq_ps7
		}

		set slaveport [get_bd_intf_pins $zynq_ps7/S_AXI_HP$current_hp_port]
		puts "Connecting $master to $slaveport"
		if { $mastermode } {
			apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config "Master \"$master\" Clk \"Auto\" intc_ip \"New AXI SmartConnect\"" $slaveport
		} else {
			apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config "Slave \"$slaveport\" Clk \"Auto\"" $master
		}

		# Set allocated memory range for this component's master interfaces
		foreach addr_space [get_bd_addr_spaces -of_objects $master] {
			puts "Mapping $master to address 0x[format %X $membase]"
			set_property range $ipmemsize [get_bd_addr_segs "$addr_space/SEG_processing_system7_0_HP${current_hp_port}_DDR_LOWOCM"]
			set_property offset $membase [get_bd_addr_segs "$addr_space/SEG_processing_system7_0_HP${current_hp_port}_DDR_LOWOCM"]
		}

		# Round robin connect to the HP ports
		set current_hp_port [expr $current_hp_port + 1]
		if { $current_hp_port == 4 } {
			set current_hp_port 0
			set mastermode 0
		}
	}

	# Set the slave interface address mapping
	# The API is set to assume the addresses of the PHANTOM cores are:
	#	Component 0 : 0x4000_0000
	#	Component 1 : 0x4100_0000
	#	Component 2 : 0x4200_0000
	# 	etc...
	set offset [expr 0x40000000 + $current_num * 0x1000000]
	puts "Mapping $core_name slave to address 0x[format %X $offset]"
	set_property offset $offset [get_bd_addr_segs "$zynq_ps7/Data/SEG_phantom_${current_num}_*reg"]
	set_property range 16M [get_bd_addr_segs "$zynq_ps7/Data/SEG_phantom_${current_num}_*reg"]

	# Print the core's address mapping to log buffer
	log ""
	log "$core_name ($ipname)"
    log "     Slave --  Address: 0x[format %X $offset]  Size: 0x1000000"
    log "    Master --  Address: 0x[format %X $membase]  Size: 0x[format %X $ipmemsize]"

	# Output details to XML
	puts $fp "\t<component_inst>"
	puts $fp "\t\t<name>$core_name</name>"
	puts $fp "\t\t<id>$current_num</id>"
	puts $fp "\t\t<ipname>$ipname</ipname>"
	if {[info exists master]} {
		puts $fp "\t\t<num_masters>[llength $masters]</num_masters>"
	} else {
		puts $fp "\t\t<num_masters>0</num_masters>"
	}
	puts $fp "\t\t<master_addr_base_0>0x[format %X $membase]</master_addr_base_0>"
	puts $fp "\t\t<master_addr_range_0>0x[format %X $ipmemsize]</master_addr_range_0>"
	puts $fp "\t\t<slave_addr_base_0>0x[format %X $offset]</slave_addr_base_0>"
	puts $fp "\t\t<slave_addr_range_0>0x1000000</slave_addr_range_0>"
	puts $fp "\t</component_inst>"

	set current_num [expr $current_num + 1]
}

# Validate the design - this might produce some warnings (some can be ignored)
validate_bd_design

# Regenerate the diagram layout and save up
regenerate_bd_layout
save_bd_design

# Add the HDL wrapper
make_wrapper -files [get_files $proj_path/$proj_name/$proj_name.srcs/sources_1/bd/design_1/design_1.bd] -top
add_files -norecurse $proj_path/$proj_name/$proj_name.srcs/sources_1/bd/design_1/hdl/design_1_wrapper.v
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# Close and save the XML
puts $fp "</phantom_fpga>"
close $fp

puts ""

puts "*************************************"
puts "*  Design Summary"
puts "********************"
puts "FPGA Board: $board_display_name ($brd_part)"
puts "FPGA Part: $board_part_name"
puts $log_buffer
puts "*************************************"
puts ""
puts "Project created."
puts "Hardware information written to $xml_path"
puts ""
