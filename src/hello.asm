bits 64
global hello

section .text

hello:
    mov rax, 1
    mov rdi, 1
    mov rsi, msg
    mov rdx, msglen
    syscall

    ret

section .rodata
    msg: db "Hello, World!", 0x0A, 0
    msglen: equ $ - msg