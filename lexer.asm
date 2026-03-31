; lexer.asm — Nihilum Stage-0 Lexer (x86-64 NASM)
; Çağrı sözleşmesi:
;   Giriş : RSI = kaynak buffer'daki mevcut pozisyon
;   Çıkış : AL  = token tipi (u8)
;            RDI = token başlangıç pointer'ı (IDENT / INT_LIT için)
;            RSI = güncellenmiş pointer (token sonrası)

BITS 64

; ─────────────────────────────────────────────
; TOKEN SABİTLERİ
; ─────────────────────────────────────────────
TOKEN_EOF         equ 0    ; gerçek dosya sonu — parser derlemeyi bitirir
TOKEN_INVALID     equ 99   ; tanımsız karakter — parser sözdizimi hatası fırlatır
TOKEN_IDENT       equ 1
TOKEN_INT_LIT     equ 2

TOKEN_FN          equ 10
TOKEN_LET         equ 11
TOKEN_MUT         equ 12
TOKEN_IF          equ 13
TOKEN_ELSE        equ 14
TOKEN_WHILE       equ 15
TOKEN_RETURN      equ 16

TOKEN_U8          equ 20
TOKEN_U16         equ 21
TOKEN_U32         equ 22
TOKEN_U64         equ 23
TOKEN_I8          equ 24
TOKEN_I16         equ 25
TOKEN_I32         equ 26
TOKEN_I64         equ 27

TOKEN_LPAREN      equ 40
TOKEN_RPAREN      equ 41
TOKEN_LBRACE      equ 42
TOKEN_RBRACE      equ 43
TOKEN_COLON       equ 44
TOKEN_COMMA       equ 45
TOKEN_SEMICOLON   equ 46
TOKEN_EQ          equ 47
TOKEN_AMP         equ 48
TOKEN_STAR        equ 49
TOKEN_DOT         equ 50

TOKEN_ARROW       equ 60
TOKEN_DOTSTAR     equ 61
TOKEN_EQEQ        equ 62
TOKEN_NEQ         equ 63
TOKEN_LT          equ 64
TOKEN_GT          equ 65
TOKEN_LEQ         equ 66
TOKEN_GEQ         equ 67

TOKEN_PLUS        equ 70
TOKEN_MINUS       equ 71
TOKEN_SLASH       equ 72

TOKEN_ASM         equ 80   ; asm "..."
TOKEN_STRING_LIT  equ 81   ; "..." string literal
TOKEN_UEFI_CALL   equ 82   ; uefi_call keyword
TOKEN_EFI_FN      equ 83   ; efi_fn keyword
TOKEN_EXTERN      equ 84

section .bss
global str_content_end
str_content_end resq 1      ; STRING_LIT: kapanış " konumu

section .rodata

; Keyword string sabitleri (null-terminated)
kw_fn     db "fn",0
kw_let    db "let",0
kw_mut    db "mut",0
kw_if     db "if",0
kw_else   db "else",0
kw_while  db "while",0
kw_return db "return",0
kw_asm       db "asm",0
kw_uefi_call db "uefi_call",0
kw_extern    db "extern",0
kw_efi_fn    db "efi_fn",0

kw_u8     db "u8",0
kw_u16    db "u16",0
kw_u32    db "u32",0
kw_u64    db "u64",0
kw_i8     db "i8",0
kw_i16    db "i16",0
kw_i32    db "i32",0
kw_i64    db "i64",0

section .text
global lexer_next_token

; ─────────────────────────────────────────────
; is_whitespace
;   Giriş : AL = karakter
;   Çıkış : AL = 1 boşluksa, 0 değilse
; ─────────────────────────────────────────────
is_whitespace:
    cmp al, ' '
    je .true
    cmp al, 9       ; \t
    je .true
    cmp al, 10      ; \n
    je .true
    cmp al, 13      ; \r
    je .true
    xor al, al
    ret
