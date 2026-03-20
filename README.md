# 4 Channel RC Servo Motor PWM Controller

## Description
This is a 4 Channel RC Servo PWM Controller with an AXI4-Lite processor interface implemented in RTL. This RC Servo PWM Controller is packaged as an AMD/Xilinx IP Core. Multiple instances can be instanciated to support more channels.

## But my CPU / SoC / microcontroller already has a PWM generator
True, but I doubt the microcontroller has 8 or 12 PWM generators. You could use the microcontroller's existing PWM generators for a couple of channels and implement the remaining channels using timers and some software code. But that will likely introduce some amount of jitter. In addition the software generated PWM pulses and will be slightly different than the hardware generated PWM pulses. This is because the hardware generated PWM pulses will always be identical. You could decide this is good enough for your application. But by using this IP core, you can rest assure that the generated pulses will be identical and free of jitter. To me this is important because I feel that your finished system is only as good as the foundation it's built on.

## But AMD/Xilinx has a AXI Timer/Counter core available free of charge that can generate PWM pulses. Why create another one?
The [AMD/Xilinx Timer / Counter IP Core](https://docs.amd.com/r/en-US/pg079-axi-timer/Introduction) is a general purpose IP Core. It is an excelent and mature core. Depending on your design goals, this could be a more appropirate IP Core to use. The drawback is that being a general purpose IP Core vs. an IP Core specifically implemented to control RC Servo Motors, the AMD/Xilinx core will use more FPGA resources.

## How the flight controller firmware will use this core?
- Typically the flight controller firmware will want to set a value of 1mS as a minimum value, 1.5mS as a middle value and 2mS as the maximum value.
- The register interface allows the firmware to directly write these time values without any translation that might be required when using a general purpose IP Core.

# Theory of Operation
- This IP Core operates in terms of Unit Interval or abbreviated as UI. This is what allows this core to be flight firmware friendly. The *UI Clock Ticks Register* is implemented as a terminal-count divisor, so a programmed value of `N` generates one UI pulse every `N+1` AXI clock cycles. In the case for RC Servo Motor Control, a convienant UI is the number of clock ticks for 1uS minus one. In this way the flight controller firmware can write 1000 for 1mS, 1500 for 1.5mS and 2000 for 2mS to the *Channel x UI Count Register*. 
- In addition the *Channel x UI Count Register* is internally double buffered so modifying the register's value in the middle of a PWM Frame will not cause a glitch on the output.
- Only the per-channel pulse width registers are frame-latched. Writes to the *UI Clock Ticks Register* and *Frame UI Count Register* are applied directly to the live timing logic. This is intentional design behavior, so software should avoid updating those registers in the middle of an active frame unless an immediate timing change is desired.
- Similarly the PWM Frame Width is defined in units of UI. The *Frame UI Count Register* is also implemented as a terminal count, so a programmed value of `N` spans `N+1` UI intervals before the next start-of-frame pulse. A typical PWM Frame Width for RC Servos is 20mS. So the firmware can write 19999 to *Frame UI Count Register* for a 20000 UI frame. Writing 14999 to the *Frame UI Count Register* sets the frame width to 15000 UI. Easy.

# Register Interface
## List of registers

Note: All registers are 32-bits wide.

| Offset  | Name | Description |
| ------------- | ------------- | - |
| 0x00 | Control Register | Main control register for Servo PWM controller  |
| 0x04 | Reserved | |
| 0x08 | UI Clock Ticks Register | Defines number of clock ticks per Unit Interval (UI) |
| 0x0C | Frame UI Count Register | Defines width of frame in number of UI |
| 0x10 | Reserved | |
| 0x14 | Reserved | |
| 0x18 | Reserved | |
| 0x1C | Reserved | |
| 0x20 | Channel 0 UI Count Register | Defines number of UI the pulse is high in each frame |
| 0x24 | Channel 1 UI Count Register | Defines number of UI the pulse is high in each frame |
| 0x28 | Channel 2 UI Count Register | Defines number of UI the pulse is high in each frame |
| 0x2C | Channel 3 UI Count Register | Defines number of UI the pulse is high in each frame |

### Control Register
| 31:20 | 19:16 | 15:8 | 7:4 | 3:0 |
| - | - | - | - | - |
| Reserved | Channel Active | Reserved | IOB | Channel Enable |

- Channel Active - Read Only status bit indicating that the channel is actively being driven.
- IOB - Tied to IOB pin of the IO Cell. Leave set to zero.
- Channel Enable - When set to 1, will cause the state machine to generate pulses. When a channel is first enabled, by design the state machine will generate pulses without glitches. Similarly when a channel is disabled, the state machine will complete the current frame before stopping.

### UI Clock Ticks Register
| 31:8 | 7:0 |
| - | - |
| Reserved | UI Clock Ticks Count |

- UI Clock Ticks Count - Terminal count for the UI divider. A value of `N` produces one UI pulse every `N+1` AXI clock ticks.
- Writes take effect immediately and are not frame-latched.

### Frame UI Ticks Register
| 31:16 | 15:0 |
| - | - |
| Reserved | Frame UI Count |

- Frame UI Count - Terminal count for the frame divider. A value of `N` spans `N+1` UI intervals per frame.
- Writes take effect immediately and are not frame-latched.

### Channel 0 UI Count Register
### Channel 1 UI Count Register
### Channel 2 UI Count Register
### Channel 3 UI Count Register
| 31:12 | 11:0 |
| - | - |
| Reserved | Channel UI Count |

- Channel UI Count - Defines the width of the pulse in number of UI. By design, changing this register value will not take effect until the start of the next frame. This is the only register class that is protected this way, and it prevents glitches from being accidently generated on the output pulse.
