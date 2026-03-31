; main.asm — Nihilum Stage-0 Derleyici Giriş Noktası
;
; Kullanım: nihilum <kaynak.nih> <çıktı.asm>
;
; Pipeline:
;   argv[1] → oku → parse_program → codegen_program → argv[2]'ye yaz
;
; Sistem çağrıları (Linux x86-64):
;   open  = 2   read  = 0   write = 1
;   close = 3   exit  = 60  creat = 85
;
; Bağımlılıklar: lexer.o  parser.o  codegen.o

BITS 64
global _start
extern parse_program
extern codegen_program
extern parse_error_flag
extern cg_error
extern out_buf
extern out_ptr

; ─────────────────────────────────────────────
; SİSTEM ÇAĞRISI NUMARALARI
; ─────────────────────────────────────────────
SYS_READ   equ 0
SYS_WRITE  equ 1
SYS_OPEN   equ 2
SYS_CLOSE  equ 3
SYS_CREAT  equ 85
SYS_EXIT   equ 60

STDIN      equ 0
STDOUT     equ 1
STDERR     equ 2

O_RDONLY   equ 0
O_WRONLY   equ 1
O_CREAT    equ 64
O_TRUNC    equ 512
CREAT_MODE equ 0644q       ; rw-r--r--

; ─────────────────────────────────────────────
; KAYNAK TAMPON
;   Stage 0: max 512 KB kaynak dosya
; ─────────────────────────────────────────────
SRC_BUF_SIZE equ 524288

section .rodata

msg_usage    db "Kullanim: nihilum <kaynak.nih> <cikti.asm>", 10, 0
msg_usage_len equ $ - msg_usage

msg_ok       db "[OK] Derleme basarili.", 10, 0
msg_ok_len   equ $ - msg_ok

msg_err_open db "[HATA] Kaynak dosya acilamadi.", 10, 0
msg_err_open_len equ $ - msg_err_open

msg_err_read db "[HATA] Kaynak dosya okunamadi.", 10, 0
msg_err_read_len equ $ - msg_err_read

msg_err_parse db "[HATA] Parser hatasi.", 10, 0
msg_err_parse_len equ $ - msg_err_parse

msg_err_cg   db "[HATA] Codegen hatasi.", 10, 0
msg_err_cg_len equ $ - msg_err_cg

msg_err_write db "[HATA] Cikti dosyasi yazilamadi.", 10, 0
msg_err_write_len equ $ - msg_err_write

section .bss

src_buf      resb SRC_BUF_SIZE
src_fd       resd 1
out_fd       resd 1

section .text

; ═══════════════════════════════════════════════════════
; YARDIMCILAR
; ═══════════════════════════════════════════════════════

; ───────────────────────────────────────────────────────
; print_str  RDI = string ptr, RSI = uzunluk → STDERR
; ───────────────────────────────────────────────────────
print_err:
    mov  rax, SYS_WRITE
    mov  rdi, STDERR
    ; RSI ve RDX çağıran tarafından ayarlanmış
    syscall
    ret

; ───────────────────────────────────────────────────────
; exit_code  DIL = çıkış kodu
; ───────────────────────────────────────────────────────
do_exit:
    mov  rax, SYS_EXIT
    movzx rdi, dil
    syscall

; ───────────────────────────────────────────────────────
; strlen  RDI = null-terminated string → RAX = uzunluk
; ───────────────────────────────────────────────────────
strlen:
    xor  rax, rax
.lp:
    cmp  byte [rdi + rax], 0
    je   .done
    inc  rax
    jmp  .lp
.done:
    ret

