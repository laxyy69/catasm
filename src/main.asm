global _start

%define SYS_READ    0x00
%define SYS_WRITE   0x01
%define SYS_OPEN    0x02
%define SYS_CLOSE   0x03
%define SYS_FSTAT   0x05
%define SYS_EXIT    0x3c

; open() flags
%define O_RDONLY    00
%define O_WRONLY    01
%define O_RDWR      02

section .bss
struct_stat: resb 144
argc: resb 8
filename: resb 8

section .text
; exit(rdi)
exit:
    mov     rax, SYS_EXIT
    syscall

; open(filename: const char* (rdi), flags: int (rsi))
open:
    mov     rax, SYS_OPEN
    syscall
    ret

; close(fd: int (rdi))
close:
    mov     rax, SYS_CLOSE
    syscall
    ret

; read(fd: int (rdi), buf: void* (rsi), len: size_t (rdx))
read:
    mov     rax, SYS_READ
    syscall
    ret

; write(fd: int (rdi), buf: const void* (rsi), len: size_t (rdx))
write:
    mov     rax, SYS_WRITE
    syscall
    ret

; fstat(fd: int (rdi), struct stat* (rsi))
fstat:
    mov     rax, SYS_FSTAT
    syscall
    ret

read_file:
    mov     [filename], rdi

    push    rbp
    mov     rbp, rsp
    sub     rsp, 16

    ; open(filename, O_RDONLY)
    mov     rdi, [filename]
    mov     rsi, O_RDONLY
    call    open
    cmp     rax, 0
    jl      read_file_failed
    mov     DWORD [rbp - 0x04], eax

    mov     edi, DWORD [rbp - 0x04]
    mov     rsi, struct_stat
    call    fstat

    ; struct_stat.st_size
    mov     r9, [struct_stat + 0x30]
    mov     [rbp - 16], r9
    ; allocate stack memory for file
    sub     rsp, r9

    ; read(fd, ptr, 10)
    mov     edi, DWORD [rbp - 0x04]
    lea     rsi, [rsp]
    mov     rdx, [rbp - 16]
    call    read
    mov     [rbp - 0x08], eax

    ; write(1, ptr, n)
    mov     rdi, 0x01
    lea     rsi, [rsp]
    mov     rdx, [rbp - 16]
    call    write

    add     rsp, r9

    mov     edi, DWORD [rbp - 0x04]
    call    close

    mov     rax, 0x00
    add     rsp, 16
    pop     rbp
    ret
read_file_failed:
    mov     rax, -1
    add     rsp, 16
    pop     rbp
    ret

_start:
    pop     rax ; = int argc
    mov     [argc], rax
    mov     rax, rsp

    pop     rax ; = const char* argv[]
    mov     rbp, rsp
    sub     rsp, 16
    mov     [rbp - 8], rax          ; [rbp - 8] = argv
    mov     QWORD [rbp - 16], 0x01  ; [rbp - 16] = i = 0
loop_start:
    mov     rax, [rbp - 16]
    cmp     rax, [argc]
    jge     loop_end_ok

    ; read_file(argv[i])
    lea     rax, [rbp - 8]
    mov     rcx, [rbp - 16]
    mov     rdi, [rax + rcx * 8]
    call    read_file 
    cmp     rax, -1
    je      loop_end_bad

    ; i++
    mov     rcx, [rbp - 16]
    inc     rcx
    mov     [rbp - 16], rcx
    jmp     loop_start

loop_end_ok:
    mov     rdi, 0x00
    jmp     exit
loop_end_bad:
    mov     rdi, -1
    jmp     exit
