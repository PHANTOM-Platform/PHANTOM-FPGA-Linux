# Hardware definition file can be in one of two places, depending on Vivado version
set filename "../hwproj/hwproj.srcs/sources_1/bd/design_1/hdl/design_1.hwdef"
if {![file exist $filename]} {
	set filename "../hwproj/hwproj.srcs/sources_1/bd/design_1/synth/design_1.hwdef"
}

set hwdsgn [open_hw_design $filename]
generate_app -hw $hwdsgn -os standalone -proc ps7_cortexa9_0 -app zynq_fsbl -compile -sw fsbl -dir ../fsbl
exit
