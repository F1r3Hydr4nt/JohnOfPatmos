ENTRY(_start)

SECTIONS
{
    /* Raspberry Pi kernel load address */
    . = 0x8000;
    
    .text : {
        KEEP(*(.vectors))
        KEEP(*(.text.boot))
        *(.text .text.*)
        *(.rodata .rodata.*)
        *(.got .got.*)
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
    . = ALIGN(4096);
    __bss_end = .;
    
    /* Stack and heap */
    . = ALIGN(16);
    __heap_start = .;
    . = . + 0x100000;  /* 1MB heap */
    __heap_end = .;
    
    __stack_start = .;
    . = . + 0x40000;   /* 256KB stack */
    __stack_top = .;
    
    __end = .;
}
