bits 64
global initsock
extern print

section .data
    opening db 'Opening a socket', 0x0A, 0
    opened db 'Socket opened!', 0x0A, 0
    handshake_error db 'Error with handshake', 0x0A, 0
    x11_sock_path db '/tmp/.X11-unix/X1', 0 ; Null terminated string
    protocol_id db 0x6C ; Protocol ID (X11)
    major_version db 0x00, 0x00, 0x00, 0x11 ; Major version 11
    minor_version db 0x00, 0x00, 0x00, 0x00 ; Minor version 0
    client_magic db 0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC, 0xDE, 0xF0 ; Magic number
    handshake_request db 0x6C, 0x00, 0x00, 0x00, 0x11, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x12, 0x34, 0x56, 0x78 ; The handshake

section .bss
    sockaddr resb 110
    response_buffer resb 16

section .text

initsock:
    mov rdi, opening
    call print
    mov eax, 41 ; Open a socket
    mov ebx, 1 ; Open it locally on UNIX domain socket (/tmp/.X11-unix/X0)
    mov ecx, 1 ; SOCK_STREAN
    mov edx, 0 ; Protocol 0 (default)
    syscall

    mov rdi, opened
    call print

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

    ; Send handshake
    call send_handshake
    
    ; Recieve handshake response
    call recv_handshake_response

    ret

send_handshake:
    mov rax, 44
    mov rdi, rbx
    lea rsi, [handshake_request]
    mov rdx, 16
    syscall
    ret

recv_handshake_response:
    ; Allocate response space
    lea rsi, [response_buffer] ; Pointer to buffer
    mov rax, 45 ; sys_recv
    mov rdi, rbx ; socket file descriptor
    mov rdx, 16 ; number of bytes to read
    syscall

    ; Check if response is valid
    ; For now only check if the status byte is correct
    mov al, [response_buffer] ; Status byte
    cmp al, 0x00 ; Check if success
    jne .error_handshake

.error_handshake:
    mov rdi, handshake_error
    call print
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