.true:
    mov al, 1
    ret

; ─────────────────────────────────────────────
; is_alpha_or_underscore
;   Giriş : AL = karakter
;   Çıkış : AL = 1 ise [A-Za-z_], 0 değilse
;   Not   : Rakamları KAPSAMAZ — ident başlangıcı için
; ─────────────────────────────────────────────
is_alpha_or_underscore:
    cmp al, 'A'
    jl .check_lower
    cmp al, 'Z'
    jle .true
.check_lower:
    cmp al, 'a'
    jl .check_us
    cmp al, 'z'
    jle .true
.check_us:
    cmp al, '_'
    je .true
    xor al, al
    ret
.true:
    mov al, 1
    ret

; ─────────────────────────────────────────────
; is_alnum_underscore
;   Giriş : AL = karakter
;   Çıkış : AL = 1 ise [A-Za-z0-9_], 0 değilse
;   Not   : Rakamları da kapsar — ident devamı için
; ─────────────────────────────────────────────
is_alnum_underscore:
    cmp al, '0'
    jl .check_alpha
    cmp al, '9'
    jle .true
.check_alpha:
    cmp al, 'A'
    jl .check_lower
    cmp al, 'Z'
    jle .true
.check_lower:
    cmp al, 'a'
    jl .check_us
    cmp al, 'z'
    jle .true
.check_us:
    cmp al, '_'
    je .true
    xor al, al
    ret
.true:
    mov al, 1
    ret

; ─────────────────────────────────────────────
; is_digit_dec
;   Giriş : AL = karakter
;   Çıkış : AL = 1 ise '0'..'9', 0 değilse
; ─────────────────────────────────────────────
is_digit_dec:
    cmp al, '0'
    jb .false
    cmp al, '9'
    ja .false
    mov al, 1
    ret
.false:
    xor al, al
    ret

; ─────────────────────────────────────────────
; is_hex_digit
;   Giriş : AL = karakter
;   Çıkış : AL = 1 ise [0-9A-Fa-f], 0 değilse
; ─────────────────────────────────────────────
is_hex_digit:
    cmp al, '0'
    jb .false
    cmp al, '9'
    jle .true
    cmp al, 'A'
    jb .false
    cmp al, 'F'
    jle .true
    cmp al, 'a'
    jb .false
    cmp al, 'f'
    jle .true
.false:
    xor al, al
    ret
.true:
    mov al, 1
    ret

; ─────────────────────────────────────────────
; skip_whitespace
;   Giriş : RSI = mevcut buffer pointer
;   Çıkış : RSI = boşluk sonrası pointer
;
; ─────────────────────────────────────────────
skip_whitespace:
.loop:
    mov al, byte [rsi]
    test al, al
    jz .done                ; EOF → dur
    push rsi
    call is_whitespace      ; AL giriş, AL çıkış
    pop rsi
    cmp al, 1
    jne .done
    inc rsi
    jmp .loop
.done:
    ret

; ─────────────────────────────────────────────
; scan_identifier
;   Giriş : RSI = ilk karakter (harf veya _)
;   Çıkış : RDI = başlangıç pointer
;            RSI = ident sonrası ilk geçersiz karakter
;
; ─────────────────────────────────────────────
scan_identifier:
    mov rdi, rsi
.loop:
    mov al, byte [rsi]
    test al, al
    jz .done
    push rsi
    call is_alnum_underscore   ; AL giriş & çıkış
    pop rsi
    cmp al, 1
    jne .done
    inc rsi
    jmp .loop
.done:
    ret

; ─────────────────────────────────────────────
; compare_string
;   Giriş : RDI = token başlangıcı
;            RSI = token sonu (son karakterin bir sonrası)
;            RDX = null-terminated keyword pointer
;   Çıkış : AL  = 1 eşitse, 0 değilse
;
; ─────────────────────────────────────────────
compare_string:
    push rbx
    mov rcx, rsi
    sub rcx, rdi               ; rcx = token uzunluğu

    mov r8, rdx
    xor r9, r9
