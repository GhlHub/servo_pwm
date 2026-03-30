# AGENT.md

## Overview

This repository contains a 4-channel RC servo PWM IP core with:

- RTL in `src/`
- Vivado IP packaging metadata under `ip_repo/servo_pwm/`
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
  Vivado batch Tcl to reopen and repackage a selected packaged `component.xml`.
- `scripts/repackage_ip.sh`
  Shell wrapper for the Vivado repackaging flow.
- `package_ip_core.tcl`
  Vivado batch Tcl to copy the packaged core into `ip_repo/servo_pwm/` and repackage that copy.
- `scripts/estimate_resources.tcl`
  Vivado batch Tcl for out-of-context resource estimation of the top-level RTL.
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

- opens the selected packaged `component.xml`
- merges current file, port, and parameter changes
- regenerates the XGUI Tcl
- runs IP integrity checks
- saves the packaged core back into the repo

To refresh the Vivado repository copy used by `ip_repo_paths`, run:

```bash
vivado -mode batch -source package_ip_core.tcl
```

This copies `src/`, `xgui/`, and `drivers/` into `ip_repo/servo_pwm/`, restores the committed `ip_repo/servo_pwm/component.xml` template, and then repackages that copied core in place.
`scripts/repackage_ip.tcl` detects the target `component.xml` from `SERVO_PWM_COMPONENT_XML` when set.

Expected outputs after repackaging:

- `ip_repo/servo_pwm/component.xml` may be refreshed
- `xgui/servo_pwm_v1_1.tcl` may be regenerated
- `ip_repo/servo_pwm/component.xml` is refreshed when using `package_ip_core.tcl`

### Resource estimation

Use:

```bash
vivado -mode batch -source scripts/estimate_resources.tcl
```

This performs out-of-context synthesis of top-level `servo_pwm` for:

- part: `xc7z020clg400-1`

The script writes:

- `resource_estimate.rpt`

Current measured estimate recorded in the README:

- Slice LUTs: `213`
- Slice Registers: `182`
- Block RAM Tile: `0`
- DSPs: `0`
- Bonded IOB: `4`

## Packaging / Versioning Notes

- When bumping the packaged IP version, update:
  - `ip_repo/servo_pwm/component.xml`
  - `xgui/servo_pwm_vX_Y.tcl`
  - versioned RTL wrapper names if they are part of the packaged source list
  - display/component names in `component.xml`
  - `xilinx:canUpgradeFrom` so the VLNV matches the actual vendor/library/name namespace
- After packaging-related source changes, run `./scripts/repackage_ip.sh` instead of editing package checksums by hand.
- After changing the packaged repo layout or anything that should be visible through Vivado `ip_repo_paths`, run `vivado -mode batch -source package_ip_core.tcl`.
- After structural RTL changes that may affect area, rerun `scripts/estimate_resources.tcl` and update the README if the reported utilization changes materially.
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
