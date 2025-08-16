BUILD_DIR=build
SRC_DIR=src
ASM=nasm

CC=i686-elf-gcc
LD=i686-elf-ld 


all: clean build_obj floppy_image build_floppy

clean:
	rm -rf $(BUILD_DIR)/*

qemu:
	qemu-system-i386 -fda $(BUILD_DIR)/floppy.img

debug:
	qemu-system-i386 -s -S -fda $(BUILD_DIR)/floppy.img

build_obj: 
	@for file in $(SRC_DIR)/*.asm; do \
		filename=$$(basename $$file .asm); \
		$(ASM) -f bin $$file -o $(BUILD_DIR)/$$filename.bin; \
	done

build_floppy:
	mcopy -i $(BUILD_DIR)/floppy.img $(BUILD_DIR)/kernel.bin ::KERNEL.BIN
	dd if=$(BUILD_DIR)/boot.bin of=$(BUILD_DIR)/floppy.img conv=notrunc


floppy_image: 
	dd if=/dev/zero of=$(BUILD_DIR)/floppy.img bs=512 count=2880
	mkfs.fat -F 12 -n "SINO" $(BUILD_DIR)/floppy.img

gdb:
	@gdb -ex "target remote localhost:1234"\
		-ex "layout asm" \
		-ex "layout regs" \
		-ex "br *0x7c00"
boot:
	$(ASM) -f bin $(SRC_DIR)/boot.asm -o $(BUILD_DIR)/bootloader.bin

