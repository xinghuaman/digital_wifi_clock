vlib work
vmap work work

vcom -93 digital_clock_tb.vhd
vlog ../hdl/digital_clock.v
vlog ../hdl/divider_clock.v
vlog ../hdl/tm1637_control_core.v
vlog ../hdl/transmitter.v
vcom -93 ../hdl/uart_core.vhd
vcom -93 ../hdl/rx_module.vhd
vcom -93 ../hdl/tx_module.vhd
vlog ../hdl/reset_module.v
vlog ../hdl/led_blink.v
vlog ../hdl/i2c_core.v
vlog ../hdl/pwm.v
vlog ../hdl/glbl.v

vsim -t 1ps -vopt -voptargs=+acc=lprn -lib work -L work work.glbl -L unisims_ver digital_clock_tb

do wave_test.do 
view wave
run 2 ms
