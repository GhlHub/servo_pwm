#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "${SCRIPT_DIR}/.." && pwd)
OUT_DIR="${ROOT_DIR}/tb/xsim"

rm -rf "${OUT_DIR}"
mkdir -p "${OUT_DIR}"

cd "${ROOT_DIR}"

xvlog -sv -L unisims_ver \
  -log "${OUT_DIR}/xvlog.log" \
  tb/OBUFT.v \
  src/servo_pwm_io_pin.v \
  src/servo_pwm_ch.v \
  src/servo_pwm_gen.v \
  src/servo_pwm_slave_lite_v1_1_S00_AXI.v \
  src/servo_pwm.v \
  tb/servo_pwm_tb.sv

xelab servo_pwm_tb \
  -debug all \
  -timescale 1ns/1ps \
  -log "${OUT_DIR}/xelab.log" \
  -s servo_pwm_tb_sim

xsim servo_pwm_tb_sim \
  -tclbatch tb/xsim_run.tcl \
  -wdb "${OUT_DIR}/servo_pwm_tb.wdb" \
  -log "${OUT_DIR}/xsim.log"
