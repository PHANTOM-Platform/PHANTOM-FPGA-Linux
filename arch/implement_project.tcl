open_project ../hwproj/hwproj.xpr
update_compile_order -fileset sources_1
launch_runs impl_1 -to_step write_bitstream -jobs 2
wait_on_run impl_1
if {[get_property PROGRESS [get_run impl_1]] != "100%"} {
	error "ERROR: impl_1 failed"
}
