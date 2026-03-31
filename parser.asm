; parser.asm — Nihilum Stage-0 Parser (x86-64 NASM)
; Recursive descent — Nihilum dil sözdizimi
;
; Çağrı sözleşmesi:
;   Giriş : RSI = kaynak buffer başlangıcı
;   Çıkış : RAX = AST_PROGRAM node pointer (0 = hata)
;            parse_error_flag = 1, parse_error_pos = hata konumu
;
; Bağımlılık: lexer.asm (lexer_next_token)

BITS 64
DEFAULT REL

; ─────────────────────────────────────────────
; TOKEN SABİTLERİ  (lexer.asm ile eşleşmeli)
; ─────────────────────────────────────────────
TOKEN_EOF         equ 0
TOKEN_INVALID     equ 99
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
TOKEN_ASM         equ 80
TOKEN_STRING_LIT  equ 81
TOKEN_UEFI_CALL   equ 82
TOKEN_EFI_FN      equ 83
TOKEN_EXTERN      equ 84

; ─────────────────────────────────────────────
; AST NODE TİPLERİ
; ─────────────────────────────────────────────
AST_PROGRAM    equ 1
AST_FN_DECL    equ 2
AST_PARAM      equ 3
AST_BLOCK      equ 4
AST_LET        equ 5
AST_MUT        equ 6
AST_ASSIGN     equ 7
AST_RETURN     equ 8
AST_IF         equ 9
AST_WHILE      equ 10
AST_EXPR_STMT  equ 11
AST_BINOP      equ 12
AST_UNARY_REF  equ 13   ; &expr
AST_DEREF      equ 14   ; expr.*
AST_CALL       equ 15
AST_IDENT      equ 16
AST_INT_LIT    equ 17
AST_TYPE_PRIM  equ 18
AST_TYPE_PTR   equ 19
AST_ASM        equ 20   ; asm "..." → N_LEFT=src ptr, N_INT=uzunluk
AST_UEFI_CALL  equ 21   ; uefi_call(fn, a1..a4) → expression
                         ;   N_LEFT    = fn_ptr expr
                         ;   N_SIBLING = arg listesi
AST_EXTERN     equ 22   ; extern ident; → N_STR = sembol adı

; ─────────────────────────────────────────────
; BINARY OPERATOR KODLARI  (N_OP alanında)
; ─────────────────────────────────────────────
OP_ADD  equ 1
OP_SUB  equ 2
OP_MUL  equ 3
OP_DIV  equ 4
OP_EQ   equ 5
OP_NEQ  equ 6
OP_LT   equ 7
OP_GT   equ 8
OP_LEQ  equ 9
OP_GEQ  equ 10

; ─────────────────────────────────────────────
; NODE LAYOUT  (64 byte sabit boyut)
;
;  [0]     N_TYPE    u8   — AST_* sabiti
;  [1]     N_OP      u8   — BINOP operatör kodu
;  [2..7]  —              — reserved
;  [8..15] N_LEFT    u64  — sol çocuk pointer  (0 = yok)
; [16..23] N_RIGHT   u64  — sağ çocuk pointer
; [24..31] N_SIBLING u64  — kardeş pointer (linked list)
; [32..39] N_INT     u64  — INT_LIT değeri / TYPE_PRIM enum
; [40..63] N_STR     24B  — null-terminated isim
; ─────────────────────────────────────────────
AST_NODE_SIZE  equ 64
AST_MAX_NODES  equ 65536

N_TYPE     equ 0
N_OP       equ 1
N_LEFT     equ 8
N_RIGHT    equ 16
N_SIBLING  equ 24
N_INT      equ 32
N_STR      equ 40

; ─────────────────────────────────────────────
; GLOBAL PARSER STATE
; ─────────────────────────────────────────────
section .bss

cur_token_type   resb 1
                 resb 7         ; hizalama
cur_token_start  resq 1         ; token başlangıç pointer
cur_token_end    resq 1         ; token bitiş pointer (= RSI sonrası)

parse_error_flag resb 1
                 resb 7
parse_error_pos  resq 1         ; hatanın kaynak konumu

alignb 64
ast_pool         resb AST_NODE_SIZE * AST_MAX_NODES
ast_node_count   resd 1

section .text

global parse_program
global parse_error_flag
global parse_error_pos
global ast_pool
global ast_node_count
extern lexer_next_token
extern str_content_end

; ═══════════════════════════════════════════════════════
; TEMEL YARDIMCILAR
; ═══════════════════════════════════════════════════════

; ───────────────────────────────────────────────────────
; advance
;   Lexer'ı bir adım ilerletir, cur_token_* günceller
;   RSI daima güncel kaynak pozisyonunu taşır
; ───────────────────────────────────────────────────────
advance:
    call lexer_next_token
    mov  [cur_token_type],  al
    mov  [cur_token_start], rdi
    cmp  al, TOKEN_STRING_LIT
    jne  .normal_end
    mov  rax, [rel str_content_end]
    mov  [cur_token_end], rax
    ret
