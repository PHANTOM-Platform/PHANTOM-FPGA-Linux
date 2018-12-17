#!/usr/bin/env python3

import argparse
import json
import math

"""
This script parses a PHANTOM FPGA Linux JSON configuration file and outputs parameters in a format appropriate for the compilation scripts.
Run with no options to see all configuration information, or use the options below for specific variables.
"""

parser = argparse.ArgumentParser(description='PHANTOM FPGA Linux Configuration File Parser')
group = parser.add_mutually_exclusive_group()
group.add_argument('--board', action='store_true', help='show target board type')
group.add_argument('--rootfs', action='store_true', help='show target rootfs type')
group.add_argument('--ipcores', action='store_true', help='show IP cores')
group.add_argument('--sharedmem', action='store_true', help='show total IP core shared memory in hex')
parser.add_argument('config_file', type=str, help='path to JSON config file')
args = parser.parse_args()

with open(args.config_file, 'r') as read_file:
	config = json.load(read_file)

target = config['target']
board = target['board']
rootfs = target['rootfs']
ipcores = config['ipcores']

# Check if memory is power of 2, and if not, round up to nearest power of 2 and make at least 4KiB (unless 0)
for ipcore in ipcores:
	memory = ipcore['memory']
	if (memory > 0):
		if (memory < 4096):
				ipcore['memory'] = 4096
		elif (memory > 0) and ((memory & (memory - 1)) != 0):
			ipcore['memory'] = int(math.pow(2, math.ceil(math.log(memory, 2))))

# Sort in descending order by memory size, so Vivado can easily map into aligned areas at the top of DDR
ipcores = sorted(ipcores, key=lambda k: k['memory'], reverse=True)

if args.board:
	print(board)
elif args.rootfs:
	print(rootfs)
elif args.ipcores:
	ipcores_string = ''
	for ipcore in ipcores:
		ipname = ipcore['ipname']
		memory = ipcore['memory']
		ipcores_string += ('{0} {1} '.format(ipname, memory))
	print(ipcores_string[0:-1])
elif args.sharedmem:
	totalmem = 0
	for ipcore in ipcores:
		memory = ipcore['memory']
		totalmem = totalmem + memory
	print(hex(totalmem))
else:
	print('Board:', board)
	print('RootFS:', rootfs)
	print("IP Cores:")
	totalmem = 0
	for ipcore in ipcores:
		ipname = ipcore['ipname']
		memory = ipcore['memory']
		totalmem = totalmem + memory
		print('    {} - {} bytes ({})'.format(ipname, memory, hex(memory)))
	print('Total Shared Memory: {} bytes ({})'.format(totalmem, hex(totalmem)))
