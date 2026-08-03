/* Only for set MPS2-AN385 machine config for QEMU */

MEMORY
{
  FLASH (rx) : ORIGIN = 0x00000000, LENGTH = 256K
  RAM   (rwx): ORIGIN = 0x20000000, LENGTH = 64K
}

SECTIONS
{
  .text : {
    KEEP(*(.vectors))
    *(.text)
  } > FLASH
}

