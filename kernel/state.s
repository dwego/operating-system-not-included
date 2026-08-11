.syntax unified
.cpu cortex-m3
.thumb

/*
 * Mutable values with non-zero initial contents.
 * Their initial bytes are stored in Flash and copied to RAM at boot.
 */
.section .data, "aw", %progbits
.balign 4

.global system_state
system_state:
    .word 1                 @ 0 = off, 1 = booting, 2 = running, 3 = fault


/*
 * Mutable values that must start at zero.
 * They reserve space in RAM and are cleared by reset_handler.
 */
.section .bss, "aw", %nobits
.balign 4

.global kernel_ticks
kernel_ticks:
    .space 4                @ 32-bit tick counter

.global last_fault
last_fault:
    .space 4                @ Identifier of the last detected fault