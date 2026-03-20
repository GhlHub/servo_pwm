#ifndef XIL_IO_H
#define XIL_IO_H

#include "xil_types.h"

void Xil_Out32(UINTPTR addr, u32 data);
u32 Xil_In32(UINTPTR addr);

#endif
