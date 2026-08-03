.syntax unified
.cpu cortex-m3
.thumb

.section .text.kernel, "ax", %progbits

.global kernel_main
.type kernel_main, %function
.thumb_func

kernel_main:
    movs r0, #10
    movs r1, #20
    adds r2, r0, r1

kernel_idle:
    b kernel_idle