.find_kw_len:
    mov bl, byte [r8 + r9]
    cmp bl, 0
    je .lengths_known
    inc r9
    jmp .find_kw_len
.lengths_known:
    cmp rcx, r9
    jne .not_equal             ; uzunluklar farklı → eşit değil

    test rcx, rcx
    jz .equal                  ; her ikisi de sıfır uzunluk → eşit

    xor r10, r10
.cmp_loop:
    mov al, byte [rdi + r10]
    cmp al, byte [r8 + r10]
    jne .not_equal
    inc r10
    cmp r10, rcx
    jne .cmp_loop

.equal:
    mov al, 1
    pop rbx
    ret
.not_equal:
    xor al, al
    pop rbx
    ret

; ─────────────────────────────────────────────
; lookup_keyword
;   Giriş : RDI = token başlangıcı, RSI = token sonu
;   Çıkış : AL  = keyword token sabiti ya da TOKEN_IDENT
; ─────────────────────────────────────────────
lookup_keyword:
    ; Her keyword için compare_string çağrılır.
    ; compare_string RDI/RSI/RDX'i okur, sadece RDX değişir.

    lea rdx, [rel kw_fn]
    call compare_string
    cmp al, 1
    je .ret_fn

    lea rdx, [rel kw_let]
    call compare_string
    cmp al, 1
    je .ret_let

    lea rdx, [rel kw_mut]
    call compare_string
    cmp al, 1
    je .ret_mut

    lea rdx, [rel kw_if]
    call compare_string
    cmp al, 1
    je .ret_if

    lea rdx, [rel kw_else]
    call compare_string
    cmp al, 1
    je .ret_else

    lea rdx, [rel kw_while]
    call compare_string
    cmp al, 1
    je .ret_while

    lea rdx, [rel kw_return]
    call compare_string
    cmp al, 1
    je .ret_return

    lea rdx, [rel kw_asm]
    call compare_string
    cmp al, 1
    je .ret_asm

    lea rdx, [rel kw_uefi_call]
    call compare_string
    cmp al, 1
    je .ret_uefi_call

    lea rdx, [rel kw_extern]
    call compare_string
    cmp al, 1
    je .ret_extern

    lea rdx, [rel kw_efi_fn]
    call compare_string
    cmp al, 1
    je .ret_efi_fn

    lea rdx, [rel kw_u8]
    call compare_string
    cmp al, 1
    je .ret_u8

    lea rdx, [rel kw_u16]
    call compare_string
    cmp al, 1
    je .ret_u16

    lea rdx, [rel kw_u32]
    call compare_string
    cmp al, 1
    je .ret_u32

    lea rdx, [rel kw_u64]
    call compare_string
    cmp al, 1
    je .ret_u64

    lea rdx, [rel kw_i8]
    call compare_string
    cmp al, 1
    je .ret_i8

    lea rdx, [rel kw_i16]
    call compare_string
    cmp al, 1
    je .ret_i16

    lea rdx, [rel kw_i32]
    call compare_string
    cmp al, 1
    je .ret_i32

    lea rdx, [rel kw_i64]
    call compare_string
    cmp al, 1
    je .ret_i64

    mov al, TOKEN_IDENT
    ret

.ret_fn:     mov al, TOKEN_FN
             ret
.ret_let:    mov al, TOKEN_LET
             ret
.ret_mut:    mov al, TOKEN_MUT
             ret
.ret_if:     mov al, TOKEN_IF
             ret
.ret_else:   mov al, TOKEN_ELSE
             ret
.ret_while:  mov al, TOKEN_WHILE
             ret
.ret_return: mov al, TOKEN_RETURN
             ret
.ret_asm:    mov al, TOKEN_ASM
             ret
.ret_uefi_call: mov al, TOKEN_UEFI_CALL
             ret
