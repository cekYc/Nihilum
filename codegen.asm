; codegen.asm — Nihilum Stage-0 Code Generator (x86-64 NASM)
;
; Strateji: Stack Machine — IR yok, optimizasyon yok.
;   Her ifade sonucu stack'te bırakır.
;   Her alt ifade tüketildiğinde stack'ten çeker.
;
; Giriş : codegen_program(RDI = AST_PROGRAM node)
; Çıkış : out_buf → tam NASM assembly metni, null-terminated
;          RAX = 0 başarı, 1 hata
;
; Node layout (parser.asm ile aynı, 64 byte):
;   [0]  N_TYPE u8   [1] N_OP u8
;   [8]  N_LEFT u64  [16] N_RIGHT u64  [24] N_SIBLING u64
;   [32] N_INT  u64  [40] N_STR  24B

BITS 64

; ─────────────────────────────────────────────
; AST TİPLERİ
; ─────────────────────────────────────────────
AST_PROGRAM   equ 1
AST_FN_DECL   equ 2
AST_PARAM     equ 3
AST_BLOCK     equ 4
AST_LET       equ 5
AST_MUT       equ 6
AST_ASSIGN    equ 7
AST_RETURN    equ 8
AST_IF        equ 9
AST_WHILE     equ 10
AST_EXPR_STMT equ 11
AST_BINOP     equ 12
AST_UNARY_REF equ 13
AST_DEREF     equ 14
AST_CALL      equ 15
AST_IDENT     equ 16
AST_INT_LIT   equ 17
AST_TYPE_PRIM equ 18
AST_TYPE_PTR  equ 19
AST_ASM       equ 20   ; asm "..." — N_LEFT=src ptr, N_INT=uzunluk
AST_UEFI_CALL equ 21   ; uefi_call — N_LEFT=fn_ptr, N_SIBLING=args
AST_EXTERN     equ 22

; ─────────────────────────────────────────────
; OPERATÖR KODLARI
; ─────────────────────────────────────────────
OP_ADD equ 1
OP_SUB equ 2
OP_MUL equ 3
OP_DIV equ 4
OP_EQ  equ 5
OP_NEQ equ 6
OP_LT  equ 7
OP_GT  equ 8
OP_LEQ equ 9
OP_GEQ equ 10

; ─────────────────────────────────────────────
; NODE ALAN OFFSETLERİ
; ─────────────────────────────────────────────
N_TYPE    equ 0
N_OP      equ 1
N_LEFT    equ 8
N_RIGHT   equ 16
N_SIBLING equ 24
N_INT     equ 32
N_STR     equ 40

; ─────────────────────────────────────────────
; SEMBOL TABLOSU LAYOUT (32 byte/giriş)
;   [0..23] isim (null-terminated, max 23 char)
;   [24..27] rbp offset (i32, daima negatif)
;   [28..31] padding
; ─────────────────────────────────────────────
SYM_ENTRY equ 32
SYM_MAX   equ 256
SYM_NAME  equ 0
SYM_OFF   equ 24

; ─────────────────────────────────────────────
; STACK FRAME SABİTİ
;   Stage 0: her fn için sabit 2048B frame açar
;   (256 değişken × 8 byte — konservatif, israf ama güvenli)
; ─────────────────────────────────────────────
FRAME_SIZE equ 2048

section .rodata

; ── Emit string sabitleri ─────────────────────────────
E_SEC_TEXT    db "section .text", 10, 0
E_GLOBAL      db "global ", 0
E_NL          db 10, 0
E_COLON_NL    db ":", 10, 0
E_COMMENT     db "; ──────────────────────────────────", 10, 0

E_PUSH_RBP    db "    push rbp", 10, 0
E_MOV_RBP_RSP db "    mov rbp, rsp", 10, 0
E_SUB_RSP     db "    sub rsp, ", 0
E_MOV_RSP_RBP db "    mov rsp, rbp", 10, 0
E_POP_RBP     db "    pop rbp", 10, 0
E_RET         db "    ret", 10, 0

E_PUSH_IMM    db "    push qword ", 0
E_MOV_RAX_IMM db "    mov rax, ", 0
E_PUSH_MEM    db "    push qword [rbp", 0
E_POP_TO_MEM  db "    pop qword [rbp", 0
E_BRACKET_NL  db "]", 10, 0

E_POP_RAX     db "    pop rax", 10, 0
E_POP_RBX     db "    pop rbx", 10, 0
E_PUSH_RAX    db "    push rax", 10, 0

E_ADD         db "    add rax, rbx", 10, 0
E_SUB         db "    sub rax, rbx", 10, 0
E_IMUL        db "    imul rax, rbx", 10, 0
E_IDIV        db "    cqo", 10, "    idiv rbx", 10, 0

E_CMP         db "    cmp rax, rbx", 10, 0
E_XOR_RAX     db "    xor rax, rax", 10, 0
E_SETE        db "    sete al", 10, "    movzx rax, al", 10, 0
E_SETNE       db "    setne al", 10, "    movzx rax, al", 10, 0
E_SETL        db "    setl al", 10, "    movzx rax, al", 10, 0
E_SETG        db "    setg al", 10, "    movzx rax, al", 10, 0
E_SETLE       db "    setle al", 10, "    movzx rax, al", 10, 0
E_SETGE       db "    setge al", 10, "    movzx rax, al", 10, 0

