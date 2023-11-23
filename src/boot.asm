; 0x2 ^ mask = 0x10
; 0x10 ^ mask = 0x2
%define SECTORS_COUNT_MASK 0b10010 

; 0x10 ^ mask = 0x1
; 0x1 ^ mask = 0x10
%define SECTOR_OFFSET_MASK 0b10000

[BITS 16]

cli
mov ax, 0x7c00
mov ss, ax
mov ds, ax

mov ax, 0x2000
mov es, ax

xor ax, ax
xor bx, bx
sti

initing:
    xor dh, dh
    mov es, ax
    xor ax, ax

    xor cx, cx
    inc cx

    dec ch
    ; mov ch, 0b11111111

    push 0x10

; reading first 21 cylinders
; after that we will need to read 12 sectors of next cylinder 
booting_loop:    
    inc ch

    mov bx, es
    cmp bx, 0x8000
    jz read_tail

    ; assuming: 
    ;   ES mutated only here
    ; MUTATED registers:
    ;   BP, BX, AX
    read_cylinder:
        ; assuming
        ;   DH (head) is set
        ;   DL (disk id) is set
        ;   CH is set (! CL is mutated !)
        ;   ES (will be mutated) is set
        ; top of stack -- amount of sectors to read
        ; BP           -- counter for attempts
        ; MUTATED registers:
        ; CL
        attempt_init:
            xor bp, bp
            xor bx, bx
        attempt:            
            cmp  bp, 0x4
            jz   boot_fail
            pop  ax
            push ax
            mov  ah, 0x2
            inc  bp
            int  0x13
            jc   attempt

       
        pop ax
        mov bx, ax
        xor bx, SECTORS_COUNT_MASK
        push bx

        xor cl, SECTOR_OFFSET_MASK

        shl ax, 0x5
        mov bx, es
        add bx, ax
        mov es, bx

        cmp ax, 0x200
        jz attempt_init

        ; move head next
        ; head in [0; 1]: dh xor 1 <=> 0 -> 1 -> 1...  
        xor dh, 0x1 
       
        cmp cl, 0x10
        jz booting_loop

        jmp attempt_init
        
; reading last 12 sectors
; assuming:
;   CX is set
;   ES is set
;   DX is set
; MUTATED registers:
;   AX, BX, BP
read_tail:

    xor bx, bx
    xor bp, bp

    tail_read_attempt:
        cmp bp, 0x4
        jz boot_fail
        
        mov ah, 0x2
        mov al, 0xc

        inc bp
        int 0x13
        jc tail_read_attempt 

    jmp boot_success
        
 
; if we somehow got here, 
; unexpected error message will be shown (unexpected_string + 0)
xor bx, bx
end_of_boot:
    pop ax
    xor ax, ax 
    print_loop:
        mov  al, [unexpected_string + bx]
        test al, al
        jz   endless
        int  0x10
        inc  bx
        jmp  print_loop

boot_success:
    mov bx, 0x2b
    jmp end_of_boot

boot_fail:
    mov bx, 0x4d
    jmp end_of_boot

endless:
    jmp endless

unexpected_string:
    db `An unexpected error occurred during boot\r\n`, 0x0 ; len = 43 (0x2b)

success_string:
    db `Successfully loaded mock kernel\r\n`, 0x0 ; len = 34 (0x22)
                                                            ; 0x2b + 0x22 == 0x4d

fail_string:
    db `Failed to load mock kernel\r\n`, 0x0

times (510 - ($ - $$)) db 0x0
dw 0xaa55
