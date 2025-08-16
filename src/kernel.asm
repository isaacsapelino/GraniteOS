[BITS 16]
[ORG 0x0000]     ; Load address used by bootloader (e.g., 0x1000:0000 = 0x10000)

start:
    mov si, msg
print_loop:
    lodsb
    cmp al, 0
    je done
    mov ah, 0x0E
    int 0x10
    jmp print_loop

done:
    jmp $


;======================
; Screen Function
;======================

clear_screen:
    mov ax, 0x0600       ; AH = 0x06 (scroll up), AL = 0 (clear)
    mov bh, 0x07         ; Attribute (light gray on black)
    mov cx, 0x0000       ; Upper left corner (row=0, col=0)
    mov dx, 0x184F       ; Lower right corner (row=24, col=79)
    int 0x10
.reset_cursor:
    mov ah, 0x02
    mov bh, 0x00        ; Page number
    mov dh, 0x00        ; Row
    mov dl, 0x00        ; Column
    int 0x10
    ret

msg db "KERNEL.BIN loaded successfully!", 0