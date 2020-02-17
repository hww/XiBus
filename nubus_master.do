onElabError resume;

# Compile all sources files and testbench
#vcom *.v
#vcom *.sv

# Load testbench for simulation
vsim -gui  -onfinish stop work.nubus_master_tb

# Tell modelsim to record everything
log * -r

# Run simulation for a certain time
run 20 us 

## Add signals to waveform window

delete wave *

# Nubus signals

add wave -divider "Nubus Clock"

add wave -bin sim:/nubus_master_tb/UNuBus/nub_clkn
add wave -bin sim:/nubus_master_tb/UNuBus/nub_resetn
add wave -hex sim:/nubus_master_tb/UNuBus/nub_idn

add wave -divider "Nubus Data"

add wave -hex sim:/nubus_master_tb/UNuBus/nub_adn
add wave -bin sim:/nubus_master_tb/UNuBus/nub_rqstn
add wave -bin sim:/nubus_master_tb/UNuBus/nub_startn
add wave -bin sim:/nubus_master_tb/UNuBus/nub_ackn
add wave -hex sim:/nubus_master_tb/UNuBus/nub_tm0n
add wave -hex sim:/nubus_master_tb/UNuBus/nub_tm1n
add wave -hex sim:/nubus_master_tb/UNuBus/nub_arbn
add wave -bin sim:/nubus_master_tb/UNuBus/nub_pfwn
    
add wave -divider "NubusExtra"

add wave -bin sim:/nubus_master_tb/UNuBus/nub_nmrqn
add wave -bin sim:/nubus_master_tb/UNuBus/nub_spn
add wave -bin sim:/nubus_master_tb/UNuBus/nub_spvn

    
# Memory bus signals connected to a memory, accesible by nubus or processor

add wave -divider "Memory"

add wave -hex -group Memory sim:/nubus_master_tb/UNuBus/mem_slot
add wave -hex -group Memory sim:/nubus_master_tb/UNuBus/mem_super
add wave -bin -group Memory sim:/nubus_master_tb/UNuBus/mem_valid
add wave -hex -group Memory sim:/nubus_master_tb/UNuBus/mem_addr
add wave -hex -group Memory sim:/nubus_master_tb/UNuBus/mem_wdata
add wave -hex -group Memory sim:/nubus_master_tb/UNuBus/mem_rdata
add wave -bin -group Memory sim:/nubus_master_tb/UNuBus/mem_write
add wave -bin -group Memory sim:/nubus_master_tb/UNuBus/mem_ready

# Processor bus signals connected to processor 

add wave -divider "CPU"

add wave -bin -group CPU sim:/nubus_master_tb/UNuBus/cpu_lock
add wave -bin -group CPU sim:/nubus_master_tb/UNuBus/cpu_valid
add wave -hex -group CPU sim:/nubus_master_tb/UNuBus/cpu_addr
add wave -hex -group CPU sim:/nubus_master_tb/UNuBus/cpu_wdata
add wave -hex -group CPU sim:/nubus_master_tb/UNuBus/cpu_rdata
add wave -bin -group CPU sim:/nubus_master_tb/UNuBus/cpu_write
add wave -bin -group CPU sim:/nubus_master_tb/UNuBus/cpu_ready

# Debugging and utilities 
    
add wave -divider "Debugging"



add wave -bin -group Master sim:/nubus_master_tb/UNuBus/UMaster/mst_arbdn_o
add wave -bin -group Master sim:/nubus_master_tb/UNuBus/UMaster/arb_grant
add wave -bin -group Master sim:/nubus_master_tb/UNuBus/UMaster/cpu_masterd
add wave -bin -group Master sim:/nubus_master_tb/UNuBus/UMaster/cpu_lock
add wave -bin -group Master sim:/nubus_master_tb/UNuBus/UMaster/mst_lockedn_o

