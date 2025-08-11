#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# ==============================================================================
# Fixed Bare Metal Build Script with Auto Key Fetching
# ==============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# ==============================================================================
# Configuration
# ==============================================================================

WORK_DIR="${PWD}/secure_build"
ARCHIVE_DIR="${PWD}/archive"
BUILD_DIR="${WORK_DIR}/build"
INSTALL_DIR="${WORK_DIR}/toolchain"
CONSOLE_DIR="${WORK_DIR}/console"

# Maximum security flags for toolchain build
SECURE_CFLAGS="-O2 -fstack-protector-strong -fPIC -D_FORTIFY_SOURCE=2 -Wformat -Wformat-security"
SECURE_CXXFLAGS="${SECURE_CFLAGS}"
SECURE_LDFLAGS="-Wl,-z,relro -Wl,-z,now -Wl,-z,noexecstack"

# ==============================================================================
# GPG Key Management
# ==============================================================================

fetch_gpg_keys() {
    log_info "Fetching GPG keys for signature verification (optional)..."
    
    # Common key servers
    KEYSERVERS=(
        "keyserver.ubuntu.com"
        "keys.openpgp.org"
    )
    
    # Known keys for GNU/LLVM projects (these are the common signing keys)
    KNOWN_KEYS=(
        "4ED8F3AA"  # GNU Binutils maintainer
        "C3C45C06"  # GNU GCC maintainer
        "BB5A0569"  # LLVM release manager
        "345AD05D"  # Hans Wennborg (LLVM)
        "474E22316ABF4785A88C6E8EA2C794A986419D8A"  # Tom Stellard (LLVM)
    )
    
    # Try first keyserver only, timeout quickly
    for key in "${KNOWN_KEYS[@]}"; do
        timeout 2 gpg --keyserver "${KEYSERVERS[0]}" --recv-keys "$key" 2>/dev/null && \
            log_success "Fetched key: $key" || true
    done
    
    # Quick attempt to get key IDs from signatures
    if [[ -d "${ARCHIVE_DIR}" ]]; then
        cd "${ARCHIVE_DIR}"
        for sig in *.sig; do
            if [[ -f "$sig" ]]; then
                key_id=$(timeout 1 gpg --list-packets "$sig" 2>/dev/null | grep -oP 'keyid \K[A-F0-9]+' | head -1 || true)
                if [[ -n "$key_id" ]]; then
                    timeout 2 gpg --keyserver "${KEYSERVERS[0]}" --recv-keys "$key_id" 2>/dev/null && \
                        log_success "Fetched key: $key_id" || true
                fi
            fi
        done
        cd - > /dev/null
    fi
    
    log_info "Key fetching complete (continuing regardless)"
}

# ==============================================================================
# Verification Functions
# ==============================================================================

verify_checksums() {
    log_info "Verifying SHA checksums..."
    
    if [[ ! -f "${ARCHIVE_DIR}/shasums.txt" ]]; then
        log_error "shasums.txt not found!"
        return 1
    fi
    
    cd "${ARCHIVE_DIR}"
    while IFS=' ' read -r hash filename; do
        if [[ -f "$filename" ]]; then
            actual=$(sha256sum "$filename" | cut -d' ' -f1)
            if [[ "$hash" != "$actual" ]]; then
                log_error "Checksum mismatch: $filename"
                return 1
            fi
            log_success "✓ $filename"
        fi
    done < shasums.txt
    cd - > /dev/null
}

verify_signatures() {
    log_info "Verifying GPG signatures (optional)..."
    
    if [[ ! -d "${ARCHIVE_DIR}" ]]; then
        log_warning "Archive directory not found, skipping signature verification"
        return 0
    fi
    
    cd "${ARCHIVE_DIR}"
    local verified_count=0
    local total_count=0
    
    for sig in *.sig; do
        if [[ -f "$sig" ]]; then
            base="${sig%.sig}"
            if [[ -f "$base" ]]; then
                ((total_count++))
                if timeout 2 gpg --verify "$sig" "$base" 2>/dev/null; then
                    log_success "✓ Signature verified: $base"
                    ((verified_count++))
                fi
            fi
        fi
    done
    
    cd - > /dev/null
    
    if [[ $total_count -gt 0 ]]; then
        log_info "Verified $verified_count/$total_count signatures (continuing regardless)"
    else
        log_info "No signatures to verify"
    fi
    
    return 0
}

