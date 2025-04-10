bits 64
global initsock
extern print
extern exit
extern exit_err

section .data
    ; Messages for printing
    opening db 'Opening a socket...', 0x0A, 0
    opened db 'Socket opened!', 0x0A, 0
    connecting db 'Connecting to X11 server...', 0x0A, 0
    connected db 'Connected to the X11 server!', 0x0A, 0
    sending db 'Sending handshake...', 0x0A, 0
    sent db 'Handshake sent!', 0x0A, 0
    receiving db 'Receiving handshake...', 0x0A, 0
    received db 'Received handshake!', 0x0A, 0
    socket_error_msg db 'Error with socket!', 0x0A, 0
    connect_error_msg db 'Error connecting to X11!', 0x0A, 0
    handshake_error_msg db 'Error with handshake!', 0x0A, 0

    ; Path to the X11 server
    x11_socket_path db "/tmp/.X11-unix/X1", 0  ; Default socket path

    ; X11 Handshake request (Big Endian format)
    handshake_request db 0x6C, 0x00, 0x00, 0x00, 0x11, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x12, 0x34, 0x56, 0x78

section .bss
    response_buffer resb 16
    sockaddr resb 110
    x11_sockfd resq 1

section .text

global x11_sockfd

initsock:
    mov rdi, opening
    call print

    ; Open a socket (sys_socket)
    mov rax, 41      ; syscall: socket
    mov rdi, 1       ; AF_UNIX (Domain)
    mov rsi, 1       ; SOCK_STREAM (Type)
    mov rdx, 0       ; Protocol 0
    syscall
    test rax, rax ; Check for errors
    js _error_socket
    mov r12, rax     ; Store socket FD

    mov rdi, opened
    call print

    mov rdi, connecting
    call print

    mov byte [sockaddr], 1 ; AF_UNIX
    lea rdi, [sockaddr + 2] ; Skip the first two bytes
    lea rsi, [x11_socket_path] ; Path to the X11 socket
    call strcpy

    mov rax, 42
    mov rdx, r12
    lea rsi, [sockaddr]
    mov rdx, 110
    syscall
    test rax, rax ; Check for errors
    js _connect_error

    mov rdi, connected
    call print

    ; Put rax into the socket
    mov [x11_sockfd], rax

    mov rdi, sending
    call print

    ; Send handshake
    call send_handshake

    mov rdi, sent
    call print
    
    mov rdi, receiving
    call print

    ; Receive handshake response
    call recv_handshake_response

    mov rdi, received
    call print

    ret

send_handshake:
    mov rax, 44      ; syscall: send
    mov rdi, r12     ; socket FD
    lea rsi, [handshake_request]
    mov rdx, 16      ; Bytes to send
    syscall
    ret

recv_handshake_response:
    lea rsi, [response_buffer]  ; Buffer pointer
    mov rax, 45                 ; syscall: recv
    mov rdi, r12                ; socket FD
    mov rdx, 16                 ; Number of bytes
    syscall
    test rax, rax               ; Check if recv was successful
    js _error_handshake

    ; Check if response is valid
    mov al, [response_buffer]   ; Status byte
    cmp al, 0x00                ; Success status?
    jne _error_handshake
    ret

_error_socket:
    mov rdi, socket_error_msg
    call print
    call exit_err

_connect_error:
    mov rdi, connect_error_msg
    call print
    call exit_err

_error_handshake:
    mov rdi, handshake_error_msg
    call print
    call exit_err

strcpy:
    ; rdi = destination
    ; rsi = source
    ; Ensure source and destination are valid
    test rdi, rdi
    jz .error
    test rsi, rsi
    jz .error

    .loop:
        mov al, [rsi]       ; Load byte from source
        mov [rdi], al       ; Store byte to destination
        inc rsi
        inc rdi
        test al, al         ; Null terminator reached?
        jnz .loop
    ret

    .error:
        ; Handle error (e.g., print a message or exit)
        mov rdi, socket_error_msg
        call print
        call exit_err
