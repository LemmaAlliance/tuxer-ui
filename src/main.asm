bits 64
extern print
extern initsock
extern create_window
global exit

section .data
    welcome db 'Welcome to the tuxer-ui software', 0x0A, 0
    exiting db 'Exiting software...', 0x0A, 0

section .text
    global _start

; Using _start for development, will change later to tuxerui
_start:
    mov rdi, welcome
    call print

    ; Initalize the socket & connect to X11
    call initsock

    ; Attempt to create a window
    call create_window
    ;call window_loop

    call exit

window_loop:
    mov rax, 35
    mov rdi, -1
    mov rsi, 0
    mov rdx, 0
    syscall
    jmp window_loop

exit:
    mov rdi, exiting
    call print
    mov rax, 60
    mov rdi, 0
    syscall