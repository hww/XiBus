onElabError resume;

#vsim -gui work.nubus_vm2s_tb
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

add wave -bin sim:/nubus_vm2s_tb/UNuBus/mem_valid
add wave -hex sim:/nubus_vm2s_tb/UNuBus/mem_addr
add wave -hex sim:/nubus_vm2s_tb/UNuBus/mem_wdata
add wave -bin sim:/nubus_vm2s_tb/UNuBus/mem_wstrb
add wave -bin sim:/nubus_vm2s_tb/UNuBus/mem_ready
add wave -hex sim:/nubus_vm2s_tb/UNuBus/mem_rdata
add wave -hex sim:/nubus_vm2s_tb/UNuBus/mem_myslot
add wave -hex sim:/nubus_vm2s_tb/UNuBus/mem_myexp

# Processor bus signals connected to processor 

add wave -divider "CPU"

add wave -bin sim:/nubus_vm2s_tb/UNuBus/cpu_valid
add wave -hex sim:/nubus_vm2s_tb/UNuBus/cpu_addr
add wave -hex sim:/nubus_vm2s_tb/UNuBus/cpu_wdata
add wave -bin sim:/nubus_vm2s_tb/UNuBus/cpu_ready
add wave -bin sim:/nubus_vm2s_tb/UNuBus/cpu_wstrb
add wave -hex sim:/nubus_vm2s_tb/UNuBus/cpu_rdata
add wave -bin sim:/nubus_vm2s_tb/UNuBus/cpu_lock

# Debugging and utilities 
    
add wave -divider "Debugging"


#$stop
