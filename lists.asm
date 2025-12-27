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
    mov rdi, 1
    call write
    ret

; Println
; rsi: text
; rdx: text length
println:
    call print
    push rsi
    push rdx
    mov rsi, newline
    mov rdx, newline_len
    call print
    pop rsi
    pop rdx

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
    mov rax, 60
    mov rdi, 0
    syscall
    ret


;# Conversion functions

; Int to string
; rdi: buffer
; rsi: integer
int_to_str:
    push rdx
    push r8
    push r9
    push rsi
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

    pop rsi
    pop r9
    pop r8
    pop rdx
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
    lea rdi, [rax + rdi]
    mov rax, 12
    syscall
    ret


;# List functions

; Create node
; rdi: node value
create_node:
    push rdi
    mov rdi, node_len
    call malloc
    pop rdi
    mov [rax], rdi
    ret

; Last node
; rdi: root
last_node:
    push rdi

    .loop:
        cmp QWORD [rdi + 8], 0
        je .break
        mov rdi, [rdi + 8]
        jmp .loop
    .break:
    mov rax, rdi

    pop rdi
    ret

; Append to
; rdi: root
; rsi: val
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


;# Main functions

main:
    mov rdi, 0x8899aabbccddeeff
    call create_node
    push rax

    mov rdi, rax
    mov rsi, 0x0011223344556677
    call append_to

    pop rax
    mov rdi, rax
    call last_node
    ret


global _start
_start:
    call main
    call exit