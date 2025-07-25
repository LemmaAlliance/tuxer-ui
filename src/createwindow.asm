bits 64
global create_window
global root_window_id
extern print
extern print_hex
extern exit
extern exit_err
extern x11_sockfd

; Data messages for logging + other stuff
section .data
    window_width dw 800
    window_height dw 600
    net_wm_window_type db "_NET_WM_WINDOW_TYPE", 0
    net_wm_window_type_normal db "_NET_WM_WINDOW_TYPE_NORMAL", 0
    wm_protocols db "WM_PROTOCOLS", 0
    wm_delete_window db "WM_DELETE_WINDOW", 0
    atom db "ATOM", 0
    creating_window  db "Creating window...", 0x0A, 0
    window_created   db "Window created.", 0x0A, 0
    win_err_msg db "Error creating window!", 0x0A, 0
    get_root_window db "Getting root window ID...", 0x0A, 0
    query_tree_snd_err db "Error sending QueryTree request!", 0x0A, 0
    query_tree_rcv_err db "QueryTree: Error receiving reply!", 0x0A, 0
    root_window_err db "Error getting root window ID!", 0x0A, 0
    debug_send db "Sending request...", 0x0A, 0
    debug_recv db "Receiving reply...", 0x0A, 0
    debug_reply_type db "Reply type: 0x", 0
    debug_reply_len db "Reply length: 0x", 0
    debug_root_id db "Root window ID: 0x", 0

section .bss align=4
    ; Do not exeed 32 bytes for cw_req EVER!!!!
    cw_req resb 32      ; Reserve 32 bytes for the CreateWindow request
    root_window_id resd 1 ; Reserve 4 bytes for the root window ID
    last_window_id resd 1 ; Reserve 4 bytes for the last window ID
    _NET_WM_WINDOW_TYPE resd 1
    _NET_WM_WINDOW_TYPE_NORMAL resd 1
    WM_PROTOCOLS resd 1
    WM_DELETE_WINDOW resd 1
    ATOM resd 1

section .text
; A buffer for our CreateWindow request
; We use a minimal CreateWindow request that fits the following format:
;   Byte  0: Major opcode = 1 (CreateWindow)
;   Byte  1: Depth (0 means “CopyFromParent”)
;   Bytes 2-3: Request length in 4-byte units (here: 8 → 8*4 = 32 bytes total)
;   Bytes 4-7: Window ID (our chosen new window ID; here 0x200000)
;   Bytes 8-11: Parent window (assumed to be the root; e.g. 0x20)
;   Bytes 12-13: X coordinate (Configurable)
;   Bytes 14-15: Y coordinate (Configurable)
;   Bytes 16-17: Width (Configurable)
;   Bytes 18-19: Height (Configurable)
;   Bytes 20-21: Border width (0)
;   Bytes 22-23: Class (1 for InputOutput)
;   Bytes 24-27: Visual (0 means “CopyFromParent”)
;   Bytes 28-31: Value mask (0 for no extra attributes)
create_window:
    ; Arguments:
    ; rdi: X coordinate
    ; rsi: Y coordinate
    ; rdx: Width
    ; rcx: Height

    ; Set X coordinate
    mov word [cw_req+12], di

    ; Set Y coordinate
    mov word [cw_req+14], si

    ; Set Width
    mov ax, dx
    mov word [cw_req+16], ax

    ; Set Height
    mov ax, cx
    mov word [cw_req+18], ax

    ; Log that we are about to get the root window ID.
    mov rdi, get_root_window
    call print

    call query_tree
    mov eax, [root_window_id]
    test eax, eax
    jz _root_window_error

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

    ; Bytes 20-21: Border width (0)
    mov word [cw_req+20], 0

    ; Bytes 22-23: Class (1 for InputOutput)
    mov word [cw_req+22], 1

    ; Bytes 24-27: Visual (0 = CopyFromParent)
    mov dword [cw_req+24], 0

    ; Bytes 28-31: Value mask (0, meaning no additional attributes)
    mov dword [cw_req+28], 0

    ; --- Send the CreateWindow request ---
    lea rsi, [cw_req]      ; pointer to our request buffer
    mov rdx, 32            ; length of our CreateWindow request
    call send_request

    ; Map the window so it becomes visible
    mov byte [cw_req], 8   ; MapWindow opcode
    mov byte [cw_req+1], 0
    mov word [cw_req+2], 2
    mov eax, [last_window_id]
    mov [cw_req+4], eax
    lea rsi, [cw_req]
    mov rdx, 8
    call send_request

    ; Log that the window was "created".
    mov rdi, window_created
    call print

    xor rax, rax

    ; Initialize the ATOM variable
    lea rdi, [atom]
    mov rsi, 4
    lea rdx, [ATOM]
    call intern_atom

    ; Intern _NET_WM_WINDOW_TYPE
    lea rsi, [net_wm_window_type]
    mov rsi, 20
    lea rdx, [_NET_WM_WINDOW_TYPE]
    call intern_atom

    ; Intern _NET_WM_WINDOW_TYPE_NORMAL
    lea rdi, [net_wm_window_type_normal]
    mov rsi, 24
    lea rdx, [_NET_WM_WINDOW_TYPE_NORMAL]
    call intern_atom

    ; Intern WM_PROTOCOLS
    lea rdi, [wm_protocols]
    mov rsi, 11
    lea rdx, [WM_PROTOCOLS]
    call intern_atom

    ; Intern WM_DELETE_WINDOW
    lea rdi, [wm_delete_window]
    mov rsi, 15
    lea rdx, [WM_DELETE_WINDOW]
    call intern_atom

    ; Set window hints
    call set_window_hints

    xor rax, rax  ; Indicate success
    ret