.ret_extern: mov al, TOKEN_EXTERN
             ret
.ret_efi_fn: mov al, TOKEN_EFI_FN
             ret             
.ret_u8:     mov al, TOKEN_U8
             ret
.ret_u16:    mov al, TOKEN_U16
             ret
.ret_u32:    mov al, TOKEN_U32
             ret
.ret_u64:    mov al, TOKEN_U64
             ret
.ret_i8:     mov al, TOKEN_I8
             ret
.ret_i16:    mov al, TOKEN_I16
             ret
.ret_i32:    mov al, TOKEN_I32
             ret
.ret_i64:    mov al, TOKEN_I64
             ret

; ─────────────────────────────────────────────
; scan_int  (decimal / 0x hex / 0b binary)
;   Giriş : RSI = ilk rakam karakteri
;   Çıkış : RDI = başlangıç pointer
;            RSI = literal sonrası
;            AL  = TOKEN_INT_LIT
;
; ─────────────────────────────────────────────
scan_int:
    mov rdi, rsi

    mov al, byte [rsi]
    cmp al, '0'
    jne .decimal

    mov al, byte [rsi+1]
    cmp al, 'x'
    je .hex
    cmp al, 'X'
    je .hex
    cmp al, 'b'
    je .binary
    cmp al, 'B'
    je .binary

.decimal:
    mov al, byte [rsi]
    test al, al
    jz .done
    push rsi
    call is_digit_dec
    pop rsi
    cmp al, 1
    jne .done
    inc rsi
    jmp .decimal

.hex:
    inc rsi             ; '0' atla
    inc rsi             ; 'x' atla
.hex_loop:
    mov al, byte [rsi]
    test al, al
    jz .done
    push rsi
    call is_hex_digit
    pop rsi
    cmp al, 1
    jne .done
    inc rsi
    jmp .hex_loop

.binary:
    inc rsi             ; '0' atla
    inc rsi             ; 'b' atla
.bin_loop:
    mov al, byte [rsi]
    cmp al, '0'
    je .bin_ok
    cmp al, '1'
    je .bin_ok
    jmp .done
.bin_ok:
    inc rsi
    jmp .bin_loop

.done:
    mov al, TOKEN_INT_LIT
    ret

; ─────────────────────────────────────────────
; lexer_next_token   ← ana giriş noktası
;   Giriş : RSI = mevcut buffer pozisyonu
;   Çıkış : AL  = token tipi
;            RDI = token başlangıç pointer'ı
;            RSI = token sonrası güncelllenmiş pointer
;
; ─────────────────────────────────────────────
lexer_next_token:
    call skip_whitespace

    mov al, byte [rsi]
    test al, al
    jz .eof

    mov rdi, rsi            ; token başlangıcını kaydet

    ; Önce rakam kontrolü
    push rsi
    call is_digit_dec
    pop rsi
    cmp al, 1
    je .int_path

    ; Sonra harf / alt çizgi kontrolü
    mov al, byte [rsi]
    push rsi
    call is_alpha_or_underscore
    pop rsi
    cmp al, 1
    je .ident_path

    ; Sembol dispatch
    mov al, byte [rsi]

    cmp al, '('
    je .lparen
    cmp al, ')'
    je .rparen
    cmp al, '{'
    je .lbrace
    cmp al, '}'
    je .rbrace
    cmp al, ':'
    je .colon
    cmp al, ','
    je .comma
    cmp al, ';'
    je .semicolon
    cmp al, '&'
    je .amp
    cmp al, '*'
    je .star
    cmp al, '+'
    je .plus
    cmp al, '/'
    je .slash
    cmp al, '.'
    je .dot_or_dotstar
    cmp al, '-'
    je .minus_or_arrow
    cmp al, '='
    je .eq_or_eqeq
    cmp al, '!'
    je .bang_or_neq
    cmp al, '<'
    je .lt_or_leq
    cmp al, '>'
    je .gt_or_geq
    cmp al, '"'
    je .string_lit

    ; Tanımsız karakter: ilerlet, INVALID dön
    inc rsi
    mov al, TOKEN_INVALID
    ret

