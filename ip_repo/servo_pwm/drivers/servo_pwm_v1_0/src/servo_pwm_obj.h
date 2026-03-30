#ifndef SERVO_PWM_OBJ_H
#define SERVO_PWM_OBJ_H


#ifdef __cplusplus
extern "C" {
#endif

#define SPWM_NUM_OF_CH 4
typedef struct {
#ifndef SDT
	u16 DeviceId;		/**< Unique ID  of device */
#else
	char *Name;
#endif
	UINTPTR RegBaseAddr;	/**< Register base address */
#ifdef SDT
	u16 IntrId;             /** Bits[11:0] Interrupt-id Bits[15:12]
				 * trigger type and level flags */
	UINTPTR IntrParent;     /** Bit[0] Interrupt parent type Bit[64/32:1]
				 * Parent base address */
#endif

} ServoPwm_Config, *PServoPwm_Config;

extern ServoPwm_Config ServoPwm_Config_Table[];


typedef struct {
	UINTPTR BaseAddress;

    // We shadow these registers so we don't have to read them 
	// from the device
	u32		enShadow;
	u32     uiTicks;
	u32     uiSofTicks;
	u32     pulseUiTicks[SPWM_NUM_OF_CH];
} ServoPwm, *PServoPwm;


int  ServoPwm_CfgInitialize(PServoPwm uPtr, UINTPTR EffectiveAddr);
void ServoPwm_EnableCh(PServoPwm uPtr, u32 chNum);
void ServoPwm_DisableCh(PServoPwm uPtr, u32 chNum);
void ServoPwm_SetUiTicks(PServoPwm uPtr, u32 clkTicks);
void ServoPwm_SetSofUiTicks(PServoPwm uPtr, u32 uiTicks);
void ServoPwm_SetChUiTicks(PServoPwm uPtr, u32 chNum, u32 uiTicks);
u32 ServoPwm_GetUiTicks(PServoPwm uPtr);
u32 ServoPwm_GetSofUiTicks(PServoPwm uPtr);
u32 ServoPwm_GetChUiTicks(PServoPwm uPtr, u32 chNum);
u32 ServoPwm_GetStatus(PServoPwm uPtr);



#ifdef __cplusplus
}
#endif
#endif