E_TEST_RAX    db "    test rax, rax", 10, 0
E_JE          db "    je ", 0
E_JMP         db "    jmp ", 0
E_LEA_RBP     db "    lea rax, [rbp", 0
E_MOV_RAX_ARG db "    mov rax, qword [rbp+", 0
E_MOV_MEM_RBP db "    mov qword [rbp", 0
E_BR_RAX_NL   db "], rax", 10, 0
E_RCXSUFFIX   db "], rcx", 10, 0
E_RDXSUFFIX   db "], rdx", 10, 0
E_R8SUFFIX    db "], r8",  10, 0
E_R9SUFFIX    db "], r9",  10, 0
E_MOV_DEREF   db "    mov rax, qword [rax]", 10, 0
E_MOV_STORE   db "    mov qword [rax], rbx", 10, 0
E_CALL_KW     db "    call ", 0

E_UEFI_SHADOW     db "    sub rsp, 32", 10, 0
E_UEFI_SHADOW_CLR db "    add rsp, 32", 10, 0
E_CALL_RAX        db "    call rax", 10, 0
E_POP_RCX         db "    pop rcx", 10, 0
E_POP_RDX         db "    pop rdx", 10, 0
E_POP_R8          db "    pop r8", 10, 0
E_POP_R9          db "    pop r9", 10, 0

E_LBL_ELSE    db ".else_", 0
E_LBL_ENDIF   db ".endif_", 0
E_LBL_WS      db ".wstart_", 0
E_LBL_WE      db ".wend_", 0
E_MINUS       db "-", 0

E_EXTERN       db "extern ", 0
E_LEA_REL      db "    lea rax, [rel ", 0
E_BRACKET_NL2  db "]", 10, 0

E_EXTERN_FONT db "extern nihilum_font", 10, 0

section .bss

out_buf     resb 1048576        ; 1 MB çıkış tamponu
out_ptr     resq 1              ; mevcut yazma pozisyonu

label_ctr   resq 1              ; if/while benzersiz etiket sayacı

sym_tbl     resb SYM_ENTRY * SYM_MAX
sym_cnt     resd 1
sym_rbp_top resd 1              ; negatif rbp offset, 8'er azalır

cg_error    resb 1

section .text
global codegen_program
global out_buf
global out_ptr
global cg_error

; ═══════════════════════════════════════════════════════
; TEMEL EMIT YARDIMCILARI
; ═══════════════════════════════════════════════════════

; ───────────────────────────────────────────────────────
; emit_str  RDI = null-terminated string
;   RAX ve RSI korunur; diğerleri bozulabilir
; ───────────────────────────────────────────────────────
emit_str:
    push rax
    push rsi
    mov  rsi, [rel out_ptr]
.lp:
    mov  al, byte [rdi]
    test al, al
    jz   .done
    mov  byte [rsi], al
    inc  rdi
    inc  rsi
    jmp  .lp
.done:
    mov  [rel out_ptr], rsi
    pop  rsi
    pop  rax
    ret

; ───────────────────────────────────────────────────────
; emit_i32  EAX = işaretli i32 → ondalık string
; ───────────────────────────────────────────────────────
emit_i32:
    push rbx
    push rcx
    push rdx
    push r8
    push r9

    movsx rax, eax

    test rax, rax
    jns  .pos
    push rax
    lea  rdi, [rel E_MINUS]
    call emit_str
    pop  rax
    neg  rax

.pos:
    sub  rsp, 24
    mov  r8, rsp
    xor  r9d, r9d
    mov  rbx, 10
.digs:
    xor  rdx, rdx
    div  rbx
    add  dl, '0'
    mov  byte [r8 + r9], dl
    inc  r9d
    test rax, rax
    jnz  .digs

    mov  rcx, [rel out_ptr]
    dec  r9d
.wrt:
    mov  al, byte [r8 + r9]
    mov  byte [rcx], al
    inc  rcx
    dec  r9d
    jns  .wrt
    mov  [rel out_ptr], rcx
    add  rsp, 24

    pop  r9
    pop  r8
    pop  rdx
    pop  rcx
    pop  rbx
    ret

; ───────────────────────────────────────────────────────
; emit_u64  RAX = işaretsiz u64 → ondalık string
; ───────────────────────────────────────────────────────
emit_u64:
    push rbx
    push rcx
    push rdx
    push r8
    push r9

    sub  rsp, 24
    mov  r8, rsp
    xor  r9d, r9d
    mov  rbx, 10
.digs:
    xor  rdx, rdx
    div  rbx
    add  dl, '0'
    mov  byte [r8 + r9], dl
    inc  r9d
    test rax, rax
    jnz  .digs

    mov  rcx, [rel out_ptr]
    dec  r9d
.wrt:
    mov  al, byte [r8 + r9]
    mov  byte [rcx], al
    inc  rcx
    dec  r9d
    jns  .wrt
    mov  [rel out_ptr], rcx
    add  rsp, 24

    pop  r9
    pop  r8
    pop  rdx
    pop  rcx
    pop  rbx
    ret

; ═══════════════════════════════════════════════════════
; SEMBOL TABLOSU
; ═══════════════════════════════════════════════════════