query_tree:
    ; Clear request buffer first
    push rcx
    push rdi
    xor eax, eax
    lea rdi, [cw_req]
    mov rcx, 32
    rep stosb
    pop rdi
    pop rcx

    ; --- Build the QueryTree request ---
    mov byte [cw_req], 15      ; QueryTree opcode
    mov byte [cw_req+1], 0     ; unused
    mov word [cw_req+2], 2     ; request length (8 bytes / 4)
    mov dword [cw_req+4], 0    ; window to query (root window = 0)

    ; Print debug message before sending
    push rdi
    mov rdi, debug_send
    call print
    pop rdi

    ; --- Send the QueryTree request ---
    lea rsi, [cw_req]      ; pointer to our request buffer
    mov rdx, 8             ; length of our QueryTree request
    call send_request

    ; Print debug message before receiving
    push rdi
    mov rdi, debug_recv
    call print
    pop rdi

    ; First receive just the header (32 bytes)
    lea rsi, [cw_req]      ; pointer to our request buffer
    mov rdx, 32            ; length of header
    call recv_request

    ; Print the first few bytes of the response for debugging
    push rdi
    push rax
    mov rdi, debug_reply_type
    call print
    movzx rax, byte [cw_req]  ; Get reply type
    call print_hex
    pop rax
    pop rdi

    ; Print each byte of the response for debugging
    push rdi
    push rax
    push rcx
    mov rcx, 32           ; Print first 32 bytes
    lea rdi, [cw_req]     ; Load buffer address
.debug_loop:
    push rcx
    movzx rax, byte [rdi] ; Load single byte into rax
    call print_hex        ; Print the byte
    pop rcx
    inc rdi              ; Move to next byte
    loop .debug_loop
    pop rcx
    pop rax
    pop rdi

    ; Continue with existing code...
    mov al, byte [cw_req]
    cmp al, 1             ; X11 successful reply is 1, not 0
    jne _query_tree_receive_error

    ; Extract the root window ID from offset 8
    mov eax, [cw_req+8]
    mov [root_window_id], eax

    ; Print debug message and root window ID
    push rax                    ; Save root window ID
    mov rdi, debug_root_id     ; Load "Root window ID: 0x" message
    call print
    pop rax                    ; Restore root window ID
    call print_hex             ; Print the ID in hexadecimal

    test eax, eax
    jz _root_window_error
    ret

send_request:
    ; Arguments:
    ; rsi: Pointer to the request buffer
    ; rdx: Length of the request
    mov rax, 44            ; syscall: send
    mov rdi, [x11_sockfd]  ; load the connected socket file descriptor
