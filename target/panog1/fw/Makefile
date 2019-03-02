BIN2MIF:= ../../../tools/bin2mif/bin2mif

all: picorv_fw.mif

picorv_fw.elf: sections.lds start.s firmware.c
	riscv32-unknown-elf-gcc -march=rv32i -O1 -Wl,-Bstatic,-T,sections.lds,-Map=picorv_fw.map,--strip-debug -ffreestanding -nostdlib -o picorv_fw.elf start.s firmware.c
	size picorv_fw.elf

picorv_fw.bin: picorv_fw.elf
	riscv32-unknown-elf-objcopy -O binary picorv_fw.elf picorv_fw.bin

picorv_fw.mif: picorv_fw.bin
	$(BIN2MIF) picorv_fw.bin picorv_fw.mif 4096 32
	$(BIN2MIF) picorv_fw.bin picorv_fw_0.mif 1024 8 0 3
	$(BIN2MIF) picorv_fw.bin picorv_fw_1.mif 1024 8 1 3
	$(BIN2MIF) picorv_fw.bin picorv_fw_2.mif 1024 8 2 3
	$(BIN2MIF) picorv_fw.bin picorv_fw_3.mif 1024 8 3 3

.PHONY: clean
clean:
	rm -f picorv_fw.elf picorv_fw.hex picorv_fw.bin picorv_fw*.mif
