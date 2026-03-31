extern nihilum_font
; ──────────────────────────────────
section .text

global draw_char
draw_char:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov rax, qword [rbp+64]
    mov qword [rbp-8], rax
    mov rax, qword [rbp+56]
    mov qword [rbp-16], rax
    mov rax, qword [rbp+48]
    mov qword [rbp-24], rax
    mov rax, qword [rbp+40]
    mov qword [rbp-32], rax
    mov rax, qword [rbp+32]
    mov qword [rbp-40], rax
    mov rax, qword [rbp+24]
    mov qword [rbp-48], rax
    mov rax, qword [rbp+16]
    mov qword [rbp-56], rax
    push qword [rbp-24]
    push qword [rbp-32]
    mov rax, 8
    push rax
    pop rbx
    pop rax
    imul rax, rbx
    push rax
    pop rbx
    pop rax
    add rax, rbx
    push rax
    pop qword [rbp-64]
    push qword [rbp-64]
    pop rax
    mov rax, qword [rax]
    push rax
    pop qword [rbp-72]
    mov rax, 0
    push rax
    pop qword [rbp-80]
    mov rax, 0
    push rax
    pop qword [rbp-88]
    mov rax, 0
    push rax
    pop qword [rbp-96]
    mov rax, 0
    push rax
    pop qword [rbp-104]
    mov rax, 0
    push rax
    pop qword [rbp-112]
    mov rax, 0
    push rax
    pop qword [rbp-120]
    mov rax, 0
    push rax
    pop qword [rbp-128]
    mov rax, 0
    push rax
    pop qword [rbp-136]
    mov rax, 0
    push rax
    pop qword [rbp-144]
    mov rax, 0
    push rax
    pop qword [rbp-152]
    mov rax, 0
    push rax
    pop qword [rbp-160]
    mov rax, 0
    push rax
    pop qword [rbp-168]
    mov rax, 0
    push rax
    pop qword [rbp-176]
    mov rax, 0
    push rax
    pop qword [rbp-184]
    mov rax, 0
    push rax
    pop qword [rbp-80]
.wstart_0:
    push qword [rbp-80]
    mov rax, 8
    push rax
    pop rbx
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    push rax
    pop rax
    test rax, rax
    je .wend_0
    push qword [rbp-72]
    pop qword [rbp-88]
    mov rax, 0
    push rax
    pop qword [rbp-96]
.wstart_1:
    push qword [rbp-96]
    push qword [rbp-80]
    pop rbx
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    push rax
    pop rax
    test rax, rax
    je .wend_1
    push qword [rbp-88]
    mov rax, 256
    push rax
    pop rbx
    pop rax
    cqo
    idiv rbx
    push rax
    pop qword [rbp-88]
    push qword [rbp-96]
    mov rax, 1
    push rax
    pop rbx
    pop rax
    add rax, rbx
    push rax
    pop qword [rbp-96]
    jmp .wstart_1
.wend_1:
    push qword [rbp-88]
    push qword [rbp-88]
    mov rax, 256
    push rax
    pop rbx
    pop rax
    cqo
    idiv rbx
    push rax
    mov rax, 256
    push rax
    pop rbx
    pop rax
    imul rax, rbx
    push rax
    pop rbx
    pop rax
    sub rax, rbx
    push rax
    pop qword [rbp-104]
    mov rax, 0
    push rax
    pop qword [rbp-112]
    mov rax, 128
    push rax
    pop qword [rbp-120]
.wstart_2:
    push qword [rbp-112]
    mov rax, 8
    push rax
    pop rbx
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    push rax
    pop rax
    test rax, rax
    je .wend_2
    push qword [rbp-104]
    push qword [rbp-120]
    pop rbx
    pop rax
    cqo
    idiv rbx
    push rax
    pop qword [rbp-128]
    push qword [rbp-128]
    push qword [rbp-128]
    mov rax, 2
    push rax
    pop rbx
    pop rax
    cqo
    idiv rbx
    push rax
    mov rax, 2
    push rax
    pop rbx
    pop rax
    imul rax, rbx
    push rax
    pop rbx
    pop rax
    sub rax, rbx
    push rax
    pop qword [rbp-136]
    push qword [rbp-136]
    mov rax, 1
    push rax
    pop rbx
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    push rax
    pop rax
    test rax, rax
    je .else_3
    mov rax, 0
    push rax
    pop qword [rbp-144]
