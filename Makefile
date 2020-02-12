COMPRESSED_ISA = C
VERILATOR_DIR = obj_dir
ICARUS_FLAGS = -g2012

# ==========================================
# Test access virtual Master to slave
# ==========================================

nubus_slave: nubus_slave_tb.sv nubus.v nubus_master.v nubus_slave.v nubus_arbiter.v nubus_driver.v nubus_memory.sv
	iverilog $(ICARUS_FLAGS) -o nubus_slave_tb.vvp $^ 

test_slave.vvp: nubus_slave_tb.sv nubus.v nubus_master.v nubus_slave.v nubus_arbiter.v nubus_driver.v nubus_memory.sv
	iverilog $(ICARUS_FLAGS) -o nubus_svave_tb.vvp $^
	vvp nubus_slave_tb.vvp

# ==========================================
# Test only for the arbiter
# ==========================================

test_arbiter.ver:
	verilator -Wall -cc nubus_arbiter.v --prefix NubusArbiter --exe nubus_arbiter_tb.cpp -CFLAGS "-std=c++11"
	$(MAKE) -C $(VERILATOR_DIR) -f NubusArbiter.mk
	cp $(VERILATOR_DIR)/NubusArbiter nubus_arbiter_tb.exe
	chmod -x $@
	./nubus_arbiter_tb.exe

# make only
arbiter:
	iverilog -g2012 -o nubus_arbiter_tb.vvp nubus_arbiter_tb.sv

# make and test
test_arbiter.vvp:
	iverilog -g2012 -o nubus_arbiter_tb.vvp nubus_arbiter_tb.sv
	vvp nubus_arbiter_tb.vvp

# ==========================================
# Clear temporary data
# ==========================================

clean:
	rm -f *.vvp
	rm -f *.exe
	rm -rf $(VERILATOR_DIR)
