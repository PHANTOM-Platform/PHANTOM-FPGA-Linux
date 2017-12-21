set hwdsgn [open_hw_design ../hwproj/hwproj.srcs/sources_1/bd/design_1/hdl/design_1.hwdef]
generate_app -hw $hwdsgn -os standalone -proc ps7_cortexa9_0 -app zynq_fsbl -compile -sw fsbl -dir ../fsbl
exit
