; isr.asm — Nihilum Interrupt Service Routines
; 64-bit Long Mode IDT stubs
; Her exception için stub, ortak handler'a atlar
; iretq ile döner (normal ret değil!)

BITS 64

global idt_table
global idtr_ptr
global setup_idt_asm
global isr_common
global sys_fb
global sys_scanline
global sys_font

extern isr_handler

; ─────────────────────────────────────────────────────────
; IDT TABLOSU — 256 × 16 byte = 4096 byte
; ─────────────────────────────────────────────────────────
section .bss
alignb 16
idt_table: resb 4096        ; 256 giriş × 16 byte

; IDTR yapısı: 10 byte (limit 2B + base 8B)
idtr_ptr:  resb 10

sys_fb: resq 1
sys_scanline: resq 1
sys_font: resq 1

; ─────────────────────────────────────────────────────────
; ISR STUB MACRO
; CPU hata kodu push'layanlarda dummy kod yok
; ─────────────────────────────────────────────────────────

; Hata kodu YOK olanlar (dummy push gerekli):
%macro ISR_NO_ERR 1
isr%1:
    push qword 0        ; dummy hata kodu
    push qword %1       ; exception numarası
    jmp isr_common
%endmacro

; Hata kodu VAR olanlar (CPU zaten push'lar):
%macro ISR_ERR 1
isr%1:
    push qword %1       ; exception numarası
    jmp isr_common
%endmacro

section .text

; ─────────────────────────────────────────────────────────
; 256 ISR STUB
; CPU'nun hata kodu push'ladığı exceptionlar:
; 8, 10, 11, 12, 13, 14, 17, 21, 29, 30
; ─────────────────────────────────────────────────────────
ISR_NO_ERR 0    ; Division by Zero
ISR_NO_ERR 1    ; Debug
ISR_NO_ERR 2    ; NMI
ISR_NO_ERR 3    ; Breakpoint
ISR_NO_ERR 4    ; Overflow
ISR_NO_ERR 5    ; Bound Range Exceeded
ISR_NO_ERR 6    ; Invalid Opcode
ISR_NO_ERR 7    ; Device Not Available
ISR_ERR    8    ; Double Fault
ISR_NO_ERR 9    ; Coprocessor Segment Overrun
ISR_ERR    10   ; Invalid TSS
ISR_ERR    11   ; Segment Not Present
ISR_ERR    12   ; Stack Fault
ISR_ERR    13   ; General Protection Fault
ISR_ERR    14   ; Page Fault
ISR_NO_ERR 15   ; Reserved
ISR_NO_ERR 16   ; x87 FPU Error
ISR_ERR    17   ; Alignment Check
ISR_NO_ERR 18   ; Machine Check
ISR_NO_ERR 19   ; SIMD Floating Point
ISR_NO_ERR 20   ; Virtualization
ISR_ERR    21   ; Control Protection
ISR_NO_ERR 22
ISR_NO_ERR 23
ISR_NO_ERR 24
ISR_NO_ERR 25
ISR_NO_ERR 26
ISR_NO_ERR 27
ISR_NO_ERR 28
ISR_ERR    29   ; HV Injection
ISR_ERR    30   ; VMM Communication
ISR_NO_ERR 31

; IRQ 32-47 (PIC hardware interrupts)
%assign i 32
%rep 16
ISR_NO_ERR i
%assign i i+1
%endrep

; Kalan 48-255
%assign i 48
%rep 208
ISR_NO_ERR i
%assign i i+1
%endrep

; ─────────────────────────────────────────────────────────
; ISR COMMON — Tüm exceptionlar buraya gelir
; Stack durumu:
;   [rsp+0]  = exception numarası (bizim push)
;   [rsp+8]  = hata kodu (CPU veya dummy)
;   [rsp+16] = RIP      (CPU push)
;   [rsp+24] = CS       (CPU push)
;   [rsp+32] = RFLAGS   (CPU push)
;   [rsp+40] = RSP      (CPU push, privilege change)
;   [rsp+48] = SS       (CPU push, privilege change)
; ─────────────────────────────────────────────────────────
isr_common:
    ; Tüm genel amaçlı registerları kaydet
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push rbp
    push r8
    push r9
    push r10
    push r11
    push r12
    push r13
    push r14
    push r15

    ; Exception numarasını ve hata kodunu argüman olarak geç
    ; Stack: [r15 push'tan önce] = exc_num, exc_num+8 = err_code
    mov  rdi, [rsp + 15*8]      ; exc_num (15 register push'tan sonra)
    mov  rsi, [rsp + 15*8 + 8]  ; err_code
    mov  rdx, [rsp + 15*8 + 16] ; RIP (CPU push)
    mov  rcx, [rsp + 15*8 + 32] ; RFLAGS

    ; Handler'ı çağır
    call isr_handler

    ; Registerları geri yükle
    pop r15
    pop r14
    pop r13
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
    pop rbp
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax

    ; exc_num ve err_code'u stack'ten temizle
    add rsp, 16

    ; Interrupt'tan dön (ret değil!)
    iretq

; ─────────────────────────────────────────────────────────
; setup_idt_asm
; IDT tablosunu ISR adresleriyle doldurur ve LIDT çalıştırır
; Giriş: yok
; ─────────────────────────────────────────────────────────
setup_idt_asm:
    push rbx
    push r12
    push r13

    ; Her ISR stub'ın adresini IDT girişine yaz
    ; ISR stub adresleri bir tabloda sıralı

    lea  r12, [rel idt_table]   ; IDT başlangıcı
    xor  r13, r13               ; index = 0

    ; Stub adreslerini tek tek işle
    ; Her stub 10 byte (push imm8 = 2B, push imm8 = 2B, jmp rel32 = 5B + 1B padding)
    ; Aslında NASM macro'ları farklı boyut üretebilir, adresleri direkt kullanalım

%macro SET_IDT_ENTRY 1
    lea  rbx, [rel isr%1]
    call write_idt_entry
    inc  r13
%endmacro

%assign i 0
%rep 256
SET_IDT_ENTRY i
%assign i i+1
%endrep

    ; IDTR'ı ayarla ve yükle
    lea  rax, [rel idt_table]
    lea  rbx, [rel idtr_ptr]
    mov  word  [rbx],   4095    ; limit = 256*16 - 1
    mov  qword [rbx+2], rax     ; base = idt_table adresi

    lidt [rbx]

    pop  r13
    pop  r12
    pop  rbx
    ret

; ─────────────────────────────────────────────────────────
; write_idt_entry
; Giriş: rbx = handler adresi
;         r12 = IDT tablosu başlangıcı
;         r13 = giriş indexi
; Bir IDT girişi (16 byte) yazar:
;   [0..1]   offset[0..15]
;   [2..3]   segment selector = 0x38 (UEFI code segment)
;   [4]      IST = 0
;   [5]      type_attr = 0x8E (P=1, DPL=0, type=0xE interrupt gate)
;   [6..7]   offset[16..31]
;   [8..11]  offset[32..63]
;   [12..15] reserved = 0
; ─────────────────────────────────────────────────────────
write_idt_entry:
    push rax
    push rcx

    ; Giriş adresi = idt_table + index * 16
    imul rcx, r13, 16
    lea  rax, [r12 + rcx]       ; rax = bu girişin adresi

    ; offset_low [0..15]
    mov  word [rax],     bx

    ; selector [2..3] = 0x38 (UEFI'nin CS değeri, long mode code)
    mov  word [rax+2],   0x38

    ; IST [4] = 0, type_attr [5] = 0x8E
    mov  byte [rax+4],   0x00
    mov  byte [rax+5],   0x8E

    ; offset_mid [6..7]
    shr  rbx, 16
    mov  word [rax+6],   bx

    ; offset_high [8..11]
    shr  rbx, 16
    mov  dword [rax+8],  ebx

    ; reserved [12..15]
    mov  dword [rax+12], 0

    pop  rcx
    pop  rax
    ret