.wstart_4:
    push qword [rbp-144]
    mov rax, 3
    push rax
    pop rbx
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    push rax
    pop rax
    test rax, rax
    je .wend_4
    mov rax, 0
    push rax
    pop qword [rbp-152]
.wstart_5:
    push qword [rbp-152]
    mov rax, 3
    push rax
    pop rbx
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    push rax
    pop rax
    test rax, rax
    je .wend_5
    push qword [rbp-40]
    push qword [rbp-112]
    mov rax, 3
    push rax
    pop rbx
    pop rax
    imul rax, rbx
    push rax
    pop rbx
    pop rax
    add rax, rbx
    push rax
    push qword [rbp-144]
    pop rbx
    pop rax
    add rax, rbx
    push rax
    pop qword [rbp-160]
    push qword [rbp-48]
    push qword [rbp-80]
    mov rax, 3
    push rax
    pop rbx
    pop rax
    imul rax, rbx
    push rax
    pop rbx
    pop rax
    add rax, rbx
    push rax
    push qword [rbp-152]
    pop rbx
    pop rax
    add rax, rbx
    push rax
    pop qword [rbp-168]
    push qword [rbp-168]
    push qword [rbp-16]
    pop rbx
    pop rax
    imul rax, rbx
    push rax
    push qword [rbp-160]
    pop rbx
    pop rax
    add rax, rbx
    push rax
    mov rax, 4
    push rax
    pop rbx
    pop rax
    imul rax, rbx
    push rax
    pop qword [rbp-176]
    push qword [rbp-8]
    push qword [rbp-176]
    pop rbx
    pop rax
    add rax, rbx
    push rax
    pop qword [rbp-184]
    push qword [rbp-56]
    push qword [rbp-184]
    pop rax
    pop rbx
    mov qword [rax], rbx
    push qword [rbp-152]
    mov rax, 1
    push rax
    pop rbx
    pop rax
    add rax, rbx
    push rax
    pop qword [rbp-152]
    jmp .wstart_5
.wend_5:
    push qword [rbp-144]
    mov rax, 1
    push rax
    pop rbx
    pop rax
    add rax, rbx
    push rax
    pop qword [rbp-144]
    jmp .wstart_4
.wend_4:
    jmp .endif_3
.else_3:
.endif_3:
    push qword [rbp-120]
    mov rax, 2
    push rax
    pop rbx
    pop rax
    cqo
    idiv rbx
    push rax
    pop qword [rbp-120]
    push qword [rbp-112]
    mov rax, 1
    push rax
    pop rbx
    pop rax
    add rax, rbx
    push rax
    pop qword [rbp-112]
    jmp .wstart_2
.wend_2:
    push qword [rbp-80]
    mov rax, 1
    push rax
    pop rbx
    pop rax
    add rax, rbx
    push rax
    pop qword [rbp-80]
    jmp .wstart_0
.wend_0:
    mov rsp, rbp
    pop rbp
    ret

global print_hex
print_hex:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov rax, qword [rbp+64]
    mov qword [rbp-8], rax
    mov rax, qword [rbp+56]
    mov qword [rbp-16], rax
    mov rax, qword [rbp+48]
    mov qword [rbp-24], rax
    mov rax, qword [rbp+40]
    mov qword [rbp-32], rax
    mov rax, qword [rbp+32]
    mov qword [rbp-40], rax
    mov rax, qword [rbp+24]
    mov qword [rbp-48], rax
    mov rax, qword [rbp+16]
    mov qword [rbp-56], rax
    mov rax, 1152921504606846976
    push rax
    pop qword [rbp-64]
    push qword [rbp-32]
    pop qword [rbp-72]
    mov rax, 0
    push rax
    pop qword [rbp-80]
    mov rax, 0
    push rax
    pop qword [rbp-88]
    mov rax, 0
    push rax
    pop qword [rbp-96]
    mov rax, 0
    push rax
    pop qword [rbp-104]
    push qword [rbp-8]
    push qword [rbp-16]
    push qword [rbp-24]
    mov rax, 48
    push rax
    push qword [rbp-72]
    push qword [rbp-40]
    push qword [rbp-56]
    call draw_char
    push rax
    pop rax
    push qword [rbp-72]
    mov rax, 24
    push rax
    pop rbx
    pop rax
    add rax, rbx
    push rax
    pop qword [rbp-72]
    push qword [rbp-8]
    push qword [rbp-16]
    push qword [rbp-24]
    mov rax, 120
    push rax
    push qword [rbp-72]
    push qword [rbp-40]
    push qword [rbp-56]
    call draw_char
    push rax
    pop rax
    push qword [rbp-72]
    mov rax, 24
    push rax
    pop rbx
    pop rax
    add rax, rbx
    push rax
    pop qword [rbp-72]
