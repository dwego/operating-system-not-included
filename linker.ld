/*
 * Linker script for the Cortex-M3 kernel running on QEMU MPS2-AN385.
 *
 * The linker script defines:
 *
 * 1. Which memory regions exist.
 * 2. Where each section of the executable will be placed.
 * 3. Symbols used by the startup code, such as the stack top and the
 *    boundaries of the .data and .bss sections.
 *
 * This memory map is currently defined for the QEMU environment and may
 * need to be changed when targeting a physical microcontroller.
 */

ENTRY(reset_handler)

/*
 * Memory regions available to the kernel.
 *
 * FLASH:
 *   Stores the vector table, executable instructions, read-only data,
 *   and the initial values of the .data section.
 *
 * RAM:
 *   Stores mutable variables, zero-initialized variables, the stack,
 *   and eventually the heap.
 */
MEMORY
{
    FLASH (rx)  : ORIGIN = 0x00000000, LENGTH = 256K
    RAM   (rwx) : ORIGIN = 0x20000000, LENGTH = 64K
}

/*
 * The initial Main Stack Pointer points to the end of RAM.
 *
 * ARM stacks normally grow downward, so execution starts with the stack
 * pointer at the highest valid RAM address.
 *
 * With the current memory map:
 *
 *   RAM origin:  0x20000000
 *   RAM size:    64 KiB = 0x00010000
 *   stack top:   0x20010000
 *
 * The vector table uses this symbol as its first entry:
 *
 *   .word _stack_top
 */
_stack_top = ORIGIN(RAM) + LENGTH(RAM);

SECTIONS
{
    /*
     * Cortex-M3 vector table.
     *
     * This section must be placed at the beginning of the boot memory
     * because the processor reads:
     *
     *   offset 0x00: initial MSP value
     *   offset 0x04: reset_handler address
     *
     * The following entries contain exception and interrupt handlers.
     *
     * KEEP prevents the linker from removing the vector table when
     * section garbage collection is enabled.
     */
    .vectors ORIGIN(FLASH) :
    {
        . = ALIGN(4);

        KEEP(*(.vectors))

        . = ALIGN(4);
    } > FLASH

    /*
     * Executable machine instructions.
     *
     * The wildcard matches all input sections whose names start with
     * ".text", including:
     *
     *   .text
     *   .text.reset_handler
     *   .text.handlers
     *   .text.kernel
     */
    .text :
    {
        . = ALIGN(4);

        *(.text*)

        . = ALIGN(4);
    } > FLASH

    /*
     * Read-only data.
     *
     * This section may contain constants, strings, lookup tables, and
     * other values that do not need to be modified during execution.
     *
     * Since the values are read-only, they can remain in Flash.
     */
    .rodata :
    {
        . = ALIGN(4);

        *(.rodata*)

        . = ALIGN(4);
    } > FLASH

    /*
     * Initialized mutable data.
     *
     * Variables in this section:
     *
     *   - can be modified during execution;
     *   - have a nonzero initial value;
     *   - are used from RAM.
     *
     * Their initial values are stored in Flash and copied into RAM by
     * reset_handler before kernel_main starts.
     *
     * Example:
     *
     *   static mut SYSTEM_MODE: u32 = 1;
     *
     * VMA: RAM
     *   The address used while the program is running.
     *
     * LMA: Flash
     *   The address where the initial bytes are stored in the firmware.
     */
    .data :
    {
        . = ALIGN(4);

        /*
         * Runtime address where .data begins in RAM.
         */
        _sdata = .;

        *(.data*)

        . = ALIGN(4);

        /*
         * Runtime address immediately after .data.
         */
        _edata = .;
    } > RAM AT > FLASH

    /*
     * Flash address containing the initial .data values.
     *
     * reset_handler copies bytes from:
     *
     *   [_sidata, _sidata + data_size)
     *
     * into:
     *
     *   [_sdata, _edata)
     */
    _sidata = LOADADDR(.data);

    /*
     * Zero-initialized mutable data.
     *
     * Variables in this section:
     *
     *   - can be modified during execution;
     *   - must initially contain zero;
     *   - exist only in RAM.
     *
     * The section does not need to store a large sequence of zero bytes
     * in the firmware image. Instead, reset_handler clears this RAM
     * region before kernel_main starts.
     *
     * Example:
     *
     *   static mut TICKS: u32 = 0;
     *   static mut BUFFER: [u8; 256] = [0; 256];
     *
     * NOLOAD indicates that this section does not need initial contents
     * loaded from the firmware image.
     */
    .bss (NOLOAD) :
    {
        . = ALIGN(4);

        /*
         * Address where .bss begins in RAM.
         */
        _sbss = .;

        *(.bss*)

        /*
         * COMMON contains some uninitialized global symbols produced by
         * certain compilers and assemblers.
         */
        *(COMMON)

        . = ALIGN(4);

        /*
         * Address immediately after .bss.
         */
        _ebss = .;
    } > RAM

    /*
     * Marks the end of the statically allocated RAM sections.
     *
     * This symbol can later be used as the beginning of a heap.
     *
     * Eight-byte alignment is useful because the ARM procedure call
     * standard expects the stack to preserve eight-byte alignment at
     * public function boundaries.
     */
    . = ALIGN(8);
    _end = .;
}