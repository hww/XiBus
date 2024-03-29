# Ξ XiBus 

Implementation of NuBus controller with Verilog for using with RiscV. 

Designed for integration with [PicoRV](https://github.com/cliffordwolf/picorv32)

## ToDo List

- [x] NuBus Arbiter
  - [x] Arbiter testbench
- [x] NuBus slave
  - [x] Testbench
  - [x] Slots
  - [x] Superslots
  - [x] Local memory access 
- [x] NuBus master
  - [x] Testbench
  - [x] Master timeout error
  - [ ] Multimaster bus transfer testbench
- [ ] Bus transfer errors
  - [x] NuBus - Parity error
  - [x] Master - Timeout
  - [x] Master - Non aligned memory access
  - [x] Slave - Memory acccess error (as input pin on memory interface)
  - [ ] Slave - Try again later (as input pin on memory interface)
  - [ ] Slave - Parity for ECC memory
  - [ ] Bus transfer errors testbench
- [ ] Interrupts 
  - [ ] Interrupt on bus error
  - [ ] Interrupt on unused memory access
  - [ ] Non master request (NMRQ)
  - [ ] Interrupts testbench 
- [ ] Block transfer
  - [ ] Block transfer testbench

## Files

nubus_arbiter.v - Arbiter

nubus_driver.v - Nubus singnals driver

nubus_master.v - Master controller

nubus_slave.v - Slave controller

nubus.svh - Included to various files definition of NuBus signals

nubus_arbiter_tb.sv - Arbiter's test bench

nubus_slave_tb.sv - Slave controller test bench (virtual master access to slave)

nubus_master_tb.sv - Master controller test bench (CPU access to slave with NuBus)

nubus_memory.sv - Memory controller used for tests

nubus_cpubus.v - Encoder from PicoRV bus to this NuBus controller

## Makefile

> make clean

> make arbiter

> make test_arbiter

> make slave

> make test_slave

> make master

> make test_master

## Data Lines Digram

![Data Lines](/docs/nubus_contr_data_address_flow.png)
