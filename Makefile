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

# Source files (common first)
COMMON_SRCS = $(wildcard $(COMMON_DIR)/*.c)
ASM_SRCS = $(SRC_DIR)/start.s

# Debug the source files (uncomment to see what files are included)
# $(info All source files in SRC_DIR: $(wildcard $(SRC_DIR)/*.c))

# We'll explicitly include mainproc.c to avoid filtering issues
MAINPROC_SRC = $(SRC_DIR)/mainproc.c
MAINPROC_OBJ = $(BUILD_DIR)/mainproc.o

# We'll exclude main files from general sources and handle them separately
SRCS = $(filter-out $(SRC_DIR)/main%.c,$(wildcard $(SRC_DIR)/*.c))
# Filter out mainproc.c since we're handling it separately
SRCS := $(filter-out $(MAINPROC_SRC),$(SRCS))

# Debug the filtered source files (uncomment to verify)
# $(info Filtered source files: $(SRCS))

# Main source files for different versions
MAIN1_SRC = $(SRC_DIR)/main.1.c
MAIN2_SRC = $(SRC_DIR)/main.2.c

# Object files (common first)
COMMON_OBJS = $(COMMON_SRCS:$(SRC_DIR)/%.c=$(BUILD_DIR)/%.o)
OBJS = $(SRCS:$(SRC_DIR)/%.c=$(BUILD_DIR)/%.o)
ASM_OBJS = $(ASM_SRCS:$(SRC_DIR)/%.s=$(BUILD_DIR)/%.o)

# Main object files for different versions
MAIN1_OBJ = $(BUILD_DIR)/main1.o
MAIN2_OBJ = $(BUILD_DIR)/main2.o

# Include paths
INCLUDES = -I$(SRC_DIR) -I$(COMMON_DIR)

# Flags
CFLAGS = -mcpu=cortex-a7 -fpic -ffreestanding -O0 -Wall -Wextra -g3 -gdwarf-4 $(INCLUDES) -ffunction-sections -fdata-sections -fno-common          -fno-omit-frame-pointer -fno-inline

ASFLAGS = -mcpu=cortex-a7
LDFLAGS = -T $(SRC_DIR)/linker.ld -ffreestanding -O2 -nostdlib \
          -Wl,--gc-sections \
          -Wl,--sort-section=alignment \
          -Wl,--sort-common=descending \
          -Wl,--no-merge-exidx-entries

# Define targets for each version
TARGET1 = $(BUILD_DIR)/kernel1.img

# Define targets for each version
TARGET1_ELF = $(BUILD_DIR)/kernel1.elf

.PHONY: all clean run debug gdb log ghidra debug-info

all: $(TARGET1)

# Build common objects first
common: $(COMMON_OBJS)

# Build rules for common objects
$(BUILD_DIR)/common/%.o: $(SRC_DIR)/common/%.c
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) -c $< -o $@

# Build rules for main source files
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.s
	@mkdir -p $(@D)
	$(AS) $(ASFLAGS) $< -o $@

# Special rule for mainproc.c
$(MAINPROC_OBJ): $(MAINPROC_SRC)
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) -c $< -o $@

# Special rules for main1 and main2
$(MAIN1_OBJ): $(MAIN1_SRC)
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) -c $< -o $@

$(MAIN2_OBJ): $(MAIN2_SRC)
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) -c $< -o $@

# Build both kernel images - explicitly include mainproc.o
$(TARGET1): $(COMMON_OBJS) $(OBJS) $(ASM_OBJS) $(MAIN1_OBJ) $(MAINPROC_OBJ)
	@mkdir -p $(@D)
	$(CC) $(LDFLAGS) $^ -o $@

# Build both kernel ELF files - explicitly include mainproc.o
$(TARGET1_ELF): $(COMMON_OBJS) $(OBJS) $(ASM_OBJS) $(MAIN1_OBJ) $(MAINPROC_OBJ)
	@mkdir -p $(@D)
	$(CC) $(LDFLAGS) $^ -o $@

clean:
	rm -rf $(BUILD_DIR)

# Run targets for each version
run: $(TARGET1)
	$(QEMU) -M versatilepb -cpu cortex-a7 -kernel $(TARGET1) -nographic -serial mon:stdio

# Log targets for each version
log: $(TARGET1)
	@mkdir -p $(RESULTS_DIR)
	$(QEMU) -M versatilepb -cpu cortex-a7 -kernel $(TARGET1) -d int,guest_errors,mmu,in_asm -D $(RESULTS_DIR)/kernel1.in_asm.log -nographic -serial mon:stdio

# Debug targets for each version
debug: $(TARGET1)
	$(QEMU) -M versatilepb -cpu cortex-a7 -kernel $(TARGET1) -nographic -serial mon:stdio -s -S

gdb:
	gdb-multiarch $(TARGET1) -x script.gdb

# Generate memory map for analysis
mapmem: $(TARGET1_ELF)
	@mkdir -p $(RESULTS_DIR)
	$(CROSS_COMPILE)nm -n $(TARGET1_ELF) > $(RESULTS_DIR)/kernel1.map
	$(CROSS_COMPILE)readelf -S $(TARGET1_ELF) > $(RESULTS_DIR)/kernel1.sections
	@echo "Memory maps generated in $(RESULTS_DIR)"

# # Useful commands
# # pkill qemu-system-arm
# # (gdb) break main.c:10 # Break at line 10
# Add these variables to your flags section
ASM_CFLAGS = $(CFLAGS) -S -fverbose-asm

# Ghidra debugging target - builds kernel1 and generates analysis files
ghidra: $(TARGET1) $(TARGET1_ELF)
	@mkdir -p $(RESULTS_DIR)
	@echo "====== PREPARING KERNEL1 FOR GHIDRA DEBUGGING ======"
	
	# Generate symbol information and analysis files
	@echo "Generating symbol tables and analysis files..."
	$(CROSS_COMPILE)nm -n $(TARGET1_ELF) > $(RESULTS_DIR)/kernel1_symbols.txt
	$(CROSS_COMPILE)objdump -t $(TARGET1_ELF) > $(RESULTS_DIR)/kernel1_symbol_table.txt
	$(CROSS_COMPILE)readelf -a $(TARGET1_ELF) > $(RESULTS_DIR)/kernel1_elf_info.txt
	$(CROSS_COMPILE)objdump -D $(TARGET1_ELF) > $(RESULTS_DIR)/kernel1_full_disasm.txt
	
	@echo ""
	@echo "====== FILES READY FOR GHIDRA ======"
	@echo "  Kernel Binary: $(TARGET1)"
	@echo "  Kernel ELF:    $(TARGET1_ELF) (import this for best symbol support)"
	@echo "  Symbols:       $(RESULTS_DIR)/kernel1_symbols.txt"
	@echo "  Disassembly:   $(RESULTS_DIR)/kernel1_full_disasm.txt"
	@echo ""
	@echo "🔧 GHIDRA SETUP STEPS:"
	@echo "  1. Import: $(TARGET1_ELF) into Ghidra (analyze when prompted)"
	@echo "  2. Debugger → Launch kernel1.elf using → qemu-system + gdb"
	@echo "  3. Configuration:"
	@echo "     - Image: $(TARGET1)"
	@echo "     - QEMU command: qemu-system-arm"
	@echo "     - Extra qemu arguments: -M versatilepb -cpu cortex-a7 -nographic -serial mon:stdio -kernel /home/freddie/JohnOfPatmos/build/kernel1.img symbol-file $(TARGET1_ELF)"
	@echo "     - gdb command: gdb-multiarch"
	@echo "     - Architecture: arm (not auto)"
	@echo "     - Port: 1234"
	@echo "  4. Click Launch"
	@echo ""
	@echo "📋 IN GDB CONSOLE (for symbols):"
	@echo "  symbol-file $(TARGET1_ELF)"
	@echo "  # Or use addresses from $(RESULTS_DIR)/kernel1_symbols.txt:"
	@echo "  break *0x800c    # main function"
	@echo "  continue"
	
# Generate comprehensive debug information for Ghidra and GDB
debug-info: $(TARGET1_ELF)
	@mkdir -p $(RESULTS_DIR)/debug
	@echo "====== GENERATING DEBUG INFORMATION ======"
	
	# Generate DWARF debug info dump
	$(CROSS_COMPILE)objdump --dwarf=info $(TARGET1_ELF) > $(RESULTS_DIR)/debug/dwarf_info.txt
	$(CROSS_COMPILE)objdump --dwarf=line $(TARGET1_ELF) > $(RESULTS_DIR)/debug/dwarf_line.txt
	
	# Generate source-to-assembly mapping
	$(CROSS_COMPILE)objdump -S -d $(TARGET1_ELF) > $(RESULTS_DIR)/debug/source_interleaved.txt
	
	# Generate memory map with sizes
	$(CROSS_COMPILE)size -A $(TARGET1_ELF) > $(RESULTS_DIR)/debug/section_sizes.txt
	
	# Generate function addresses
	$(CROSS_COMPILE)nm -S -n $(TARGET1_ELF) | grep -E ' [TtWw] ' > $(RESULTS_DIR)/debug/functions.txt
	
	# Generate global variable addresses
	$(CROSS_COMPILE)nm -S -n $(TARGET1_ELF) | grep -E ' [BbDdGg] ' > $(RESULTS_DIR)/debug/globals.txt
	
	# Generate GDB script with automatic loading from important_*.txt files
	@echo "====== GENERATING ADVANCED GDB MONITORING SCRIPT ======"
	@if [ -f scripts/important_functions.txt ] || [ -f scripts/important_globals.txt ]; then \
		python3 scripts/generate_gdb_script.py \
			-d $(RESULTS_DIR)/debug \
			-o $(RESULTS_DIR)/debug/monitor.gdb \
			--script-dir scripts \
			--max-watchpoints 8; \
		echo ""; \
		echo "Advanced monitoring script generated: $(RESULTS_DIR)/debug/monitor.gdb"; \
		echo ""; \
		echo "To use the monitoring script:"; \
		echo "  1. Start GDB: gdb $(TARGET1_ELF)"; \
		echo "  2. Load script: source $(RESULTS_DIR)/debug/monitor.gdb"; \
		echo "  3. Run program: run"; \
		echo ""; \
		echo "Monitor commands:"; \
		echo "  - debug-status     : Show monitoring overview"; \
		echo "  - show-monitored   : Display current values"; \
		echo "  - show-history     : View change history"; \
		echo "  - verify-functions : Check function integrity"; \
		echo ""; \
		echo "NOTE: If you get type errors, regenerate the script:"; \
		echo "      make clean && make debug-info"; \
	else \
		echo "WARNING: No important_functions.txt or important_globals.txt found in scripts/"; \
		echo "         Create these files to enable targeted monitoring"; \
	fi
	
	@echo ""
	@echo "Debug info generated in $(RESULTS_DIR)/debug/"