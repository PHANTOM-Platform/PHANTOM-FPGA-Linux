#!/usr/bin/env python3

import argparse
from xml.dom import minidom

"""
This script parses a PHANTOM FPGA Linux hardware configuration XML file and outputs either a device tree overlay or U-Boot environment based on a provided template file.
Run with no options to see all hardware information, or use the options below for specific file generation.
"""

parser = argparse.ArgumentParser(description='PHANTOM FPGA Linux Hardware Environment Generator')
group = parser.add_mutually_exclusive_group()
group.add_argument('--devicetree', action='store_true', help='output device tree, based on template')
group.add_argument('--uenv', action='store_true', help='output U-Boot environment, based on template')
parser.add_argument('config_file', type=str, help='path to PHANTOM hardware platform XML config file')
parser.add_argument('template_file', type=str, help='path to device tree or U-Boot environment template file', nargs='?')
args = parser.parse_args()

doc = minidom.parse(args.config_file, False)

components = doc.getElementsByTagName("component_inst")

if args.devicetree:
	reserved_mem = ''
	master_devices = ''
	slave_devices = ''
	for component in components:
		name = component.getElementsByTagName("name")[0].firstChild.data
		slave_base = component.getElementsByTagName("slave_addr_base_0")[0].firstChild.data
		slave_range = component.getElementsByTagName("slave_addr_range_0")[0].firstChild.data
		slave_devices += '\t\t\t{0}_slave@{1} {{\n\t\t\t\tcompatible = "phantom_platform,generic-uio,ui_pdrv";\n\t\t\t\t#address-cells = <1>;\n\t\t\t\t#size-cells = <1>;\n\t\t\t\treg = <{2} {3}>;\n\t\t\t}};\n'.format(name, slave_base[2:], slave_base, slave_range)
		num_masters = component.getElementsByTagName("num_masters")[0].firstChild.data
		if int(num_masters) > 0:
			master_base = component.getElementsByTagName("master_addr_base_0")[0].firstChild.data
			master_range = component.getElementsByTagName("master_addr_range_0")[0].firstChild.data
			reserved_mem += '\t\t\t\t{0}_master_mem: {0}_master_mem@{1} {{\n\t\t\t\t\tno-map;\n\t\t\t\t\treg = <{2} {3}>;\n\t\t\t\t}};\n'.format(name, master_base[2:], master_base, master_range)
			master_devices += '\t\t\t{0}_master@{1} {{\n\t\t\t\tcompatible = "phantom_platform,generic-uio,ui_pdrv";\n\t\t\t\t#address-cells = <1>;\n\t\t\t\t#size-cells = <1>;\n\t\t\t\treg = <{2} {3}>;\n\t\t\t\tmemory-region = <&{0}_master_mem>;\n\t\t\t}};\n'.format(name, master_base[2:], master_base, master_range)
	with open(args.template_file, 'r') as read_file:
		template = read_file.read()
	output = template.replace('/* PHANTOM RESERVED MEMORY */', reserved_mem)
	output = output.replace('/* PHANTOM MASTERS */', master_devices)
	output = output.replace('/* PHANTOM SLAVES */', slave_devices)
	print(output)

elif args.uenv:
	initrd_fdt_mem_high = components[-1].getElementsByTagName("master_addr_base_0")[0].firstChild.data
	# initrd and fdt must be loaded below 768 MiB (see https://www.denx.de/wiki/DULG/KernelCrashesWithRamdisk)
	if int(initrd_fdt_mem_high, 16) > 0x30000000:
		initrd_fdt_mem_high = '0x30000000'
	with open(args.template_file, 'r') as read_file:
		template = read_file.read()
	output = template.replace('#MEMORY HIGH ADDRESS#', initrd_fdt_mem_high)
	print(output)

else:
	board = doc.getElementsByTagName("target_board_display_name")[0].firstChild.data
	print('Board:', board)
	ddr_size = doc.getElementsByTagName("ddr_size")[0].firstChild.data
	print('DDR Size: {} bytes ({} MiB)'.format(ddr_size, int(ddr_size)/1024/1024))
	master_address_base = components[-1].getElementsByTagName("master_addr_base_0")[0].firstChild.data
	print('PHANTOM Memory Base: {}'.format(master_address_base))
	print('PHANTOM Components:')
	for component in components:
		name = component.getElementsByTagName("name")[0].firstChild.data
		ipname = component.getElementsByTagName("ipname")[0].firstChild.data
		slave_base = component.getElementsByTagName("slave_addr_base_0")[0].firstChild.data
		slave_range = component.getElementsByTagName("slave_addr_range_0")[0].firstChild.data
		num_masters = component.getElementsByTagName("num_masters")[0].firstChild.data
		print('    {} ({})'.format(name, ipname))
		print('        1 Slave interface at {}, size {}'.format(slave_base, slave_range))
		if int(num_masters) > 0:
			master_base = component.getElementsByTagName("master_addr_base_0")[0].firstChild.data
			master_range = component.getElementsByTagName("master_addr_range_0")[0].firstChild.data
			print('        {} Master interface(s) at {}, size {}'.format(num_masters, master_base, master_range))
		else:
			print('        0 Master interfaces')