; ───────────────────────────────────────────────────────
; sym_reset — fonksiyon başında çağrılır
; ───────────────────────────────────────────────────────
sym_reset:
    mov  dword [rel sym_cnt],     0
    mov  dword [rel sym_rbp_top], 0
    ret

; ───────────────────────────────────────────────────────
; sym_add  RDI = null-terminated isim → EAX = rbp offset
; ───────────────────────────────────────────────────────
sym_add:
    push rbx
    push rcx
    push rdx
    push rsi

    mov  eax, [rel sym_rbp_top]
    sub  eax, 8
    mov  [rel sym_rbp_top], eax

    mov  ecx, [rel sym_cnt]
    cmp  ecx, SYM_MAX
    jae  .overflow

    imul rbx, rcx, SYM_ENTRY
    lea  rcx, [rel sym_tbl]
    add  rbx, rcx

    lea  rsi, [rbx + SYM_NAME]
    mov  ecx, 23
.cp:
    mov  dl, byte [rdi]
    test dl, dl
    jz   .cp_done
    mov  byte [rsi], dl
    inc  rdi
    inc  rsi
    dec  ecx
    jnz  .cp
.cp_done:
    mov  byte [rsi], 0

    mov  dword [rbx + SYM_OFF], eax
    inc  dword [rel sym_cnt]

    pop  rsi
    pop  rdx
    pop  rcx
    pop  rbx
    ret

.overflow:
    mov  byte [rel cg_error], 1
    xor  eax, eax
    pop  rsi
    pop  rdx
    pop  rcx
    pop  rbx
    ret

; ───────────────────────────────────────────────────────
; sym_lookup  RDI = null-terminated isim → EAX = rbp offset
;             bulunamazsa cg_error=1
; ───────────────────────────────────────────────────────
sym_lookup:
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi                    ; orijinal rdi'yi koru

    mov  ecx, [rel sym_cnt]
    xor  ebx, ebx

.search:
    cmp  ebx, ecx
    jge  .not_found

    imul rdx, rbx, SYM_ENTRY
    lea  rax, [rel sym_tbl]     ; önce sabit adresi al
    add  rdx, rax               ; sonra dinamik offset ekle

    lea  rsi, [rdx + SYM_NAME]
    mov  rdi, [rsp]             ; orijinal rdi
.cmp:
    mov  al, byte [rdi]
    cmp  al, byte [rsi]
    jne  .next
    test al, al
    jz   .found
    inc  rdi
    inc  rsi
    jmp  .cmp

.found:
    mov  eax, dword [rdx + SYM_OFF]
    pop  rdi
    pop  rsi
    pop  rdx
    pop  rcx
    pop  rbx
    ret

.next:
    inc  ebx
    jmp  .search

.not_found:
    mov  byte [rel cg_error], 1
    xor  eax, eax
    pop  rdi
    pop  rsi
    pop  rdx
    pop  rcx
    pop  rbx
    ret

; ═══════════════════════════════════════════════════════
; İFADE CODEGEN
;   cg_expr  RDI = expr node → stack'e 1 qword bırakır
; ═══════════════════════════════════════════════════════
cg_expr:
    push rbx
    mov  rbx, rdi

    movzx eax, byte [rbx + N_TYPE]

    cmp  al, AST_INT_LIT   ; je .int_lit
    je   .int_lit
    cmp  al, AST_IDENT
    je   .ident
    cmp  al, AST_BINOP
    je   .binop
    cmp  al, AST_UNARY_REF
    je   .addrof
    cmp  al, AST_DEREF
    je   .deref
    cmp  al, AST_CALL
    je   .call
    cmp  al, AST_UEFI_CALL
    je   .uefi_call_expr

    mov  byte [rel cg_error], 1
    pop  rbx
    ret

; ── INT_LIT ───────────────────────────────────────────
.int_lit:
    lea  rdi, [rel E_MOV_RAX_IMM]  ; "    mov rax, " bas
    call emit_str
    lea  rdi, [rbx + N_STR]        ; "0x6a51..." sayısını bas
    call emit_str
    lea  rdi, [rel E_NL]           ; alt satıra geç
    call emit_str
    lea  rdi, [rel E_PUSH_RAX]     ; "    push rax" basarak yığına güvenle at
    call emit_str
    pop  rbx
    ret

; ── IDENT: push qword [rbp-N] ─────────────────────────
.ident:
    lea  rdi, [rbx + N_STR]
    call sym_lookup             ; EAX = offset
    push rax
    lea  rdi, [rel E_PUSH_MEM]
    call emit_str
    pop  rax
    movsx rax, eax
    call emit_i32
    lea  rdi, [rel E_BRACKET_NL]
    call emit_str
    pop  rbx
    ret

