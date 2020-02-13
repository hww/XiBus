COMPRESSED_ISA = C
VERILATOR_DIR = obj_dir
ICARUS_FLAGS = -g2012

# ==========================================
# Test access virtual Master to slave
# ==========================================

slave: nubus_slave_tb.sv nubus.v nubus_master.v nubus_slave.v nubus_arbiter.v nubus_driver.v nubus_memory.sv cpu_encoder.v
	iverilog $(ICARUS_FLAGS) -o nubus_slave_tb.vvp $^ 

test_slave: nubus_slave_tb.sv nubus.v nubus_master.v nubus_slave.v nubus_arbiter.v nubus_driver.v nubus_memory.sv cpu_encoder.v
	iverilog $(ICARUS_FLAGS) -o nubus_slave_tb.vvp $^
	vvp nubus_slave_tb.vvp

# ==========================================
# Test access NuBus Master to same NuBus slave
# ==========================================

master: nubus_master_tb.sv nubus.v nubus_master.v nubus_slave.v nubus_arbiter.v nubus_driver.v nubus_memory.sv cpu_encoder.v
	iverilog $(ICARUS_FLAGS) -o nubus_master_tb.vvp $^ 

test_master: nubus_master_tb.sv nubus.v nubus_master.v nubus_slave.v nubus_arbiter.v nubus_driver.v nubus_memory.sv cpu_encoder.v
	iverilog $(ICARUS_FLAGS) -o nubus_master_tb.vvp $^
	vvp nubus_master_tb.vvp

# ==========================================
# Test only for the arbiter
# ==========================================

# make only
arbiter: nubus_arbiter.v nubus_arbiter_tb.sv
	iverilog -g2012 -o nubus_arbiter_tb.vvp nubus_arbiter_tb.sv nubus_arbiter.v

# make and test
test_arbiter: nubus_arbiter.v nubus_arbiter_tb.sv
	iverilog -g2012 -o nubus_arbiter_tb.vvp nubus_arbiter_tb.sv nubus_arbiter.v
	vvp nubus_arbiter_tb.vvp

# ==========================================
# Clear temporary data
# ==========================================

clean:
	rm -f *.vcd
	rm -f *.vvp
	rm -f *.exe
	rm -rf $(VERILATOR_DIR)
