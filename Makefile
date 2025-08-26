# Compiler and emulator
CROSS_COMPILE ?= arm-none-eabi-
CC = $(CROSS_COMPILE)gcc
AS = $(CROSS_COMPILE)as
LD = $(CROSS_COMPILE)ld
OBJCOPY = $(CROSS_COMPILE)objcopy
QEMU = qemu-system-arm
GDB = gdb-multiarch

# Directories
SRC_DIR = src
COMMON_DIR = $(SRC_DIR)/common
BUILD_DIR = build
RESULTS_DIR = results
BUILD_COMMON_DIR = $(BUILD_DIR)/common
ASM_OUTPUT_DIR = $(BUILD_DIR)/asm_output

# Create separate build directories for each kernel
BUILD_DIR1 = $(BUILD_DIR)/kernel1
BUILD_DIR2 = $(BUILD_DIR)/kernel2

# Source files (common first)
COMMON_SRCS = $(wildcard $(COMMON_DIR)/*.c)
ASM_SRCS = $(SRC_DIR)/start.s

# Main proc source
MAINPROC_SRC = $(SRC_DIR)/mainproc.c

# Filter out main files from general sources and handle them separately
SRCS = $(filter-out $(SRC_DIR)/main%.c,$(wildcard $(SRC_DIR)/*.c))
SRCS := $(filter-out $(MAINPROC_SRC),$(SRCS))

# Main source file
MAIN_SRC = $(SRC_DIR)/main.c

# Object files for kernel1 (SUCCESS=1)
COMMON_OBJS1 = $(COMMON_SRCS:$(SRC_DIR)/%.c=$(BUILD_DIR1)/%.o)
OBJS1 = $(SRCS:$(SRC_DIR)/%.c=$(BUILD_DIR1)/%.o)
ASM_OBJS1 = $(ASM_SRCS:$(SRC_DIR)/%.s=$(BUILD_DIR1)/%.o)
MAIN_OBJ1 = $(BUILD_DIR1)/main.o
MAINPROC_OBJ1 = $(BUILD_DIR1)/mainproc.o

# Object files for kernel2 (SUCCESS=0)
COMMON_OBJS2 = $(COMMON_SRCS:$(SRC_DIR)/%.c=$(BUILD_DIR2)/%.o)
OBJS2 = $(SRCS:$(SRC_DIR)/%.c=$(BUILD_DIR2)/%.o)
ASM_OBJS2 = $(ASM_SRCS:$(SRC_DIR)/%.s=$(BUILD_DIR2)/%.o)
MAIN_OBJ2 = $(BUILD_DIR2)/main.o
MAINPROC_OBJ2 = $(BUILD_DIR2)/mainproc.o

# Include paths
INCLUDES = -I$(SRC_DIR) -I$(COMMON_DIR)

# Base flags
BASE_CFLAGS = -mcpu=cortex-a7 -fpic -ffreestanding -O0 -Wall -Wextra -g -gdwarf-4 $(INCLUDES) \
              -ffunction-sections -fdata-sections -fno-common \
              -fno-omit-frame-pointer -fno-inline

# Flags for each kernel
CFLAGS1 = $(BASE_CFLAGS) -DSUCCESS=1
CFLAGS2 = $(BASE_CFLAGS)

ASFLAGS = -mcpu=cortex-a7
LDFLAGS = -T $(SRC_DIR)/linker.ld -ffreestanding -O2 -nostdlib \
          -Wl,--gc-sections \
          -Wl,--sort-section=alignment \
          -Wl,--sort-common=descending \
          -Wl,--no-merge-exidx-entries \
          -Wl,--build-id

# Define targets for each version
TARGET1 = $(BUILD_DIR)/kernel1.img
TARGET2 = $(BUILD_DIR)/kernel2.img
TARGET1_ELF = $(BUILD_DIR)/kernel1.elf
TARGET2_ELF = $(BUILD_DIR)/kernel2.elf

.PHONY: all clean run1 run2 debug1 debug2 gdb log1 log2 ghidra debug-info

# Build both kernels by default
all: $(TARGET1) $(TARGET2)

# Build only kernel1
kernel1: $(TARGET1)

# Build only kernel2
kernel2: $(TARGET2)

# ==================== Build rules for kernel1 (SUCCESS=1) ====================

# Common objects for kernel1
$(BUILD_DIR1)/common/%.o: $(SRC_DIR)/common/%.c
	@mkdir -p $(@D)
	@echo "[K1-COMMON] Compiling $<"
	$(CC) $(CFLAGS1) -c $< -o $@

# Regular source objects for kernel1
$(BUILD_DIR1)/%.o: $(SRC_DIR)/%.c
	@mkdir -p $(@D)
	@echo "[K1] Compiling $<"
	$(CC) $(CFLAGS1) -c $< -o $@

# Assembly objects for kernel1
$(BUILD_DIR1)/%.o: $(SRC_DIR)/%.s
	@mkdir -p $(@D)
	@echo "[K1-ASM] Assembling $<"
	$(AS) $(ASFLAGS) $< -o $@

# Main object for kernel1
$(MAIN_OBJ1): $(MAIN_SRC)
	@mkdir -p $(@D)
	@echo "[K1-MAIN] Compiling $< with SUCCESS=1"
	$(CC) $(CFLAGS1) -c $< -o $@

# Mainproc object for kernel1
$(MAINPROC_OBJ1): $(MAINPROC_SRC)
	@mkdir -p $(@D)
	@echo "[K1-PROC] Compiling $<"
	$(CC) $(CFLAGS1) -c $< -o $@

# Link kernel1
$(TARGET1): $(COMMON_OBJS1) $(OBJS1) $(ASM_OBJS1) $(MAIN_OBJ1) $(MAINPROC_OBJ1)
	@mkdir -p $(@D)
	@echo "[K1-LINK] Linking kernel1.img"
	$(CC) $(LDFLAGS) $^ -o $@
	@echo "[K1] SUCCESS: kernel1.img built with SUCCESS=1"

# ELF for kernel1
$(TARGET1_ELF): $(COMMON_OBJS1) $(OBJS1) $(ASM_OBJS1) $(MAIN_OBJ1) $(MAINPROC_OBJ1)
	@mkdir -p $(@D)
	$(CC) $(LDFLAGS) $^ -o $@

# ==================== Build rules for kernel2 (SUCCESS=0) ====================

# Common objects for kernel2
$(BUILD_DIR2)/common/%.o: $(SRC_DIR)/common/%.c
	@mkdir -p $(@D)
	@echo "[K2-COMMON] Compiling $<"
	$(CC) $(CFLAGS2) -c $< -o $@

# Regular source objects for kernel2
$(BUILD_DIR2)/%.o: $(SRC_DIR)/%.c
	@mkdir -p $(@D)
	@echo "[K2] Compiling $<"
	$(CC) $(CFLAGS2) -c $< -o $@

# Assembly objects for kernel2
$(BUILD_DIR2)/%.o: $(SRC_DIR)/%.s
	@mkdir -p $(@D)
	@echo "[K2-ASM] Assembling $<"
	$(AS) $(ASFLAGS) $< -o $@

# Main object for kernel2
$(MAIN_OBJ2): $(MAIN_SRC)
	@mkdir -p $(@D)
	@echo "[K2-MAIN] Compiling $< with SUCCESS=0"
	$(CC) $(CFLAGS2) -c $< -o $@

# Mainproc object for kernel2
$(MAINPROC_OBJ2): $(MAINPROC_SRC)
	@mkdir -p $(@D)
	@echo "[K2-PROC] Compiling $<"
	$(CC) $(CFLAGS2) -c $< -o $@

# Link kernel2
$(TARGET2): $(COMMON_OBJS2) $(OBJS2) $(ASM_OBJS2) $(MAIN_OBJ2) $(MAINPROC_OBJ2)
	@mkdir -p $(@D)
	@echo "[K2-LINK] Linking kernel2.img"
	$(CC) $(LDFLAGS) $^ -o $@
	@echo "[K2] SUCCESS: kernel2.img built with SUCCESS=0"

# ELF for kernel2
$(TARGET2_ELF): $(COMMON_OBJS2) $(OBJS2) $(ASM_OBJS2) $(MAIN_OBJ2) $(MAINPROC_OBJ2)
	@mkdir -p $(@D)
	$(CC) $(LDFLAGS) $^ -o $@

# ==================== Clean ====================
clean:
	rm -rf $(BUILD_DIR)

# ==================== Run targets ====================
run1: $(TARGET1)
	@echo "Running kernel1 (with passwordpassword...gpg.h)"
	$(QEMU) -M versatilepb -cpu cortex-a7 -kernel $(TARGET1) -nographic -serial mon:stdio

run2: $(TARGET2)
	@echo "Running kernel2 (with 7379ab50...gpg.h)"
	$(QEMU) -M versatilepb -cpu cortex-a7 -kernel $(TARGET2) -nographic -serial mon:stdio

# Run both kernels in sequence
run-both: $(TARGET1) $(TARGET2)
	@echo "====== Running kernel1 (SUCCESS=1) ======"
	$(QEMU) -M versatilepb -cpu cortex-a7 -kernel $(TARGET1) -nographic -serial mon:stdio
	@echo ""
	@echo "====== Running kernel2 (SUCCESS=0) ======"
	$(QEMU) -M versatilepb -cpu cortex-a7 -kernel $(TARGET2) -nographic -serial mon:stdio

# ==================== Log targets ====================
log1: $(TARGET1)
	@mkdir -p $(RESULTS_DIR)
	$(QEMU) -M versatilepb -cpu cortex-a7 -kernel $(TARGET1) -d int,guest_errors,mmu,in_asm -D $(RESULTS_DIR)/kernel1.in_asm.log -nographic -serial mon:stdio

log2: $(TARGET2)
	@mkdir -p $(RESULTS_DIR)
	$(QEMU) -M versatilepb -cpu cortex-a7 -kernel $(TARGET2) -d int,guest_errors,mmu,in_asm -D $(RESULTS_DIR)/kernel2.in_asm.log -nographic -serial mon:stdio

# ==================== Memory maps ====================
mapmem1: $(TARGET1_ELF)
	@mkdir -p $(RESULTS_DIR)
	$(CROSS_COMPILE)nm -n $(TARGET1_ELF) > $(RESULTS_DIR)/kernel1.map
	$(CROSS_COMPILE)readelf -S $(TARGET1_ELF) > $(RESULTS_DIR)/kernel1.sections
	@echo "Memory maps for kernel1 generated in $(RESULTS_DIR)"

mapmem2: $(TARGET2_ELF)
	@mkdir -p $(RESULTS_DIR)
	$(CROSS_COMPILE)nm -n $(TARGET2_ELF) > $(RESULTS_DIR)/kernel2.map
	$(CROSS_COMPILE)readelf -S $(TARGET2_ELF) > $(RESULTS_DIR)/kernel2.sections
	@echo "Memory maps for kernel2 generated in $(RESULTS_DIR)"

mapmem: mapmem1 mapmem2

# ==================== Debug targets ====================
debug1: $(TARGET1_ELF)
	@echo "======================================"
	@echo "Starting QEMU in debug mode for kernel1..."
	@echo "Waiting for GDB connection on port 1234"
	@echo "======================================"
	@echo "In another terminal, run: make gdb1"
	@echo "======================================"
	$(QEMU) -M versatilepb -cpu cortex-a7 -kernel $(TARGET1_ELF) -nographic -serial mon:stdio -s -S

debug2: $(TARGET2_ELF)
	@echo "======================================"
	@echo "Starting QEMU in debug mode for kernel2..."
	@echo "Waiting for GDB connection on port 1234"
	@echo "======================================"
	@echo "In another terminal, run: make gdb2"
	@echo "======================================"
	$(QEMU) -M versatilepb -cpu cortex-a7 -kernel $(TARGET2_ELF) -nographic -serial mon:stdio -s -S

gdb1: 
	@echo "Connecting to QEMU for kernel1..."
	gdb-multiarch $(TARGET1_ELF) \
		-ex "target remote localhost:1234" \
		-ex "set confirm off" \
		-ex "handle SIGSEGV nostop noprint pass"

gdb2: 
	@echo "Connecting to QEMU for kernel2..."
	gdb-multiarch $(TARGET2_ELF) \
		-ex "target remote localhost:1234" \
		-ex "set confirm off" \
		-ex "handle SIGSEGV nostop noprint pass"

# ==================== Ghidra support ====================
ghidra1: $(TARGET1) $(TARGET1_ELF)
	@mkdir -p $(RESULTS_DIR)
	@echo "====== PREPARING KERNEL1 FOR GHIDRA DEBUGGING ======"
	$(CROSS_COMPILE)nm -n $(TARGET1_ELF) > $(RESULTS_DIR)/kernel1_symbols.txt
	$(CROSS_COMPILE)objdump -t $(TARGET1_ELF) > $(RESULTS_DIR)/kernel1_symbol_table.txt
	$(CROSS_COMPILE)readelf -a $(TARGET1_ELF) > $(RESULTS_DIR)/kernel1_elf_info.txt
	$(CROSS_COMPILE)objdump -D $(TARGET1_ELF) > $(RESULTS_DIR)/kernel1_full_disasm.txt
	@echo "Files ready for Ghidra in $(RESULTS_DIR)/"
	@echo "Import $(TARGET1_ELF) into Ghidra for best symbol support"

ghidra2: $(TARGET2) $(TARGET2_ELF)
	@mkdir -p $(RESULTS_DIR)
	@echo "====== PREPARING KERNEL2 FOR GHIDRA DEBUGGING ======"
	$(CROSS_COMPILE)nm -n $(TARGET2_ELF) > $(RESULTS_DIR)/kernel2_symbols.txt
	$(CROSS_COMPILE)objdump -t $(TARGET2_ELF) > $(RESULTS_DIR)/kernel2_symbol_table.txt
	$(CROSS_COMPILE)readelf -a $(TARGET2_ELF) > $(RESULTS_DIR)/kernel2_elf_info.txt
	$(CROSS_COMPILE)objdump -D $(TARGET2_ELF) > $(RESULTS_DIR)/kernel2_full_disasm.txt
	@echo "Files ready for Ghidra in $(RESULTS_DIR)/"
	@echo "Import $(TARGET2_ELF) into Ghidra for best symbol support"

ghidra: ghidra1 ghidra2

# ==================== Patching support ====================
# After building both kernels, you can use your patcher
patch: $(TARGET1) $(TARGET2)
	@echo "====== KERNELS READY FOR PATCHING ======"
	@echo "kernel1.img (SUCCESS=1): $(TARGET1)"
	@echo "kernel2.img (SUCCESS=0): $(TARGET2)"
	@echo ""
	@echo "You can now use your auto_offset_kernel_patcher.py:"
	@echo "python3 auto_offset_kernel_patcher.py $(TARGET1) patched_kernel1.img new.gpg original.gpg"
	@echo "python3 auto_offset_kernel_patcher.py $(TARGET2) patched_kernel2.img new.gpg original.gpg"

# ==================== Comparison tools ====================
compare: $(TARGET1) $(TARGET2)
	@echo "====== BINARY COMPARISON ======"
	@echo "Size of kernel1: $$(stat -c%s $(TARGET1)) bytes"
	@echo "Size of kernel2: $$(stat -c%s $(TARGET2)) bytes"
	@echo ""
	@echo "Hexdump differences (first 100 bytes that differ):"
	@cmp -l $(TARGET1) $(TARGET2) | head -100 || true
	@echo ""
	@echo "For detailed comparison, use:"
	@echo "  hexdiff $(TARGET1) $(TARGET2)"
	@echo "  vbindiff $(TARGET1) $(TARGET2)"

# ==================== Diagnostic target ====================
check:
	@echo "====== BUILD DIAGNOSTICS ======"
	@echo "Source files:"
	@echo "  COMMON_SRCS: $(COMMON_SRCS)"
	@echo "  SRCS: $(SRCS)"
	@echo "  MAINPROC_SRC: $(MAINPROC_SRC)"
	@echo "  MAIN_SRC: $(MAIN_SRC)"
	@echo ""
	@echo "Kernel1 objects:"
	@echo "  COMMON_OBJS1: $(COMMON_OBJS1)"
	@echo "  OBJS1: $(OBJS1)"
	@echo "  MAIN_OBJ1: $(MAIN_OBJ1)"
	@echo "  MAINPROC_OBJ1: $(MAINPROC_OBJ1)"
	@echo ""
	@echo "Kernel2 objects:"
	@echo "  COMMON_OBJS2: $(COMMON_OBJS2)"
	@echo "  OBJS2: $(OBJS2)"
	@echo "  MAIN_OBJ2: $(MAIN_OBJ2)"
	@echo "  MAINPROC_OBJ2: $(MAINPROC_OBJ2)"
	@echo ""
	@echo "Build flags:"
	@echo "  CFLAGS1: $(CFLAGS1)"
	@echo "  CFLAGS2: $(CFLAGS2)"
	@echo ""
	@echo "Targets:"
	@echo "  TARGET1: $(TARGET1)"
	@echo "  TARGET2: $(TARGET2)"

# ==================== Help target ====================
help:
	@echo "Makefile for building two kernel variants with different GPG headers"
	@echo ""
	@echo "Build targets:"
	@echo "  make all      - Build both kernel1 and kernel2"
	@echo "  make kernel1  - Build only kernel1 (SUCCESS=1)"
	@echo "  make kernel2  - Build only kernel2 (SUCCESS=0)"
	@echo "  make clean    - Remove all build artifacts"
	@echo ""
	@echo "Run targets:"
	@echo "  make run1     - Run kernel1 in QEMU"
	@echo "  make run2     - Run kernel2 in QEMU"
	@echo "  make run-both - Run both kernels in sequence"
	@echo ""
	@echo "Debug targets:"
	@echo "  make debug1   - Start QEMU in debug mode for kernel1"
	@echo "  make debug2   - Start QEMU in debug mode for kernel2"
	@echo "  make gdb1     - Connect GDB to kernel1"
	@echo "  make gdb2     - Connect GDB to kernel2"
	@echo ""
	@echo "Analysis targets:"
	@echo "  make mapmem   - Generate memory maps for both kernels"
	@echo "  make ghidra   - Prepare both kernels for Ghidra analysis"
	@echo "  make compare  - Compare the two kernel binaries"
	@echo "  make patch    - Show patching commands for both kernels"