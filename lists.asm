BITS 64

struc node
    .value resd 1
    .next resq 1
endstruc

section .rodata
    newline db 13, 10
    newline_len equ $ - newline

    node_len equ 12

section .data
    msg db 'Prova'
    msg_len equ $ - msg

section .bss


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


global _start
_start:
    mov rsi, msg
    mov rdx, msg_len
    call println

    mov rdi, 12
    call create_node    

    call exit