# AGENT.md

## Overview

This repository contains a 4-channel RC servo PWM IP core with:

- RTL in `src/`
- Vivado IP packaging metadata in `component.xml` and `xgui/`
- A bare-metal software driver in `drivers/servo_pwm_v1_0/src/`
- RTL and software-side tests in `tb/`

The packaged IP version is currently `1.1`.

## Repository Layout

- `src/servo_pwm.v`
  Top-level RTL wrapper.
- `src/servo_pwm_slave_lite_v1_1_S00_AXI.v`
  AXI-Lite slave plus timing/divider register logic.
- `src/servo_pwm_gen.v`
  4-channel generator wrapper.
- `src/servo_pwm_ch.v`
  Per-channel PWM state machine.
- `src/servo_pwm_io_pin.v`
  Xilinx `OBUFT` wrapper for output enable behavior.
- `drivers/servo_pwm_v1_0/src/`
  C driver and public headers.
- `scripts/repackage_ip.tcl`
  Vivado batch Tcl to reopen and repackage the IP core from `component.xml`.
- `scripts/repackage_ip.sh`
  Shell wrapper for the Vivado repackaging flow.
- `tb/servo_pwm_tb.sv`
  Self-checking XSIM testbench for the RTL.
- `tb/servo_pwm_driver_test.c`
  Host-side unit test for the C driver.

## Important Design Semantics

- AXI-Lite write handling is single-outstanding and requires aligned `AW` + `W` acceptance.
- The API is 0-based for channels. Valid channel numbers are `0..3`.
- Only the per-channel pulse-width registers are frame-latched.
- Writes to the UI divisor register and frame divisor register take effect immediately. That is intentional.
- The UI divisor and frame divisor are terminal counts:
  - programming `N` yields an event every `N+1` cycles/intervals
  - documentation has been updated to match this RTL behavior

## Verification

### RTL simulation

Use XSIM:

```bash
./tb/run_xsim.sh
```

Artifacts:

- wave database: `tb/xsim/servo_pwm_tb.wdb`
- logs: `tb/xsim/xvlog.log`, `tb/xsim/xelab.log`, `tb/xsim/xsim.log`

The XSIM batch flow logs the full hierarchy with:

```tcl
log_wave -r /*
```

### Software-side driver test

Use:

```bash
./tb/run_driver_test.sh
```

This builds a host-side test binary using shim Xilinx headers in `tb/sw_include/`.

### IP repackaging

Use:

```bash
./scripts/repackage_ip.sh
```

This runs Vivado in batch mode and:

- opens the packaged IP from `component.xml`
- merges current file, port, and parameter changes
- regenerates the XGUI Tcl
- runs IP integrity checks
- saves the packaged core back into the repo

Expected outputs after repackaging:

- `component.xml` may be refreshed
- `xgui/servo_pwm_v1_1.tcl` may be regenerated

## Packaging / Versioning Notes

- When bumping the packaged IP version, update:
  - `component.xml`
  - `xgui/servo_pwm_vX_Y.tcl`
  - versioned RTL wrapper names if they are part of the packaged source list
  - display/component names in `component.xml`
  - `xilinx:canUpgradeFrom` so the VLNV matches the actual vendor/library/name namespace
- After packaging-related source changes, run `./scripts/repackage_ip.sh` instead of editing package checksums by hand.
- Current VLNV namespace is:
  - vendor: `SFG`
  - library: `user`
  - name: `servo_pwm`

## Editing Guidance

- Prefer preserving existing register offsets and public API names unless explicitly changing the interface.
- If you change AXI-Lite behavior, rerun `./tb/run_xsim.sh`.
- If you change driver indexing, public headers, or register access logic, rerun `./tb/run_driver_test.sh`.
- `src/servo_pwm_io_pin.v` instantiates `OBUFT`; the testbench uses `tb/OBUFT.v` as a simulation stub.

## Generated Files

Simulation leaves transient outputs such as:

- `xsim.dir/`
- `xsim.jou`
- `xvlog.pb`
- `xelab.pb`

These are tool outputs, not source files.
