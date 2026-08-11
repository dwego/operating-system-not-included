.syntax unified
.cpu cortex-m3
.thumb

.section .text.memory, "ax", %progbits
.balign 2


/*
 * Copies the initial .data contents from Flash to RAM.
 *
 * r0 = current source address in Flash
 * r1 = current destination address in RAM
 * r2 = end of .data in RAM
 * r3 = temporary copied value
 */
.global initialize_data
.type initialize_data, %function
.thumb_func

initialize_data:
    ldr r0, =_sidata
    ldr r1, =_sdata
    ldr r2, =_edata

copy_data_loop:
    cmp r1, r2
    bhs copy_data_done

    ldr r3, [r0]
    str r3, [r1]

    adds r0, r0, #4
    adds r1, r1, #4

    b copy_data_loop

copy_data_done:
    bx lr

.size initialize_data, . - initialize_data


/*
 * Clears the .bss section in RAM.
 *
 * r0 = current address in .bss
 * r1 = end of .bss
 * r2 = zero
 */
 
.global initialize_bss
.type initialize_bss, %function
.thumb_func

initialize_bss:
    ldr r0, =_sbss
    ldr r1, =_ebss
    movs r2, #0

clear_bss_loop:
    cmp r0, r1
    bhs clear_bss_done

    str r2, [r0]
    adds r0, r0, #4

    b clear_bss_loop

clear_bss_done:
    bx lr

.size initialize_bss, . - initialize_bss