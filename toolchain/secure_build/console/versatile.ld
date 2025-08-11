ENTRY(_start)

SECTIONS
{
    /* QEMU VersatilePB loads at 0x10000 */
    . = 0x10000;
    
    .text : {
        KEEP(*(.text.boot))
        *(.text .text.*)
        *(.rodata .rodata.*)
    }
    
    . = ALIGN(4096);
    
    .data : {
        *(.data .data.*)
    }
    
    . = ALIGN(4096);
    
    __bss_start = .;
    .bss : {
        *(.bss .bss.*)
        *(COMMON)
    }
    __bss_end = .;
    
    . = ALIGN(4096);
    __end = .;
}