.wstart_6:
    push qword [rbp-80]
    mov rax, 16
    push rax
    pop rbx
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    push rax
    pop rax
    test rax, rax
    je .wend_6
    push qword [rbp-48]
    push qword [rbp-64]
    pop rbx
    pop rax
    cqo
    idiv rbx
    push rax
    pop qword [rbp-88]
    push qword [rbp-88]
    push qword [rbp-88]
    mov rax, 16
    push rax
    pop rbx
    pop rax
    cqo
    idiv rbx
    push rax
    mov rax, 16
    push rax
    pop rbx
    pop rax
    imul rax, rbx
    push rax
    pop rbx
    pop rax
    sub rax, rbx
    push rax
    pop qword [rbp-96]
    push qword [rbp-96]
    mov rax, 10
    push rax
    pop rbx
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    push rax
    pop rax
    test rax, rax
    je .else_7
    push qword [rbp-96]
    mov rax, 48
    push rax
    pop rbx
    pop rax
    add rax, rbx
    push rax
    pop qword [rbp-104]
    jmp .endif_7
.else_7:
.endif_7:
    push qword [rbp-96]
    mov rax, 9
    push rax
    pop rbx
    pop rax
    cmp rax, rbx
    setg al
    movzx rax, al
    push rax
    pop rax
    test rax, rax
    je .else_8
    push qword [rbp-96]
    mov rax, 55
    push rax
    pop rbx
    pop rax
    add rax, rbx
    push rax
    pop qword [rbp-104]
    jmp .endif_8
.else_8:
.endif_8:
    push qword [rbp-8]
    push qword [rbp-16]
    push qword [rbp-24]
    push qword [rbp-104]
    push qword [rbp-72]
    push qword [rbp-40]
    push qword [rbp-56]
    call draw_char
    push rax
    pop rax
    push qword [rbp-72]
    mov rax, 24
    push rax
    pop rbx
    pop rax
    add rax, rbx
    push rax
    pop qword [rbp-72]
    push qword [rbp-64]
    mov rax, 16
    push rax
    pop rbx
    pop rax
    cqo
    idiv rbx
    push rax
    pop qword [rbp-64]
    push qword [rbp-80]
    mov rax, 1
    push rax
    pop rbx
    pop rax
    add rax, rbx
    push rax
    pop qword [rbp-80]
    jmp .wstart_6
.wend_6:
    mov rsp, rbp
    pop rbp
    ret

global isr_handler
isr_handler:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
extern sys_fb
extern sys_scanline
extern sys_font
    lea rax, [rel sys_fb]
    push rax
    pop qword [rbp-8]
    push qword [rbp-8]
    pop rax
    mov rax, qword [rax]
    push rax
    pop qword [rbp-16]
    lea rax, [rel sys_scanline]
    push rax
    pop qword [rbp-24]
    push qword [rbp-24]
    pop rax
    mov rax, qword [rax]
    push rax
    pop qword [rbp-32]
    lea rax, [rel sys_font]
    push rax
    pop qword [rbp-40]
    push qword [rbp-40]
    pop rax
    mov rax, qword [rax]
    push rax
    pop qword [rbp-48]
    mov rax, 0x00FF000000FF0000
    push rax
    pop qword [rbp-56]
    push qword [rbp-16]
    push qword [rbp-32]
    push qword [rbp-48]
    mov rax, 50
    push rax
    mov rax, 50
    push rax
    mov rax, 0xDEADBEEF
    push rax
    push qword [rbp-56]
    call print_hex
    push rax
    pop rax
.wstart_9:
    mov rax, 1
    push rax
    mov rax, 1
    push rax
    pop rbx
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    push rax
    pop rax
    test rax, rax
    je .wend_9
    jmp .wstart_9
.wend_9:
    mov rsp, rbp
    pop rbp
    ret

