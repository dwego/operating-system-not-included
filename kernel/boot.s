.syntax unified
.cpu cortex-m3
.thumb

.extern kernel_main
.extern initialize_data
.extern initialize_bss

.extern nmi_handler
.extern hard_fault_handler
.extern default_handler

.section .vectors, "a", %progbits
.balign 4

.global vector_table

vector_table:
    .word _stack_top          @ Initial MSP
    .word reset_handler       @ Reset
    .word nmi_handler         @ NMI
    .word hard_fault_handler  @ HardFault
    .word default_handler     @ MemManage
    .word default_handler     @ BusFault
    .word default_handler     @ UsageFault

    .word 0                   @ Reserved
    .word 0                   @ Reserved
    .word 0                   @ Reserved
    .word 0                   @ Reserved

    .word default_handler     @ SVCall
    .word default_handler     @ DebugMonitor
    .word 0                   @ Reserved
    .word default_handler     @ PendSV
    .word default_handler     @ SysTick


.section .text.reset_handler, "ax", %progbits
.balign 2

.global reset_handler
.type reset_handler, %function
.thumb_func

reset_handler:
    bl initialize_data
    bl initialize_bss
    bl kernel_main

reset_hang:
    b reset_hang

.size reset_handler, . - reset_handler