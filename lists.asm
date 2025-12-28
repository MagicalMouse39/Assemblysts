bits 64

struc node
    .value resq 0x01
    .next resq 0x01
endstruc

section .rodata
    newline db 0x0d, 0x0a
    newline_len equ $ - newline

    node_len equ 0x10

section .data
    msg db 'Prova'
    msg_len equ $ - msg

section .bss
    buffer resb 0x100
    buffer_len equ $ - buffer

section .text
;# Primitive procedures

; Print
; rsi: text
; rdx: text length
print:
    push rdi

    mov rdi, 0x01
    call write

    pop rdi
    ret

; Println
; rsi: text
println:
    push rdi
    push rsi
    push rdx

    mov rdi, rsi
    call str_len

    mov rdx, rax
    call print

    mov rsi, newline
    mov rdx, newline_len
    call print

    pop rdx
    pop rsi
    pop rdi
    ret

; Write
; rdi: file descriptor
; rsi: text
; rdx: text length
write:
    mov rax, 0x01
    syscall
    ret

; Exit
exit:
    push rdi

    mov rax, 0x3c
    mov rdi, 0x00
    syscall

    pop rdi
    ret


;# Utility procedures

; Int to string
; rdi: buffer
; rsi: integer
; rdi -> converted string
int_to_str:
    push rdi
    push rsi
    push rdx
    push rcx
    push r8
    push r9

    mov rcx, rsi
    xor rdx, rdx
    xor r9, r9

    .convert_loop:
        ; Divide by 10
        mov rax, rcx
        mov r8, 0x0a
        xor edx, edx
        idiv r8

        ; Add char '0' to the desired number
        add dl, 0x30
        mov [rdi], dl
        inc rdi
        inc r9

        mov rcx, rax

        cmp rcx, 0x00
        jg .convert_loop

    ; Insert null byte as string termination
    mov [rdi], BYTE 0x00

    mov rax, r9

    pop r9
    pop r8
    pop rcx
    pop rdx
    pop rsi
    pop rdi
    call str_reverse
    ret

; String length
; rdi: buffer
; rax -> string length
str_len:
    push rdi

    ; Loop until null byte, increment counter in rdi
    .loop:
        cmp BYTE [rdi], 0x00
        je .break
        inc rdi
        jmp .loop
    .break:
        mov rax, rdi
        pop rdi
        push rdi
        sub rax, rdi

    pop rdi
    ret

; String reverse
; rdi: buffer
; rdi -> reversed string
str_reverse:
    push rdi
    push rsi
    push rbx

    call str_len

    mov rsi, rdi
    lea rdi, [rdi + rax]
    dec rdi
    ; rsi: buffer start
    ; rdi: buffer end

    ; Loop with double index: incrementing from start and decrementing from end
    .loop:
        cmp rsi, rdi
        jge .break

        ; Exchange places using al and bl as storage BYTE registries
        mov al, [rsi]
        mov bl, [rdi]
        mov [rdi], al
        mov [rsi], bl

        inc rsi
        dec rdi
        jmp .loop
    .break:

    pop rbx
    pop rsi
    pop rdi
    ret


;# Memory procedures

; Malloc
; rdi: segment size
malloc:
    push rdi

    ; First call to SYS_BRK with rdi = 0 to get memory base address
    xor rdi, rdi
    mov rax, 0x0c
    syscall

    ; Second call to SYS_BRK with desired space value in rdi
    pop rdi
    push rdi
    lea rdi, [rax + rdi]
    mov rax, 0x0c
    syscall

    pop rdi
    ret


;# List procedures

; Create node
; rdi: node value
; rax -> node pointer
create_node:
    push rdi

    ; Create node memory space
    mov rdi, node_len
    call malloc

    ; Insert node value
    pop rdi
    mov [rax], rdi

    ret

; Last node
; rdi: root
; rax -> last node
; rdi -> list size
last_node:
    push rsi
    push rdi

    ; Loop until node->next = 0
    .loop:
        cmp QWORD [rdi + 0x08], 0x00
        je .break
        ; node = node->next
        mov rdi, [rdi + 0x08]
        jmp .loop
    .break:
    mov rax, rdi

    pop rsi
    push rax

    ; (final addr - start addr) / node_len = list size
    sub rdi, rsi
    mov rax, rdi
    mov rsi, node_len
    div rsi
    mov rdi, rax
    inc rdi

    pop rax
    pop rsi
    ret

; Append to
; rdi: root
; rsi: val
; rax -> new node pointer
append_to:
    push rdi

    ; Find last node and save index
    call last_node
    push rax

    ; Create new node with required value
    mov rdi, rsi
    call create_node

    ; Set last_node->next = new_node
    pop rdi
    mov [rdi + 8], rax

    pop rdi
    ret

; Get at
; rdi: root
; rsi: index
; rax -> node
get_at:
    push rsi
    push rdi

    ; Loop from rsi to zero
    .loop:
        cmp QWORD rsi, 0
        jle .break
        ; node = node->next
        mov rdi, [rdi + 8]
        dec rsi
        jmp .loop
    .break:
    mov rax, rdi

    pop rdi
    pop rsi
    ret

; Insert after
; rdi: root
; rsi: index
; rdx: val
; rax -> new node
insert_after:
    push rdi
    push rsi

    ; Get required node's address
    call get_at

    ; Save required node's next
    mov rsi, [rax + 8]
    push rax

    ; Create new node
    mov rdi, rdx
    call create_node

    ; Set new_node->next = required_node->next
    pop rdi
    mov [rdi + 8], rax

    ; Set required_node->next = new_node
    mov [rax + 8], rsi

    pop rsi
    pop rdi
    ret


; Remove after
; rdi: root
; rsi: index
remove_after:
    push rdi
    push rsi

    ; required_node->next = required_node->next->next;
    call get_at
    mov rdi, [rax + 8]
    mov rdi, [rdi + 8]
    mov [rax + 8], rdi

    pop rsi
    pop rdi
    ret

;# Main procedures

main:
    mov rdi, 104
    call create_node
    push rax

    mov rdi, rax
    mov rsi, 105
    call append_to

    pop rdi
    push rdi
    mov rsi, 1000
    call append_to

    pop rdi
    push rdi
    mov rsi, 1
    mov rdx, 39
    call insert_after

    pop rdi
    push rdi
    mov rsi, 2
    call get_at

    mov rsi, [rax]
    mov rdi, buffer
    call int_to_str

    mov rsi, buffer
    call println

    pop rdi
    mov rsi, 1
    call remove_after

    mov rsi, 2
    call get_at

    mov rsi, [rax]
    mov rdi, buffer
    call int_to_str

    mov rsi, buffer
    call println

    ret


global _start
_start:
    call main
    call exit