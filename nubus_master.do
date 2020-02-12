onElabError resume;

# Compile all sources files and testbench
#vcom *.v
#vcom *.sv

# Load testbench for simulation
vsim -gui -onfinish exit work.nubus_slave_tb

# Tell modelsim to record everything
log * -r

# Run simulation for a certain time
run 20 us 

## Add signals to waveform window

delete wave *

# Simulator signals

add wave -divider "Simulate"

add wave -hex sim:/nubus_vm2s_tb/fsm_tm
add wave -hex sim:/nubus_vm2s_tb/fsm_status

# Nubus signals

add wave -divider "Nubus Clock"

add wave -bin sim:/nubus_vm2s_tb/UNuBus/nub_clkn
add wave -bin sim:/nubus_vm2s_tb/UNuBus/nub_resetn
add wave -hex sim:/nubus_vm2s_tb/UNuBus/nub_idn

add wave -divider "Nubus Data"

add wave -hex sim:/nubus_vm2s_tb/UNuBus/nub_adn
add wave -hex sim:/nubus_vm2s_tb/UNuBus/address
add wave -bin sim:/nubus_vm2s_tb/UNuBus/nub_rqstn
add wave -bin sim:/nubus_vm2s_tb/UNuBus/nub_startn
add wave -bin sim:/nubus_vm2s_tb/UNuBus/nub_ackn
add wave -hex sim:/nubus_vm2s_tb/UNuBus/nub_tm0n
add wave -hex sim:/nubus_vm2s_tb/UNuBus/nub_tm1n
add wave -hex sim:/nubus_vm2s_tb/UNuBus/nub_arbn
add wave -bin sim:/nubus_vm2s_tb/UNuBus/nub_pfwn
    
add wave -divider "NubusExtra"

add wave -bin sim:/nubus_vm2s_tb/UNuBus/nub_nmrqn
add wave -bin sim:/nubus_vm2s_tb/UNuBus/nub_spn
add wave -bin sim:/nubus_vm2s_tb/UNuBus/nub_spvn

    
# Memory bus signals connected to a memory, accesible by nubus or processor

add wave -divider "Memory"

add wave -bin -group Memory sim:/nubus_vm2s_tb/UNuBus/mem_valid
add wave -hex -group Memory sim:/nubus_vm2s_tb/UNuBus/mem_addr
add wave -hex -group Memory sim:/nubus_vm2s_tb/UNuBus/mem_wdata
add wave -bin -group Memory sim:/nubus_vm2s_tb/UNuBus/mem_wstrb
add wave -bin -group Memory sim:/nubus_vm2s_tb/UNuBus/mem_ready
add wave -hex -group Memory sim:/nubus_vm2s_tb/UNuBus/mem_rdata
add wave -hex -group Memory sim:/nubus_vm2s_tb/UNuBus/mem_myslot
add wave -hex -group Memory sim:/nubus_vm2s_tb/UNuBus/mem_myexp

# Processor bus signals connected to processor 

add wave -divider "CPU"

add wave -bin -group CPU sim:/nubus_vm2s_tb/UNuBus/cpu_valid
add wave -hex -group CPU sim:/nubus_vm2s_tb/UNuBus/cpu_addr
add wave -hex -group CPU sim:/nubus_vm2s_tb/UNuBus/cpu_wdata
add wave -bin -group CPU sim:/nubus_vm2s_tb/UNuBus/cpu_ready
add wave -bin -group CPU sim:/nubus_vm2s_tb/UNuBus/cpu_wstrb
add wave -hex -group CPU sim:/nubus_vm2s_tb/UNuBus/cpu_rdata
add wave -bin -group CPU sim:/nubus_vm2s_tb/UNuBus/cpu_lock

# Debugging and utilities 
    
add wave -divider "Debugging"

add wave -bin -group Slave sim:/nubus_vm2s_tb/UNuBus/USlave/nub_clkn
add wave -bin -group Slave sim:/nubus_vm2s_tb/UNuBus/USlave/nub_resetn
add wave -bin -group Slave sim:/nubus_vm2s_tb/UNuBus/USlave/nub_startn
add wave -bin -group Slave sim:/nubus_vm2s_tb/UNuBus/USlave/nub_ackn
add wave -bin -group Slave sim:/nubus_vm2s_tb/UNuBus/USlave/nub_tm0n
add wave -bin -group Slave sim:/nubus_vm2s_tb/UNuBus/USlave/nub_tm1n
add wave -bin -group Slave sim:/nubus_vm2s_tb/UNuBus/USlave/mem_ready
add wave -bin -group Slave sim:/nubus_vm2s_tb/UNuBus/USlave/myslot
add wave -bin -group Slave sim:/nubus_vm2s_tb/UNuBus/USlave/mstdn

add wave -bin -group Slave sim:/nubus_vm2s_tb/UNuBus/USlave/slave_o
add wave -bin -group Slave sim:/nubus_vm2s_tb/UNuBus/USlave/master_o
add wave -bin -group Slave sim:/nubus_vm2s_tb/UNuBus/USlave/myslot_o
add wave -bin -group Slave sim:/nubus_vm2s_tb/UNuBus/USlave/tm0n_o
add wave -bin -group Slave sim:/nubus_vm2s_tb/UNuBus/USlave/tm1n_o
add wave -bin -group Slave sim:/nubus_vm2s_tb/UNuBus/USlave/ackcy_o

#add wave -recursive -depth 10 *

#$stop
