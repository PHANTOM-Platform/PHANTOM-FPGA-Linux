open_project ../hwproj/hwproj.xpr

make_wrapper -files [get_files ../hwproj/hwproj.srcs/sources_1/bd/design_1/design_1.bd] -top
add_files -norecurse ../hwproj/hwproj.srcs/sources_1/bd/design_1/hdl/design_1_wrapper.v
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

launch_runs impl_1 -to_step write_bitstream -jobs 2