; ── BINOP ─────────────────────────────────────────────
.binop:
    mov  rdi, [rbx + N_LEFT]
    call cg_expr
    mov  rdi, [rbx + N_RIGHT]
    call cg_expr

    lea  rdi, [rel E_POP_RBX]
    call emit_str
    lea  rdi, [rel E_POP_RAX]
    call emit_str

    movzx eax, byte [rbx + N_OP]

    cmp  al, OP_ADD;  je .b_add
    je   .b_add
    cmp  al, OP_SUB;  je .b_sub
    je   .b_sub
    cmp  al, OP_MUL
    je   .b_mul
    cmp  al, OP_DIV
    je   .b_div
    cmp  al, OP_EQ
    je   .b_eq
    cmp  al, OP_NEQ
    je   .b_neq
    cmp  al, OP_LT
    je   .b_lt
    cmp  al, OP_GT
    je   .b_gt
    cmp  al, OP_LEQ
    je   .b_leq
    cmp  al, OP_GEQ
    je   .b_geq
    jmp  .b_done

.b_add:
    lea  rdi, [rel E_ADD]
    call emit_str
    jmp  .b_done

.b_sub:
    lea  rdi, [rel E_SUB]
    call emit_str
    jmp  .b_done

.b_mul:
    lea  rdi, [rel E_IMUL]
    call emit_str
    jmp  .b_done

.b_div:
    lea  rdi, [rel E_IDIV]
    call emit_str
    jmp  .b_done

.b_eq:
    lea  rdi, [rel E_CMP]
    call emit_str
    lea  rdi, [rel E_SETE]
    call emit_str
    jmp  .b_done
.b_neq:
    lea  rdi, [rel E_CMP]
    call emit_str
    lea  rdi, [rel E_SETNE]
    call emit_str
    jmp  .b_done
.b_lt:
    lea  rdi, [rel E_CMP]
    call emit_str
    lea  rdi, [rel E_SETL]
    call emit_str
    jmp  .b_done
.b_gt:
    lea  rdi, [rel E_CMP]
    call emit_str
    lea  rdi, [rel E_SETG]
    call emit_str
    jmp  .b_done
.b_leq:
    lea  rdi, [rel E_CMP]
    call emit_str
    lea  rdi, [rel E_SETLE]
    call emit_str
    jmp  .b_done
.b_geq:
    lea  rdi, [rel E_CMP]
    call emit_str
    lea  rdi, [rel E_SETGE]
    call emit_str

.b_done:
    lea  rdi, [rel E_PUSH_RAX]
    call emit_str
    pop  rbx
    ret

; ── UEFI_CALL expression: Microsoft x64 ABI ─────────
;
; Doğru sıra:
;   1. Argümanları stack'e push (soldan sağa)
;   2. Argümanları register'lara POP (RCX,RDX,R8,R9)
;   3. SONRA sub rsp, 32 (shadow space)
;   4. fn_ptr → rax → call rax
;   5. add rsp, 32
;   6. push rax (dönüş değeri expression sonucu)
.uefi_call_expr:
    push r12
    push r13

    ; Argümanları değerlendir → stack (soldan sağa)
    mov  r12, [rbx + N_SIBLING]
    xor  r13d, r13d

.uce_push_loop:
    test r12, r12
    jz   .uce_args_done
    push rbx
    push r12
    mov  rdi, r12
    call cg_expr
    pop  r12
    pop  rbx
    inc  r13d
    mov  r12, [r12 + N_SIBLING]
    jmp  .uce_push_loop

.uce_args_done:
    ; Önce argümanları register'lara taşı
    cmp  r13d, 4
    jl   .uce_lt4
    lea  rdi, [rel E_POP_R9]
    call emit_str
.uce_lt4:
    cmp  r13d, 3
    jl   .uce_lt3
    lea  rdi, [rel E_POP_R8]
    call emit_str
.uce_lt3:
    cmp  r13d, 2
    jl   .uce_lt2
    lea  rdi, [rel E_POP_RDX]
    call emit_str
.uce_lt2:
    cmp  r13d, 1
    jl   .uce_no_args
    lea  rdi, [rel E_POP_RCX]
    call emit_str
.uce_no_args:

    ; fn_ptr → rax
    push rbx
    mov  rdi, [rbx + N_LEFT]
    call cg_expr
    pop  rbx
    lea  rdi, [rel E_POP_RAX]
    call emit_str

    ; Argümanlar register'larda, şimdi shadow space aç
    lea  rdi, [rel E_UEFI_SHADOW]
    call emit_str

    ; call rax
    lea  rdi, [rel E_CALL_RAX]
    call emit_str

    ; shadow space kapat
    lea  rdi, [rel E_UEFI_SHADOW_CLR]
    call emit_str

    ; Dönüş değerini expression sonucu olarak stack'e bırak
    lea  rdi, [rel E_PUSH_RAX]
    call emit_str

    pop  r13
    pop  r12
    pop  rbx
    ret

; ── ADDROF: &ident → lea rax, [rbp-N]; push rax ──────
.addrof:
    mov  rdi, [rbx + N_LEFT]
    movzx eax, byte [rdi + N_TYPE]
    cmp  al, AST_IDENT
    jne  .addrof_err

    push rdi                    ; N_LEFT node'unu sakla
    lea  rdi, [rdi + N_STR]
    call sym_lookup             ; EAX = offset, RDI bozulur
    pop  r12                    ; r12 = N_LEFT node pointer

    cmp  byte [rel cg_error], 1
    jne  .addrof_local

    ; extern sembol → lea rax, [rel sembol]
    mov  byte [rel cg_error], 0
    lea  rdi, [rel E_LEA_REL]
    call emit_str
    lea  rdi, [r12 + N_STR]     ; sembol adı
    call emit_str
    lea  rdi, [rel E_BRACKET_NL2]
    call emit_str
    lea  rdi, [rel E_PUSH_RAX]
    call emit_str
    pop  rbx
    ret

