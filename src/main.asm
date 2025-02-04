bits 64
extern print
extern initsock
global exit

section .data
    welcome db 'Welcome to the tuxer-ui software', 0x0A, 0
    exiting db 'Exiting software', 0x0A, 0

section .text
    global _start

; Using _start for development, will change later to tuxerui
_start:
    mov rdi, welcome
    call print
    call initsock

    call exit

exit:
    mov rdi, exiting
    call print
    mov rax, 60
    mov rdi, 0
    syscall