bits 64
extern hello

section .text
    global _start

; Using _start for development, will change later
_start:
    call hello

    mov rax, 60
    mov rdi, 0
    syscall