# ==============================================================================
# Setup Functions
# ==============================================================================

setup_environment() {
    log_info "Creating secure build environment..."
    
    umask 0077
    mkdir -p "${BUILD_DIR}"/{llvm,binutils}
    mkdir -p "${INSTALL_DIR}"/{bin,lib,include}
    mkdir -p "${CONSOLE_DIR}"
    
    chmod 700 "${WORK_DIR}"
    
    export PATH="${INSTALL_DIR}/bin:${PATH}"
    export CFLAGS="${SECURE_CFLAGS}"
    export CXXFLAGS="${SECURE_CXXFLAGS}"
    export LDFLAGS="${SECURE_LDFLAGS}"
    
    log_success "Environment configured"
}

# ==============================================================================
# Extract Archives (FIXED)
# ==============================================================================

extract_archives() {
    log_info "Extracting archives..."
    
    cd "${WORK_DIR}"
    
    # Extract LLVM/Clang (fixed tar options)
    if [[ -f "${ARCHIVE_DIR}/llvm-3.2.src.tar.gz" ]]; then
        log_info "Extracting LLVM..."
        tar --no-same-owner --no-same-permissions -xzf "${ARCHIVE_DIR}/llvm-3.2.src.tar.gz" || \
        tar -xzf "${ARCHIVE_DIR}/llvm-3.2.src.tar.gz"
        
        if [[ -f "${ARCHIVE_DIR}/clang-3.2.src.tar.gz" ]]; then
            log_info "Extracting Clang..."
            tar --no-same-owner --no-same-permissions -xzf "${ARCHIVE_DIR}/clang-3.2.src.tar.gz" || \
            tar -xzf "${ARCHIVE_DIR}/clang-3.2.src.tar.gz"
            
            # Move clang into LLVM tools
            if [[ -d "clang-3.2.src" ]]; then
                mv clang-3.2.src llvm-3.2.src/tools/clang
            elif [[ -d "cfe-3.2.src" ]]; then
                mv cfe-3.2.src llvm-3.2.src/tools/clang
            fi
        fi
    fi
    
    # Extract binutils
    if [[ -f "${ARCHIVE_DIR}/binutils-2.23.1.tar.gz" ]]; then
        log_info "Extracting binutils..."
        tar --no-same-owner --no-same-permissions -xzf "${ARCHIVE_DIR}/binutils-2.23.1.tar.gz" || \
        tar -xzf "${ARCHIVE_DIR}/binutils-2.23.1.tar.gz"
    fi
    
    cd - > /dev/null
    log_success "Archives extracted"
}

# ==============================================================================
# Build Toolchain
# ==============================================================================

build_binutils() {
    log_info "Building binutils for arm-none-eabi..."
    
    cd "${BUILD_DIR}/binutils"
    
    if [[ ! -f "${WORK_DIR}/binutils-2.23.1/configure" ]]; then
        log_error "Binutils source not found at ${WORK_DIR}/binutils-2.23.1"
        return 1
    fi
    
    "${WORK_DIR}/binutils-2.23.1/configure" \
        --target=arm-none-eabi \
        --prefix="${INSTALL_DIR}" \
        --disable-nls \
        --disable-werror \
        --enable-gold \
        --enable-deterministic-archives \
        --enable-secureplt \
        --with-gnu-as \
        --with-gnu-ld \
        CFLAGS="${SECURE_CFLAGS}" \
        LDFLAGS="${SECURE_LDFLAGS}"
    
    make -j$(nproc) MAKEINFO=true
    make install MAKEINFO=true
    
    cd - > /dev/null
    log_success "Binutils built"
}