.addrof_local:
    push rax
    lea  rdi, [rel E_LEA_RBP]
    call emit_str
    pop  rax
    movsx rax, eax
    call emit_i32
    lea  rdi, [rel E_BRACKET_NL]
    call emit_str
    lea  rdi, [rel E_PUSH_RAX]
    call emit_str
    pop  rbx
    ret

.addrof_err:
    mov  byte [rel cg_error], 1
    pop  rbx
    ret

; ── DEREF: expr.* ─────────────────────────────────────
.deref:
    mov  rdi, [rbx + N_LEFT]
    call cg_expr
    lea  rdi, [rel E_POP_RAX]
    call emit_str
    lea  rdi, [rel E_MOV_DEREF]
    call emit_str
    lea  rdi, [rel E_PUSH_RAX]
    call emit_str
    pop  rbx
    ret

; ── CALL ──────────────────────────────────────────────
.call:
    mov  rdi, [rbx + N_LEFT]
.arg_loop:
    test rdi, rdi
    jz   .do_call
    push rbx
    push rdi
    call cg_expr
    pop  rdi
    pop  rbx
    mov  rdi, [rdi + N_SIBLING]
    jmp  .arg_loop
.do_call:
    lea  rdi, [rel E_CALL_KW]
    call emit_str
    lea  rdi, [rbx + N_STR]
    call emit_str
    lea  rdi, [rel E_NL]
    call emit_str
    lea  rdi, [rel E_PUSH_RAX]
    call emit_str
    pop  rbx
    ret

; ═══════════════════════════════════════════════════════
; STATEMENT CODEGEN
; ═══════════════════════════════════════════════════════
cg_stmt:
    push rbx
    mov  rbx, rdi
    movzx eax, byte [rbx + N_TYPE]

    cmp  al, AST_LET;  je .let
    je   .let
    cmp  al, AST_MUT
    je   .mut
    cmp  al, AST_ASSIGN
    je   .assign
    cmp  al, AST_RETURN
    je   .ret_stmt
    cmp  al, AST_IF
    je   .if_stmt
    cmp  al, AST_WHILE
    je   .while_stmt
    cmp  al, AST_EXPR_STMT
    je   .expr_stmt
    cmp  al, AST_EXTERN
    je   .extern_stmt
    cmp  al, AST_ASM
    je   .asm_stmt
    cmp  al, AST_UEFI_CALL
    je   .uefi_call_stmt

    mov  byte [rel cg_error], 1
    pop  rbx
    ret

; ── LET / MUT ─────────────────────────────────────────
.let:
.mut:
    lea  rdi, [rbx + N_STR]
    call sym_add                ; EAX = rbp offset
    push rax

    mov  rdi, [rbx + N_RIGHT]
    call cg_expr

    lea  rdi, [rel E_POP_TO_MEM]
    call emit_str
    pop  rax
    movsx rax, eax
    call emit_i32
    lea  rdi, [rel E_BRACKET_NL]
    call emit_str
    pop  rbx
    ret

; ── ASSIGN ────────────────────────────────────────────
.assign:
    mov  rdi, [rbx + N_RIGHT]
    call cg_expr

    mov  rdi, [rbx + N_LEFT]
    movzx eax, byte [rdi + N_TYPE]

    cmp  al, AST_IDENT
    je   .assign_ident
    cmp  al, AST_DEREF
    je   .assign_deref

    mov  byte [rel cg_error], 1
    pop  rbx
    ret

.assign_ident:
    push rdi
    lea  rdi, [rdi + N_STR]
    call sym_lookup
    pop  rdi
    push rax
    lea  rdi, [rel E_POP_TO_MEM]
    call emit_str
    pop  rax
    movsx rax, eax
    call emit_i32
    lea  rdi, [rel E_BRACKET_NL]
    call emit_str
    pop  rbx
    ret

.assign_deref:
    ; adres.* = değer
    ; Stack'te önce değer push'landı, şimdi adres
    mov  rdi, [rdi + N_LEFT]
    call cg_expr
    ; stack: [alt=değer, üst=adres]
    lea  rdi, [rel E_POP_RAX]   ; rax = adres
    call emit_str
    lea  rdi, [rel E_POP_RBX]   ; rbx = değer
    call emit_str
    lea  rdi, [rel E_MOV_STORE]
    call emit_str
    pop  rbx
    ret

; ── RETURN ────────────────────────────────────────────
.ret_stmt:
    mov  rdi, [rbx + N_LEFT]
    test rdi, rdi
    jz   .ret_void
    call cg_expr
    lea  rdi, [rel E_POP_RAX]
    call emit_str
.ret_void:
    lea  rdi, [rel E_MOV_RSP_RBP]
    call emit_str
    lea  rdi, [rel E_POP_RBP]
    call emit_str
    lea  rdi, [rel E_RET]
    call emit_str
    pop  rbx
    ret

