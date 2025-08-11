#!/bin/bash

# ARM Bare Metal Toolchain Builder for LLVM/Clang 3.2
# Compatible versions from late 2012/early 2013 timeframe

set -e  # Exit on error

# Configuration
PREFIX="$HOME/arm-llvm-3.2-toolchain"
BUILD_DIR="$PWD/build"
SOURCES_DIR="$PWD/sources"
PARALLEL_JOBS=$(nproc)

# Version selection (contemporary with LLVM 3.2 - Dec 2012)
BINUTILS_VERSION="2.23.1"  # Released Nov 2012
NEWLIB_VERSION="2.0.0"     # Released Dec 2012
# GCC is needed for initial bootstrap and libgcc
GCC_VERSION="4.7.2"         # Released Sep 2012

# Target configuration
TARGET="arm-none-eabi"
TARGET_ARCH="armv7-m"  # For Cortex-M series, change as needed

# Create directories
mkdir -p "$BUILD_DIR"
mkdir -p "$SOURCES_DIR"
mkdir -p "$PREFIX"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Download function
download_sources() {
    log "Downloading sources..."
    cd "$SOURCES_DIR"
    
    # Binutils
    if [ ! -f "binutils-${BINUTILS_VERSION}.tar.bz2" ]; then
        log "Downloading binutils ${BINUTILS_VERSION}..."
        wget -c "https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.bz2"
    fi
    
    # Newlib
    if [ ! -f "newlib-${NEWLIB_VERSION}.tar.gz" ]; then
        log "Downloading newlib ${NEWLIB_VERSION}..."
        wget -c "ftp://sourceware.org/pub/newlib/newlib-${NEWLIB_VERSION}.tar.gz"
    fi
    
    # GCC (for libgcc and initial bootstrap)
    if [ ! -f "gcc-${GCC_VERSION}.tar.bz2" ]; then
        log "Downloading gcc ${GCC_VERSION}..."
        wget -c "https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.bz2"
    fi
    
    log "Extracting sources..."
    tar -xjf "binutils-${BINUTILS_VERSION}.tar.bz2"
    tar -xzf "newlib-${NEWLIB_VERSION}.tar.gz"
    tar -xjf "gcc-${GCC_VERSION}.tar.bz2"
}

# Build binutils
build_binutils() {
    log "Building binutils for ${TARGET}..."
    
    mkdir -p "$BUILD_DIR/binutils"
    cd "$BUILD_DIR/binutils"
    
    "$SOURCES_DIR/binutils-${BINUTILS_VERSION}/configure" \
        --prefix="$PREFIX" \
        --target="$TARGET" \
        --with-sysroot="$PREFIX/$TARGET" \
        --disable-nls \
        --disable-werror \
        --disable-multilib \
        --enable-interwork
    
    make -j"$PARALLEL_JOBS"
    make install
    
    log "Binutils build complete!"
}

# Build LLVM/Clang
build_llvm_clang() {
    log "Building LLVM/Clang 3.2..."
    
    # Assuming LLVM and Clang sources are already extracted
    if [ ! -d "llvm-3.2.src" ]; then
        error "LLVM source directory 'llvm-3.2.src' not found!"
    fi
    
    # Move Clang into LLVM tools directory
    if [ -d "clang-3.2.src" ] && [ ! -d "llvm-3.2.src/tools/clang" ]; then
        log "Moving Clang into LLVM tools directory..."
        mv clang-3.2.src llvm-3.2.src/tools/clang
    fi
    
    mkdir -p "$BUILD_DIR/llvm"
    cd "$BUILD_DIR/llvm"
    
    # Configure LLVM/Clang for ARM cross-compilation
    "$PWD/../../llvm-3.2.src/configure" \
        --prefix="$PREFIX" \
        --target="$TARGET" \
        --enable-targets=arm \
        --disable-multilib \
        --disable-shared \
        --enable-static \
        --enable-optimized \
        --disable-assertions \
        --with-binutils-include="$SOURCES_DIR/binutils-${BINUTILS_VERSION}/include" \
        --with-gcc-toolchain="$PREFIX" \
        --with-default-sysroot="$PREFIX/$TARGET"
    
    make -j"$PARALLEL_JOBS"
    make install
    
    log "LLVM/Clang build complete!"
}

# Build bootstrap GCC (for libgcc)
build_bootstrap_gcc() {
    log "Building bootstrap GCC for libgcc..."
    
    cd "$SOURCES_DIR/gcc-${GCC_VERSION}"
    ./contrib/download_prerequisites
    
    mkdir -p "$BUILD_DIR/gcc-bootstrap"
    cd "$BUILD_DIR/gcc-bootstrap"
    
    "$SOURCES_DIR/gcc-${GCC_VERSION}/configure" \
        --prefix="$PREFIX" \
        --target="$TARGET" \
        --with-sysroot="$PREFIX/$TARGET" \
        --with-newlib \
        --without-headers \
        --with-gnu-as \
        --with-gnu-ld \
        --disable-nls \
        --disable-shared \
        --disable-multilib \
        --disable-decimal-float \
        --disable-threads \
        --disable-libatomic \
        --disable-libgomp \
        --disable-libmpx \
        --disable-libquadmath \
        --disable-libssp \
        --disable-libvtv \
        --disable-libstdcxx \
        --enable-languages=c \
        --with-arch="$TARGET_ARCH" \
        --with-float=soft
    
    make -j"$PARALLEL_JOBS" all-gcc all-target-libgcc
    make install-gcc install-target-libgcc
    
    log "Bootstrap GCC build complete!"
}