.normal_end:
    mov  [cur_token_end], rsi
    ret

; ───────────────────────────────────────────────────────
; expect
;   Giriş : DIL = beklenen TOKEN_* sabiti
;   Çıkış : AL  = 0 (başarı → advance çağırır)
;           AL  = 1 (hata → parse_error_flag=1)
; ───────────────────────────────────────────────────────
expect:
    cmp  byte [cur_token_type], dil
    jne  .fail
    call advance
    xor  al, al
    ret
.fail:
    mov  byte [parse_error_flag], 1
    mov  [parse_error_pos], rsi
    mov  al, 1
    ret

; ───────────────────────────────────────────────────────
; alloc_node
;   Giriş : DIL = AST_* node tipi
;   Çıkış : RAX = node pointer  (0 = havuz doldu)
;   64 byte'ı sıfırlar, tipi yazar
; ───────────────────────────────────────────────────────
alloc_node:
    mov  eax, [ast_node_count]
    cmp  eax, AST_MAX_NODES
    jae  .overflow

    imul rax, rax, AST_NODE_SIZE
    lea  rcx, [ast_pool]     ; Havuzun taban adresini al
    add  rax, rcx            ; Node'un gerçek adresini bul

    mov  qword [rax+0],  0
    mov  qword [rax+8],  0
    mov  qword [rax+16], 0
    mov  qword [rax+24], 0
    mov  qword [rax+32], 0
    mov  qword [rax+40], 0
    mov  qword [rax+48], 0
    mov  qword [rax+56], 0

    mov  byte  [rax + N_TYPE], dil
    inc  dword [ast_node_count]
    ret

.overflow:
    mov  byte [parse_error_flag], 1
    xor  rax, rax
    ret

; ───────────────────────────────────────────────────────
; copy_cur_str
;   cur_token_start..end → [rbx + N_STR]  (max 23 byte)
;   Giriş : RBX = hedef node pointer
;   RSI, RDI, RCX korunur
; ───────────────────────────────────────────────────────
copy_cur_str:
    push rsi
    push rdi
    push rcx

    lea  rdi, [rbx + N_STR]
    mov  rsi, [cur_token_start]
    mov  rcx, [cur_token_end]
    sub  rcx, rsi               ; uzunluk
    cmp  rcx, 23
    jle  .ok
    mov  rcx, 23                ; kırp (null için 1 byte boşluk)
.ok:
    rep  movsb

    pop  rcx
    pop  rdi
    pop  rsi
    ret

; ───────────────────────────────────────────────────────
; is_prim_type
;   cur_token bir primitive tip mi?
;   Çıkış : AL = 1 evet, 0 hayır
; ───────────────────────────────────────────────────────
is_prim_type:
    movzx eax, byte [cur_token_type]
    cmp   al, TOKEN_U8
    je    .yes
    cmp   al, TOKEN_U16
    je    .yes
    cmp   al, TOKEN_U32
    je    .yes
    cmp   al, TOKEN_U64
    je    .yes
    cmp   al, TOKEN_I8
    je    .yes
    cmp   al, TOKEN_I16
    je    .yes
    cmp   al, TOKEN_I32
    je    .yes
    cmp   al, TOKEN_I64
    je    .yes
    xor   al, al
    ret
.yes:
    mov   al, 1
    ret

; ═══════════════════════════════════════════════════════
; TİP PARSERİ
; ═══════════════════════════════════════════════════════

; ───────────────────────────────────────────────────────
; parse_type
;   *<type>      → AST_TYPE_PTR  (N_LEFT = iç tip, recursive)
;   u8/u16/…/i64 → AST_TYPE_PRIM (N_INT  = token tipi enum)
;   Çıkış : RAX = tip node pointer (0 = hata)
; ───────────────────────────────────────────────────────
parse_type:
    push rbx

    cmp  byte [cur_token_type], TOKEN_STAR
    jne  .not_ptr

    ; pointer: *<inner>
    call advance
    mov  dil, AST_TYPE_PTR
    call alloc_node
    test rax, rax
    jz   .error
    mov  rbx, rax

    call parse_type             ; recursive: **u8 vb.
    test rax, rax
    jz   .error
    mov  [rbx + N_LEFT], rax

    mov  rax, rbx
    pop  rbx
    ret

.not_ptr:
    call is_prim_type
    test al, al
    jz   .error

    mov  dil, AST_TYPE_PRIM
    call alloc_node
    test rax, rax
    jz   .error
    mov  rbx, rax

    movzx eax, byte [cur_token_type]
    mov   qword [rbx + N_INT], rax  ; hangi primitive?
    call  advance

    mov  rax, rbx
    pop  rbx
    ret

.error:
    mov  byte [parse_error_flag], 1
    xor  rax, rax
    pop  rbx
    ret

; ═══════════════════════════════════════════════════════
; PARAMETRE PARSERLERİ
; ═══════════════════════════════════════════════════════

