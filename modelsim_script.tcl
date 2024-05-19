# create modelsim working library
vlib work

# compile all the Verilog sources

vlog ../testbench.sv ../stream_upsize.sv ../flip_flop_fifo.sv

# open the testbench module for simulation
vsim work.testbench
vsim -voptargs=+acc testbench


# add all testbench signals to time diagram
add wave sim:/testbench/*

# run the simulation
run -all

#expand the signals time diagram
wave zoom full