# Build Newlib with Clang
build_newlib() {
    log "Building Newlib..."
    
    mkdir -p "$BUILD_DIR/newlib"
    cd "$BUILD_DIR/newlib"
    
    # Export Clang as compiler for newlib build
    export CC_FOR_TARGET="$PREFIX/bin/clang"
    export CXX_FOR_TARGET="$PREFIX/bin/clang++"
    export AR_FOR_TARGET="$PREFIX/bin/$TARGET-ar"
    export AS_FOR_TARGET="$PREFIX/bin/$TARGET-as"
    export LD_FOR_TARGET="$PREFIX/bin/$TARGET-ld"
    export NM_FOR_TARGET="$PREFIX/bin/$TARGET-nm"
    export RANLIB_FOR_TARGET="$PREFIX/bin/$TARGET-ranlib"
    export STRIP_FOR_TARGET="$PREFIX/bin/$TARGET-strip"
    
    # Configure flags for bare metal
    NEWLIB_FLAGS="-O2 -ffunction-sections -fdata-sections"
    
    "$SOURCES_DIR/newlib-${NEWLIB_VERSION}/configure" \
        --prefix="$PREFIX" \
        --target="$TARGET" \
        --disable-newlib-supplied-syscalls \
        --enable-newlib-reent-small \
        --disable-newlib-fvwrite-in-streamio \
        --disable-newlib-fseek-optimization \
        --disable-newlib-wide-orient \
        --enable-newlib-nano-malloc \
        --disable-newlib-unbuf-stream-opt \
        --enable-lite-exit \
        --enable-newlib-global-atexit \
        --disable-nls \
        --disable-multilib \
        CFLAGS_FOR_TARGET="$NEWLIB_FLAGS" \
        CXXFLAGS_FOR_TARGET="$NEWLIB_FLAGS"
    
    make -j"$PARALLEL_JOBS"
    make install
    
    log "Newlib build complete!"
}

# Create compiler wrapper scripts
create_wrapper_scripts() {
    log "Creating compiler wrapper scripts..."
    
    # Create clang wrapper for ARM target
    cat > "$PREFIX/bin/arm-none-eabi-clang" << 'EOF'
#!/bin/bash
TOOLCHAIN_PREFIX="$(dirname "$0")/.."
TARGET="arm-none-eabi"
SYSROOT="$TOOLCHAIN_PREFIX/$TARGET"

exec "$TOOLCHAIN_PREFIX/bin/clang" \
    -target "$TARGET" \
    --sysroot="$SYSROOT" \
    -I"$SYSROOT/include" \
    -L"$SYSROOT/lib" \
    "$@"
EOF
    
    cat > "$PREFIX/bin/arm-none-eabi-clang++" << 'EOF'
#!/bin/bash
TOOLCHAIN_PREFIX="$(dirname "$0")/.."
TARGET="arm-none-eabi"
SYSROOT="$TOOLCHAIN_PREFIX/$TARGET"

exec "$TOOLCHAIN_PREFIX/bin/clang++" \
    -target "$TARGET" \
    --sysroot="$SYSROOT" \
    -I"$SYSROOT/include" \
    -L"$SYSROOT/lib" \
    "$@"
EOF
    
    chmod +x "$PREFIX/bin/arm-none-eabi-clang"
    chmod +x "$PREFIX/bin/arm-none-eabi-clang++"
    
    log "Wrapper scripts created!"
}

# Create test program
create_test_program() {
    log "Creating test program..."
    
    cat > "$BUILD_DIR/test.c" << 'EOF'
#include <stdint.h>

// Simple ARM bare metal test program
void _start(void) {
    volatile uint32_t counter = 0;
    while(1) {
        counter++;
    }
}

// Minimal vector table for Cortex-M
__attribute__((section(".vectors")))
const uint32_t vectors[] = {
    0x20008000,  // Initial stack pointer
    (uint32_t)_start  // Reset handler
};
EOF
    
    cat > "$BUILD_DIR/link.ld" << 'EOF'
MEMORY
{
    FLASH (rx) : ORIGIN = 0x08000000, LENGTH = 256K
    RAM (rwx) : ORIGIN = 0x20000000, LENGTH = 64K
}

SECTIONS
{
    .vectors : {
        KEEP(*(.vectors))
    } > FLASH
    
    .text : {
        *(.text*)
        *(.rodata*)
    } > FLASH
    
    .data : {
        *(.data*)
    } > RAM AT > FLASH
    
    .bss : {
        *(.bss*)
        *(COMMON)
    } > RAM
}
EOF
    
    log "Test compilation command:"
    echo "$PREFIX/bin/arm-none-eabi-clang -nostdlib -T link.ld test.c -o test.elf"
}

# Main build process
main() {
    log "Starting ARM bare metal toolchain build for LLVM/Clang 3.2"
    log "Install prefix: $PREFIX"
    log "Target: $TARGET"
    
    # Check if LLVM sources exist
    if [ ! -d "llvm-3.2.src" ]; then
        error "Please extract llvm-3.2.src.tar.gz in the current directory first!"
    fi
    
    if [ ! -d "clang-3.2.src" ] && [ ! -d "llvm-3.2.src/tools/clang" ]; then
        error "Please extract clang-3.2.src.tar.gz in the current directory first!"
    fi
    
    # Download required sources
    download_sources
    
    # Build components in order
    build_binutils
    build_llvm_clang
    build_bootstrap_gcc  # For libgcc
    build_newlib
    create_wrapper_scripts
    create_test_program
    
    log "Toolchain build complete!"
    log "Toolchain installed to: $PREFIX"
    log "Add $PREFIX/bin to your PATH to use the toolchain"
    echo
    echo "export PATH=\"$PREFIX/bin:\$PATH\""
    echo
    log "Test with: arm-none-eabi-clang -v"
}

# Run main function
main "$@"