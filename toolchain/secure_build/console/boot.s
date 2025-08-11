.section ".text.boot"
.global _start
.global _get_stack_pointer

_start:
    @ Detect CPU and set appropriate stack
    mrc p15, 0, r0, c0, c0, 0    @ Read CPU ID
    
    @ Set stack based on detected platform
    @ Pi 4 and newer use different memory layout
    ldr r1, =0x410fc075           @ Cortex-A7 ID (Pi 2)
    cmp r0, r1
    ldreq sp, =0x8000000          @ 128MB stack for Pi 2+
    
    @ Default stack for Pi 1/Zero/QEMU
    ldrne sp, =0x8000000          @ 128MB stack
    
    @ Enable VFP if available (Pi 1+)
    mrc p15, 0, r0, c1, c0, 2
    orr r0, r0, #0xf00000         @ Enable VFP
    mcr p15, 0, r0, c1, c0, 2
    isb
    
    @ Clear BSS
    ldr r0, =__bss_start
    ldr r1, =__bss_end
    mov r2, #0
1:  cmp r0, r1
    strlt r2, [r0], #4
    blt 1b
    
    @ Jump to C code
    bl universal_console_init
    bl main_loop
    
    @ Halt
halt:
    wfe
    b halt

_get_stack_pointer:
    mov r0, sp
    bx lr

@ ARM exception vectors
.section ".vectors", "ax"
.global _vectors
_vectors:
    ldr pc, reset_addr
    ldr pc, undefined_addr
    ldr pc, swi_addr
    ldr pc, prefetch_addr
    ldr pc, data_addr
    ldr pc, unused_addr
    ldr pc, irq_addr
    ldr pc, fiq_addr

reset_addr:     .word _start
undefined_addr: .word halt
swi_addr:       .word halt
prefetch_addr:  .word halt
data_addr:      .word halt
unused_addr:    .word halt
irq_addr:       .word halt
fiq_addr:       .word halt