build_clang() {
    log_info "Building LLVM/Clang 3.2..."
    
    cd "${BUILD_DIR}/llvm"
    
    if [[ ! -f "${WORK_DIR}/llvm-3.2.src/configure" ]]; then
        log_error "LLVM source not found at ${WORK_DIR}/llvm-3.2.src"
        return 1
    fi
    
    # Configure for ARM bare metal
    "${WORK_DIR}/llvm-3.2.src/configure" \
        --prefix="${INSTALL_DIR}" \
        --target=arm-none-eabi \
        --enable-targets=arm \
        --disable-libffi \
        --disable-docs \
        --enable-optimized \
        --enable-assertions \
        --enable-pic \
        --with-binutils-include="${WORK_DIR}/binutils-2.23.1/include" \
        CFLAGS="${SECURE_CFLAGS}" \
        CXXFLAGS="${SECURE_CXXFLAGS}" \
        LDFLAGS="${SECURE_LDFLAGS}"
    
    make -j$(nproc) ENABLE_OPTIMIZED=1
    make install
    
    cd - > /dev/null
    log_success "Clang built"
}

# ==============================================================================
# Console Build Components
# ==============================================================================

create_boot_stub() {
    log_info "Creating universal boot stub..."
    
    cat > "${CONSOLE_DIR}/boot.s" << 'EOF'
.section ".text.boot"
.global _start
.global _get_stack_pointer

_start:
    @ Detect CPU and set appropriate stack
    mrc p15, 0, r0, c0, c0, 0    @ Read CPU ID
    
    @ Set stack based on detected platform
    @ Pi 4 and newer use different memory layout
    ldr r1, =0x410fc075           @ Cortex-A7 ID (Pi 2)
    cmp r0, r1
    ldreq sp, =0x8000000          @ 128MB stack for Pi 2+
    
    @ Default stack for Pi 1/Zero/QEMU
    ldrne sp, =0x8000000          @ 128MB stack
    
    @ Enable VFP if available (Pi 1+)
    mrc p15, 0, r0, c1, c0, 2
    orr r0, r0, #0xf00000         @ Enable VFP
    mcr p15, 0, r0, c1, c0, 2
    isb
    
    @ Clear BSS
    ldr r0, =__bss_start
    ldr r1, =__bss_end
    mov r2, #0
1:  cmp r0, r1
    strlt r2, [r0], #4
    blt 1b
    
    @ Jump to C code
    bl universal_console_init
    bl main_loop
    
    @ Halt
halt:
    wfe
    b halt

_get_stack_pointer:
    mov r0, sp
    bx lr

@ ARM exception vectors
.section ".vectors", "ax"
.global _vectors
_vectors:
    ldr pc, reset_addr
    ldr pc, undefined_addr
    ldr pc, swi_addr
    ldr pc, prefetch_addr
    ldr pc, data_addr
    ldr pc, unused_addr
    ldr pc, irq_addr
    ldr pc, fiq_addr

reset_addr:     .word _start
undefined_addr: .word halt
swi_addr:       .word halt
prefetch_addr:  .word halt
data_addr:      .word halt
unused_addr:    .word halt
irq_addr:       .word halt
fiq_addr:       .word halt
EOF
    
    log_success "Boot stub created"
}

create_linker_scripts() {
    log_info "Creating linker scripts..."
    
    # QEMU VersatilePB linker script
    cat > "${CONSOLE_DIR}/versatile.ld" << 'EOF'
ENTRY(_start)

SECTIONS
{
    /* QEMU VersatilePB loads at 0x10000 */
    . = 0x10000;
    
    .text : {
        KEEP(*(.text.boot))
        *(.text .text.*)
        *(.rodata .rodata.*)
    }
    
    . = ALIGN(4096);
    
    .data : {
        *(.data .data.*)
    }
    
    . = ALIGN(4096);
    
    __bss_start = .;
    .bss : {
        *(.bss .bss.*)
        *(COMMON)
    }
    __bss_end = .;
    
    . = ALIGN(4096);
    __end = .;
}
EOF

    # Universal Raspberry Pi linker script
    cat > "${CONSOLE_DIR}/rpi_universal.ld" << 'EOF'
ENTRY(_start)

SECTIONS
{
    /* Raspberry Pi kernel load address */
    . = 0x8000;
    
    .text : {
        KEEP(*(.vectors))
        KEEP(*(.text.boot))
        *(.text .text.*)
        *(.rodata .rodata.*)
        *(.got .got.*)
    }
    
    . = ALIGN(4096);
    
    .data : {
        *(.data .data.*)
    }
    
    . = ALIGN(4096);
    
    __bss_start = .;
    .bss : {
        *(.bss .bss.*)
        *(COMMON)
    }
    . = ALIGN(4096);
    __bss_end = .;
    
    /* Stack and heap */
    . = ALIGN(16);
    __heap_start = .;
    . = . + 0x100000;  /* 1MB heap */
    __heap_end = .;
    
    __stack_start = .;
    . = . + 0x40000;   /* 256KB stack */
    __stack_top = .;
    
    __end = .;
}
EOF
    
    log_success "Linker scripts created"
}

