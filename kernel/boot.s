.syntax unified
.cpu cortex-m3
.thumb

.section .vectors
.word 0x20005000            @ Stack pointer address (This number is the RAM top address 20 kB)
.word reset_handler + 1     @ Boot address (+1 for set thumb mode)

.section .text
.global reset_handler

reset_handler:
    mov r0, #10           @ Move number 10 to the r0 register
    mov r1, #20           @ Move number 20 to the r1 register
    add r2, r0, r1        @ r2 = r0 + r1 (30)

loop:
    b loop       @ OS Idle