; ───────────────────────────────────────────────────────
; parse_param
;   ident : type  →  AST_PARAM  (N_STR=isim, N_LEFT=tip)
; ───────────────────────────────────────────────────────
parse_param:
    push rbx

    cmp  byte [cur_token_type], TOKEN_IDENT
    jne  .error

    mov  dil, AST_PARAM
    call alloc_node
    test rax, rax
    jz   .error
    mov  rbx, rax

    call copy_cur_str           ; ident ismi → N_STR
    call advance                ; IDENT tüket

    mov  dil, TOKEN_COLON
    call expect
    test al, al
    jnz  .error

    call parse_type
    test rax, rax
    jz   .error
    mov  [rbx + N_LEFT], rax    ; tip = sol çocuk

    mov  rax, rbx
    pop  rbx
    ret

.error:
    mov  byte [parse_error_flag], 1
    xor  rax, rax
    pop  rbx
    ret

; ───────────────────────────────────────────────────────
; parse_param_list
;   param (, param)*  →  sibling zinciri
;   Boş liste ())     →  RAX = 0  (hata DEĞİL)
; ───────────────────────────────────────────────────────
parse_param_list:
    push rbx
    push r12

    cmp  byte [cur_token_type], TOKEN_RPAREN
    je   .empty

    call parse_param
    test rax, rax
    jz   .error
    mov  rbx, rax               ; rbx = ilk param (döndürülecek)
    mov  r12, rax               ; r12 = son param (zincir için)

.loop:
    cmp  byte [cur_token_type], TOKEN_COMMA
    jne  .done
    call advance                ; ',' tüket

    call parse_param
    test rax, rax
    jz   .error
    mov  [r12 + N_SIBLING], rax
    mov  r12, rax
    jmp  .loop

.done:
    mov  rax, rbx
    pop  r12
    pop  rbx
    ret

.empty:
    xor  rax, rax
    pop  r12
    pop  rbx
    ret

.error:
    xor  rax, rax
    pop  r12
    pop  rbx
    ret

; ═══════════════════════════════════════════════════════
; İFADE PARSERİ
; Öncelik piramidi (düşük → yüksek):
;   parse_comparison  →  parse_addition  →  parse_multiplication
;   →  parse_unary  →  parse_primary
; ═══════════════════════════════════════════════════════

; ───────────────────────────────────────────────────────
; parse_primary
;   INT_LIT | IDENT | fn_call | (expr)
;
;   RBX  = mevcut node
;   R12  = geçici (grouped expr)
;   rbx/r12 callee-saved → çağrılan parse_* fonksiyonlar değiştirmez
; ───────────────────────────────────────────────────────
parse_primary:
    push rbx
    push r12

    movzx eax, byte [cur_token_type]

    cmp  al, TOKEN_INT_LIT
    je   .int_lit
    cmp  al, TOKEN_IDENT
    je   .ident
    cmp  al, TOKEN_LPAREN
    je   .grouped
    cmp  al, TOKEN_UEFI_CALL
    je   .uefi_call_expr
    jmp  .error

; ── Tamsayı literali ──────────────────────────────────
.int_lit:
    mov  dil, AST_INT_LIT
    call alloc_node
    test rax, rax
    jz   .error
    mov  rbx, rax
    call copy_cur_str           ; ham metin → N_STR (codegen dönüştürür)
    call advance
    mov  rax, rbx
    pop  r12
    pop  rbx
    ret

; ── Tanımlayıcı ya da fonksiyon çağrısı ──────────────
.ident:
    mov  dil, AST_IDENT
    call alloc_node
    test rax, rax
    jz   .error
    mov  rbx, rax
    call copy_cur_str
    call advance

    ; '(' varsa fn_call
    cmp  byte [cur_token_type], TOKEN_LPAREN
    jne  .just_ident

    mov  byte [rbx + N_TYPE], AST_CALL
    call advance                ; '(' tüket

    ; Argüman var mı?
    cmp  byte [cur_token_type], TOKEN_RPAREN
    je   .call_no_args

    call parse_arg_list
    test rax, rax
    jz   .error
    mov  [rbx + N_LEFT], rax    ; arg listesi = sol çocuk

.call_no_args:
    mov  dil, TOKEN_RPAREN
    call expect
    test al, al
    jnz  .error

    mov  rax, rbx
    pop  r12
    pop  rbx
    ret

.just_ident:
    mov  rax, rbx
    pop  r12
    pop  rbx
    ret

; ── Parantezli ifade ──────────────────────────────────
.grouped:
    call advance                ; '(' tüket
    call parse_comparison
    test rax, rax
    jz   .error
    mov  r12, rax               ; r12 = içteki expr

    mov  dil, TOKEN_RPAREN
    call expect
    test al, al
    jnz  .error

    mov  rax, r12
    pop  r12
    pop  rbx
    ret

