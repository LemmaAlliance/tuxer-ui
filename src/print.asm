bits 64
global print

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
