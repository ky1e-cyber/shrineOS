[BITS 16]

cli
mov ax, 0x7c0
mov ds, ax
mov ss, ax
mov sp, 0x0
sti


; 
read_disk:



unexpected_error:
    xor bx, bx
    print_loop:
        
        
endless:
    jmp endless

success_string:
    db `Successfully loaded mock kernel\r\n`, 0x0

fail_string:
    db `Failed to load mock kernel\r\n`, 0x0

unexpected_string:
    db `An unexpected error occurred during boot\r\n`, 0x0

times (510 - ($ - $$)) db 0x0
dw 0xaa55