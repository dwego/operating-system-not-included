TARGET := build/os.elf

AS := arm-none-eabi-as
LD := arm-none-eabi-ld

ASFLAGS := -mcpu=cortex-m3 -mthumb -g
LDFLAGS := -T kernel/linker.ld

OBJECTS := \
	build/boot.o \
	build/handlers.o \
	build/kernel.o

all: $(TARGET)

$(TARGET): $(OBJECTS) kernel/linker.ld
	$(LD) $(LDFLAGS) $(OBJECTS) -o $@

build/boot.o: kernel/boot.s
	@mkdir -p build
	$(AS) $(ASFLAGS) $< -o $@

build/handlers.o: kernel/handlers.s
	@mkdir -p build
	$(AS) $(ASFLAGS) $< -o $@

build/kernel.o: kernel/kernel.s
	@mkdir -p build
	$(AS) $(ASFLAGS) $< -o $@

run: all
	qemu-system-arm \
		-machine mps2-an385 \
		-cpu cortex-m3 \
		-kernel $(TARGET)

debug: all
	qemu-system-arm \
		-machine mps2-an385 \
		-cpu cortex-m3 \
		-kernel $(TARGET) \
		-S \
		-s

clean:
	rm -rf build

.PHONY: all run debug clean