; ── UEFI_CALL expression ──────────────────────────────
; uefi_call(fn_ptr, arg1..arg4) → AST_UEFI_CALL
;   N_LEFT    = fn_ptr expr node
;   N_SIBLING = arg listesi (sibling zinciri)
; Sonuç yığında — let status = uefi_call(...) yazılabilir.
.uefi_call_expr:
    call advance                    ; 'uefi_call' token'ını tüket

    mov  dil, TOKEN_LPAREN
    call expect
    test al, al
    jnz  .error

    ; fn_ptr ifadesini parse et
    call parse_comparison
    test rax, rax
    jz   .error
    push rax                        ; fn_ptr'ı koru

    mov  dil, AST_UEFI_CALL
    call alloc_node
    pop  r12                        ; r12 = fn_ptr node
    test rax, rax
    jz   .error
    mov  rbx, rax
    mov  [rbx + N_LEFT], r12        ; fn_ptr = N_LEFT

    xor  r12, r12                   ; r12 = son arg node

.uefi_arg_loop:
    cmp  byte [cur_token_type], TOKEN_RPAREN
    je   .uefi_args_done
    cmp  byte [cur_token_type], TOKEN_COMMA
    jne  .uefi_parse_arg
    call advance                    ; ',' tüket
    jmp  .uefi_arg_loop

.uefi_parse_arg:
    call parse_comparison
    test rax, rax
    jz   .error
    test r12, r12
    jnz  .uefi_chain
    mov  [rbx + N_SIBLING], rax     ; ilk arg → N_SIBLING
    jmp  .uefi_tail
.uefi_chain:
    mov  [r12 + N_SIBLING], rax     ; zincire ekle
.uefi_tail:
    mov  r12, rax
    jmp  .uefi_arg_loop

.uefi_args_done:
    mov  dil, TOKEN_RPAREN
    call expect
    test al, al
    jnz  .error

    mov  rax, rbx
    pop  r12
    pop  rbx
    ret

.error:
    mov  byte [parse_error_flag], 1
    xor  rax, rax
    pop  r12
    pop  rbx
    ret

; ───────────────────────────────────────────────────────
; parse_arg_list
;   expr (, expr)*  →  sibling zinciri
;   En az 1 argüman garantili (çağıran kontrol eder)
; ───────────────────────────────────────────────────────
parse_arg_list:
    push rbx
    push r12

    call parse_comparison
    test rax, rax
    jz   .error
    mov  rbx, rax               ; ilk argüman
    mov  r12, rax               ; son argüman

.loop:
    cmp  byte [cur_token_type], TOKEN_COMMA
    jne  .done
    call advance
    call parse_comparison
    test rax, rax
    jz   .error
    mov  [r12 + N_SIBLING], rax
    mov  r12, rax
    jmp  .loop

.done:
    mov  rax, rbx
    pop  r12
    pop  rbx
    ret

.error:
    xor  rax, rax
    pop  r12
    pop  rbx
    ret

; ───────────────────────────────────────────────────────
; parse_unary
;   &expr      → AST_UNARY_REF  (N_LEFT = iç expr)
;   primary.*  → AST_DEREF zinciri (N_LEFT = sarmalanan)
; ───────────────────────────────────────────────────────
parse_unary:
    push rbx

    ; Adres alma: &expr
    cmp  byte [cur_token_type], TOKEN_AMP
    jne  .not_ref

    call advance
    mov  dil, AST_UNARY_REF
    call alloc_node
    test rax, rax
    jz   .error
    mov  rbx, rax

    call parse_unary            ; recursive: &&ptr vb.
    test rax, rax
    jz   .error
    mov  [rbx + N_LEFT], rax

    mov  rax, rbx
    pop  rbx
    ret

.not_ref:
    call parse_primary
    test rax, rax
    jz   .error
    mov  rbx, rax

    ; Dereference zinciri: a.* ya da a.*.*
.deref_loop:
    cmp  byte [cur_token_type], TOKEN_DOTSTAR
    jne  .deref_done
    call advance

    mov  dil, AST_DEREF
    call alloc_node
    test rax, rax
    jz   .error
    mov  [rax + N_LEFT], rbx    ; sarmalanan expr
    mov  rbx, rax               ; yeni düğüm artık dış katman
    jmp  .deref_loop

.deref_done:
    mov  rax, rbx
    pop  rbx
    ret

.error:
    xor  rax, rax
    pop  rbx
    ret

; ───────────────────────────────────────────────────────
; parse_multiplication   (* /)
;   Sol-birleşimli: a * b / c  →  ((a * b) / c)
;   rbx = sol operand  (callee-saved, alt çağrılar bozmaz)
;   r12b = operatör kodu (callee-saved)
; ───────────────────────────────────────────────────────
parse_multiplication:
    push rbx
    push r12

    call parse_unary
    test rax, rax
    jz   .error
    mov  rbx, rax

.loop:
    movzx eax, byte [cur_token_type]
    cmp  al, TOKEN_STAR
    je   .op_mul
    cmp  al, TOKEN_SLASH
    je   .op_div
    jmp  .done