global alloc_page
alloc_page:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
extern pmm_count
extern pmm_starts
extern pmm_pages
    lea rax, [rel pmm_count]
    push rax
    pop qword [rbp-8]
    push qword [rbp-8]
    pop rax
    mov rax, qword [rax]
    push rax
    pop qword [rbp-16]
    mov rax, 0
    push rax
    pop qword [rbp-24]
    lea rax, [rel pmm_starts]
    push rax
    pop qword [rbp-32]
    lea rax, [rel pmm_pages]
    push rax
    pop qword [rbp-40]
    mov rax, 0
    push rax
    pop qword [rbp-48]
    mov rax, 0
    push rax
    pop qword [rbp-56]
    mov rax, 0
    push rax
    pop qword [rbp-64]
    mov rax, 0
    push rax
    pop qword [rbp-72]
.wstart_10:
    push qword [rbp-24]
    push qword [rbp-16]
    pop rbx
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    push rax
    pop rax
    test rax, rax
    je .wend_10
    push qword [rbp-32]
    push qword [rbp-24]
    mov rax, 8
    push rax
    pop rbx
    pop rax
    imul rax, rbx
    push rax
    pop rbx
    pop rax
    add rax, rbx
    push rax
    pop qword [rbp-48]
    push qword [rbp-40]
    push qword [rbp-24]
    mov rax, 8
    push rax
    pop rbx
    pop rax
    imul rax, rbx
    push rax
    pop rbx
    pop rax
    add rax, rbx
    push rax
    pop qword [rbp-56]
    push qword [rbp-56]
    pop rax
    mov rax, qword [rax]
    push rax
    pop qword [rbp-64]
    push qword [rbp-64]
    mov rax, 0
    push rax
    pop rbx
    pop rax
    cmp rax, rbx
    setg al
    movzx rax, al
    push rax
    pop rax
    test rax, rax
    je .else_11
    push qword [rbp-48]
    pop rax
    mov rax, qword [rax]
    push rax
    pop qword [rbp-72]
    push qword [rbp-72]
    mov rax, 4096
    push rax
    pop rbx
    pop rax
    add rax, rbx
    push rax
    push qword [rbp-48]
    pop rax
    pop rbx
    mov qword [rax], rbx
    push qword [rbp-64]
    mov rax, 1
    push rax
    pop rbx
    pop rax
    sub rax, rbx
    push rax
    push qword [rbp-56]
    pop rax
    pop rbx
    mov qword [rax], rbx
    push qword [rbp-72]
    pop rax
    mov rsp, rbp
    pop rbp
    ret
    jmp .endif_11
.else_11:
.endif_11:
    push qword [rbp-24]
    mov rax, 1
    push rax
    pop rbx
    pop rax
    add rax, rbx
    push rax
    pop qword [rbp-24]
    jmp .wstart_10
.wend_10:
    mov rax, 0
    push rax
    pop rax
    mov rsp, rbp
    pop rbp
    ret
    mov rsp, rbp
    pop rbp
    ret