; ── Tek karakter tokenlar ─────────────────
.lparen:    inc rsi
            mov al, TOKEN_LPAREN
            ret
.rparen:    inc rsi
            mov al, TOKEN_RPAREN
            ret
.lbrace:    inc rsi
            mov al, TOKEN_LBRACE
            ret
.rbrace:    inc rsi
            mov al, TOKEN_RBRACE
            ret
.colon:     inc rsi
            mov al, TOKEN_COLON
            ret
.comma:     inc rsi
            mov al, TOKEN_COMMA
            ret
.semicolon: inc rsi
            mov al, TOKEN_SEMICOLON
            ret
.amp:       inc rsi
            mov al, TOKEN_AMP
            ret
.star:      inc rsi
            mov al, TOKEN_STAR
            ret
.plus:      inc rsi
            mov al, TOKEN_PLUS
            ret
.slash:     inc rsi
            mov al, TOKEN_SLASH
            ret

; ── Çift karakter tokenlar ───────────────
.dot_or_dotstar:
    cmp byte [rsi+1], '*'
    jne .just_dot
    inc rsi
    inc rsi
    mov al, TOKEN_DOTSTAR
    ret
.just_dot:
    inc rsi
    mov al, TOKEN_DOT
    ret

.minus_or_arrow:
    cmp byte [rsi+1], '>'
    jne .just_minus
    inc rsi
    inc rsi
    mov al, TOKEN_ARROW
    ret
.just_minus:
    inc rsi
    mov al, TOKEN_MINUS
    ret

.eq_or_eqeq:
    cmp byte [rsi+1], '='
    jne .just_eq
    inc rsi
    inc rsi
    mov al, TOKEN_EQEQ
    ret
.just_eq:
    inc rsi
    mov al, TOKEN_EQ
    ret

.bang_or_neq:
    cmp byte [rsi+1], '='
    jne .unknown_bang
    inc rsi
    inc rsi
    mov al, TOKEN_NEQ
    ret
.unknown_bang:
    ; Tek '!' dilde tanımsız
    inc rsi
    mov al, TOKEN_INVALID
    ret

.lt_or_leq:
    cmp byte [rsi+1], '='
    jne .just_lt
    inc rsi
    inc rsi
    mov al, TOKEN_LEQ
    ret
.just_lt:
    inc rsi
    mov al, TOKEN_LT
    ret

.gt_or_geq:
    cmp byte [rsi+1], '='
    jne .just_gt
    inc rsi
    inc rsi
    mov al, TOKEN_GEQ
    ret
.just_gt:
    inc rsi
    mov al, TOKEN_GT
    ret

; ── Alt yollar ───────────────────────────
.int_path:
    call scan_int
    ret

.ident_path:
    call scan_identifier
    call lookup_keyword
    ret

; ── String literal: "..." ────────────────
; RDI = açılış '"' sonrası (içerik başı)
; str_content_end = kapanış '"' konumu (içerik sonu, hariç)
; RSI = kapanış '"' sonrası (sonraki token için)
.string_lit:
    inc  rsi                    ; açılış " atla
    mov  rdi, rsi               ; RDI = içerik başı
.str_scan:
    mov  al, byte [rsi]
    test al, al
    jz   .str_eof
    cmp  al, '"'
    je   .str_close
    inc  rsi
    jmp  .str_scan
.str_close:
    lea  rax, [rel str_content_end]
    mov  [rax], rsi             ; kapanış " konumunu kaydet
    inc  rsi                    ; " atla → sonraki token için RSI hazır
    mov  al, TOKEN_STRING_LIT
    ret
.str_eof:
    mov  al, TOKEN_INVALID
    ret

.eof:
    mov al, TOKEN_EOF
    ret
