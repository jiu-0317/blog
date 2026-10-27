
xsdb% 에서

connect
targets
targets -set -nocase -filter {name =~ "*PSU*"}
source D:/jiu/fpga/ver_1/xsa_extracted/psu_init.tcl
psu_init
targets -set -nocase -filter {name =~ "*PL*"}
fpga -f D:/jiu/fpga/ver_1/ver_1.runs/impl_1/design_1_wrapper.bit

targets -set -nocase -filter {name =~ "*PSU*"}
psu_ps_pl_isolation_removal
psu_ps_pl_reset_config

--> ila 시작, 대기 중

targets -set -filter {name =~ "*A53*#0"}
rst -processor
dow D:/jiu/vitis_workspace/ver_1_app/build/ver_1_app.elf
con