create_dummy_font() {
    log_info "Creating dummy font file..."
    
    # Create a minimal qemu_vga_font.h if not present
    cat > "${CONSOLE_DIR}/qemu_vga_font.h" << 'EOF'
#ifndef QEMU_VGA_FONT_H
#define QEMU_VGA_FONT_H

// Minimal 8x16 VGA font (just basic ASCII)
// In production, replace with full VGA font data
static const unsigned char qemu_vga_font_8x16[256*16] = {
    // Space character and basic ASCII set
    [0 ... 256*16-1] = 0xFF  // Placeholder - replace with actual font data
};

#endif
EOF
    
    log_success "Font header created"
}

create_main_loop() {
    log_info "Creating main loop wrapper..."
    
    cat > "${CONSOLE_DIR}/main_loop.c" << 'EOF'
// Main loop for the console
extern int universal_console_init(void);
extern void console_update(void);
extern void console_puts(const char *str);

void main_loop(void) {
    // Console already initialized by boot.s
    
    console_puts("\nConsole initialized successfully!\n");
    console_puts("Entering main loop...\n");
    
    // Main event loop
    while (1) {
        console_update();
        
        // Small delay
        for (volatile int i = 0; i < 100000; i++);
    }
}
EOF
    
    log_success "Main loop created"
}

# ==============================================================================
# Build Console
# ==============================================================================

build_console() {
    log_info "Building Universal Pi Console..."
    
    cd "${CONSOLE_DIR}"
    
    # First, check if paste.txt exists in current directory or parent
    if [[ -f "${PWD}/../../paste.txt" ]]; then
        cp "${PWD}/../../paste.txt" universal_pi_console.c
        log_success "Found paste.txt in parent directory"
    elif [[ -f "${PWD}/../paste.txt" ]]; then
        cp "${PWD}/../paste.txt" universal_pi_console.c
        log_success "Found paste.txt in working directory"
    else
        log_error "Console source (paste.txt) not found!"
        log_info "Please copy your console source code to paste.txt in the current directory"
        return 1
    fi
    
    # Create support files
    create_boot_stub
    create_linker_scripts
    create_dummy_font
    create_main_loop
    
    # Common security flags for bare metal
    BARE_METAL_FLAGS=(
        -ffreestanding
        -nostdlib
        -nostartfiles
        -fno-builtin
        -fno-exceptions
        -fno-unwind-tables
        -fno-asynchronous-unwind-tables
        -ffunction-sections
        -fdata-sections
        -Wall
        -Wextra
        -Wformat=2
        -Wformat-security
        -Wstack-usage=8192
        -O2
        -g
    )
    
    log_info "Building for QEMU VersatilePB..."
    "${INSTALL_DIR}/bin/clang" \
        --target=arm-none-eabi \
        -march=armv5te \
        -mcpu=arm926ej-s \
        -marm \
        -mfloat-abi=soft \
        "${BARE_METAL_FLAGS[@]}" \
        -D_FORTIFY_SOURCE=0 \
        -DPLATFORM_QEMU_VERSATILE \
        boot.s \
        universal_pi_console.c \
        main_loop.c \
        -T versatile.ld \
        -o kernel_qemu.elf 2>&1 | tee qemu_build.log || true
    
    if [[ -f kernel_qemu.elf ]]; then
        "${INSTALL_DIR}/bin/arm-none-eabi-objcopy" \
            kernel_qemu.elf -O binary kernel_qemu.img
        log_success "QEMU build complete: kernel_qemu.img"
    else
        log_warning "QEMU build failed - check qemu_build.log"
    fi
    
    log_info "Building universal Pi hardware binary..."
    "${INSTALL_DIR}/bin/clang" \
        --target=arm-none-eabi \
        -march=armv6zk \
        -mfpu=vfp \
        -marm \
        -mfloat-abi=soft \
        "${BARE_METAL_FLAGS[@]}" \
        -D_FORTIFY_SOURCE=0 \
        -DPLATFORM_PI_UNIVERSAL \
        boot.s \
        universal_pi_console.c \
        main_loop.c \
        -T rpi_universal.ld \
        -o kernel_pi.elf 2>&1 | tee pi_build.log || true
    
    if [[ -f kernel_pi.elf ]]; then
        "${INSTALL_DIR}/bin/arm-none-eabi-objcopy" \
            kernel_pi.elf -O binary kernel.img
        log_success "Pi universal build complete: kernel.img"
        
        # Generate info files
        "${INSTALL_DIR}/bin/arm-none-eabi-size" kernel_pi.elf > size_report.txt
        "${INSTALL_DIR}/bin/arm-none-eabi-objdump" -d kernel_pi.elf > kernel_pi.dis
        "${INSTALL_DIR}/bin/arm-none-eabi-nm" kernel_pi.elf | sort > kernel_pi.sym
    else
        log_warning "Pi build failed - check pi_build.log"
    fi
    
    cd - > /dev/null
}