; ═══════════════════════════════════════════════════════
; _start
; ═══════════════════════════════════════════════════════
_start:
    ; ── Argüman kontrolü ──────────────────────────────
    ; [rsp]    = argc
    ; [rsp+8]  = argv[0]
    ; [rsp+16] = argv[1]  (kaynak)
    ; [rsp+24] = argv[2]  (çıktı)
    mov  rax, [rsp]
    cmp  rax, 3
    jl   .usage_err

    mov  r12, [rsp+16]          ; r12 = kaynak dosya yolu
    mov  r13, [rsp+24]          ; r13 = çıktı dosya yolu

    ; ── Kaynak dosyayı aç ─────────────────────────────
    mov  rax, SYS_OPEN
    mov  rdi, r12
    mov  rsi, O_RDONLY
    xor  rdx, rdx
    syscall
    test rax, rax
    js   .open_err
    mov  dword [rel src_fd], eax

    ; ── Kaynak dosyayı oku ────────────────────────────
    mov  rax, SYS_READ
    mov  edi, dword [rel src_fd]
    lea  rsi, [rel src_buf]
    mov  rdx, SRC_BUF_SIZE - 1  ; null için 1 byte boşluk
    syscall
    test rax, rax
    js   .read_err
    ; Null-terminate: src_buf[bytes_read] = 0
    lea  rcx, [rel src_buf]     ; sabit adres önce
    mov  byte [rcx + rax], 0    ; sonra dinamik offset

    ; Dosyayı kapat
    mov  rax, SYS_CLOSE
    mov  edi, dword [rel src_fd]
    syscall

    ; ── Parser ────────────────────────────────────────
    lea  rsi, [rel src_buf]
    call parse_program          ; RAX = AST_PROGRAM node (0 = hata)

    cmp  byte [rel parse_error_flag], 1
    je   .parse_err
    test rax, rax
    jz   .parse_err

    mov  r14, rax               ; r14 = AST root

    ; ── Codegen ───────────────────────────────────────
    mov  rdi, r14
    call codegen_program        ; RAX = 0 başarı, 1 hata

    cmp  byte [rel cg_error], 1
    je   .cg_err
    test rax, rax
    jnz  .cg_err

    ; ── Çıktı dosyasını oluştur ve yaz ───────────────
    mov  rax, SYS_OPEN
    mov  rdi, r13
    mov  rsi, O_WRONLY | O_CREAT | O_TRUNC
    mov  rdx, CREAT_MODE
    syscall
    test rax, rax
    js   .write_err
    mov  dword [rel out_fd], eax

    ; out_buf uzunluğunu hesapla: out_ptr - out_buf
    mov  rcx, [rel out_ptr]
    lea  rdx, [rel out_buf]
    sub  rcx, rdx               ; rcx = byte sayısı

    mov  rax, SYS_WRITE
    mov  edi, dword [rel out_fd]
    lea  rsi, [rel out_buf]
    mov  rdx, rcx
    syscall

    ; Dosyayı kapat
    mov  rax, SYS_CLOSE
    mov  edi, dword [rel out_fd]
    syscall

    ; ── Başarı ────────────────────────────────────────
    mov  rax, SYS_WRITE
    mov  rdi, STDOUT
    lea  rsi, [rel msg_ok]
    mov  rdx, msg_ok_len
    syscall

    mov  dil, 0
    jmp  do_exit

; ── Hata yolları ──────────────────────────────────────
.usage_err:
    mov  rax, SYS_WRITE
    mov  rdi, STDERR
    lea  rsi, [rel msg_usage]
    mov  rdx, msg_usage_len
    syscall
    mov  dil, 1
    jmp  do_exit

.open_err:
    mov  rax, SYS_WRITE
    mov  rdi, STDERR
    lea  rsi, [rel msg_err_open]
    mov  rdx, msg_err_open_len
    syscall
    mov  dil, 1
    jmp  do_exit

.read_err:
    mov  rax, SYS_CLOSE
    mov  edi, dword [rel src_fd]
    syscall
    mov  rax, SYS_WRITE
    mov  rdi, STDERR
    lea  rsi, [rel msg_err_read]
    mov  rdx, msg_err_read_len
    syscall
    mov  dil, 1
    jmp  do_exit

.parse_err:
    mov  rax, SYS_WRITE
    mov  rdi, STDERR
    lea  rsi, [rel msg_err_parse]
    mov  rdx, msg_err_parse_len
    syscall
    mov  dil, 1
    jmp  do_exit

.cg_err:
    mov  rax, SYS_WRITE
    mov  rdi, STDERR
    lea  rsi, [rel msg_err_cg]
    mov  rdx, msg_err_cg_len
    syscall
    mov  dil, 1
    jmp  do_exit

.write_err:
    mov  rax, SYS_WRITE
    mov  rdi, STDERR
    lea  rsi, [rel msg_err_write]
    mov  rdx, msg_err_write_len
    syscall
    mov  dil, 1
    jmp  do_exit