; ── IF ────────────────────────────────────────────────
.if_stmt:
    mov  r8, [rel label_ctr]
    inc  qword [rel label_ctr]

    ; Koşul
    push rbx
    push r8
    mov  rdi, [rbx + N_LEFT]
    call cg_expr
    pop  r8
    pop  rbx

    lea  rdi, [rel E_POP_RAX]
    call emit_str
    lea  rdi, [rel E_TEST_RAX]
    call emit_str
    lea  rdi, [rel E_JE]
    call emit_str
    lea  rdi, [rel E_LBL_ELSE]
    call emit_str
    mov  rax, r8
    call emit_u64
    lea  rdi, [rel E_NL]
    call emit_str

    ; Then
    push rbx
    push r8
    mov  rdi, [rbx + N_RIGHT]
    call cg_block_body
    pop  r8
    pop  rbx

    ; jmp .endif_N
    lea  rdi, [rel E_JMP]
    call emit_str
    lea  rdi, [rel E_LBL_ENDIF]
    call emit_str
    mov  rax, r8
    call emit_u64
    lea  rdi, [rel E_NL]
    call emit_str

    ; .else_N:
    lea  rdi, [rel E_LBL_ELSE]
    call emit_str
    mov  rax, r8
    call emit_u64
    lea  rdi, [rel E_COLON_NL]
    call emit_str

    ; Else (varsa)
    mov  rdi, [rbx + N_SIBLING]
    test rdi, rdi
    jz   .if_no_else
    push rbx
    push r8
    call cg_block_body
    pop  r8
    pop  rbx

.if_no_else:
    ; .endif_N:
    lea  rdi, [rel E_LBL_ENDIF]
    call emit_str
    mov  rax, r8
    call emit_u64
    lea  rdi, [rel E_COLON_NL]
    call emit_str
    pop  rbx
    ret

; ── WHILE ─────────────────────────────────────────────
.while_stmt:
    mov  r8, [rel label_ctr]
    inc  qword [rel label_ctr]

    ; .wstart_N:
    lea  rdi, [rel E_LBL_WS]
    call emit_str
    mov  rax, r8
    call emit_u64
    lea  rdi, [rel E_COLON_NL]
    call emit_str

    ; Koşul
    push rbx
    push r8
    mov  rdi, [rbx + N_LEFT]
    call cg_expr
    pop  r8
    pop  rbx

    lea  rdi, [rel E_POP_RAX]
    call emit_str
    lea  rdi, [rel E_TEST_RAX]
    call emit_str
    lea  rdi, [rel E_JE]
    call emit_str
    lea  rdi, [rel E_LBL_WE]
    call emit_str
    mov  rax, r8
    call emit_u64
    lea  rdi, [rel E_NL]
    call emit_str

    ; Gövde
    push rbx
    push r8
    mov  rdi, [rbx + N_RIGHT]
    call cg_block_body
    pop  r8
    pop  rbx

    ; jmp .wstart_N
    lea  rdi, [rel E_JMP]
    call emit_str
    lea  rdi, [rel E_LBL_WS]
    call emit_str
    mov  rax, r8
    call emit_u64
    lea  rdi, [rel E_NL]
    call emit_str

    ; .wend_N:
    lea  rdi, [rel E_LBL_WE]
    call emit_str
    mov  rax, r8
    call emit_u64
    lea  rdi, [rel E_COLON_NL]
    call emit_str

    pop  rbx
    ret

; ── EXTERN: "extern sembol_adı" emit et ──────────────
.extern_stmt:
    ; Nihilum'da extern sadece derleyiciye bilgi verir.
    ; "Bu sembol dışarıdan gelecek, &ile kullanılırsa lea üret."
    ; NASM çıktısına hiçbir şey yazılmaz — linker halleder.
    pop  rbx
    ret

; ── ASM: ham assembly satırını doğrudan emit et ──────
; N_LEFT = kaynak buffer pointer, N_INT = byte uzunluğu
; Tırnak yok, yorum yok, soyutlama yok.
.asm_stmt:
    push r12
    push r13
    mov  r12, [rbx + N_LEFT]    ; kaynak pointer
    mov  r13, [rbx + N_INT]     ; uzunluk
    mov  rcx, [rel out_ptr]
.asm_raw:
    test r13, r13
    jz   .asm_done
    mov  al, byte [r12]
    mov  byte [rcx], al
    inc  r12
    inc  rcx
    dec  r13
    jmp  .asm_raw
.asm_done:
    mov  [rel out_ptr], rcx
    pop  r13
    pop  r12
    lea  rdi, [rel E_NL]
    call emit_str
    pop  rbx
    ret

; ── UEFI_CALL: Microsoft x64 ABI ile çağrı ───────────
;
; Nihilum sözdizimi: uefi_call(fn_ptr, arg1, arg2, arg3, arg4);
;
; Üretilen assembly:
;   ; argümanları değerlendir → stack
;   sub rsp, 32          ; shadow space
;   mov rcx, arg1        ; 1. argüman
;   mov rdx, arg2        ; 2. argüman
;   mov r8,  arg3        ; 3. argüman
;   mov r9,  arg4        ; 4. argüman
;   call [fn_ptr]        ; UEFI fonksiyonu çağır
;   add rsp, 32          ; shadow space temizle
;
; N_LEFT    = fn_ptr expr node
; N_SIBLING = arg zinciri (sırayla RCX, RDX, R8, R9)
.uefi_call_stmt:
    push r12
    push r13

    ; Argümanları say ve değerlendir → stack
    mov  r12, [rbx + N_SIBLING] ; r12 = ilk arg node
    xor  r13d, r13d             ; arg sayısı