.op_mul:
    mov  r12b, OP_MUL
    call advance
    jmp  .do_binop

.op_div:
    mov  r12b, OP_DIV
    call advance

.do_binop:
    ; rbx=sol, r12b=op — callee-saved, parse_unary bozmaz
    call parse_unary
    test rax, rax
    jz   .error

    push rax                    ; sağ operandı sakla
    mov  dil, AST_BINOP
    call alloc_node
    pop  r8                     ; r8 = sağ operand
    test rax, rax
    jz   .error
    mov  [rax + N_LEFT],       rbx
    mov  [rax + N_RIGHT],      r8
    mov  byte [rax + N_OP],    r12b
    mov  rbx, rax               ; yeni düğüm = sonraki sol
    jmp  .loop

.done:
    mov  rax, rbx
    pop  r12
    pop  rbx
    ret

.error:
    xor  rax, rax
    pop  r12
    pop  rbx
    ret

; ───────────────────────────────────────────────────────
; parse_addition   (+ -)
; ───────────────────────────────────────────────────────
parse_addition:
    push rbx
    push r12

    call parse_multiplication
    test rax, rax
    jz   .error
    mov  rbx, rax

.loop:
    movzx eax, byte [cur_token_type]
    cmp  al, TOKEN_PLUS
    je   .op_add
    cmp  al, TOKEN_MINUS
    je   .op_sub
    jmp  .done

.op_add:
    mov  r12b, OP_ADD
    call advance
    jmp  .do_binop

.op_sub:
    mov  r12b, OP_SUB
    call advance

.do_binop:
    call parse_multiplication
    test rax, rax
    jz   .error

    push rax
    mov  dil, AST_BINOP
    call alloc_node
    pop  r8
    test rax, rax
    jz   .error
    mov  [rax + N_LEFT],    rbx
    mov  [rax + N_RIGHT],   r8
    mov  byte [rax + N_OP], r12b
    mov  rbx, rax
    jmp  .loop

.done:
    mov  rax, rbx
    pop  r12
    pop  rbx
    ret

.error:
    xor  rax, rax
    pop  r12
    pop  rbx
    ret

; ───────────────────────────────────────────────────────
; parse_comparison   (== != < > <= >=)
; ───────────────────────────────────────────────────────
parse_comparison:
    push rbx
    push r12

    call parse_addition
    test rax, rax
    jz   .error
    mov  rbx, rax

.loop:
    movzx eax, byte [cur_token_type]
    cmp  al, TOKEN_EQEQ  ;  je .op_eq
    je   .op_eq
    cmp  al, TOKEN_NEQ
    je   .op_neq
    cmp  al, TOKEN_LT
    je   .op_lt
    cmp  al, TOKEN_GT
    je   .op_gt
    cmp  al, TOKEN_LEQ
    je   .op_leq
    cmp  al, TOKEN_GEQ
    je   .op_geq
    jmp  .done

.op_eq:  mov r12b, OP_EQ  ; ve advance, sonra do_binop
         call advance
         jmp .do_binop
.op_neq: mov r12b, OP_NEQ
         call advance
         jmp .do_binop
.op_lt:  mov r12b, OP_LT
         call advance
         jmp .do_binop
.op_gt:  mov r12b, OP_GT
         call advance
         jmp .do_binop
.op_leq: mov r12b, OP_LEQ
         call advance
         jmp .do_binop
.op_geq: mov r12b, OP_GEQ
         call advance

.do_binop:
    call parse_addition
    test rax, rax
    jz   .error

    push rax
    mov  dil, AST_BINOP
    call alloc_node
    pop  r8
    test rax, rax
    jz   .error
    mov  [rax + N_LEFT],    rbx
    mov  [rax + N_RIGHT],   r8
    mov  byte [rax + N_OP], r12b
    mov  rbx, rax
    jmp  .loop

.done:
    mov  rax, rbx
    pop  r12
    pop  rbx
    ret

.error:
    xor  rax, rax
    pop  r12
    pop  rbx
    ret

; ═══════════════════════════════════════════════════════
; STATEMENT PARSERLERİ
; ═══════════════════════════════════════════════════════

; ───────────────────────────────────────────────────────
; parse_let_stmt   ('let' zaten tüketildi)
;   let ident : type = expr ;
;   AST_LET  →  N_STR=isim, N_LEFT=tip, N_RIGHT=değer
; ───────────────────────────────────────────────────────
parse_let_stmt:
    push rbx

    cmp  byte [cur_token_type], TOKEN_IDENT
    jne  .error

    mov  dil, AST_LET
    call alloc_node
    test rax, rax
    jz   .error
    mov  rbx, rax

    call copy_cur_str           ; isim
    call advance

    mov  dil, TOKEN_COLON
    call expect
    test al, al
    jnz  .error

    call parse_type
    test rax, rax
    jz   .error
    mov  [rbx + N_LEFT], rax

    mov  dil, TOKEN_EQ
    call expect
    test al, al
    jnz  .error

    call parse_comparison
    test rax, rax
    jz   .error
    mov  [rbx + N_RIGHT], rax

    mov  dil, TOKEN_SEMICOLON
    call expect
    test al, al
    jnz  .error

    mov  rax, rbx
    pop  rbx
    ret