global efi_main
efi_main:
    push rbp
    mov rbp, rsp
    sub rsp, 2048
    mov qword [rbp-8], rcx
    mov qword [rbp-16], rdx
    push qword [rbp-16]
    mov rax, 64
    push rax
    pop rbx
    pop rax
    add rax, rbx
    push rax
    pop qword [rbp-24]
    push qword [rbp-24]
    pop rax
    mov rax, qword [rax]
    push rax
    pop qword [rbp-32]
    push qword [rbp-32]
    mov rax, 48
    push rax
    pop rbx
    pop rax
    add rax, rbx
    push rax
    pop qword [rbp-40]
    push qword [rbp-40]
    pop rax
    mov rax, qword [rax]
    push rax
    pop qword [rbp-48]
    push qword [rbp-32]
    pop rcx
    push qword [rbp-48]
    pop rax
    sub rsp, 32
    call rax
    add rsp, 32
    push rax
    pop rax
    push qword [rbp-16]
    mov rax, 96
    push rax
    pop rbx
    pop rax
    add rax, rbx
    push rax
    pop qword [rbp-56]
    push qword [rbp-56]
    pop rax
    mov rax, qword [rax]
    push rax
    pop qword [rbp-64]
    push qword [rbp-64]
    mov rax, 320
    push rax
    pop rbx
    pop rax
    add rax, rbx
    push rax
    pop qword [rbp-72]
    push qword [rbp-72]
    pop rax
    mov rax, qword [rax]
    push rax
    pop qword [rbp-80]
    mov rax, 0x6a5180d0de7afb96
    push rax
    pop qword [rbp-88]
    mov rax, 0x4a3823dc9042a9de
    push rax
    pop qword [rbp-96]
    mov rax, 0
    push rax
    pop qword [rbp-104]
    lea rax, [rbp-96]
    push rax
    mov rax, 0
    push rax
    lea rax, [rbp-104]
    push rax
    pop r8
    pop rdx
    pop rcx
    push qword [rbp-80]
    pop rax
    sub rsp, 32
    call rax
    add rsp, 32
    push rax
    pop qword [rbp-112]
    push qword [rbp-112]
    mov rax, 0
    push rax
    pop rbx
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    push rax
    pop rax
    test rax, rax
    je .else_12
    push qword [rbp-104]
    mov rax, 24
    push rax
    pop rbx
    pop rax
    add rax, rbx
    push rax
    pop qword [rbp-120]
    push qword [rbp-120]
    pop rax
    mov rax, qword [rax]
    push rax
    pop qword [rbp-128]
    push qword [rbp-128]
    mov rax, 24
    push rax
    pop rbx
    pop rax
    add rax, rbx
    push rax
    pop qword [rbp-136]
    push qword [rbp-136]
    pop rax
    mov rax, qword [rax]
    push rax
    pop qword [rbp-144]
    push qword [rbp-128]
    mov rax, 8
    push rax
    pop rbx
    pop rax
    add rax, rbx
    push rax
    pop qword [rbp-152]
    push qword [rbp-152]
    pop rax
    mov rax, qword [rax]
    push rax
    pop qword [rbp-160]
    push qword [rbp-160]
    mov rax, 4
    push rax
    pop rbx
    pop rax
    add rax, rbx
    push rax
    pop rax
    mov rax, qword [rax]
    push rax
    pop qword [rbp-168]
    push qword [rbp-168]
    mov rax, 4294967296
    push rax
    pop rbx
    pop rax
    cqo
    idiv rbx
    push rax
    pop qword [rbp-176]
    push qword [rbp-168]
    push qword [rbp-176]
    mov rax, 4294967296
    push rax
    pop rbx
    pop rax
    imul rax, rbx
    push rax
    pop rbx
    pop rax
    sub rax, rbx
    push rax
    pop qword [rbp-184]
    push qword [rbp-184]
    pop qword [rbp-192]
extern nihilum_font
    lea rax, [rel nihilum_font]
    push rax
    pop qword [rbp-200]
    mov rax, 0x0000FFFF0000FFFF
    push rax
    pop qword [rbp-208]
    mov rax, 0x00FF000000FF0000
    push rax
    pop qword [rbp-216]
    push qword [rbp-184]
    mov rax, 2
    push rax
    pop rbx
    pop rax
    cqo
    idiv rbx
    push rax
    mov rax, 220
    push rax
    pop rbx
    pop rax
    sub rax, rbx
    push rax
    pop qword [rbp-224]
    push qword [rbp-176]
    mov rax, 2
    push rax
    pop rbx
    pop rax
    cqo
    idiv rbx
    push rax
    mov rax, 50
    push rax
    pop rbx
    pop rax
    sub rax, rbx
    push rax
    pop qword [rbp-232]
    push qword [rbp-144]
    push qword [rbp-192]
    push qword [rbp-200]
    push qword [rbp-224]
    push qword [rbp-232]
    push qword [rbp-144]
    push qword [rbp-208]
    call print_hex
    push rax
    pop rax
    push qword [rbp-232]
    mov rax, 40
    push rax
    pop rbx
    pop rax
    add rax, rbx
    push rax
    pop qword [rbp-232]
    push qword [rbp-144]
    push qword [rbp-192]
    push qword [rbp-200]
    push qword [rbp-224]
    push qword [rbp-232]
    push qword [rbp-16]
    push qword [rbp-216]
    call print_hex
    push rax
    pop rax
