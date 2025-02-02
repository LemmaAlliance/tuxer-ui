bits 64
global initsock

section .data
    x11_sock_path db '/tmp/.X11-unix/X0', 0 ; Null terminated string

section .bss
    sockaddr resb 110

section .text

initsock:
    mov eax, 41 ; Open a socket
    mov ebx, 1 ; Open it locally on UNIX domain socket (/tmp/.X11-unix/X0)
    mov ecx, 1 ; SOCK_STREAN
    mov edx, 0 ; Protocol 0 (default)
    syscall

    mov rbx, rax ; Save socket file descriptor

    mov byte [sockaddr], 1 ; sa_family = AF_UNIX
    lea rdi, [x11_sock_path] ; Load address of /tmp/.X11-unix/X0
    mov rsi, sockaddr + 2 ; Address of sun_path (starting at byte 2)
    call strcpy ; Copy path
    
    mov rax, 42 ; Syscall n for connect
    mov rdi, rbx ; Socket file descriptor
    lea rsi, [sockaddr] ; Pointer to sockaddr_un structure
    mov rdx, 110
    syscall

    ; Send other requests

    ret

strcpy:
    ; rdi = destination
    ; rsi = source
    ; Copy string from rsi to rdi

    .loop:
        mov al, [rsi]
        mov [rdi], al
        inc rsi
        inc rdi
        test al, al ; Did we reach a null byte?
        jnz .loop ; If not continue looping
    
    ret