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

# We'll explicitly include mainproc.c to avoid filtering issues
MAINPROC_SRC = $(SRC_DIR)/mainproc.c
MAINPROC_OBJ = $(BUILD_DIR)/mainproc.o

# We'll exclude main files from general sources and handle them separately
SRCS = $(filter-out $(SRC_DIR)/main%.c,$(wildcard $(SRC_DIR)/*.c))
# Filter out mainproc.c since we're handling it separately
SRCS := $(filter-out $(MAINPROC_SRC),$(SRCS))

# Main source files for different versions
MAIN1_SRC = $(SRC_DIR)/main.1.c

# Object files (common first)
COMMON_OBJS = $(COMMON_SRCS:$(SRC_DIR)/%.c=$(BUILD_DIR)/%.o)
OBJS = $(SRCS:$(SRC_DIR)/%.c=$(BUILD_DIR)/%.o)
ASM_OBJS = $(ASM_SRCS:$(SRC_DIR)/%.s=$(BUILD_DIR)/%.o)

# Main object files for different versions
MAIN1_OBJ = $(BUILD_DIR)/main1.o

# Include paths
INCLUDES = -I$(SRC_DIR) -I$(COMMON_DIR)

# Flags
CFLAGS = -mcpu=cortex-a7 -fpic -ffreestanding -O0 -Wall -Wextra -g3 -gdwarf-4 $(INCLUDES) -ffunction-sections -fdata-sections -fno-common -fno-stack-protector
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

.PHONY: all clean run1 debug1 gdb1 log1 ghidra run-trace run-analyze run-snapshot check-binary analyze-functions run-patch analyze-all

all: $(TARGET1) $(TARGET1_ELF)

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

# Build both kernel images - explicitly include mainproc.o
$(TARGET1): $(COMMON_OBJS) $(OBJS) $(ASM_OBJS) $(MAIN1_OBJ) $(MAINPROC_OBJ)
	@mkdir -p $(@D)
	$(CC) $(LDFLAGS) $^ -o $@

# Build both kernel ELF files - explicitly include mainproc.o
$(TARGET1_ELF): $(COMMON_OBJS) $(OBJS) $(ASM_OBJS) $(MAIN1_OBJ) $(MAINPROC_OBJ)
	@mkdir -p $(@D)
	$(CC) $(LDFLAGS) $^ -o $@

# # Create binary images from ELF files
# $(TARGET1): $(TARGET1_ELF)
# 	$(OBJCOPY) -O binary $< $@

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
	@echo "     - Extra qemu arguments: -M versatilepb -cpu cortex-a7 -nographic -serial mon:stdio -kernel /home/freddie/JohnOfPatmos/build/kernel1.img -d int,guest_errors,mmu -D /home/freddie/JohnOfPatmos/results/ghidra_debug.txt"
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

# Add these variables at the top
TRACE_LOG = $(RESULTS_DIR)/execution_trace.log
MEMORY_DUMP = $(RESULTS_DIR)/memory_dump.bin
ANALYSIS_SCRIPT = analysis.gdb

# Enhanced run with full tracing
run-trace: $(TARGET1)
	@mkdir -p $(RESULTS_DIR)
	@echo "Starting traced execution..."
	$(QEMU) -M versatilepb -cpu cortex-a7 -kernel $(TARGET1) -nographic \
		-serial mon:stdio \
		-d exec,cpu,in_asm,op,int,mmu,guest_errors \
		-D $(TRACE_LOG) \
		-singlestep 2>&1 | tee $(RESULTS_DIR)/console_output.log
	@echo "Trace saved to $(TRACE_LOG)"

# Run with GDB automation for analysis
run-analyze: $(TARGET1)
	@mkdir -p $(RESULTS_DIR)
	@echo "set pagination off" > $(ANALYSIS_SCRIPT)
	@echo "set logging file $(RESULTS_DIR)/gdb_analysis.log" >> $(ANALYSIS_SCRIPT)
	@echo "set logging on" >> $(ANALYSIS_SCRIPT)
	@echo "target remote :1234" >> $(ANALYSIS_SCRIPT)
	@echo "# Breakpoints for critical functions" >> $(ANALYSIS_SCRIPT)
	@echo "break decrypt_memory" >> $(ANALYSIS_SCRIPT)
	@echo "commands" >> $(ANALYSIS_SCRIPT)
	@echo "  silent" >> $(ANALYSIS_SCRIPT)
	@echo "  printf \"decrypt_memory entry: PC=%%x\\n\", \$$pc" >> $(ANALYSIS_SCRIPT)
	@echo "  x/10i \$$pc" >> $(ANALYSIS_SCRIPT)
	@echo "  continue" >> $(ANALYSIS_SCRIPT)
	@echo "end" >> $(ANALYSIS_SCRIPT)
	@echo "break _gcry_cipher_cfb_decrypt" >> $(ANALYSIS_SCRIPT)
	@echo "commands" >> $(ANALYSIS_SCRIPT)
	@echo "  silent" >> $(ANALYSIS_SCRIPT)
	@echo "  printf \"CFB decrypt entry: PC=%%x\\n\", \$$pc" >> $(ANALYSIS_SCRIPT)
	@echo "  x/10i \$$pc" >> $(ANALYSIS_SCRIPT)
	@echo "  continue" >> $(ANALYSIS_SCRIPT)
	@echo "end" >> $(ANALYSIS_SCRIPT)
	@echo "continue" >> $(ANALYSIS_SCRIPT)
	@echo "quit" >> $(ANALYSIS_SCRIPT)
	# Start QEMU in background
	$(QEMU) -M versatilepb -cpu cortex-a7 -kernel $(TARGET1) -nographic \
		-serial tcp::4444,server,nowait -s -S &
	sleep 2
	# Connect GDB and run analysis
	$(GDB) $(TARGET1) -batch -x $(ANALYSIS_SCRIPT)
	# Kill QEMU
	pkill -f "qemu-system-arm.*$(TARGET1)"

# Memory snapshot comparison
run-snapshot: $(TARGET1)
	@mkdir -p $(RESULTS_DIR)
	@echo "Running with memory snapshots..."
	# Create a GDB script for snapshots
	@echo "set pagination off" > snapshot.gdb
	@echo "target remote :1234" >> snapshot.gdb
	@echo "break unified_decrypt" >> snapshot.gdb
	@echo "commands" >> snapshot.gdb
	@echo "  silent" >> snapshot.gdb
	@echo "  if \$$decrypt_count == 0" >> snapshot.gdb
	@echo "    dump memory $(RESULTS_DIR)/memory_before.bin 0x8000 0x20000" >> snapshot.gdb
	@echo "    set \$$decrypt_count = 1" >> snapshot.gdb
	@echo "  else" >> snapshot.gdb
	@echo "    dump memory $(RESULTS_DIR)/memory_after.bin 0x8000 0x20000" >> snapshot.gdb
	@echo "  end" >> snapshot.gdb
	@echo "  continue" >> snapshot.gdb
	@echo "end" >> snapshot.gdb
	@echo "set \$$decrypt_count = 0" >> snapshot.gdb
	@echo "continue" >> snapshot.gdb
	# Run with snapshots
	$(QEMU) -M versatilepb -cpu cortex-a7 -kernel $(TARGET1) -nographic -s -S &
	sleep 2
	$(GDB) $(TARGET1) -batch -x snapshot.gdb || true
	pkill -f "qemu-system-arm.*$(TARGET1)"
	# Compare snapshots
	@if [ -f $(RESULTS_DIR)/memory_before.bin ] && [ -f $(RESULTS_DIR)/memory_after.bin ]; then \
		echo "Comparing memory snapshots..."; \
		hexdump -C $(RESULTS_DIR)/memory_before.bin > $(RESULTS_DIR)/before.hex; \
		hexdump -C $(RESULTS_DIR)/memory_after.bin > $(RESULTS_DIR)/after.hex; \
		diff -u $(RESULTS_DIR)/before.hex $(RESULTS_DIR)/after.hex > $(RESULTS_DIR)/memory_diff.txt || true; \
		echo "Memory differences saved to $(RESULTS_DIR)/memory_diff.txt"; \
	fi

# Binary integrity check
check-binary: $(TARGET1)
	@mkdir -p $(RESULTS_DIR)
	# Generate checksums of code sections
	$(CROSS_COMPILE)objdump -h $(TARGET1_ELF) | grep -E "\.text|\.rodata" > $(RESULTS_DIR)/sections.txt
	$(CROSS_COMPILE)objcopy --dump-section .text=$(RESULTS_DIR)/text_section.bin $(TARGET1_ELF) 2>/dev/null || true
	$(CROSS_COMPILE)objcopy --dump-section .rodata=$(RESULTS_DIR)/rodata_section.bin $(TARGET1_ELF) 2>/dev/null || true
	@echo "Binary sections extracted:"
	@ls -la $(RESULTS_DIR)/*.bin 2>/dev/null || echo "No sections found"
	# Calculate checksums
	@if [ -f $(RESULTS_DIR)/text_section.bin ]; then \
		md5sum $(RESULTS_DIR)/text_section.bin; \
		sha256sum $(RESULTS_DIR)/text_section.bin; \
	fi

# Function address analysis
analyze-functions: $(TARGET1_ELF)
	@mkdir -p $(RESULTS_DIR)
	@echo "Analyzing function addresses..."
	# Extract all function addresses
	$(CROSS_COMPILE)nm -n $(TARGET1_ELF) | grep " T " > $(RESULTS_DIR)/function_addresses.txt
	# Get specific crypto functions
	@echo "=== Critical Function Addresses ===" > $(RESULTS_DIR)/crypto_functions.txt
	@$(CROSS_COMPILE)nm $(TARGET1_ELF) | grep -E "decrypt_memory|_gcry_cipher|proc_encryption" >> $(RESULTS_DIR)/crypto_functions.txt || true
	# Disassemble critical functions
	@echo "=== Function Disassembly ===" > $(RESULTS_DIR)/function_disasm.txt
	@for func in decrypt_memory _gcry_cipher_cfb_decrypt proc_encryption_packets; do \
		echo "\\n=== $$func ===" >> $(RESULTS_DIR)/function_disasm.txt; \
		$(CROSS_COMPILE)objdump -d $(TARGET1_ELF) | sed -n "/^[0-9a-f]* <$$func>:/,/^$$/p" >> $(RESULTS_DIR)/function_disasm.txt || true; \
	done
	@cat $(RESULTS_DIR)/crypto_functions.txt

# Live monitoring with patching capability
run-patch: $(TARGET1)
	@mkdir -p $(RESULTS_DIR)
	@echo "Creating patch script..."
	@cat > patch.gdb <<EOF
	set pagination off
	set logging file $(RESULTS_DIR)/patch_log.txt
	set logging on
	
	# Connect to QEMU
	target remote :1234
	
	# Define patching function
	define patch_redirect
	    printf "Patching at %%x to redirect to %%x\\n", \$$arg0, \$$arg1
	    set *((unsigned int*)\$$arg0) = 0xEA000000 | (((\$$arg1 - \$$arg0 - 8) >> 2) & 0x00FFFFFF)
	end
	
	# Monitor critical functions
	set \$$first_decrypt_addr = 0
	set \$$first_cfb_addr = 0
	
	break decrypt_memory
	commands
	    silent
	    if \$$first_decrypt_addr == 0
	        set \$$first_decrypt_addr = \$$pc
	        printf "First decrypt_memory at: %%x\\n", \$$pc
	    else
	        if \$$pc != \$$first_decrypt_addr
	            printf "!!! decrypt_memory address changed! Was %%x, now %%x\\n", \$$first_decrypt_addr, \$$pc
	            printf "!!! Attempting to patch...\\n"
	            # Force correct entry
	            set \$$pc = \$$first_decrypt_addr
	        end
	    end
	    continue
	end
	
	break _gcry_cipher_cfb_decrypt
	commands
	    silent
	    if \$$first_cfb_addr == 0
	        set \$$first_cfb_addr = \$$pc
	        printf "First CFB decrypt at: %%x\\n", \$$pc
	    else
	        if \$$pc != \$$first_cfb_addr
	            printf "!!! CFB address changed! Was %%x, now %%x\\n", \$$first_cfb_addr, \$$pc
	            set \$$pc = \$$first_cfb_addr
	        end
	    end
	    continue
	end
	
	continue
	EOF
	# Run with patching
	$(QEMU) -M versatilepb -cpu cortex-a7 -kernel $(TARGET1) -nographic -s -S &
	sleep 2
	$(GDB) $(TARGET1) -x patch.gdb

# Combined analysis target
analyze-all: check-binary analyze-functions run-trace # run-snapshot
	@echo "=== ANALYSIS COMPLETE ==="
	@echo "Check the following files in $(RESULTS_DIR):"
	@echo "  - execution_trace.log: Full execution trace"
	@echo "  - memory_diff.txt: Memory changes between decryptions"
	@echo "  - crypto_functions.txt: Critical function addresses"
	@echo "  - function_disasm.txt: Disassembly of key functions"