extern sys_fb
extern sys_scanline
extern sys_font
    lea rax, [rel sys_fb]
    push rax
    pop qword [rbp-240]
    push qword [rbp-144]
    push qword [rbp-240]
    pop rax
    pop rbx
    mov qword [rax], rbx
    lea rax, [rel sys_scanline]
    push rax
    pop qword [rbp-248]
    push qword [rbp-192]
    push qword [rbp-248]
    pop rax
    pop rbx
    mov qword [rax], rbx
    lea rax, [rel sys_font]
    push rax
    pop qword [rbp-256]
    push qword [rbp-200]
    push qword [rbp-256]
    pop rax
    pop rbx
    mov qword [rax], rbx
    push qword [rbp-64]
    mov rax, 56
    push rax
    pop rbx
    pop rax
    add rax, rbx
    push rax
    pop qword [rbp-264]
    push qword [rbp-264]
    pop rax
    mov rax, qword [rax]
    push rax
    pop qword [rbp-272]
    push qword [rbp-64]
    mov rax, 232
    push rax
    pop rbx
    pop rax
    add rax, rbx
    push rax
    pop qword [rbp-280]
    push qword [rbp-280]
    pop rax
    mov rax, qword [rax]
    push rax
    pop qword [rbp-288]
    mov rax, 8192
    push rax
    pop qword [rbp-296]
    mov rax, 0
    push rax
    pop qword [rbp-304]
    mov rax, 0
    push rax
    pop qword [rbp-312]
    mov rax, 0
    push rax
    pop qword [rbp-320]
    lea rax, [rel mmap_buf]
    push rax
    pop qword [rbp-328]
    lea rax, [rbp-320]
    push rax
    pop qword [rbp-336]
    sub rsp, 8
    push qword [rbp-312]
    lea rax, [rbp-296]
    push rax
    push qword [rbp-328]
    lea rax, [rbp-304]
    push rax
    lea rax, [rbp-312]
    push rax
    pop r9
    pop r8
    pop rdx
    pop rcx
    push qword [rbp-272]
    pop rax
    sub rsp, 32
    call rax
    add rsp, 32
    push rax
    pop qword [rbp-344]
    add rsp, 16
    push qword [rbp-232]
    mov rax, 40
    push rax
    pop rbx
    pop rax
    add rax, rbx
    push rax
    pop qword [rbp-232]
    push qword [rbp-144]
    push qword [rbp-192]
    push qword [rbp-200]
    push qword [rbp-224]
    push qword [rbp-232]
    push qword [rbp-344]
    mov rax, 0x0000FF000000FF00
    push rax
    call print_hex
    push rax
    pop rax
    push qword [rbp-8]
    push qword [rbp-304]
    mov rax, 0
    push rax
    mov rax, 0
    push rax
    pop r9
    pop r8
    pop rdx
    pop rcx
    push qword [rbp-288]
    pop rax
    sub rsp, 32
    call rax
    add rsp, 32
    push rax
    pop qword [rbp-352]
    push qword [rbp-232]
    mov rax, 40
    push rax
    pop rbx
    pop rax
    add rax, rbx
    push rax
    pop qword [rbp-232]
    push qword [rbp-144]
    push qword [rbp-192]
    push qword [rbp-200]
    push qword [rbp-224]
    push qword [rbp-232]
    push qword [rbp-352]
    mov rax, 0x00FF00FF00FF00FF
    push rax
    call print_hex
    push rax
    pop rax
    cli
extern setup_idt_asm
    call setup_idt_asm
    mov rax, 0
    push rax
    pop qword [rbp-360]
    mov rax, 0
    push rax
    pop qword [rbp-368]
    mov rax, 0
    push rax
    pop qword [rbp-376]
    mov rax, 0
    push rax
    pop qword [rbp-384]
    mov rax, 0
    push rax
    pop qword [rbp-392]
    push qword [rbp-232]
    mov rax, 40
    push rax
    pop rbx
    pop rax
    add rax, rbx
    push rax
    pop qword [rbp-232]