.uefi_args_push:
    test r12, r12
    jz   .uefi_args_done
    push rbx
    push r12
    mov  rdi, r12
    call cg_expr                ; arg → stack
    pop  r12
    pop  rbx
    inc  r13d
    mov  r12, [r12 + N_SIBLING]
    jmp  .uefi_args_push

.uefi_args_done:
    ; Argümanları register'lara taşı (ters sırayla pop)
    ; Stack'te: son arg altta, ilk arg üstte
    ; RCX=1., RDX=2., R8=3., R9=4.
    ; ÖNEMLİ: sub rsp, 32 ÖNCE DEĞİL, SONRA gelir.
    ; Önce argümanları çek, sonra shadow space aç.
    cmp  r13d, 4
    jl   .uefi_lt4
    lea  rdi, [rel E_POP_R9]
    call emit_str
.uefi_lt4:
    cmp  r13d, 3
    jl   .uefi_lt3
    lea  rdi, [rel E_POP_R8]
    call emit_str
.uefi_lt3:
    cmp  r13d, 2
    jl   .uefi_lt2
    lea  rdi, [rel E_POP_RDX]
    call emit_str
.uefi_lt2:
    cmp  r13d, 1
    jl   .uefi_done_regs
    lea  rdi, [rel E_POP_RCX]
    call emit_str
.uefi_done_regs:

    ; fn_ptr'ı değerlendir → rax
    push rbx
    mov  rdi, [rbx + N_LEFT]
    call cg_expr                ; fn_ptr → stack
    pop  rbx
    lea  rdi, [rel E_POP_RAX]
    call emit_str

    ; shadow space BURADA açılır — argümanlar zaten register'larda
    lea  rdi, [rel E_UEFI_SHADOW]
    call emit_str

    ; call rax
    lea  rdi, [rel E_CALL_RAX]
    call emit_str

    ; add rsp, 32  (shadow space temizle)
    lea  rdi, [rel E_UEFI_SHADOW_CLR]
    call emit_str

    pop  r13
    pop  r12
    pop  rbx
    ret

; ── EXPR_STMT ─────────────────────────────────────────
.expr_stmt:
    mov  rdi, [rbx + N_LEFT]
    call cg_expr
    lea  rdi, [rel E_POP_RAX]   ; kullanılmayan sonucu temizle
    call emit_str
    pop  rbx
    ret

; ═══════════════════════════════════════════════════════
; BLOK CODEGEN
; ═══════════════════════════════════════════════════════
cg_block_body:
    push rbx
    test rdi, rdi
    jz   .done

    movzx eax, byte [rdi + N_TYPE]
    cmp  al, AST_BLOCK
    jne  .done

    mov  rbx, [rdi + N_LEFT]

.loop:
    test rbx, rbx
    jz   .done
    cmp  byte [rel cg_error], 1
    je   .done

    mov  rdi, rbx
    call cg_stmt

    ; [Tehlike 1 fix] hata varsa zinciri yürüme
    cmp  byte [rel cg_error], 1
    je   .done

    mov  rbx, [rbx + N_SIBLING]
    jmp  .loop

.done:
    pop  rbx
    ret

; ═══════════════════════════════════════════════════════
; FONKSİYON CODEGEN
; ═══════════════════════════════════════════════════════
cg_fn:
    push rbx
    push r12
    push r13
    push r14
    mov  rbx, rdi

    call sym_reset

    ; Parametreleri sembol tablosuna ekle
    mov  rdi, [rbx + N_LEFT]
.param_loop:
    test rdi, rdi
    jz   .params_done
    movzx eax, byte [rdi + N_TYPE]
    cmp  al, AST_PARAM
    jne  .params_done
    push rdi
    lea  rdi, [rdi + N_STR]
    call sym_add
    pop  rdi
    mov  rdi, [rdi + N_SIBLING]
    jmp  .param_loop
.params_done:

    ; global isim \n  isim: \n
    lea  rdi, [rel E_GLOBAL]
    call emit_str
    lea  rdi, [rbx + N_STR]
    call emit_str
    lea  rdi, [rel E_NL]
    call emit_str
    lea  rdi, [rbx + N_STR]
    call emit_str
    lea  rdi, [rel E_COLON_NL]
    call emit_str

    ; Prologue: push rbp / mov rbp, rsp / sub rsp, FRAME_SIZE
    lea  rdi, [rel E_PUSH_RBP]
    call emit_str
    lea  rdi, [rel E_MOV_RBP_RSP]
    call emit_str
    lea  rdi, [rel E_SUB_RSP]
    call emit_str
    mov  rax, FRAME_SIZE
    call emit_u64
    lea  rdi, [rel E_NL]
    call emit_str

    ; Parametre köprüsü: efi_fn mi, normal fn mi?
    ; N_OP = 1 → efi_fn: RCX/RDX/R8/R9'dan oku
    ; N_OP = 0 → normal fn: [rbp+N]'den oku
    cmp  byte [rbx + N_OP], 1
    je   .efi_param_bridge

    ; ── Normal köprü ─────────────────────────────────
    mov  r14, [rbx + N_LEFT]
    xor  r12d, r12d
