
#include "servo_pwm.h"
#include "servo_pwm_obj.h"

/*
void  Xil_Out32(UINTPTR ptr, u32 data) {
	*(u32 *)(ptr) = data;
}

u32  Xil_In32(UINTPTR ptr){
	u32 x;
	x = *(u32 *)(ptr);
	return x;
}
*/

int  ServoPwm_CfgInitialize(PServoPwm uPtr, UINTPTR EffectiveAddr) {
	int idx;
	
	uPtr->BaseAddress = EffectiveAddr;
	uPtr->enShadow    = 0;
	uPtr->uiTicks     = 0;
	uPtr->uiSofTicks  = 0;
	for(idx=0; idx < SPWM_NUM_OF_CH; idx++) {
		uPtr->pulseUiTicks[idx] = 0;
	}
	SPWM_mWriteReg(uPtr->BaseAddress, SPWM_CTRL_OFFSET, 0);
	SPWM_mWriteReg(uPtr->BaseAddress, SPWM_UI_TICKS_OFFSET, 0);
	SPWM_mWriteReg(uPtr->BaseAddress, SPWM_SOF_UI_TICKS_OFFSET, 0);
	for(idx=0; idx < SPWM_NUM_OF_CH; idx++) {
		// Initialize to 0 for now. 1000 is min, 1500 center, 2000 is max
		SPWM_mWriteReg(uPtr->BaseAddress, SPWM_CH0_UI_TICKS_OFFSET + (idx*4), 0);
	}
	return XST_SUCCESS;
}

void ServoPwm_EnableCh(PServoPwm uPtr, u32 chNum) {
	u32 en;
	
	if(chNum >= SPWM_NUM_OF_CH)
		return;
	
	en = 0x01 << chNum;
	uPtr->enShadow |= en;
	SPWM_mWriteReg(uPtr->BaseAddress, SPWM_CTRL_OFFSET, uPtr->enShadow);
}

void ServoPwm_DisableCh(PServoPwm uPtr, u32 chNum) {
	u32 en;
	
	if(chNum >= SPWM_NUM_OF_CH)
		return;
	
	en = 0x01 << chNum;
	uPtr->enShadow &= ~en;
	SPWM_mWriteReg(uPtr->BaseAddress, SPWM_CTRL_OFFSET, uPtr->enShadow);
}

void ServoPwm_SetUiTicks(PServoPwm uPtr, u32 clkTicks) {
	if(clkTicks > SPWM_UI_TICKS_MASK)
		return;
	
	uPtr->uiTicks = clkTicks;
	SPWM_mWriteReg(uPtr->BaseAddress, SPWM_UI_TICKS_OFFSET, uPtr->uiTicks);
}

void ServoPwm_SetSofUiTicks(PServoPwm uPtr, u32 uiTicks) {
	if(uiTicks > SPWM_SOF_UI_TICKS_MASK)
		return;
	
	uPtr->uiSofTicks = uiTicks;
	SPWM_mWriteReg(uPtr->BaseAddress, SPWM_SOF_UI_TICKS_OFFSET, uPtr->uiSofTicks);
}

void ServoPwm_SetChUiTicks(PServoPwm uPtr, u32 chNum, u32 uiTicks) {
	if(chNum >= SPWM_NUM_OF_CH)
		return;
	if(uiTicks > SPWM_CH_UI_TICKS_MASK)
		return;
	
	uPtr->pulseUiTicks[chNum] = uiTicks;
	SPWM_mWriteReg(uPtr->BaseAddress, SPWM_CH0_UI_TICKS_OFFSET + (chNum*4), uPtr->pulseUiTicks[chNum]);
}

u32 ServoPwm_GetUiTicks(PServoPwm uPtr) {
	return uPtr->uiTicks;
}

u32 ServoPwm_GetSofUiTicks(PServoPwm uPtr) {
	return uPtr->uiSofTicks;
}

u32 ServoPwm_GetChUiTicks(PServoPwm uPtr, u32 chNum) {
	if(chNum >= SPWM_NUM_OF_CH)
		return 0xffffffff;

	return uPtr->pulseUiTicks[chNum];
}

u32 ServoPwm_GetStatus(PServoPwm uPtr) {
	u32 x32;
	x32 = SPWM_mReadReg(uPtr->BaseAddress,SPWM_CTRL_OFFSET);
	return x32;
}
