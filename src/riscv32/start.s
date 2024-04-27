
    .section .init
    .globl _start
    .type _start,@function
_start:
    .cfi_startproc
    .cfi_undefined ra
.option push
.option norelax
    la  gp, __global_pointer$
.option pop

    // Continue primary hart
    csrr a0, mhartid
    li   a1, 0
    bne  a0, a1, secondary

    // Primary hart
    la sp, _stack_top
    csrw mscratch,sp

    // lw data section
    la a0, _data_lma
    la a1, _data
    la a2, _edata
    bgeu a1, a2, 2f
1:
    lw t0, (a0)
    sw t0, (a1)
    addi a0, a0, 4
    addi a1, a1, 4
    bltu a1, a2, 1b
2:

    // Clear bss section
    la a0, _bss
    la a1, _ebss
    bgeu a0, a1, 2f
1:
    sw zero, (a0)
    addi a0, a0, 4
    bltu a0, a1, 1b
2:

    // argc, argv, envp is 0
    li  a0, 0
    li  a1, 0
    li  a2, 0
    jal main
1:
    wfi
    j 1b

secondary:            // a0 id
    la   sp, _stack_top
    lI   a3, 1024  // stack_size
    li   a2, 0        // i = 0
loop:
    bgeu a2, a0, end  // if i >= id then end
    addi a2, a2, 1    // i ++
    add  sp, sp, a3
    j loop
end:
    csrw mscratch,sp
    jal subcpu_entry
1:
    wfi
    j 1b
    .cfi_endproc
