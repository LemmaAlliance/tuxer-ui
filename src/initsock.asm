bits 64
global initsock
extern print
extern exit

section .data
    opening db 'Opening a socket.', 0x0A, 0
    opened db 'Socket opened!', 0x0A, 0
    connecting db 'Connecting to X11 server.', 0x0A, 0
    connected db 'Connected to the X11 server.', 0x0A, 0
    sending db 'Sending handshake.', 0x0A, 0
    sent db 'Handshake sent.', 0x0A, 0
    receiving db 'Receiving handshake.', 0x0A, 0
    received db 'Received handshake.', 0x0A, 0
    socket_error_msg db 'Error with socket.', 0x0A, 0
    connect_error_msg db 'Error connecting to X11.', 0x0A, 0
    handshake_error_msg db 'Error with handshake.', 0x0A, 0

    x11_socket db "/tmp/.X11-unix/X0", 0 ; Null terminal
    protocol_id db 0x6C ; Protocol ID (X11)
    major_version db 0x00, 0x00, 0x00, 0x11 ; Major version 11
    minor_version db 0x00, 0x00, 0x00, 0x00 ; Minor version 0
    client_magic db 0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC, 0xDE, 0xF0 ; Magic number
    handshake_request db 0x6C, 0x00, 0x00, 0x00, 0x11, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x12, 0x34, 0x56, 0x78 ; The handshake

section .bss
    response resb 32
    sockaddr resb 110
    response_buffer resb 16

section .text

initsock:
    mov rdi, opening
    call print

    ; Opening a socket
    mov rax, 41 ; Open a socket
    mov rdi, 1 ; Socket
    mov rsi, 1 ; SOCK_STREAM
    mov rdx, 0 ; Protocol 0
    syscall
    test rax, rax
    js _error_socket
    mov r12, rax ; Store socket FD

    mov rdi, opened
    call print

    ; Connecting an X11 socket
    mov rax, 42 ; syscall: connect to a socket
    mov rdi, r12 ; socket FD
    lea rsi, [x11_socket]
    mov rdx, 110 ; Size of socket addr
    syscall
    test rax, rax ; Did we connect?
    js _connect_error ; If not, throw an error
    
    mov rdi, connecting
    call print

    mov rax, 42 ; Syscall n for connect
    mov rdi, rbx ; Socket file descriptor
    lea rsi, [sockaddr] ; Pointer to sockaddr_un structure
    mov rdx, 110
    syscall

    mov rdi, connected
    call print

    mov rdi, sending
    call print

    ; Send handshake
    call send_handshake

    mov rdi, sent
    call print
    
    mov rdi, receiving
    call print

    ; Recieve handshake response
    call recv_handshake_response

    mov rdi, received
    call print

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
    mov rdi, response_buffer
    call print
    mov al, [response_buffer] ; Status byte
    cmp al, 0x00 ; Check if success
    jne _error_handshake
    ret

_error_socket:
    mov rdi, socket_error_msg
    call print
    call exit

_connect_error:
    mov rdi, connect_error_msg
    call print
    call exit

_error_handshake:
    mov rdi, handshake_error_msg
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