.param_count_loop:
    test r14, r14
    jz   .param_count_done
    inc  r12d
    mov  r14, [r14 + N_SIBLING]
    jmp  .param_count_loop
.param_count_done:

    mov  r14, [rbx + N_LEFT]
    xor  r13d, r13d
.param_copy_loop:
    test r14, r14
    jz   .param_copy_done

    mov  eax, r12d
    dec  eax
    sub  eax, r13d
    imul eax, eax, 8
    add  eax, 16

    lea  rdi, [rel E_MOV_RAX_ARG]
    call emit_str
    call emit_i32
    lea  rdi, [rel E_BRACKET_NL]
    call emit_str

    push r14
    lea  rdi, [r14 + N_STR]
    call sym_lookup
    pop  r14

    push rax
    lea  rdi, [rel E_MOV_MEM_RBP]
    call emit_str
    pop  rax
    call emit_i32
    lea  rdi, [rel E_BR_RAX_NL]
    call emit_str

    inc  r13d
    mov  r14, [r14 + N_SIBLING]
    jmp  .param_copy_loop

    ; ── UEFI ABI köprüsü ─────────────────────────────
    ; efi_fn: parametreler RCX, RDX, R8, R9'da gelir
    ; emit: mov qword [rbp-N], rcx/rdx/r8/r9
.efi_param_bridge:
    mov  r14, [rbx + N_LEFT]    ; ilk param
    xor  r13d, r13d             ; index: 0=RCX,1=RDX,2=R8,3=R9
.efi_bridge_loop:
    test r14, r14
    jz   .param_copy_done

    push r14
    lea  rdi, [r14 + N_STR]
    call sym_lookup             ; EAX = rbp offset
    pop  r14

    push rax
    lea  rdi, [rel E_MOV_MEM_RBP]
    call emit_str
    pop  rax
    call emit_i32               ; negatif offset

    cmp  r13d, 0
    je   .efi_use_rcx
    cmp  r13d, 1
    je   .efi_use_rdx
    cmp  r13d, 2
    je   .efi_use_r8
    lea  rdi, [rel E_R9SUFFIX]
    call emit_str
    jmp  .efi_next
.efi_use_rcx:
    lea  rdi, [rel E_RCXSUFFIX]
    call emit_str
    jmp  .efi_next
.efi_use_rdx:
    lea  rdi, [rel E_RDXSUFFIX]
    call emit_str
    jmp  .efi_next
.efi_use_r8:
    lea  rdi, [rel E_R8SUFFIX]
    call emit_str
.efi_next:
    inc  r13d
    mov  r14, [r14 + N_SIBLING]
    jmp  .efi_bridge_loop
.param_copy_done:

    ; Gövde
    mov  rdi, [rbx + N_INT]
    call cg_block_body

    ; Varsayılan epilogue (return içermeyen fn için güvenli zemin)
    lea  rdi, [rel E_MOV_RSP_RBP]
    call emit_str
    lea  rdi, [rel E_POP_RBP]
    call emit_str
    lea  rdi, [rel E_RET]
    call emit_str
    lea  rdi, [rel E_NL]
    call emit_str

    pop  r14
    pop  r13
    pop  r12
    pop  rbx
    ret

; ═══════════════════════════════════════════════════════
; codegen_program — Ana Giriş Noktası
;   RDI = AST_PROGRAM node pointer
;   RAX = 0 başarı, 1 hata
; ═══════════════════════════════════════════════════════
codegen_program:
    push rbx
    mov  rbx, rdi               ; rbx = PROGRAM node

    ; Tampon ve durum sıfırla
    lea  rax, [rel out_buf]
    mov  [rel out_ptr], rax
    mov  qword [rel label_ctr], 0
    mov  byte  [rel cg_error],  0

    test rbx, rbx
    jz   .error

    movzx eax, byte [rbx + N_TYPE]
    cmp  al, AST_PROGRAM
    jne  .error

    ; Başlık
    lea  rdi, [rel E_EXTERN_FONT]  ; <--- BUNU EKLE!
    call emit_str                  ; <--- BUNU EKLE!
    lea  rdi, [rel E_COMMENT]
    call emit_str
    lea  rdi, [rel E_SEC_TEXT]
    call emit_str
    lea  rdi, [rel E_NL]
    call emit_str

    ; Fonksiyon zinciri: PROGRAM.N_LEFT = ilk FN_DECL
    mov  rbx, [rbx + N_LEFT]

.fn_loop:
    test rbx, rbx
    jz   .done

    movzx eax, byte [rbx + N_TYPE]
    cmp  al, AST_FN_DECL
    jne  .done

    mov  rdi, rbx
    call cg_fn

    cmp  byte [rel cg_error], 1
    je   .error

    mov  rbx, [rbx + N_SIBLING]
    jmp  .fn_loop

.done:
    ; Tamponu null-terminate et
    mov  rcx, [rel out_ptr]
    mov  byte [rcx], 0
    xor  eax, eax
    pop  rbx
    ret

.error:
    mov  byte [rel cg_error], 1
    mov  eax, 1
    pop  rbx
    ret