.error:
    mov  byte [parse_error_flag], 1
    xor  rax, rax
    pop  rbx
    ret

; ───────────────────────────────────────────────────────
; parse_mut_stmt   ('mut' zaten tüketildi)
;   mut ident : type = expr ;
;   AST_MUT  →  N_STR=isim, N_LEFT=tip, N_RIGHT=değer
; ───────────────────────────────────────────────────────
parse_mut_stmt:
    push rbx

    cmp  byte [cur_token_type], TOKEN_IDENT
    jne  .error

    mov  dil, AST_MUT
    call alloc_node
    test rax, rax
    jz   .error
    mov  rbx, rax

    call copy_cur_str
    call advance

    mov  dil, TOKEN_COLON
    call expect
    test al, al
    jnz  .error

    call parse_type
    test rax, rax
    jz   .error
    mov  [rbx + N_LEFT], rax

    mov  dil, TOKEN_EQ
    call expect
    test al, al
    jnz  .error

    call parse_comparison
    test rax, rax
    jz   .error
    mov  [rbx + N_RIGHT], rax

    mov  dil, TOKEN_SEMICOLON
    call expect
    test al, al
    jnz  .error

    mov  rax, rbx
    pop  rbx
    ret

.error:
    mov  byte [parse_error_flag], 1
    xor  rax, rax
    pop  rbx
    ret

; ───────────────────────────────────────────────────────
; parse_return_stmt   ('return' zaten tüketildi)
;   return expr? ;
;   AST_RETURN  →  N_LEFT=değer (0 = boş return)
; ───────────────────────────────────────────────────────
parse_return_stmt:
    push rbx

    mov  dil, AST_RETURN
    call alloc_node
    test rax, rax
    jz   .error
    mov  rbx, rax

    ; Boş return: sadece ';'
    cmp  byte [cur_token_type], TOKEN_SEMICOLON
    je   .empty_return

    call parse_comparison
    test rax, rax
    jz   .error
    mov  [rbx + N_LEFT], rax

.empty_return:
    mov  dil, TOKEN_SEMICOLON
    call expect
    test al, al
    jnz  .error

    mov  rax, rbx
    pop  rbx
    ret

.error:
    mov  byte [parse_error_flag], 1
    xor  rax, rax
    pop  rbx
    ret

; ───────────────────────────────────────────────────────
; parse_if_stmt   ('if' zaten tüketildi)
;   if expr block (else block)?
;   AST_IF  →  N_LEFT=cond, N_RIGHT=then, N_SIBLING=else
; ───────────────────────────────────────────────────────
parse_if_stmt:
    push rbx

    mov  dil, AST_IF
    call alloc_node
    test rax, rax
    jz   .error
    mov  rbx, rax

    call parse_comparison
    test rax, rax
    jz   .error
    mov  [rbx + N_LEFT], rax        ; koşul

    call parse_block
    test rax, rax
    jz   .error
    mov  [rbx + N_RIGHT], rax       ; then bloğu

    cmp  byte [cur_token_type], TOKEN_ELSE
    jne  .no_else
    call advance
    call parse_block
    test rax, rax
    jz   .error
    mov  [rbx + N_SIBLING], rax     ; else bloğu

.no_else:
    mov  rax, rbx
    pop  rbx
    ret

.error:
    mov  byte [parse_error_flag], 1
    xor  rax, rax
    pop  rbx
    ret

; ───────────────────────────────────────────────────────
; parse_while_stmt   ('while' zaten tüketildi)
;   while expr block
;   AST_WHILE  →  N_LEFT=cond, N_RIGHT=body
; ───────────────────────────────────────────────────────
parse_while_stmt:
    push rbx

    mov  dil, AST_WHILE
    call alloc_node
    test rax, rax
    jz   .error
    mov  rbx, rax

    call parse_comparison
    test rax, rax
    jz   .error
    mov  [rbx + N_LEFT], rax

    call parse_block
    test rax, rax
    jz   .error
    mov  [rbx + N_RIGHT], rax

    mov  rax, rbx
    pop  rbx
    ret

.error:
    mov  byte [parse_error_flag], 1
    xor  rax, rax
    pop  rbx
    ret

; ───────────────────────────────────────────────────────
; parse_stmt   — statement dispatcher
;
;   let   → parse_let_stmt
;   mut   → parse_mut_stmt
;   return→ parse_return_stmt
;   if    → parse_if_stmt
;   while → parse_while_stmt
;   diğer → expr sonrası:
;           '=' varsa AST_ASSIGN
;           yok ise  AST_EXPR_STMT
; ───────────────────────────────────────────────────────
parse_stmt:
    push rbx

    movzx eax, byte [cur_token_type]

    cmp  al, TOKEN_LET
    jne  .not_let
    call advance
    call parse_let_stmt
    test rax, rax
    jz   .error
    pop  rbx
    ret