.send_loop:
    syscall
    test rax, rax
    js _win_error          ; Exit on error
    cmp rax, rdx
    je .send_done          ; Exit loop if all bytes are sent
    add rsi, rax           ; Adjust buffer pointer
    sub rdx, rax           ; Adjust remaining length
    jmp .send_loop
.send_done:
    ret

recv_request:
    ; Arguments:
    ; rsi: Pointer to the receive buffer
    ; rdx: Expected length of the response
    mov rax, 45            ; syscall: recv
    mov rdi, [x11_sockfd]  ; load the connected socket file descriptor
.recv_loop:
    syscall
    test rax, rax
    js _win_error          ; Exit on error
    cmp rax, rdx
    je .recv_done          ; Exit loop if all bytes are received
    add rsi, rax           ; Adjust buffer pointer
    sub rdx, rax           ; Adjust remaining length
    jmp .recv_loop
.recv_done:
    ; Verify the response length
    cmp rdx, 0
    jne _win_error         ; Error if not all bytes are received
    ret

intern_atom:
    ; Arguments:
    ; rdi: Pointer to the atom name (e.g., "_NET_WM_WINDOW_TYPE")
    ; rsi: Length of the atom name
    ; rdx: Address to store the atom ID

    ; -- Build the InternAtom request ---
    mov byte [cw_req], 16  ; Major opcode for InternAtom
    mov byte [cw_req+1], 0 ; Only one atom is requested
    mov word [cw_req+2], 2 ; Request length in 4-byte units (2 for 8 bytes)

    ; Ensure the atom name fits within the buffer
    cmp rsi, 24            ; Atom name must be <= 24 bytes
    ja _win_error

    ; Copy the atom name to the request buffer
    push rsi              ; Save length
    mov rcx, rsi          ; Length to rcx
    mov rsi, rdi          ; Original source to rsi
    lea rdi, [cw_req+8]   ; Destination
    rep movsb             ; Copy
    pop rsi               ; Restore length

    ; Adjust the request length to include the atom name
    add rsi, 8             ; Total length = header (8 bytes) + atom name
    mov rdx, rsi           ; Length of the InternAtom request

    ; -- Send the InternAtom request ---
    lea rsi, [cw_req]      ; Pointer to the request buffer
    call send_request

    ; -- Receive the InternAtom reply ---
    lea rsi, [cw_req]      ; Pointer to the receive buffer
    mov rdx, 32            ; Expected length of the reply
    call recv_request

    ; Extract the atom ID from the reply (bytes 8-11)
    mov eax, [cw_req+8]
    mov [rdx], eax         ; Store the atom ID in the provided address
    ret

set_window_hints:
    ; -- Set _WN_WINDOW_TYPE to _WN_WINDOW_TYPE_NORMAL --
    ; Atom for _NET_WM_WINDOW_TYPE
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

    ; Bytes 12-15: Type (atom for _NET_WM_WINDOW_TYPE)
    mov dword [cw_req+12], ATOM

    ; Bytes 16-19: Format (32 bits)
    mov dword [cw_req+16], 32

    ; Bytes 20-23
    mov dword [cw_req+20], _NET_WM_WINDOW_TYPE_NORMAL

    ; Send the ChangeProperty request
    mov rdx, 32           ; length of our ChangeProperty request
    call send_request

    ; --- Set WM_PROTOCOLS and WM_DELETE_WINDOW ---
    ; Atom for WM_PROTOCOLS
    mov dword [cw_req+8], WM_PROTOCOLS

    ; Atom for WM_DELETE_WINDOW
    mov dword [cw_req+12], WM_DELETE_WINDOW

    ; Send the ChangeProperty request
    call send_request

    ret

_win_error:
    mov rdi, win_err_msg
    call print
    mov rax, -1
    call exit_err

_query_tree_send_error:
    mov rdi, query_tree_snd_err
    call print
    mov rax, -2
    call exit_err

_query_tree_receive_error:
    mov rdi, query_tree_rcv_err
    call print
    mov rax, -3
    call exit_err

_root_window_error:
    mov rdi, root_window_err
    call print
    mov rax, -4
    call exit_err
