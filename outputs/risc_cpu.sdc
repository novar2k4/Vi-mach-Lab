# Set the current design
current_design risc_cpu

create_clock -name "clk" -add -period 1 -waveform {0.0 0.5} [get_ports clk]

set_input_delay  -clock [get_clocks clk] -add_delay 0.5 [get_ports rst]
set_output_delay -clock [get_clocks clk] -add_delay 0.5 [get_ports debug_pc]
set_output_delay -clock [get_clocks clk] -add_delay 0.5 [get_ports debug_acc]
set_output_delay -clock [get_clocks clk] -add_delay 0.5 [get_ports debug_pc]
set_output_delay -clock [get_clocks clk] -add_delay 0.5 [get_ports debug_ir]
set_output_delay -clock [get_clocks clk] -add_delay 0.5 [get_ports debug_state]
set_output_delay -clock [get_clocks clk] -add_delay 0.5 [get_ports debug_halt]

set_max_fanout 15.000 [current_design]

set_max_transition 1.2 [current_design]