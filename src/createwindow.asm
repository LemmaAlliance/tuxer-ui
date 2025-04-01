bits 64
global create_window
extern print
extern exit
extern exit_err
extern x11_sockfd

; Data messages for logging + other stuff
section .data
    window_width dw 800
    window_height dw 600
    creating_window  db "Creating window...", 0x0A, 0
    window_created   db "Window created.", 0x0A, 0
    win_err_msg db "Error creating window!", 0x0A, 0
    get_root_window db "Getting root window ID...", 0x0A, 0
    query_tree_snd_err db "Error sending QueryTree request!", 0x0A, 0
    query_tree_rcv_err db "Error receiving QueryTree reply!", 0x0A, 0
    root_window_err db "Error getting root window ID!", 0x0A, 0

section .bss align=4
    ; Do not exeed 32 bytes for cw_req EVER!!!!
    cw_req resb 32      ; Reserve 32 bytes for the CreateWindow request
    root_window_id resd 1 ; Reserve 4 bytes for the root window ID
    last_window_id resd 1 ; Reserve 4 bytes for the last window ID

section .text
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
create_window:
    ; Log that we are about to get the root window ID.
    mov rdi, get_root_window
    call print

    call query_tree

    ; --- Get a free window ID ---
    ; Initialize the last window ID only if it is zero.
    cmp dword [last_window_id], 0
    jne .skip_init
    ; If it is zero, set it to 0x200000.
    mov dword [last_window_id], 0x200000
    .skip_init:

    ; Generate a new window ID by incrementing the last one.
    mov eax, [last_window_id]
    add eax, 1
    mov [last_window_id], eax
    mov dword [cw_req+4], eax

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

    ; Bytes 4-7: New window ID (here we use our ID).
    mov eax, [last_window_id]
    mov dword [cw_req+4], eax

    ; Bytes 8-11: Parent window ID (use the retrieved root window ID).
    mov eax, [root_window_id]
    mov dword [cw_req+8], eax

    ; Bytes 12-13: X coordinate (0)
    mov word [cw_req+12], 0

    ; Bytes 14-15: Y coordinate (0)
    mov word [cw_req+14], 0

    ; Bytes 16-17: Width (800). Decimal 800 = 0x320.
    mov ax, [window_width]
    mov word [cw_req+16], ax

    ; Bytes 18-19: Height (600). Decimal 600 = 0x258.
    mov ax, [window_height]
    mov word [cw_req+18], ax

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

    xor rax, rax
    ret

query_tree:
    ; --- Build the QueryTree request ---
    mov byte [cw_req], 15
    mov byte [cw_req+1], 0
    mov word [cw_req+2], 2
    mov dword [cw_req+4], 0

    ; --- Send the QueryTree request ---
    ; Yes I know it is duplicated logic, but I can't be bothered.
    mov rax, 44            ; syscall: send
    mov rdi, [x11_sockfd]  ; load the connected socket file descriptor
    lea rsi, [cw_req]      ; pointer to our request buffer
    mov rdx, 8            ; length of our QueryTree request
    syscall                ; perform the send syscall
    test rax, rax
    js _query_tree_send_error

    ; --- Receive the QueryTree reply ---
    mov rax, 45            ; syscall: recv
    mov rdi, [x11_sockfd]  ; load the connected socket file descriptor
    lea rsi, [cw_req]      ; pointer to our request buffer
    mov rdx, 32            ; length of our receive buffer
    syscall                ; perform the recv syscall
    test rax, rax
    js _query_tree_receive_error

    ; Check if we received the expected number of bytes (32).
    cmp rax, 32
    jne _query_tree_receive_error

    ; Extract the root window ID from the reply (bytes 8-11).
    mov eax, [cw_req+8]
    mov [root_window_id], eax
    test eax, eax
    jz _root_window_error
    ret

send_request:
    mov rax, 44            ; syscall: send
    mov rdi, [x11_sockfd]  ; load the connected socket file descriptor
    lea rsi, [cw_req]      ; pointer to our request buffer
    mov rdx, 32            ; length of our CreateWindow request
.send_loop:
    syscall
    test rax, rax
    js .check_eintr
    cmp rax, rdx
    je .send_done
    add rsi, rax
    sub rdx, rax
    jmp .send_loop
.send_done:
    ret

.check_eintr:
    mov rdi, rax
    cmp rdi, -4
    je .send_loop
    jmp _win_error

set_window_hints:
    ; -- Set _WN_WINDOW_TYPE to _WN_WINDOW_TYPE_NORMAL --
    ; Atom for _NET_WM_WINDOW_TYPE
    mov rax, 44           ; syscall: send
    mov rdi, [x11_sockfd] ; load the connected socket file descriptor
    lea rsi, [cw_req]     ; pointer to our request buffer

    ; Build the ChangeProperty request

    ; Byte 0: Major opcode (ChangeProperty). X11’s ChangeProperty opcode is 18.
    mov byte [cw_req], 18 ; Major opcode for ChangeProperty

    ; Byte 1: Mode (0 = Replace)
    mov byte [cw_req+1], 0

    ; Bytes 2-3: Request length in 4-byte units (8 for 32 bytes).
    mov word [cw_req+2], 5

    ; Bytes 4-7: Window ID (our chosen new window ID; here 0x200000)
    mov eax, [last_window_id]
    mov dword [cw_req+4], eax

    ; Bytes 8-11: Property (atom for _NET_WM_WINDOW_TYPE)
    mov dword [cw_req+8], _NET_WM_WINDOW_TYPE ; Placeholder for the atom


_query_tree_send_error:
    mov rdi, query_tree_snd_err
    call print
    call exit_err

_query_tree_receive_error:
    mov rdi, query_tree_rcv_err
    call print
    call exit_err

_root_window_error:
    mov rdi, root_window_err
    call print
    call exit_err

_win_error:
    mov rdi, rax
    call print
    mov rdi, win_err_msg
    call print
    mov rax, -1
    call exit_err