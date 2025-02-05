; create_window.asm
; This file provides an entry point "create_window" that solely builds
; and sends an X11 CreateWindow request using an already established
; X11 connection.
;
; Assumptions:
;   - The connected socket file descriptor is stored in "sock_fd"
;   - "window_id_placeholder" holds our new window ID.
;   - "root_window_placeholder" holds the root window ID.
;   - "visual_id_placeholder" holds the default visual ID.
;
; Assemble with: nasm -f elf64 create_window.asm -o create_window.o
; Link with: ld create_window.o -o create_window
; (If linking with other modules, adjust your linker settings accordingly.)

bits 64
global create_window
extern print    ; An external routine for printing strings (optional)
extern exit     ; An external exit routine (optional)

;-------------------------------------------------------------------------
; Data Section: Messages (for debugging)
;-------------------------------------------------------------------------
section .data
    window_created_msg db "Window created.", 0x0A, 0

;-------------------------------------------------------------------------
; BSS Section: Global Variables and Request Buffer
;-------------------------------------------------------------------------
section .bss
    ; These variables must be initialized before calling create_window:
    sock_fd                  resq 1  ; The connected socket file descriptor.
    window_id_placeholder    resd 1  ; New window ID.
    root_window_placeholder  resd 1  ; Root window ID from the X11 setup reply.
    visual_id_placeholder    resd 1  ; Default visual ID from the X11 setup reply.

    ; Buffer for the CreateWindow request (we use 32 bytes)
    create_window_req        resb 32

;-------------------------------------------------------------------------
; Text Section: The create_window Routine
;-------------------------------------------------------------------------
section .text

; create_window: Entry point to construct and send the CreateWindow request.
; The CreateWindow request (simplified) is constructed as follows:
;  Offset  Field                  Size    Description
;   0      reqType                1       (1 for CreateWindow)
;   1      depth                  1       (0 for CopyFromParent)
;   2      request length         2       (in 4-byte units; here 8 = 32 bytes)
;   4      window id              4       (our new window ID)
;   8      parent window id       4       (the root window ID)
;  12      x position             2       (we use 0)
;  14      y position             2       (we use 0)
;  16      width                  2       (e.g., 640)
;  18      height                 2       (e.g., 480)
;  20      border width           2       (e.g., 1)
;  22      class                  2       (1 for InputOutput)
;  24      visual id              4       (the visual ID)
;  28      padding                4       (zeros to pad to 32 bytes)
create_window:
    ;--- Build the CreateWindow Request in create_window_req ---
    ; Byte 0: reqType = 1 (CreateWindow)
    mov byte [create_window_req], 1

    ; Byte 1: depth = 0 (CopyFromParent)
    mov byte [create_window_req+1], 0

    ; Bytes 2-3: request length = 8 (i.e. 32 bytes total)
    mov word [create_window_req+2], 8

    ; Bytes 4-7: window id (from our placeholder)
    mov eax, [window_id_placeholder]
    mov dword [create_window_req+4], eax

    ; Bytes 8-11: parent window id (from placeholder, i.e. the root window)
    mov eax, [root_window_placeholder]
    mov dword [create_window_req+8], eax

    ; Bytes 12-13: x position = 0
    mov word [create_window_req+12], 0
    ; Bytes 14-15: y position = 0
    mov word [create_window_req+14], 0

    ; Bytes 16-17: width = 640 (you can change this value)
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

    ; Bytes 28-31: padding (set to 0)
    mov dword [create_window_req+28], 0

    ;--- Send the CreateWindow request over the already established socket ---
    ; We use the sys_send syscall (number 44 on Linux x86-64)
    ; Syscall arguments:
    ;   rax = 44 (sys_send)
    ;   rdi = socket FD
    ;   rsi = pointer to request buffer
    ;   rdx = length of request (32 bytes)
    mov rax, 44
    mov rdi, [sock_fd]    ; load the socket FD
    lea rsi, [create_window_req]
    mov rdx, 32
    syscall

    ;--- Optionally print a confirmation message ---
    mov rdi, window_created_msg
    call print

    ret
