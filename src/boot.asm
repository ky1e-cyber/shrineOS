[BITS 16]

cli
mov ax, 0x7c0
mov ds, ax
mov ss, ax
mov sp, 0x0
mov ax, 0x200
mov es, ax
sti




; assuming: 
;   ES mutated only here
; VOLATILE registers:
;   BP, BX, AX
read_disk:
    ; assuming
    ;   DH (head) is set
    ;   DL (disk id) is set
    ;   CX is set
    ;   ES (will be mutated) is set
    ; top of stack -- amount of sectors to read
    ; BP -- counter for attempts

    ; mov bx, es
    ; cmp bx, 0x800
    ; jz boot_success

    xor bx, bx
    xor bp, bp
    read_sector_attempt:
        cmp bp, 0x4
        jz boot_fail
        pop ax
        push ax ; very bruh
        mov ah, 0x2
        inc bp
        int 0x13
        jc read_sector_attempt
    xor ah, ah
    shl ax, 0x1
    mov bx, es
    add bx, ax
    mov es, bx

    jmp read_disk

; if we somehow got here, 
; unexpected error message will be shown (unexpected_string + 0)
xor bx, bx
end_of_boot:
    print_loop:
        mov al, [unexpected_string + bx]
        test al, al
        jz endless
        int 0x10
        inc bx
        jmp print_loop

boot_success:
    mov bx, 0x2b
    jmp end_of_boot

boot_fail:
    mov bx, 0x4d
    jmp end_of_boot

endless:
    jmp endless

unexpected_string:
    db `An unexpected error occurred during boot\r\n`, 0x0  ; len = 43 (0x2b)

success_string:
    db `Successfully loaded mock kernel\r\n`, 0x0           ; len = 34 (0x22)
                                                            ; 0x2b + 0x22 == 0x4d

fail_string:
    db `Failed to load mock kernel\r\n`, 0x0

times (510 - ($ - $$)) db 0x0
dw 0xaa55