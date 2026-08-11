TARGET := kernel

CC := arm-none-eabi-gcc
AS := arm-none-eabi-as
LD := arm-none-eabi-ld
OBJCOPY := arm-none-eabi-objcopy

CFLAGS := -mcpu=cortex-m3 -mthumb -ffreestanding -nostdlib -Wall -Wextra -g
ASFLAGS := -mcpu=cortex-m3 -mthumb -g

OBJS := \
	build/boot.o \
	build/memory.o \
	build/state.o \
	build/kernel.o \
	build/handlers.o

all: build/$(TARGET).elf

build:
	mkdir -p build

build/boot.o: kernel/boot.s | build
	$(AS) $(ASFLAGS) $< -o $@

build/memory.o: kernel/memory.s | build
	$(AS) $(ASFLAGS) $< -o $@

build/state.o: kernel/state.s | build
	$(AS) $(ASFLAGS) $< -o $@

build/kernel.o: kernel/kernel.s | build
	$(AS) $(ASFLAGS) $< -o $@

build/handlers.o: kernel/handlers.c | build
	$(CC) $(CFLAGS) -c $< -o $@

build/$(TARGET).elf: $(OBJS)
	$(LD) -T linker.ld $(OBJS) -o $@

run: build/$(TARGET).elf
	qemu-system-arm \
		-M mps2-an385 \
		-kernel build/$(TARGET).elf \
		-nographic

debug: build/$(TARGET).elf
	qemu-system-arm \
		-M mps2-an385 \
		-kernel build/$(TARGET).elf \
		-nographic \
		-S \
		-gdb tcp::1234

clean:
	rm -rf build