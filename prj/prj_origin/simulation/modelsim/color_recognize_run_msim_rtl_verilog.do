transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+D:/study/FPGA/color_recognize/rtl/rtl_origin {D:/study/FPGA/color_recognize/rtl/rtl_origin/ws2812_top.v}
vlog -vlog01compat -work work +incdir+D:/study/FPGA/color_recognize/rtl/rtl_origin {D:/study/FPGA/color_recognize/rtl/rtl_origin/ws2812_ctrl.v}
vlog -vlog01compat -work work +incdir+D:/study/FPGA/color_recognize/rtl/rtl_origin {D:/study/FPGA/color_recognize/rtl/rtl_origin/ws2812_cfg_ctrl.v}
vlog -vlog01compat -work work +incdir+D:/study/FPGA/color_recognize/rtl/rtl_origin {D:/study/FPGA/color_recognize/rtl/rtl_origin/i2c_ctrl.v}
vlog -vlog01compat -work work +incdir+D:/study/FPGA/color_recognize/rtl/rtl_origin {D:/study/FPGA/color_recognize/rtl/rtl_origin/color_recognize.v}
vlog -vlog01compat -work work +incdir+D:/study/FPGA/color_recognize/rtl/rtl_origin {D:/study/FPGA/color_recognize/rtl/rtl_origin/cls381_top.v}
vlog -vlog01compat -work work +incdir+D:/study/FPGA/color_recognize/rtl/rtl_origin {D:/study/FPGA/color_recognize/rtl/rtl_origin/cls381_cfg_ctrl.v}

vlog -vlog01compat -work work +incdir+D:/study/FPGA/color_recognize/prj/prj_origin/../../tb/tb_origin {D:/study/FPGA/color_recognize/prj/prj_origin/../../tb/tb_origin/top_tb.v}
vlog -vlog01compat -work work +incdir+D:/study/FPGA/color_recognize/prj/prj_origin/../../rtl/rtl_origin {D:/study/FPGA/color_recognize/prj/prj_origin/../../rtl/rtl_origin/driver.v}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cycloneive_ver -L rtl_work -L work -voptargs="+acc"  top_tb

add wave *
view structure
view signals
run -all
