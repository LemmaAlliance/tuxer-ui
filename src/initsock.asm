bits 64
global initsock

section .text

initsock:
    mov eax, 41 ; Open a socket
    mov ebx, 1 ; Open it locally on UNIX domain socket (/tmp/.X11-unix/X0)
    mov ecx, 1 ; SOCK_STREAN
    mov edx, 0
    syscall

    ret
