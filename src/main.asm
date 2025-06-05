bits 64
extern print
extern initsock
extern create_window
global exit
global exit_err

section .data
    welcome db 'Welcome to the tuxer-ui software', 0x0A, 0
    exiting db 'Exiting software...', 0x0A, 0
    loop_error db 'Error in loop!', 0x0A, 0
    sleep_ts dq 1, 0

section .text
    global _start

; Using _start for development, will change later to tuxerui
_start:
    mov rdi, welcome
    call print

    ; Initalize the socket & connect to X11
    call initsock

    ; Attempt to create a window
    mov rdi, 0
    mov rsi, 0
    mov rdx, 800
    mov rcx, 600
    call create_window
    call window_loop

    call exit

window_loop:
.loop:
    mov rax, 35            ; nanosleep
    lea rdi, [sleep_ts]    ; timespec pointer
    mov rsi, 0             ; no remaining time
    syscall
    test rax, rax
    js _loop_error
    jmp .loop

_loop_error:
    mov rdi, loop_error
    call print
    call exit

exit:
    mov rdi, exiting
    call print
    mov rax, 60
    mov rdi, 0
    syscall

exit_err:
    mov rdi, exiting
    call print
    mov rax, 60
    mov rdi, -1
    syscall
