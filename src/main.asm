bits 64
extern hello
extern initsock

section .text
    global _start

; Using _start for development, will change later to tuxerui
_start:
    call hello
    call initsock

    mov rax, 60
    mov rdi, 0
    syscall