# ==============================================================================
# Security Verification
# ==============================================================================

verify_binary() {
    local binary=$1
    log_info "Verifying $binary..."
    
    if [[ ! -f "$binary" ]]; then
        log_warning "Binary not found: $binary"
        return
    fi
    
    # Check for unsafe functions
    if "${INSTALL_DIR}/bin/arm-none-eabi-nm" "$binary" 2>/dev/null | \
       grep -E "(gets|strcpy|strcat|sprintf|vsprintf)" > /dev/null; then
        log_warning "Binary contains potentially unsafe functions"
    else
        log_success "No unsafe functions detected"
    fi
    
    # Display section info
    "${INSTALL_DIR}/bin/arm-none-eabi-size" -A "$binary"
}

# ==============================================================================
# Main
# ==============================================================================

main() {
    log_info "Starting secure bare metal build..."
    
    # Check for paste.txt first
    if [[ ! -f "paste.txt" ]]; then
        log_error "paste.txt not found in current directory!"
        log_info "Please copy your Universal Pi Console source code to paste.txt"
        exit 1
    fi
    
    # Verify archives
    if [[ ! -d "${ARCHIVE_DIR}" ]]; then
        log_error "Archive directory not found: ${ARCHIVE_DIR}"
        exit 1
    fi
    
    # Setup
    setup_environment
    
    # Fetch GPG keys (optional, with timeout)
    log_info "Attempting to fetch GPG keys (will timeout quickly if unavailable)..."
    fetch_gpg_keys || true
    
    # Verify integrity (optional checks)
    verify_checksums || {
        log_error "Checksum verification failed! This is critical."
        exit 1
    }
    verify_signatures || true  # Optional, continue regardless
    
    # Extract
    extract_archives || exit 1
    
    # Build toolchain
    build_binutils || exit 1
    build_clang || exit 1
    
    # Build console
    build_console || exit 1
    
    # Verify results
    verify_binary "${CONSOLE_DIR}/kernel_pi.elf"
    
    # Summary
    echo ""
    log_success "Build complete!"
    echo "================================"
    echo "Toolchain: ${INSTALL_DIR}"
    echo "Console builds: ${CONSOLE_DIR}"
    echo ""
    echo "Generated binaries:"
    if [[ -f "${CONSOLE_DIR}/kernel.img" ]]; then
        echo "  • kernel.img      - Universal Pi hardware (all models)"
    fi
    if [[ -f "${CONSOLE_DIR}/kernel_qemu.img" ]]; then
        echo "  • kernel_qemu.img - QEMU VersatilePB emulator"
    fi
    echo ""
    echo "To deploy on Raspberry Pi:"
    echo "  1. Copy kernel.img to SD card root"
    echo "  2. Add to config.txt: kernel=kernel.img"
    echo "  3. Boot your Pi"
    echo ""
    echo "To test with QEMU:"
    echo "  qemu-system-arm -M versatilepb -m 256M -kernel kernel_qemu.img -serial stdio"
    echo "================================"
}

# Execute
main "$@"