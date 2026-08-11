.syntax unified
.cpu cortex-m3
.thumb

.section .text.kernel, "ax", %progbits

.global kernel_main
.type kernel_main, %function
.thumb_func

kernel_main:
    svc #0 @ TESTING DEFAULT_HANDLER FUNCTION

1:
    b 1b