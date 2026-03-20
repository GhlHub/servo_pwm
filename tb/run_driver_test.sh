#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "${SCRIPT_DIR}/.." && pwd)
OUT_DIR="${ROOT_DIR}/tb/sw_test"

rm -rf "${OUT_DIR}"
mkdir -p "${OUT_DIR}"

cd "${ROOT_DIR}"

gcc -std=c99 -Wall -Wextra -Werror \
  -Itb/sw_include \
  -Idrivers/servo_pwm_v1_0/src \
  drivers/servo_pwm_v1_0/src/servo_pwm.c \
  tb/servo_pwm_driver_test.c \
  -o "${OUT_DIR}/servo_pwm_driver_test"

"${OUT_DIR}/servo_pwm_driver_test"