add wave -bin -group Master sim:/nubus_master_tb/UNuBus/UMaster/mst_arbcyn_o
add wave -bin -group Master sim:/nubus_master_tb/UNuBus/UMaster/mst_adrcyn_o
add wave -bin -group Master sim:/nubus_master_tb/UNuBus/UMaster/mst_dtacyn_o
add wave -bin -group Master sim:/nubus_master_tb/UNuBus/UMaster/mst_ownern_o
add wave -bin -group Master sim:/nubus_master_tb/UNuBus/UMaster/mst_busyn_o
add wave -bin -group Master sim:/nubus_master_tb/UNuBus/UMaster/mst_timeout_o
add wave -bin -group Master sim:/nubus_master_tb/UNuBus/UMaster/nub_rqstn
add wave -bin -group Master sim:/nubus_master_tb/UNuBus/UMaster/nub_startn
add wave -bin -group Master sim:/nubus_master_tb/UNuBus/UMaster/nub_ackn

add wave -bin -group Slave sim:/nubus_master_tb/UNuBus/USlave/nub_clkn
add wave -bin -group Slave sim:/nubus_master_tb/UNuBus/USlave/nub_resetn
add wave -bin -group Slave sim:/nubus_master_tb/UNuBus/USlave/nub_startn
add wave -bin -group Slave sim:/nubus_master_tb/UNuBus/USlave/nub_ackn
add wave -bin -group Slave sim:/nubus_master_tb/UNuBus/USlave/nub_tm0n
add wave -bin -group Slave sim:/nubus_master_tb/UNuBus/USlave/nub_tm1n
add wave -bin -group Slave sim:/nubus_master_tb/UNuBus/USlave/mem_ready
add wave -bin -group Slave sim:/nubus_master_tb/UNuBus/USlave/drv_mstdn

add wave -bin -group Slave sim:/nubus_master_tb/UNuBus/USlave/slv_slave_o
add wave -bin -group Slave sim:/nubus_master_tb/UNuBus/USlave/slv_tm0n_o
add wave -bin -group Slave sim:/nubus_master_tb/UNuBus/USlave/slv_tm1n_o
add wave -bin -group Slave sim:/nubus_master_tb/UNuBus/USlave/slv_ackcyn_o
add wave -bin -group Slave sim:/nubus_master_tb/UNuBus/USlave/mem_slot_o
add wave -bin -group Slave sim:/nubus_master_tb/UNuBus/USlave/mem_super_o




add wave -bin -group Driver sim:/nubus_master_tb/UNuBus/UNDriver/slv_ackcyn
add wave -bin -group Driver sim:/nubus_master_tb/UNuBus/UNDriver/mst_arbcyn
add wave -bin -group Driver sim:/nubus_master_tb/UNuBus/UNDriver/mst_adrcyn
add wave -bin -group Driver sim:/nubus_master_tb/UNuBus/UNDriver/mst_dtacyn
add wave -bin -group Driver sim:/nubus_master_tb/UNuBus/UNDriver/mst_ownern
add wave -bin -group Driver sim:/nubus_master_tb/UNuBus/UNDriver/mst_lockedn
add wave -bin -group Driver sim:/nubus_master_tb/UNuBus/UNDriver/mst_tm1n
add wave -bin -group Driver sim:/nubus_master_tb/UNuBus/UNDriver/mst_tm0n

add wave -bin -group Driver sim:/nubus_master_tb/UNuBus/UNDriver/nub_tm0n_o
add wave -bin -group Driver sim:/nubus_master_tb/UNuBus/UNDriver/nub_tm1n_o
add wave -bin -group Driver sim:/nubus_master_tb/UNuBus/UNDriver/nub_ackn_o
add wave -bin -group Driver sim:/nubus_master_tb/UNuBus/UNDriver/nub_startn_o
add wave -bin -group Driver sim:/nubus_master_tb/UNuBus/UNDriver/nub_rqstn_o
add wave -bin -group Driver sim:/nubus_master_tb/UNuBus/UNDriver/nub_rqstoen_o
add wave -bin -group Driver sim:/nubus_master_tb/UNuBus/UNDriver/drv_tmoen_o
add wave -bin -group Driver sim:/nubus_master_tb/UNuBus/UNDriver/drv_mstdn_o
   
#add wave -recursive -depth 10 *

#$stop
