.syntax unified
.cpu cortex-m3
.thumb

.section .text.handlers, "ax", %progbits

.global nmi_handler
.type nmi_handler, %function
.thumb_func

nmi_handler:
    b nmi_handler

.global hard_fault_handler
.type hard_fault_handler, %function
.thumb_func

hard_fault_handler:
    b hard_fault_handler


.global default_handler
.type default_handler, %function
.thumb_func

default_handler:
    b default_handler