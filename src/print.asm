bits 64
global print
global print_hex

section .data
    hex_chars db "0123456789ABCDEF", 0
    newline db 0x0A, 0

section .text

print:
    ; rdi = pointer to null-terminated string
    mov rsi, rdi      ; Save original string pointer in rsi
    xor rdx, rdx      ; Clear rdx, will be used as the length counter

find_length:
    mov al, byte [rsi + rdx]  ; Load next byte from string (using saved pointer)
    cmp al, 0                 ; Check if we reached the null terminator
    je print_string           ; If zero, end of string found
    inc rdx                   ; Increment length counter
    jmp find_length           ; Continue loop

print_string:
    mov rdi, 1      ; Set file descriptor to 1 (stdout)
    ; rsi already holds the pointer to the string
    ; rdx already holds the length of the string
    mov rax, 1      ; Syscall number for sys_write
    syscall         ; Invoke system call
    ret             ; Return from function

print_hex:
    ; Input: rax = value to print
    push rax
    push rcx
    push rdx
    push rdi
    push rsi
    push r8
    push r9
    
    mov rcx, 16         ; 16 nibbles (64 bits)
    mov r9, rax         ; Save original value
    lea r8, [hex_chars] ; Load address of hex characters
    
.print_loop:
    rol r9, 4          ; Rotate left by 4 bits
    mov rax, r9        ; Copy current value
    and rax, 0xf       ; Mask out all but the lowest 4 bits
    mov al, [r8 + rax] ; Get the corresponding hex character
    push rax           ; Save the character
    dec rcx
    jnz .print_loop

    mov rcx, 16        ; Reset counter for printing
.output_loop:
    pop rax            ; Get the character back
    push rcx           ; Save counter
    push rax           ; Save character
    sub rsp, 1         ; Make room for the character
    mov [rsp], al      ; Put character in the buffer
    mov rsi, rsp       ; Point to our character
    mov rdx, 1         ; Length = 1 character
    mov rax, 1         ; sys_write
    mov rdi, 1         ; stdout
    syscall
    add rsp, 1         ; Clean up stack
    pop rax            ; Restore character
    pop rcx            ; Restore counter
    dec rcx
    jnz .output_loop
    
    ; Print newline
    mov rdi, newline
    call print
    
    pop r9
    pop r8
    pop rsi
    pop rdi
    pop rdx
    pop rcx
    pop rax
    ret