.not_let:
    cmp  al, TOKEN_MUT
    jne  .not_mut
    call advance
    call parse_mut_stmt
    test rax, rax
    jz   .error
    pop  rbx
    ret

.not_mut:
    cmp  al, TOKEN_RETURN
    jne  .not_return
    call advance
    call parse_return_stmt
    test rax, rax
    jz   .error
    pop  rbx
    ret

.not_return:
    cmp  al, TOKEN_IF
    jne  .not_if
    call advance
    call parse_if_stmt
    test rax, rax
    jz   .error
    pop  rbx
    ret

.not_if:
    cmp  al, TOKEN_WHILE
    jne  .not_while
    call advance
    call parse_while_stmt
    test rax, rax
    jz   .error
    pop  rbx
    ret

.not_while:
    cmp  al, TOKEN_ASM
    jne  .not_asm
    call advance
    call parse_asm_stmt
    test rax, rax
    jz   .error
    pop  rbx
    ret

.not_asm:
    cmp  al, TOKEN_EXTERN
    jne  .not_extern
    call advance
    call parse_extern_stmt
    test rax, rax
    jz   .error
    pop  rbx
    ret

.not_extern:
    ; expr veya assign
    call parse_comparison
    test rax, rax
    jz   .error
    mov  rbx, rax           ; rbx = sol taraf

    cmp  byte [cur_token_type], TOKEN_EQ
    jne  .expr_stmt

    ; atama: lhs = rhs
    call advance            ; '=' tüket
    ; rbx (lhs) callee-saved — parse_comparison bozmaz
    call parse_comparison   ; rhs
    test rax, rax
    jz   .error

    push rax                ; rhs'yi koru
    mov  dil, AST_ASSIGN
    call alloc_node
    pop  r8                 ; r8 = rhs
    test rax, rax
    jz   .error
    mov  [rax + N_LEFT],  rbx
    mov  [rax + N_RIGHT], r8
    mov  rbx, rax

    mov  dil, TOKEN_SEMICOLON
    call expect
    test al, al
    jnz  .error

    mov  rax, rbx
    pop  rbx
    ret

.expr_stmt:
    ; ifade statement: expr ;
    mov  dil, AST_EXPR_STMT
    call alloc_node
    test rax, rax
    jz   .error
    mov  [rax + N_LEFT], rbx    ; expr = sol çocuk
    mov  rbx, rax

    mov  dil, TOKEN_SEMICOLON
    call expect
    test al, al
    jnz  .error

    mov  rax, rbx
    pop  rbx
    ret

.error:
    mov  byte [parse_error_flag], 1
    xor  rax, rax
    pop  rbx
    ret

parse_extern_stmt:
    push rbx

    cmp  byte [cur_token_type], TOKEN_IDENT
    jne  .error

    mov  dil, AST_EXTERN
    call alloc_node
    test rax, rax
    jz   .error
    mov  rbx, rax

    call copy_cur_str
    call advance

    mov  dil, TOKEN_SEMICOLON
    call expect
    test al, al
    jnz  .error

    mov  rax, rbx
    pop  rbx
    ret

.error:
    mov  byte [parse_error_flag], 1
    xor  rax, rax
    pop  rbx
    ret

