# APB3 Slave Peripheral Controller

A Verilog RTL implementation of a memory-mapped APB3 slave peripheral featuring register read/write operations, address decoding, error detection, asynchronous reset, and wait-state support.

## Overview

This project implements a basic AMBA APB3-inspired slave peripheral using Verilog HDL.

The peripheral interfaces with an APB master and provides access to four 32-bit memory-mapped registers. It supports read and write transactions, read-only register protection, invalid address detection, and two-cycle wait-state insertion.

The design is simulated using Icarus Verilog and verified through GTKWave waveform analysis.

## Features

- APB Setup and Access phase handling
- 32-bit data bus and 8-bit address bus
- Four memory-mapped registers
- Address decoding and register selection
- Register read and write operations
- Read-only STATUS register protection
- Invalid address detection using `PSLVERR`
- Active-low asynchronous reset
- Two-cycle wait-state support using `PREADY`
- Functional testbench with reusable read/write tasks
- VCD waveform generation for GTKWave

## Register Map

| Address | Register | Access |
|---|---|---|
| `0x00` | CTRL_REG | Read/Write |
| `0x04` | STATUS_REG | Read-only |
| `0x08` | DATA_REG | Read/Write |
| `0x0C` | CONFIG_REG | Read/Write |

All registers are 32 bits wide.

## Architecture

The design consists of the following logical components:

1. **APB Interface:** Handles APB control, address and data signals.
2. **Wait-State Controller:** Inserts two wait cycles before completing a transfer.
3. **Address Decoder:** Selects the appropriate register based on `PADDR`.
4. **Register Bank:** Stores control, status, data and configuration values.
5. **Read Data Logic:** Selects the appropriate register value for `PRDATA`.
6. **Error Detection:** Generates `PSLVERR` for invalid addresses and writes to the read-only register.

## APB Transfer Behavior

The peripheral follows the APB Setup and Access phase sequence.

| Phase | PSEL | PENABLE |
|---|---|---|
| Idle | 0 | 0 |
| Setup | 1 | 0 |
| Access | 1 | 1 |

The slave introduces two wait cycles by keeping `PREADY` LOW before asserting it HIGH.

During wait states, the master must maintain stable address, control and write-data signals.

A transfer completes when `PSEL`, `PENABLE`, and `PREADY` are HIGH at the active clock edge.

## Error Handling

The peripheral asserts `PSLVERR` when:

- An invalid register address is accessed.
- A write is attempted on `STATUS_REG`.

## Reset Behavior

The design uses an active-low asynchronous reset through `PRESETn`.

When reset is asserted, all four registers and `PRDATA` are cleared to zero.

## Project Structure

```text
APB3-Slave-Peripheral-Controller/
│
├── rtl/
│   └── apb_slave.v
│
├── testbench/
│   └── apb_slave_tb.v
│
├── simulation/
│   └── .gitkeep
│
├── docs/
│   └── waveforms/
│
├── .gitignore
└── README.md
```

## Tools Used

| Tool | Purpose |
|---|---|
| Verilog HDL | RTL implementation |
| Icarus Verilog | Compilation and simulation |
| GTKWave | Waveform analysis |
| Visual Studio Code | Development environment |
| Git | Version control |

## Simulation Instructions

Run the following commands from the project root.

### 1. Compile

```bash
iverilog -o simulation/apb_test rtl/apb_slave.v testbench/apb_slave_tb.v
```

### 2. Run Simulation

```bash
vvp simulation/apb_test
```

### 3. Open Waveform

```bash
gtkwave simulation/apb_slave_tb.vcd
```

## Verification

The testbench is designed to cover:

- CTRL_REG write and read
- DATA_REG write and read
- CONFIG_REG write and read
- STATUS_REG read-only protection
- Invalid address detection
- Asynchronous reset
- Two-cycle wait-state behavior for read and write transactions

Waveforms are generated in VCD format and can be inspected using GTKWave.

## Scope and Limitations

This is a learning-oriented APB3 peripheral implementation covering selected protocol features. It is not intended to claim complete AMBA APB3 compliance.

Current limitations include:

- Fixed two-cycle wait-state behavior
- No programmable wait-state configuration
- No external hardware integration
- Simplified peripheral status-register behavior

## Future Improvements

- Configurable wait-state generation
- More comprehensive protocol assertions
- Randomized transaction testing
- Additional register access policies
- Integration with a simple APB master
- FPGA-based validation

## Learning Outcomes

This project provided practical experience with:

- RTL design using Verilog
- Memory-mapped peripheral architecture
- Synchronous and asynchronous reset behavior
- APB protocol timing
- Sequential and combinational logic
- Functional verification and waveform debugging

## Author

Developed as an RTL design and digital verification learning project.
