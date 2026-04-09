set_db init_lib_search_path {./lib}
set_db init_hdl_search_path {./rtl}
set_db library dff_stdcell_1.lib

#Set variables
set period_ps 1000

##Analize and elaborate
set file_list {saturation_step_counter.v}
read_hdl $file_list
elaborate

set clock [define_clock -period ${period_ps} -name clk]

#Low, Medium, High express
set_db syn_generic_effort medium
set_db syn_map_effort medium
set_db syn_opt_effort medium

syn_generic
syn_map
syn_opt

#Reports
report_timing > ./reports/report_timing.rpt
report_power  > ./reports/report_power.rpt
report_area > ./reports/report_area.rpt
report_qor > ./reports/report_qor.rpt

#Outputs
write_hdl > ./outputs/aes_cipher_top_syn.v
write_sdc > ./outputs/aes_cipher_top_syn.sdc
write_sdf -timescale ns -nonegchecks -recrem split -edges check_edge -setuphold split > ./outputs/aes_cipher_top_syn.sdf
