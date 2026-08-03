# Cortex-M3 Startup

## Overview

The Cortex-M3 startup process defines how the processor transitions from a reset state to the execution of the operating system kernel.

Unlike an application running on top of an existing operating system, a bare-metal kernel does not have a runtime responsible for preparing the processor and memory. The kernel must provide its own startup code, vector table, exception handlers, memory layout, and initial stack configuration.

The startup process is currently divided into three main files:

Each file has a specific responsibility:

```text
boot.s
├── defines the vector table
└── defines the reset handler

handlers.s
└── defines exception and fault handlers

kernel.s
└── defines the main kernel entry point

linker.ld
├── defines the memory regions
├── places sections in Flash and RAM
└── defines symbols used during startup
```

The initial implementation targets the ARM Cortex-M3 processor emulated by QEMU using the `mps2-an385` machine.

The general startup flow is:

```text
Power-on or reset
        ↓
Load the initial Main Stack Pointer
        ↓
Load the reset handler address
        ↓
Execute the reset handler
        ↓
Prepare the runtime environment
        ↓
Enter kernel_main
```

---

## Boot sequence

When the Cortex-M3 leaves the reset state, it does not begin by executing the first bytes in memory as normal instructions.

Instead, the processor interprets the first two 32-bit words of the vector table as special initialization values:

```text
vector_table[0] → initial MSP value
vector_table[1] → reset handler address
```

The processor performs an operation conceptually equivalent to:

```text
MSP = memory[vector_table_base + 0x00]
PC  = memory[vector_table_base + 0x04]
```

This operation is performed automatically by the Cortex-M3 hardware. It is not implemented as Assembly instructions inside `boot.s`.

For the current memory layout, the vector table begins at address `0x00000000`:

```text
0x00000000  initial MSP value
0x00000004  reset_handler address
0x00000008  nmi_handler address
0x0000000C  hard_fault_handler address
```

After loading the initial MSP and PC, the processor begins fetching and executing instructions from `reset_handler`.

The current boot sequence is therefore:

```text
CPU reset
    ↓
Read the first vector table entry
    ↓
Set MSP to the top of RAM
    ↓
Read the second vector table entry
    ↓
Set PC to reset_handler
    ↓
Execute reset_handler
    ↓
Call kernel_main
```

The remaining vector table entries are not used during the normal reset path. They are accessed only when their corresponding exceptions or interrupts occur.

---

## Vector table

The vector table is a sequence of 32-bit values stored at the beginning of the boot memory.

The first entry contains the initial stack pointer. Every other implemented entry contains the address of an exception or interrupt handler.

The current table is declared in `boot.s`:

```asm
.section .vectors, "a", %progbits
.balign 4

.global vector_table

vector_table:
    .word _stack_top
    .word reset_handler
    .word nmi_handler
    .word hard_fault_handler
    .word default_handler
    .word default_handler
    .word default_handler

    .word 0
    .word 0
    .word 0
    .word 0

    .word default_handler
    .word default_handler
    .word 0
    .word default_handler
    .word default_handler
```

The first sixteen entries are defined by the Cortex-M architecture:

| Index | Offset | Entry        |
| ----: | -----: | ------------ |
|     0 | `0x00` | Initial MSP  |
|     1 | `0x04` | Reset        |
|     2 | `0x08` | NMI          |
|     3 | `0x0C` | HardFault    |
|     4 | `0x10` | MemManage    |
|     5 | `0x14` | BusFault     |
|     6 | `0x18` | UsageFault   |
|     7 | `0x1C` | Reserved     |
|     8 | `0x20` | Reserved     |
|     9 | `0x24` | Reserved     |
|    10 | `0x28` | Reserved     |
|    11 | `0x2C` | SVCall       |
|    12 | `0x30` | DebugMonitor |
|    13 | `0x34` | Reserved     |
|    14 | `0x38` | PendSV       |
|    15 | `0x3C` | SysTick      |

Interrupts specific to the board or microcontroller begin after these sixteen entries.

