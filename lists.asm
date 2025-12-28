bits 64

struc node
    .value resq 1
    .next resq 1
endstruc

section .rodata
    newline db 13, 10
    newline_len equ $ - newline

    node_len equ 16

section .data
    msg db 'Prova'
    msg_len equ $ - msg

section .bss
    buffer resb 256
    buffer_len equ $ - buffer

section .text
;# Primitive functions

; Print
; rsi: text
; rdx: text length
print:
    push rdi

    mov rdi, 1
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
    mov rax, 1
    syscall
    ret

; Exit
exit:
    push rdi

    mov rax, 60
    mov rdi, 0
    syscall

    pop rdi
    ret


;# Utility functions

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
        mov rax, rcx
        mov r8, 0x0a
        xor edx, edx
        idiv r8

        add dl, 0x30
        mov [rdi], dl
        inc rdi
        inc r9

        mov rcx, rax

        cmp rcx, 0x0
        jg .convert_loop

    mov [rdi], BYTE 0x0

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

    .loop:
        cmp BYTE [rdi], 0
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

    .loop:
        cmp rsi, rdi
        jge .break

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


;# Memory functions

; Malloc
; rdi: segment size
malloc:
    push rdi

    xor rdi, rdi
    mov rax, 12
    syscall

    pop rdi
    push rdi
    lea rdi, [rax + rdi]
    mov rax, 12
    syscall

    pop rdi
    ret


;# List functions

; Create node
; rdi: node value
; rax -> node pointer
create_node:
    push rdi

    mov rdi, node_len
    call malloc
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

    .loop:
        cmp QWORD [rdi + 8], 0
        je .break
        mov rdi, [rdi + 8]
        jmp .loop
    .break:
    mov rax, rdi

    pop rsi
    push rax
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

    call last_node
    push rax

    mov rdi, rsi
    call create_node

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

    .loop:
        cmp QWORD rsi, 0
        jle .break
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

    call get_at

    mov rsi, [rax + 8]
    push rax

    mov rdi, rdx
    call create_node

    pop rdi
    mov [rdi + 8], rax

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

    call get_at
    mov rdi, [rax + 8]
    mov rdi, [rdi + 8]
    mov [rax + 8], rdi

    pop rsi
    pop rdi
    ret

;# Main functions

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