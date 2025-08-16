BITS 16             
ORG 0x7C00          

%define ENDL 0x0D, 0x0A

;==================
; FAT12 Headers
;==================

jmp short pre_start
nop

bpb_oem:                    db "GRANITE "
bpb_bytes_per_sector:       dw 512
bpb_sectors_per_cluster:    db 1
bpb_reserved_sectors:       dw 1
bpb_fat_count:              db 2
bpb_dir_entries_count:      dw 224
bpb_logical_sectors:        dw 2880
bpb_media_descriptor_type:  db 0xF0
bpb_sectors_per_fat:        dw 9
bpb_sectors_per_track:      dw 18
bpb_heads:                  dw 2
bpb_hidden_sectors:         dd 0
bpb_large_sector_count:     dd 0

ebr_drive_number:           db 0
                            db 0
ebr_signature:              db 0x29
ebr_volume_id:              db 0x12, 0x34, 0x56, 0x78
ebr_volume_label:           db "GRANITE  OS"
ebr_system_id:              db "FAT12   "

pre_start:
    cli
    xor ax, ax
    mov es, ax
    mov ds, ax

    mov ss, ax
    mov sp, 0x7C00
    sti

    jmp $
    hlt
;===========================
; LBA to CHS
;===========================
lba_to_chs:
    push ax
    push dx

    xor dx, dx
    div word [bpb_sectors_per_track]

    inc dx
    mov cx, dx

    xor dx, dx
    div word [bpb_heads]

    mov dh, dl
    mov ch, al
    shl ah, 6
    or cl, ah

    pop ax
    mov dl, al
    pop ax
    ret


;===========================
; Disk Read Function
;===========================

disk_read:
    push ax
    push bx
    push cx
    push dx
    push di
    push cx

    call lba_to_chs

    pop ax
    mov ah, 0x02
    mov di, 3

.retry:
    pusha
    stc 
    int 0x13
    jnc .done

    popa
    call disk_reset

    dec di
    test di, di
    jnz .retry

.fail:
    jmp read_error

.done:
    popa
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

disk_reset:
    pusha
    mov ah, 0
    stc
    int 0x13
    jc read_error
    popa
    ret

;========================
; Error Handlers
;========================
read_error:
    mov si, msg_read_failed
    call print

keypress_and_reboot:
    mov si, msg_keypress_reboot
    call print
    mov ah, 0
    int 0x16
    jmp 0FFFFh:0

;========================
; Print 
;========================

print:
    pusha               ; Save all general-purpose registers
.next_char:
    lodsb               ; Load byte at DS:SI into AL, increment SI
    cmp al, 0
    je .done            ; If null terminator, done
    mov ah, 0x0E        ; BIOS teletype function
    int 0x10
    jmp .next_char
.done:
    popa
    ret

;=====================
; Messages
;=====================

motd: db "Welcome to Granite OS v1.0", ENDL, 0
msg_read_failed: db "Disk failed to read.", ENDL, ENDL, 0
msg_keypress_reboot: db "Please press any key to reboot.", ENDL,0

times 510 - ($ - $$) db 0  
dw 0xAA55                 