.wstart_13:
    push qword [rbp-360]
    push qword [rbp-296]
    pop rbx
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    push rax
    pop rax
    test rax, rax
    je .wend_13
    push qword [rbp-328]
    push qword [rbp-360]
    pop rbx
    pop rax
    add rax, rbx
    push rax
    pop qword [rbp-368]
    push qword [rbp-368]
    pop rax
    mov rax, qword [rax]
    push rax
    pop qword [rbp-376]
    push qword [rbp-376]
    mov rax, 7
    push rax
    pop rbx
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    push rax
    pop rax
    test rax, rax
    je .else_14
    push qword [rbp-368]
    mov rax, 8
    push rax
    pop rbx
    pop rax
    add rax, rbx
    push rax
    pop rax
    mov rax, qword [rax]
    push rax
    pop qword [rbp-384]
    push qword [rbp-368]
    mov rax, 24
    push rax
    pop rbx
    pop rax
    add rax, rbx
    push rax
    pop rax
    mov rax, qword [rax]
    push rax
    pop qword [rbp-392]
    push qword [rbp-232]
    push qword [rbp-176]
    mov rax, 50
    push rax
    pop rbx
    pop rax
    sub rax, rbx
    push rax
    pop rbx
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    push rax
    pop rax
    test rax, rax
    je .else_15
    push qword [rbp-144]
    push qword [rbp-192]
    push qword [rbp-200]
    push qword [rbp-224]
    push qword [rbp-232]
    push qword [rbp-384]
    mov rax, 0x0000FF000000FF00
    push rax
    call print_hex
    push rax
    pop rax
    push qword [rbp-144]
    push qword [rbp-192]
    push qword [rbp-200]
    push qword [rbp-224]
    mov rax, 425
    push rax
    pop rbx
    pop rax
    add rax, rbx
    push rax
    push qword [rbp-232]
    push qword [rbp-392]
    mov rax, 0x0000FFFF0000FFFF
    push rax
    call print_hex
    push rax
    pop rax
extern pmm_count
    lea rax, [rel pmm_count]
    push rax
    pop qword [rbp-400]
    push qword [rbp-400]
    pop rax
    mov rax, qword [rax]
    push rax
    pop qword [rbp-408]
    push qword [rbp-408]
    mov rax, 64
    push rax
    pop rbx
    pop rax
    cmp rax, rbx
    setl al
    movzx rax, al
    push rax
    pop rax
    test rax, rax
    je .else_16
extern pmm_starts
    lea rax, [rel pmm_starts]
    push rax
    pop qword [rbp-416]
    push qword [rbp-416]
    push qword [rbp-408]
    mov rax, 8
    push rax
    pop rbx
    pop rax
    imul rax, rbx
    push rax
    pop rbx
    pop rax
    add rax, rbx
    push rax
    pop qword [rbp-424]
    push qword [rbp-384]
    push qword [rbp-424]
    pop rax
    pop rbx
    mov qword [rax], rbx
extern pmm_pages
    lea rax, [rel pmm_pages]
    push rax
    pop qword [rbp-432]
    push qword [rbp-432]
    push qword [rbp-408]
    mov rax, 8
    push rax
    pop rbx
    pop rax
    imul rax, rbx
    push rax
    pop rbx
    pop rax
    add rax, rbx
    push rax
    pop qword [rbp-440]
    push qword [rbp-392]
    push qword [rbp-440]
    pop rax
    pop rbx
    mov qword [rax], rbx
    push qword [rbp-408]
    mov rax, 1
    push rax
    pop rbx
    pop rax
    add rax, rbx
    push rax
    push qword [rbp-400]
    pop rax
    pop rbx
    mov qword [rax], rbx
    jmp .endif_16
.else_16:
.endif_16:
    push qword [rbp-232]
    mov rax, 40
    push rax
    pop rbx
    pop rax
    add rax, rbx
    push rax
    pop qword [rbp-232]
    jmp .endif_15
.else_15:
.endif_15:
    jmp .endif_14
.else_14:
.endif_14:
    push qword [rbp-360]
    push qword [rbp-312]
    pop rbx
    pop rax
    add rax, rbx
    push rax
    pop qword [rbp-360]
    jmp .wstart_13
.wend_13:
    jmp .endif_12
.else_12:
.endif_12:
.wstart_17:
    mov rax, 1
    push rax
    mov rax, 1
    push rax
    pop rbx
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    push rax
    pop rax
    test rax, rax
    je .wend_17
    jmp .wstart_17
.wend_17:
section .bss
mmap_buf: resb 8192
pmm_starts: resq 64
pmm_pages:  resq 64
pmm_count:  resq 1
section .text
    push qword [rbp-112]
    pop rax
    mov rsp, rbp
    pop rbp
    ret
    mov rsp, rbp
    pop rbp
    ret

