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
sti

initing:
    mov ax, 0x2000
    mov es, ax

    xor dh, dh
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

; args:
;   ch -- ind of cylinder
;   dl -- disk id
;   es -- mem address dest.
; mutated:
;   ax, bx, cx, dh, es, bp
; return:
;   ch -- ind of read cylinder
; ! goes to panic if read failed (see read_sectors) !
read_cylinder:
    mov cl, 17
    mov ax, 2
    
    xor dh, dh
        
    .read_sector:
        xor ax, 0b10010
        xor cl, 0b10000 
        call read_sectors
        cmp ax, 16
        je .read_sector

    cmp dh, 0
    jne .read_cylinder_end
    inc dh 
    jmp .read_sector
    
    .read_cylinder_end:
        ret
    
; args:
;   ax -- amount of sectors to read
;   cx -- starting segment and cylinder (see int 13h)
;   dh -- head ([0; 1])
;   dl -- disk id
;   es -- mem address dest.
; mutated:
;   bx, es, bp
; return:
;   ax -- number of read sectors
; ! goes to panic if unable to read given sectors !
read_sectors:
    xor bp, bp
    push ax
    .attempt_loop:
        cmp bp, 4
        je .read_fail

        pop ax
        push ax
        mv ah, 0x2

        inc bp
        int 0x13
        jc .attempt_loop

    
    shl ax, 5
    mov bx, es
    add bx, ax
    mov es, bx
    
    pop ax
    ret
        
    .read_fail:
        mov bx, 0x4d
        mov dx, halt
        call end_of_boot


; args:
;   bx -- addr offset of string to print at end
;      0x0  -- unexpected
;      0x2b -- success
;      0x4d -- fail
;   dx -- addr to jump to
; mutated:
;   ax, bx
; return:
;   ! does not return, jumps to addr in dx !
end_of_boot:
    pop bx
    xor bx, bx
    xor ax, ax
    print_loop:
        mov al, [strings + bx]
        test al, al
        jz dx
        int 0x10
        inc bx
        jmp print_loop

halt:
    jmp halt

strings:
unexpected_string:
    db `An unexpected error occurred during boot\r\n`, 0x0 ; len = 43 (0x2b)

success_string:
    db `Successfully loaded mock kernel\r\n`, 0x0 ; len = 34 (0x22)
                                                            ; 0x2b + 0x22 == 0x4d
fail_string:
    db `Failed to load mock kernel\r\n`, 0x0

times (510 - ($ - $$)) db 0x0
dw 0xaa55
