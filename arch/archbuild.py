#!/usr/bin/env python3
import os, sys
from xml.dom import expatbuilder

"""
This simple script can be used to build an FPGA design based on a PHANTOM deployment XML. 
It automates a call to build_project.tcl with the IP cores that are described in the deployment.
"""


ANSI_RED = "\033[1;31m"
ANSI_GREEN = "\033[1;32m"
ANSI_YELLOW = "\033[1;33m"
ANSI_BLUE = "\033[1;34m"
ANSI_MAGENTA = "\033[1;35m"
ANSI_CYAN = "\033[1;36m"
ANSI_END = "\033[0;0m"

DEFAULTBOARDPART = "xilinx.com:zc706:part0:1.3"

def main():
	boardpart = DEFAULTBOARDPART
	if len(sys.argv) < 3:
		print("Usage {} <project_to_create> <input_de.xml> <board_part>".format(sys.argv[0]))
		sys.exit(1)
	if len(sys.argv) >= 4:
		boardpart = sys.argv[3]

	if not os.path.exists(sys.argv[2]):
		print("File {} does not exist.".format(sys.argv[2]))
		sys.exit(1)

	fpgas = {}

	# Check for deployment mappings which have 'component' and 'fpga' subelements
	# The fpga element has attributes:
	#   name = name of the fpga to target
	#   ipname = name of the IP core to use to implement it
	doc = expatbuilder.parse(sys.argv[2], False)
	mappings = doc.getElementsByTagName('mapping')
	for m in mappings:
		fpga = m.getElementsByTagName('fpga')
		comp = m.getElementsByTagName('component')
		if len(fpga) > 0 and len(comp) > 0:
			if fpga[0].getAttribute('name') in fpgas:
				fpgas[fpga[0].getAttribute('name')].append((fpga[0], comp[0]))
			else:
				fpgas[fpga[0].getAttribute('name')] = [(fpga[0], comp[0])]

 	# Report what we found
	print(ANSI_MAGENTA + "FPGA designs to construct:" + ANSI_END)
	for fpganame in fpgas:
		print("\tFPGA: {}{}{}".format(ANSI_CYAN, fpganame, ANSI_END))
		for f, c in fpgas[fpganame]:
			print("\t\tComponent: {}{} -> {}{}".format(ANSI_GREEN, c.getAttribute('name'), f.getAttribute('ipname'), ANSI_END))

	# Now for each FPGA we build a Vivado design
	if len(fpgas) > 1:
		print("Warning: Currently only automatic construction of the first design is supported.")
		fpgas = fpgas[:1]
	for fpganame in fpgas:
		print(ANSI_MAGENTA + "Constructing design for FPGA {}...".format(fpganame) + ANSI_END)

		cmd = "vivado -mode batch -source build_project.tcl -quiet -notrace -tclargs hwproj {} {} ".format(sys.argv[1], boardpart)
		for f, c in fpgas[fpganame]:
			cmd = cmd + f.getAttribute('ipname') + " "
		print(cmd)
		os.system(cmd)

if __name__ == "__main__":
	main()