The following directive selects the section used to store the table:

```asm
.section .vectors, "a", %progbits
```

Its components mean:

```text
.vectors   section name
a          the section must occupy memory
%progbits  the section contains bytes stored in the executable
```

The vector table contains data rather than executable instructions. For this reason, the section has the allocatable flag `a`, but not the executable flag `x`.

The alignment directive:

```asm
.balign 4
```

ensures that the table starts at an address aligned to four bytes. Each vector table entry is one 32-bit word and therefore occupies four bytes.

The linker script must explicitly place this section at the beginning of Flash:

```ld
.vectors ORIGIN(FLASH) :
{
    KEEP(*(.vectors))
} > FLASH
```

The `KEEP` command prevents the linker from removing the table, even if no normal instruction directly references it.

---

## Main Stack Pointer

MSP means **Main Stack Pointer**.

The Cortex-M3 provides two stack pointers:

```text
MSP — Main Stack Pointer
PSP — Process Stack Pointer
```

After reset, the processor starts in Thread mode using the MSP. Exception handlers also execute using the MSP.

The initial value of the MSP is stored in the first entry of the vector table:

```asm
.word _stack_top
```

The `_stack_top` symbol is defined by the linker:

```ld
_stack_top = ORIGIN(RAM) + LENGTH(RAM);
```

For the current QEMU memory configuration:

```ld
RAM (rwx) : ORIGIN = 0x20000000, LENGTH = 64K
```

The calculation is:

```text
RAM origin = 0x20000000
RAM size   = 0x00010000
RAM end    = 0x20010000
```

Therefore:

```text
_stack_top = 0x20010000
```

The stack begins at the upper boundary of RAM and grows toward lower addresses:

```text
Higher addresses

0x20010000  ← initial MSP
0x2000FFFC
0x2000FFF8
0x2000FFF4
     ↓
Stack growth

Lower addresses
```

When an instruction pushes values onto the stack, the processor decreases the stack pointer before storing the values.

For example:

```asm
push {r4, lr}
```

conceptually performs:

```text
MSP = MSP - 8
memory[MSP]     = r4
memory[MSP + 4] = lr
```

Using `_stack_top` instead of a fixed address keeps the startup code synchronized with the memory layout. If the RAM size changes in `linker.ld`, the initial stack pointer is automatically recalculated.

In a future multitasking implementation, the kernel may use the stack pointers separately:

```text
MSP → kernel and exception-handler stack
PSP → currently executing task stack
```

During the initial startup implementation, only the MSP is used.

---

## Reset handler

The reset handler is the first function executed by the processor after the initial MSP and PC have been loaded from the vector table.

The current implementation is:

```asm
.section .text.reset_handler, "ax", %progbits

.global reset_handler
.type reset_handler, %function
.thumb_func

reset_handler:
    bl kernel_main

reset_hang:
    b reset_hang
```

The reset handler currently transfers execution directly to `kernel_main`.

The `bl` instruction means **branch with link**. It changes the PC to the address of `kernel_main` while saving the return address in the Link Register:

```text
LR = address after the bl instruction
PC = kernel_main address
```

The flow is:

```text
reset_handler
      ↓
bl kernel_main
      ↓
kernel_main executes
```

The kernel is not expected to return. However, if `kernel_main` returns accidentally, execution continues at `reset_hang`:

```asm
reset_hang:
    b reset_hang
```

This creates an infinite loop and prevents the processor from continuing into an undefined region of memory.

The `.thumb_func` directive marks `reset_handler` as a Thumb function. The Cortex-M3 executes only Thumb instructions, and exception-handler addresses stored in the vector table must identify valid Thumb code.

As the kernel evolves, the reset handler will also become responsible for preparing the runtime memory before calling `kernel_main`:

```text
reset_handler
├── copy .data from Flash to RAM
├── clear .bss in RAM
├── initialize essential processor state
└── call kernel_main
```

The reset handler runs only once after each reset. It is responsible for preparing the execution environment, while `kernel_main` contains the main operating-system logic.
