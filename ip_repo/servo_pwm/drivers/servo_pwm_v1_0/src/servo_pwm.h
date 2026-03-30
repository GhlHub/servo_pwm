#ifndef SERVO_PWM_H
#define SERVO_PWM_H

#ifdef __cplusplus
extern "C" {
#endif


/****************** Include Files ********************/
#include "xil_types.h"
#include "xil_io.h"
#include "xstatus.h"

#define SPWM_CTRL_OFFSET		0x00
// 0x04 Reserved
#define SPWM_UI_TICKS_OFFSET		0x08
#define SPWM_SOF_UI_TICKS_OFFSET	0x0C
// 0x10 - 0x1C reserved
#define SPWM_CH0_UI_TICKS_OFFSET	0x20
#define SPWM_CH1_UI_TICKS_OFFSET	0x24
#define SPWM_CH2_UI_TICKS_OFFSET	0x28
#define SPWM_CH3_UI_TICKS_OFFSET	0x2C

// Offset 0x00
#define SPWM_CTRL_CH_EN_MASK	0x0F
#define SPWM_CTRL_CH_EN_SHIFT	0
#define SPWM_CTRL_CH_IOB_MASK	0x0F
#define SPWM_CTRL_CH_IOB_SHIFT	4
#define SPWM_CTRL_CH_ACTIVE_MASK	0x0F
#define SPWM_CTRL_CH_ACTIVE_SHIFT	16

#define SPWM_UI_TICKS_MASK		0xFF
#define SPWM_SOF_UI_TICKS_MASK	0xFFFF
#define SPWM_CH_UI_TICKS_MASK	0xFFF

#define SPWM_mWriteReg(BaseAddress, RegOffset, Data) \
  	Xil_Out32((BaseAddress) + (RegOffset), (u32)(Data))

#define SPWM_mReadReg(BaseAddress, RegOffset) \
    Xil_In32((BaseAddress) + (RegOffset))

#ifdef __cplusplus
}
#endif

#endif
