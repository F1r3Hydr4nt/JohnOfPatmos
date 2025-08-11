#ifndef QEMU_VGA_FONT_H
#define QEMU_VGA_FONT_H

// Minimal 8x16 VGA font (just basic ASCII)
// In production, replace with full VGA font data
static const unsigned char qemu_vga_font_8x16[256*16] = {
    // Space character and basic ASCII set
    [0 ... 256*16-1] = 0xFF  // Placeholder - replace with actual font data
};

#endif
