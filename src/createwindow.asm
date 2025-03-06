; create_window.asm
; This snippet builds an X11 CreateWindow request and sends it using the send syscall.
; For simplicity, many X11 details are hardcoded or simplified.

bits 64
global create_window
extern print
extern exit
extern x11_sockfd

; Data messages for logging
section .data
    creating_window  db "Creating window...", 0x0A, 0
    window_created   db "Window created.", 0x0A, 0
    win_err_msg db "Error creating window!", 0x0A, 0

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
section .bss
    cw_req resb 32      ; Reserve 32 bytes for the CreateWindow request

section .text
create_window:
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

    ; Bytes 8-11: Parent window ID (for simplicity, using a placeholder value, e.g. 0x20).
    mov dword [cw_req+8], 0x20

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
    ; We use the send syscall to write the request over the socket.
    ; Syscall details for send:
    ;   rax: 44          (syscall number for send)
    ;   rdi: Socket FD   (here loaded from our global x11_sockfd)
    ;   rsi: Pointer to buffer (cw_req)
    ;   rdx: Buffer length (32 bytes)
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

_win_error:
    mov rdi, win_err_msg
    call print
    call exit