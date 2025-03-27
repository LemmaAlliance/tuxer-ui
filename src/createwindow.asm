bits 64
global create_window
extern print
extern exit
extern x11_sockfd

%define OPCODE_CREATE_WINDOW 1
%define OPCODE_GET_GEOMETRY 14
%define NEW_WINDOW_ID 0x200000

; Data messages for logging
section .data
    creating_window  db "Creating window...", 0x0A, 0
    window_created   db "Window created.", 0x0A, 0
    win_err_msg db "Error creating window!", 0x0A, 0
    get_root_window db "Getting root window ID...", 0x0A, 0
    root_window_err db "Error getting root window ID!", 0x0A, 0

; A buffer for our CreateWindow request
; We use a minimal CreateWindow request that fits the following format:
;   Byte  0: Major opcode = 1 (CreateWindow)
;   Byte  1: Depth (0 means “CopyFromParent”)
;   Bytes 2-3: Request length in 4-byte units (here: 8 → 8*4 = 32 bytes total)
;   Bytes 4-7: Window ID (our chosen new window ID; here 0x200000)
;   Bytes 8-11: Parent window (assumed to be the root; e.g. 0x20)
;   Bytes 12-13: X coordinate (0)
;   Bytes 14-15: Y coordinate (0)
;   Bytes 16-17: Width (800)
;   Bytes 18-19: Height (600)
;   Bytes 20-21: Border width (0)
;   Bytes 22-23: Class (1 for InputOutput)
;   Bytes 24-27: Visual (0 means “CopyFromParent”)
;   Bytes 28-31: Value mask (0 for no extra attributes)
section .bss align=4
    cw_req resb 32      ; Reserve 32 bytes for the CreateWindow request
    root_window_id resd 1 ; Reserve 4 bytes for the root window ID

section .text
create_window:
    ; Log that we are about to get the root window ID.
    mov rdi, get_root_window
    call print

    ; --- Build the GetGeometry request ---
    ; Byte 0: Major opcode (GetGeometry). X11’s GetGeometry opcode is 14.
    ; Byte 1: Unused (0)
    ; Bytes 2-3: Request length in 4-byte units (2 for 8 bytes).
    ; Bytes 4-7: Drawable (root window ID placeholder, e.g. 0x20).
    mov byte [cw_req], 14
    mov byte [cw_req+1], 0
    mov word [cw_req+2], 2
    mov dword [cw_req+4], 0x20

    ; --- Send the GetGeometry request ---
    jmp send_request

    test rax, rax
    js _root_window_error
    cmp rax, 32
    jl _root_window_error

    ; --- Receive the GetGeometry reply ---
    ; We use the recv syscall to read the reply from the socket.
    ; Syscall details for recv:
    ;   rax: 45          (syscall number for recv)
    ;   rdi: Socket FD   (here loaded from our global x11_sockfd)
    ;   rsi: Pointer to buffer (cw_req)
    ;   rdx: Buffer length (32 bytes)
    mov rax, 45            ; syscall: recv
    mov rdi, [x11_sockfd]  ; load the connected socket file descriptor
    lea rsi, [cw_req]      ; pointer to our request buffer
    mov rdx, 32            ; length of our receive buffer
    syscall                ; perform the recv syscall

    test rax, rax
    js _root_window_error

    ; Extract the root window ID from the reply (bytes 8-11).
    mov eax, [cw_req+8]
    mov [root_window_id], eax

    ; Check if the root window ID is valid (non-zero).
    mov eax, [cw_req+8]
    test eax, eax
    jz _root_window_error
    mov [root_window_id], eax

    ; Log that we are about to create the window.
    mov rdi, creating_window
    call print

    ; --- Build the CreateWindow request ---
    ; Byte 0: Major opcode (CreateWindow). X11’s CreateWindow opcode is 1.
    mov byte [cw_req], 1

    ; Byte 1: Depth (0 = CopyFromParent)
    mov byte [cw_req+1], 0

    ; Bytes 2-3: Request length in 4-byte units (8 for 32 bytes).
    mov word [cw_req+2], 8

    ; Bytes 4-7: New window ID (here we hardcode 0x200000).
    mov dword [cw_req+4], 0x200000

    ; Bytes 8-11: Parent window ID (use the retrieved root window ID).
    mov eax, [root_window_id]
    mov dword [cw_req+8], eax

    ; Bytes 12-13: X coordinate (0)
    mov word [cw_req+12], 0

    ; Bytes 14-15: Y coordinate (0)
    mov word [cw_req+14], 0

    ; Bytes 16-17: Width (800). Decimal 800 = 0x320.
    mov word [cw_req+16], 800

    ; Bytes 18-19: Height (600). Decimal 600 = 0x258.
    mov word [cw_req+18], 600

    ; Bytes 20-21: Border width (0)
    mov word [cw_req+20], 0

    ; Bytes 22-23: Class (1 for InputOutput)
    mov word [cw_req+22], 1

    ; Bytes 24-27: Visual (0 = CopyFromParent)
    mov dword [cw_req+24], 0

    ; Bytes 28-31: Value mask (0, meaning no additional attributes)
    mov dword [cw_req+28], 0

    ; --- Send the CreateWindow request ---
    mov rax, 44            ; syscall: send
    mov rdi, [x11_sockfd]  ; load the connected socket file descriptor
    lea rsi, [cw_req]      ; pointer to our request buffer
    mov rdx, 32            ; length of our CreateWindow request
    syscall                ; perform the send syscall

    test rax, rax
    js _win_error

    ; Log that the window was “created”.
    mov rdi, window_created
    call print

    ret

send_request:
    mov rax, 44            ; syscall: send
    mov rdi, [x11_sockfd]  ; load the connected socket file descriptor
    lea rsi, [cw_req]      ; pointer to our request buffer
    mov rdx, 32            ; length of our CreateWindow request
    syscall
    test rax, rax
    js _win_error
    cmp rax, 32
    jne send_request       ; Retry if not all bytes were sent
    ret

_root_window_error:
    mov rdi, root_window_err
    call print
    call exit

_win_error:
    mov rdi, win_err_msg
    call print
    call exit