; ───────────────────────────────────────────────────────
; parse_asm_stmt   ('asm' zaten tüketildi)
;   asm "..." ;
;   AST_ASM → N_LEFT = kaynak pointer, N_INT = uzunluk
;   Sıfır soyutlama: string içeriği codegen'e pointer+len.
; ───────────────────────────────────────────────────────
parse_asm_stmt:
    push rbx

    cmp  byte [cur_token_type], TOKEN_STRING_LIT
    jne  .error

    mov  dil, AST_ASM
    call alloc_node
    test rax, rax
    jz   .error
    mov  rbx, rax

    mov  rcx, [cur_token_start]
    mov  [rbx + N_LEFT], rcx        ; kaynak pointer

    mov  rax, [cur_token_end]
    sub  rax, rcx                   ; uzunluk (kapanış " hariç)
    mov  [rbx + N_INT], rax

    call advance                    ; STRING_LIT tüket

    mov  dil, TOKEN_SEMICOLON
    call expect
    test al, al
    jnz  .error

    mov  rax, rbx
    pop  rbx
    ret

.error:
    mov  byte [parse_error_flag], 1
    xor  rax, rax
    pop  rbx
    ret

; ───────────────────────────────────────────────────────
; parse_block
;   { stmt* }
;   AST_BLOCK  →  N_LEFT = ilk stmt (sibling zinciri)
; ───────────────────────────────────────────────────────
parse_block:
    push rbx
    push r12
    push r13

    mov  dil, TOKEN_LBRACE
    call expect
    test al, al
    jnz  .error

    mov  dil, AST_BLOCK
    call alloc_node
    test rax, rax
    jz   .error
    mov  rbx, rax

    xor  r12, r12           ; r12 = first stmt
    xor  r13, r13           ; r13 = last stmt (sibling güncellemesi için)

.stmt_loop:
    movzx eax, byte [cur_token_type]
    cmp  al, TOKEN_RBRACE
    je   .block_done
    cmp  al, TOKEN_EOF
    je   .error
    cmp  al, TOKEN_INVALID
    je   .error

    call parse_stmt
    test rax, rax
    jz   .error

    ; İlk stmt ise block.left'e bağla
    test r12, r12
    jnz  .not_first
    mov  r12, rax
    mov  [rbx + N_LEFT], rax
.not_first:
    ; Önceki stmt varsa sibling bağla
    test r13, r13
    jz   .update_tail
    mov  [r13 + N_SIBLING], rax
.update_tail:
    mov  r13, rax
    jmp  .stmt_loop

.block_done:
    call advance            ; '}' tüket
    mov  rax, rbx
    pop  r13
    pop  r12
    pop  rbx
    ret

.error:
    mov  byte [parse_error_flag], 1
    xor  rax, rax
    pop  r13
    pop  r12
    pop  rbx
    ret

; ───────────────────────────────────────────────────────
; parse_fn_decl   ('fn' zaten tüketildi)
;   fn ident ( params? ) (-> type)? block
;   AST_FN_DECL →  N_STR=isim, N_LEFT=params,
;                  N_RIGHT=dönüş tipi, N_SIBLING=block
; ───────────────────────────────────────────────────────
parse_fn_decl:
    push rbx

    cmp  byte [cur_token_type], TOKEN_IDENT
    jne  .error

    mov  dil, AST_FN_DECL
    call alloc_node
    test rax, rax
    jz   .error
    mov  rbx, rax

    call copy_cur_str           ; fn ismi → N_STR
    call advance

    mov  dil, TOKEN_LPAREN
    call expect
    test al, al
    jnz  .error

    call parse_param_list
    mov  [rbx + N_LEFT], rax    ; parametre listesi (0 = boş)

    mov  dil, TOKEN_RPAREN
    call expect
    test al, al
    jnz  .error

    ; İsteğe bağlı dönüş tipi
    cmp  byte [cur_token_type], TOKEN_ARROW
    jne  .no_ret_type
    call advance
    call parse_type
    test rax, rax
    jz   .error
    mov  [rbx + N_RIGHT], rax   ; dönüş tipi = sağ çocuk

.no_ret_type:
    call parse_block
    test rax, rax
    jz   .error
    mov  [rbx + N_INT], rax     ; gövde = N_INT

    mov  rax, rbx
    pop  rbx
    ret

.error:
    mov  byte [parse_error_flag], 1
    xor  rax, rax
    pop  rbx
    ret

; ═══════════════════════════════════════════════════════
; parse_program  — ana giriş noktası
; ═══════════════════════════════════════════════════════
parse_program:
    push rbx
    push r12
    push r13

    call advance            ; ilk token'ı yükle

    mov  dil, AST_PROGRAM
    call alloc_node
    test rax, rax
    jz   .error
    mov  rbx, rax

    xor  r12, r12           ; r12 = first fn
    xor  r13, r13           ; r13 = last fn

.fn_loop:
    movzx eax, byte [cur_token_type]
    cmp  al, TOKEN_EOF
    je   .done
    cmp  al, TOKEN_INVALID
    je   .error
    cmp  al, TOKEN_FN
    je   .is_fn
    cmp  al, TOKEN_EFI_FN
    jne  .error             ; ne TOKEN_FN ne TOKEN_EFI_FN → hata
.is_fn:
    push rax                ; keyword tipini sakla
    call advance
    call parse_fn_decl
    test rax, rax
    jz   .is_fn_error
    pop  rcx                ; keyword tipi
    cmp  cl, TOKEN_EFI_FN
    jne  .not_efi
    mov  byte [rax + N_OP], 1   ; efi_fn flag'i
    jmp  .link_node         ; <--- ÇÖZÜM BURADA: Hata bloğuna düşmeyi engelle!

.not_efi:
.link_node:
    test r12, r12
    jnz  .not_first_fn
    mov  r12, rax
    mov  [rbx + N_LEFT], rax
.not_first_fn:
    test r13, r13
    jz   .update_last
    mov  [r13 + N_SIBLING], rax
.update_last:
    mov  r13, rax
    jmp  .fn_loop

.is_fn_error:               ; <--- HATA BLOĞU GÜVENLİ YERE ALINDI
    pop  rcx
    jmp  .error    

.done:
    mov  rax, rbx
    pop  r13
    pop  r12
    pop  rbx
    ret

.error:
    mov  byte [parse_error_flag], 1
    xor  rax, rax
    pop  r13
    pop  r12
    pop  rbx
    ret