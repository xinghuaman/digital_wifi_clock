add wave -noupdate -divider testbench
add wave -noupdate -format Logic -radix UNSIGNED  -group {testbench} /digital_clock_tb/*

add wave -noupdate -divider digital_clock
add wave -noupdate -format Logic -radix UNSIGNED  -group {digital_clock} /digital_clock_tb/digital_clock_inst/*

add wave -noupdate -divider divider_clock
add wave -noupdate -format Logic -radix UNSIGNED  -group {divider_clock} /digital_clock_tb/digital_clock_inst/divider_clock_inst/*

add wave -noupdate -divider reset_module
add wave -noupdate -format Logic -radix UNSIGNED  -group {reset_module} /digital_clock_tb/digital_clock_inst/reset_module_inst/*

add wave -noupdate -divider uart_core
add wave -noupdate -format Logic -radix UNSIGNED  -group {uart_core} /digital_clock_tb/digital_clock_inst/uart_core_inst/*

add wave -noupdate -divider control
add wave -noupdate -format Logic -radix UNSIGNED  -group {control} /digital_clock_tb/digital_clock_inst/control_inst/*

add wave -noupdate -divider tm1637_control_core
add wave -noupdate -format Logic -radix UNSIGNED  -group {tm1637_control_core} /digital_clock_tb/digital_clock_inst/tm1637_control_core_inst/*

add wave -noupdate -divider transmitter
add wave -noupdate -format Logic -radix UNSIGNED  -group {transmitter} /digital_clock_tb/digital_clock_inst/tm1637_control_core_inst/transmitter_inst/*

add wave -noupdate -divider pwm_led
add wave -noupdate -format Logic -radix UNSIGNED  -group {pwm_led} /digital_clock_tb/digital_clock_inst/pwm_led_inst/*

add wave -noupdate -divider i2c_core
add wave -noupdate -format Logic -radix UNSIGNED  -group {i2c_core} /digital_clock_tb/digital_clock_inst/i2c_core_inst/*

TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1611 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps