; create_window.asm
; An example assembly program whose entry point is "create_window".
; It connects to the X11 Unix domain socket, then builds and sends a CreateWindow request.
; Note: This is a simplified demonstration. In a full client you would perform a complete handshake
;       and parse the X11 setup reply to obtain proper values.

bits 64
global create_window          ; this will be our entry point
extern print                ; external routine to print a string
extern exit                 ; external routine to exit (if available)

; ===============================================================
; DATA SECTION
; ===============================================================
section .data
    msg_opening       db "Opening socket for CreateWindow script.", 0x0A, 0
    msg_socket_error  db "Error opening socket.", 0x0A, 0
    msg_connect_error db "Error connecting to X11.", 0x0A, 0
    msg_window_created db "Window created.", 0x0A, 0

    ; Unix socket path for X11 (null-terminated)
    x11_socket_path   db "/tmp/.X11-unix/X0", 0

    ; CreateWindow request template (32 bytes)
    ; Fields:
    ;   Byte 0:   reqType (1 = CreateWindow)
    ;   Byte 1:   depth (0 = CopyFromParent)
    ;   Bytes 2-3: request length in 4-byte units (8 for 32 bytes)
    ;   Bytes 4-7:  window id (placeholder)
    ;   Bytes 8-11: parent (root window id, placeholder)
    ;   Bytes 12-13: x (INT16)
    ;   Bytes 14-15: y (INT16)
    ;   Bytes 16-17: width (CARD16)
    ;   Bytes 18-19: height (CARD16)
    ;   Bytes 20-21: border width (CARD16)
    ;   Bytes 22-23: class (InputOutput = 1)
    ;   Bytes 24-27: visual id (placeholder)
    ;   Bytes 28-31: padding (zeros)
    create_window_req: times 32 db 0

; ===============================================================
; BSS SECTION
; ===============================================================
section .bss
    ; Buffer for sockaddr_un (110 bytes is a safe size)
    sockaddr resb 110

    ; Placeholders for values normally parsed from the X11 setup reply.
    ; In a real client, these come from the handshake reply.
    window_id_placeholder      resd 1  ; e.g., resource id base + 1 (0x2000001)
    root_window_placeholder    resd 1  ; e.g., the root window id (0x1000000)
    visual_id_placeholder      resd 1  ; e.g., default visual id (0x21)

; ===============================================================
; TEXT SECTION (CODE)
; ===============================================================
section .text

;------------------------------------------------------------------
; create_window - Entry point.
; This routine opens a socket to X11, connects it, sets dummy values,
; builds a CreateWindow request, sends it, then prints a confirmation.
;------------------------------------------------------------------
create_window:
    ; --- Open the socket ---
    mov rdi, msg_opening
    call print

    mov rax, 41          ; sys_socket
    mov rdi, 1           ; AF_UNIX (1)
    mov rsi, 1           ; SOCK_STREAM (1)
    mov rdx, 0           ; Protocol 0
    syscall
    test rax, rax
    js .error_socket
    mov r13, rax         ; store socket FD in r13

    ; --- Set up sockaddr_un ---
    ; The sockaddr_un structure for AF_UNIX has:
    ;   - 2 bytes for the address family (AF_UNIX = 1)
    ;   - Followed by the null-terminated path.
    mov word [sockaddr], 1         ; set family = AF_UNIX
    lea rdi, [sockaddr + 2]        ; destination for the path
    lea rsi, [x11_socket_path]     ; source path
    call strcpy                  ; copy the path

    ; --- Connect to the X11 socket ---
    mov rax, 42          ; sys_connect
    mov rdi, r13         ; socket FD
    lea rsi, [sockaddr]
    mov rdx, 110         ; size of sockaddr_un buffer
    syscall
    test rax, rax
    js .error_connect

    ; --- Set up dummy placeholders ---
    ; In a real application, these values must be parsed from the X11 setup reply.
    mov dword [window_id_placeholder], 0x2000001    ; new window id
    mov dword [root_window_placeholder], 0x1000000   ; root window id
    mov dword [visual_id_placeholder], 0x21          ; visual id

    ; --- Build the CreateWindow request ---
    ; Byte 0: reqType = 1 (CreateWindow)
    mov byte [create_window_req], 1
    ; Byte 1: depth = 0 (CopyFromParent)
    mov byte [create_window_req+1], 0
    ; Bytes 2-3: request length = 8 (32 bytes total, in 4-byte units)
    mov word [create_window_req+2], 8

    ; Bytes 4-7: window id (from placeholder)
    mov eax, [window_id_placeholder]
    mov dword [create_window_req+4], eax

    ; Bytes 8-11: parent = root window id
    mov eax, [root_window_placeholder]
    mov dword [create_window_req+8], eax

    ; Bytes 12-13: x = 0
    mov word [create_window_req+12], 0
    ; Bytes 14-15: y = 0
    mov word [create_window_req+14], 0

    ; Bytes 16-17: width = 640
    mov word [create_window_req+16], 640
    ; Bytes 18-19: height = 480
    mov word [create_window_req+18], 480

    ; Bytes 20-21: border width = 1
    mov word [create_window_req+20], 1
    ; Bytes 22-23: class = InputOutput (1)
    mov word [create_window_req+22], 1

    ; Bytes 24-27: visual id (from placeholder)
    mov eax, [visual_id_placeholder]
    mov dword [create_window_req+24], eax
    ; Bytes 28-31 are left as 0 (padding)

    ; --- Send the CreateWindow request ---
    mov rax, 44          ; sys_send
    mov rdi, r13         ; socket FD
    lea rsi, [create_window_req]
    mov rdx, 32         ; 32 bytes of request
    syscall

    ; --- Report success ---
    mov rdi, msg_window_created
    call print

    ; --- Exit gracefully ---
    mov rax, 60         ; sys_exit
    xor rdi, rdi
    syscall

; ===============================================================
; Error handlers
; ===============================================================
.error_socket:
    mov rdi, msg_socket_error
    call print
    mov rax, 60
    xor rdi, rdi
    syscall

.error_connect:
    mov rdi, msg_connect_error
    call print
    mov rax, 60
    xor rdi, rdi
    syscall

; ===============================================================
; strcpy: Copy a null-terminated string from rsi to rdi.
; ===============================================================
strcpy:
    .copy_loop:
        mov al, [rsi]
        mov [rdi], al
        inc rsi
        inc rdi
        test al, al
        jnz .copy_loop
    ret
