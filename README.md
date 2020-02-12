
Implementation of NuBus controller with Verilog

## ToDo List

- [x] Arbiter
- [x] Slave
- [ ] Master
- [ ] Errors
- [ ] Interrupts 
- [ ] Parity
- [ ] Block Transfer

## Files

nubus_arbiter.v - Arbiter

nubus_driver.v - Nubus singnals driver

nubus_master.v - Master controller

nubus_slave.v - Slave controller

nubus_inc.sv - Included to various files definition of NuBus signals

nubus_arbiter_tb.sv - Arbiter's test bench

nubus_slave_tb.sv - Slave controller test bench

nubus_memory.sv - Memory controller used for tests
