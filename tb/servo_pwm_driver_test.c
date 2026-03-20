#include <stdio.h>
#include <string.h>

#include "servo_pwm.h"
#include "servo_pwm_obj.h"

static u32 reg_space[16];
static unsigned write_count;

void Xil_Out32(UINTPTR addr, u32 data) {
    unsigned reg_idx = (unsigned)(addr >> 2);

    if (reg_idx < (sizeof(reg_space) / sizeof(reg_space[0]))) {
        reg_space[reg_idx] = data;
    }
    write_count++;
}

u32 Xil_In32(UINTPTR addr) {
    unsigned reg_idx = (unsigned)(addr >> 2);

    if (reg_idx < (sizeof(reg_space) / sizeof(reg_space[0]))) {
        return reg_space[reg_idx];
    }
    return 0;
}

static void expect_u32(const char *label, u32 actual, u32 expected, int *failures) {
    if (actual != expected) {
        fprintf(stderr, "%s mismatch: actual=0x%08x expected=0x%08x\n", label, actual, expected);
        (*failures)++;
    }
}

static void expect_uint(const char *label, unsigned actual, unsigned expected, int *failures) {
    if (actual != expected) {
        fprintf(stderr, "%s mismatch: actual=%u expected=%u\n", label, actual, expected);
        (*failures)++;
    }
}

int main(void) {
    ServoPwm pwm;
    int failures = 0;
    unsigned baseline_writes;

    memset(&pwm, 0, sizeof(pwm));
    memset(reg_space, 0xa5, sizeof(reg_space));
    write_count = 0;

    expect_u32("CfgInitialize status", (u32)ServoPwm_CfgInitialize(&pwm, 0), XST_SUCCESS, &failures);
    expect_u32("CfgInitialize writes control", reg_space[SPWM_CTRL_OFFSET >> 2], 0, &failures);
    expect_u32("CfgInitialize writes ui", reg_space[SPWM_UI_TICKS_OFFSET >> 2], 0, &failures);
    expect_u32("CfgInitialize writes sof", reg_space[SPWM_SOF_UI_TICKS_OFFSET >> 2], 0, &failures);
    expect_u32("CfgInitialize writes ch3", reg_space[SPWM_CH3_UI_TICKS_OFFSET >> 2], 0, &failures);

    ServoPwm_EnableCh(&pwm, 0);
    expect_u32("Enable ch0 shadow", pwm.enShadow, 0x1, &failures);
    expect_u32("Enable ch0 register", reg_space[SPWM_CTRL_OFFSET >> 2], 0x1, &failures);

    ServoPwm_EnableCh(&pwm, 3);
    expect_u32("Enable ch3 shadow", pwm.enShadow, 0x9, &failures);
    expect_u32("Enable ch3 register", reg_space[SPWM_CTRL_OFFSET >> 2], 0x9, &failures);

    ServoPwm_DisableCh(&pwm, 0);
    expect_u32("Disable ch0 shadow", pwm.enShadow, 0x8, &failures);
    expect_u32("Disable ch0 register", reg_space[SPWM_CTRL_OFFSET >> 2], 0x8, &failures);

    baseline_writes = write_count;
    ServoPwm_EnableCh(&pwm, 4);
    expect_u32("Invalid enable ignored", pwm.enShadow, 0x8, &failures);
    expect_uint("Invalid enable write count", write_count, baseline_writes, &failures);

    ServoPwm_SetChUiTicks(&pwm, 0, 1000);
    ServoPwm_SetChUiTicks(&pwm, 3, 2000);
    expect_u32("Set ch0 shadow", pwm.pulseUiTicks[0], 1000, &failures);
    expect_u32("Set ch3 shadow", pwm.pulseUiTicks[3], 2000, &failures);
    expect_u32("Set ch0 register", reg_space[SPWM_CH0_UI_TICKS_OFFSET >> 2], 1000, &failures);
    expect_u32("Set ch3 register", reg_space[SPWM_CH3_UI_TICKS_OFFSET >> 2], 2000, &failures);

    expect_u32("Get ch0", ServoPwm_GetChUiTicks(&pwm, 0), 1000, &failures);
    expect_u32("Get ch3", ServoPwm_GetChUiTicks(&pwm, 3), 2000, &failures);
    expect_u32("Get invalid channel", ServoPwm_GetChUiTicks(&pwm, 4), 0xffffffffu, &failures);

    baseline_writes = write_count;
    ServoPwm_SetChUiTicks(&pwm, 4, 1234);
    ServoPwm_SetChUiTicks(&pwm, 1, SPWM_CH_UI_TICKS_MASK + 1);
    expect_uint("Invalid channel/ticks writes ignored", write_count, baseline_writes, &failures);
    expect_u32("Channel 1 remains unchanged after invalid write", pwm.pulseUiTicks[1], 0, &failures);

    if (failures != 0) {
        fprintf(stderr, "servo_pwm_driver_test: %d failure(s)\n", failures);
        return 1;
    }

    printf("servo_pwm_driver_test: PASS\n");
    return 0;
}
