bits 64
extern print
extern initsock

section .data
    welcome db 'Welcome to the tuxer-ui software', 0x0A, 0

section .text
    global _start

; Using _start for development, will change later to tuxerui
_start:
    mov rdi, welcome
    call print
    call initsock

    mov rax, 60
    mov rdi, 0
    syscall

