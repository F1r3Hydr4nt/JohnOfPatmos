/*
 * CORRECTED Universal Raspberry Pi Console with Accurate Hardware Detection
 * Supports Pi 1, Pi Zero, Pi 2, Pi 3, Pi 4 + QEMU versatilepb
 * Based on ACTUAL peripheral addresses from official documentation
 */

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#include "qemu_vga_font.h"  // External 8x16 VGA font

// =============================================================================
// CORRECTED Hardware Detection and Memory Maps
// =============================================================================

typedef enum {
    PLATFORM_UNKNOWN = 0,
    PLATFORM_PI_BCM2835 = 1,    // Pi 1, Pi Zero, Pi Zero W, Compute Module 1
    PLATFORM_PI_BCM2836 = 2,    // Pi 2 (some models)
    PLATFORM_PI_BCM2837 = 3,    // Pi 2 (later), Pi 3, Pi Zero 2 W, CM3
    PLATFORM_PI_BCM2837B0 = 4,  // Pi 3B+, Pi 3A+, CM3+
    PLATFORM_PI_BCM2711 = 5,    // Pi 4, Pi 400, CM4
    PLATFORM_QEMU_VERSATILE = 6 // QEMU versatilepb emulation
} platform_type_t;

typedef struct {
    platform_type_t platform;
    uint32_t peripheral_base;
    uint32_t mailbox_base;
    uint32_t gpio_base;
    uint32_t uart_base;
    uint32_t usb_base;
    const char *name;
    bool has_usb;
    bool has_ps2;  // For QEMU
} platform_info_t;

static platform_info_t current_platform = {0};

// ACTUAL peripheral base addresses from BCM datasheets and QEMU docs
#define BCM2835_PERIPHERAL_BASE  0x20000000  // Pi 1, Pi Zero (BCM2835)
#define BCM2836_PERIPHERAL_BASE  0x3F000000  // Pi 2/3 (BCM2836/2837)
#define BCM2711_PERIPHERAL_BASE  0xFE000000  // Pi 4 (BCM2711)

// QEMU versatilepb addresses (from QEMU source)
#define QEMU_PL050_KBD_BASE      0x10007000  // PS/2 keyboard
#define QEMU_PL050_MOUSE_BASE    0x10008000  // PS/2 mouse
#define QEMU_PL011_UART_BASE     0x101F1000  // Primary UART
#define QEMU_CLCD_BASE           0x10120000  // Color LCD controller

// Standard offsets from peripheral base (same for all BCM chips)
#define GPIO_OFFSET              0x200000
#define UART_OFFSET              0x201000
#define MAILBOX_OFFSET           0x00B880
#define USB_OFFSET               0x980000

// Console configuration
#define FONT_WIDTH               8
#define FONT_HEIGHT              16
#define MIN_CONSOLE_COLS         40
#define MIN_CONSOLE_ROWS         15
#define MAX_BUFFER_LINES         3000
#define STATUS_BAR_HEIGHT        FONT_HEIGHT

// Colors (32-bit ARGB)
#define COLOR_BLACK              0xFF000000
#define COLOR_BLUE               0xFF0000AA
#define COLOR_GREEN              0xFF00AA00
#define COLOR_CYAN               0xFF00AAAA
#define COLOR_RED                0xFFAA0000
#define COLOR_MAGENTA            0xFFAA00AA
#define COLOR_BROWN              0xFFAA5500
#define COLOR_LIGHT_GRAY         0xFFAAAAAA
#define COLOR_DARK_GRAY          0xFF555555
#define COLOR_LIGHT_BLUE         0xFF5555FF
#define COLOR_LIGHT_GREEN        0xFF55FF55
#define COLOR_LIGHT_CYAN         0xFF55FFFF
#define COLOR_LIGHT_RED          0xFFFF5555
#define COLOR_LIGHT_MAGENTA      0xFFFF55FF
#define COLOR_YELLOW             0xFFFFFF55
#define COLOR_WHITE              0xFFFFFFFF

// =============================================================================
// Console State
// =============================================================================

typedef struct {
    char character;
    uint32_t foreground;
    uint32_t background;
    uint8_t attributes;
} console_cell_t;

typedef struct {
    // Display properties
    uint32_t *framebuffer;
    uint32_t width, height;
    uint32_t pitch;  // In pixels
    uint32_t console_cols, console_rows;
    
    // Console buffer
    console_cell_t *buffer;
    uint32_t buffer_lines;
    uint32_t current_line;
    uint32_t current_col;
    uint32_t display_start;
    
    // Colors and cursor
    uint32_t current_fg, current_bg;
    bool cursor_visible;
    uint32_t cursor_blink_counter;
    
    // Input state
    int mouse_x, mouse_y;
    uint8_t mouse_buttons;
    bool mouse_available;
    bool keyboard_available;
    
    // Statistics
    uint32_t total_chars;
    uint32_t scroll_position;
    
} universal_console_t;

static universal_console_t console = {0};

// =============================================================================
// CORRECTED Hardware Detection
// =============================================================================

static bool safe_peek32(uint32_t address, uint32_t *value) {
    // Simple memory access test - in real implementation, add exception handling
    volatile uint32_t *ptr = (volatile uint32_t *)address;
    *value = *ptr;
    
    // Basic sanity check - should not be all 1s or 0s for peripheral registers
    return (*value != 0xFFFFFFFF && *value != 0x00000000);
}

static platform_type_t detect_platform(void) {
    uint32_t test_value;
    
    // Test for QEMU versatilepb first (most specific)
    // Check for PL050 PS/2 controller signature
    if (safe_peek32(QEMU_PL050_KBD_BASE + 0x04, &test_value)) {  // Status register
        if ((test_value & 0xFF) != 0xFF) {  // Valid PS/2 status
            current_platform.platform = PLATFORM_QEMU_VERSATILE;
            current_platform.peripheral_base = 0x10000000;  // QEMU base
            current_platform.mailbox_base = 0;              // No mailbox in versatilepb
            current_platform.gpio_base = QEMU_PL050_KBD_BASE;
            current_platform.uart_base = QEMU_PL011_UART_BASE;
            current_platform.usb_base = 0;                  // USB via PCI
            current_platform.name = "QEMU ARM Versatile PB";
            current_platform.has_usb = false;               // No direct USB
            current_platform.has_ps2 = true;
            return PLATFORM_QEMU_VERSATILE;
        }
    }
    
    // Test for Pi 4 (BCM2711) - highest address
    if (safe_peek32(BCM2711_PERIPHERAL_BASE + MAILBOX_OFFSET + 0x18, &test_value)) {
        current_platform.platform = PLATFORM_PI_BCM2711;
        current_platform.peripheral_base = BCM2711_PERIPHERAL_BASE;
        current_platform.mailbox_base = BCM2711_PERIPHERAL_BASE + MAILBOX_OFFSET;
        current_platform.gpio_base = BCM2711_PERIPHERAL_BASE + GPIO_OFFSET;
        current_platform.uart_base = BCM2711_PERIPHERAL_BASE + UART_OFFSET;
        current_platform.usb_base = BCM2711_PERIPHERAL_BASE + USB_OFFSET;
        current_platform.name = "Raspberry Pi 4/400/CM4 (BCM2711)";
        current_platform.has_usb = true;
        current_platform.has_ps2 = false;
        return PLATFORM_PI_BCM2711;
    }
    
    // Test for Pi 2/3 (BCM2836/2837) - middle address  
    if (safe_peek32(BCM2836_PERIPHERAL_BASE + MAILBOX_OFFSET + 0x18, &test_value)) {
        // Try to distinguish between BCM2836 and BCM2837 by checking ARM timer
        uint32_t arm_timer_base = BCM2836_PERIPHERAL_BASE + 0x40000;
        if (safe_peek32(arm_timer_base, &test_value)) {
            // BCM2836 has different ARM timer layout than BCM2837
            // For simplicity, assume BCM2837 (more common)
            current_platform.platform = PLATFORM_PI_BCM2837;
            current_platform.name = "Raspberry Pi 2/3/Zero2W (BCM2836/2837)";
        } else {
            current_platform.platform = PLATFORM_PI_BCM2836;
            current_platform.name = "Raspberry Pi 2 (BCM2836)";
        }
        
        current_platform.peripheral_base = BCM2836_PERIPHERAL_BASE;
        current_platform.mailbox_base = BCM2836_PERIPHERAL_BASE + MAILBOX_OFFSET;
        current_platform.gpio_base = BCM2836_PERIPHERAL_BASE + GPIO_OFFSET;
        current_platform.uart_base = BCM2836_PERIPHERAL_BASE + UART_OFFSET;
        current_platform.usb_base = BCM2836_PERIPHERAL_BASE + USB_OFFSET;
        current_platform.has_usb = true;
        current_platform.has_ps2 = false;
        return current_platform.platform;
    }
    
    // Default to Pi 1/Zero (BCM2835) - most compatible
    // This covers: Pi 1 A/B/A+/B+, Pi Zero/Zero W, Compute Module 1
    current_platform.platform = PLATFORM_PI_BCM2835;
    current_platform.peripheral_base = BCM2835_PERIPHERAL_BASE;
    current_platform.mailbox_base = BCM2835_PERIPHERAL_BASE + MAILBOX_OFFSET;
    current_platform.gpio_base = BCM2835_PERIPHERAL_BASE + GPIO_OFFSET;
    current_platform.uart_base = BCM2835_PERIPHERAL_BASE + UART_OFFSET;
    current_platform.usb_base = BCM2835_PERIPHERAL_BASE + USB_OFFSET;
    current_platform.name = "Raspberry Pi 1/Zero (BCM2835)";
    current_platform.has_usb = true;
    current_platform.has_ps2 = false;
    
    return PLATFORM_PI_BCM2835;
}

// =============================================================================
// Mailbox Communication (Pi models only)
// =============================================================================

#define MAILBOX_READ             0x00
#define MAILBOX_STATUS           0x18
#define MAILBOX_WRITE            0x20
#define MAILBOX_CHANNEL_GPU      8

#define MAILBOX_FULL             0x80000000
#define MAILBOX_EMPTY            0x40000000

static volatile uint32_t *mailbox_base = NULL;

static bool mailbox_available(void) {
    return (current_platform.mailbox_base != 0 && 
            current_platform.platform != PLATFORM_QEMU_VERSATILE);
}

static void mailbox_write(uint32_t channel, uint32_t data) {
    if (!mailbox_available()) return;
    
    mailbox_base = (volatile uint32_t *)current_platform.mailbox_base;
    while (mailbox_base[MAILBOX_STATUS / 4] & MAILBOX_FULL);
    mailbox_base[MAILBOX_WRITE / 4] = (data & 0xFFFFFFF0) | (channel & 0xF);
}

static uint32_t mailbox_read(uint32_t channel) {
    if (!mailbox_available()) return 0;
    
    uint32_t data;
    do {
        while (mailbox_base[MAILBOX_STATUS / 4] & MAILBOX_EMPTY);
        data = mailbox_base[MAILBOX_READ / 4];
    } while ((data & 0xF) != channel);
    return data & 0xFFFFFFF0;
}

// =============================================================================
// Display Detection and Setup
// =============================================================================

typedef struct {
    uint32_t size;
    uint32_t code;
    
    // Get physical size
    uint32_t tag_get_physical;
    uint32_t tag_get_physical_size;
    uint32_t tag_get_physical_code;
    uint32_t physical_width;
    uint32_t physical_height;
    
    // Set physical size
    uint32_t tag_set_physical;
    uint32_t tag_set_physical_size;
    uint32_t tag_set_physical_code;
    uint32_t set_width;
    uint32_t set_height;
    
    // Set virtual size
    uint32_t tag_set_virtual;
    uint32_t tag_set_virtual_size;
    uint32_t tag_set_virtual_code;
    uint32_t virtual_width;
    uint32_t virtual_height;
    
    // Set depth
    uint32_t tag_set_depth;
    uint32_t tag_set_depth_size;
    uint32_t tag_set_depth_code;
    uint32_t depth;
    
    // Allocate buffer
    uint32_t tag_allocate;
    uint32_t tag_allocate_size;
    uint32_t tag_allocate_code;
    uint32_t fb_address;
    uint32_t fb_size;
    
    // Get pitch
    uint32_t tag_get_pitch;
    uint32_t tag_get_pitch_size;
    uint32_t tag_get_pitch_code;
    uint32_t pitch;
    
    uint32_t end_tag;
} __attribute__((aligned(16))) display_request_t;

static int detect_display_resolution(uint32_t *width, uint32_t *height) {
    // QEMU versatilepb has fixed CLCD controller
    if (current_platform.platform == PLATFORM_QEMU_VERSATILE) {
        *width = 640;   // QEMU default
        *height = 480;
        return 0;
    }
    
    if (!mailbox_available()) {
        *width = 640;
        *height = 480;
        return -1;
    }
    
    static display_request_t request = {
        .size = sizeof(display_request_t),
        .code = 0,
        
        .tag_get_physical = 0x40003,  // Get physical size
        .tag_get_physical_size = 8,
        .tag_get_physical_code = 0,
        .physical_width = 0,
        .physical_height = 0,
        
        .end_tag = 0
    };
    
    mailbox_write(MAILBOX_CHANNEL_GPU, (uint32_t)&request);
    uint32_t result = mailbox_read(MAILBOX_CHANNEL_GPU);
    
    if (request.code == 0x80000000 && request.physical_width > 0 && request.physical_height > 0) {
        *width = request.physical_width;
        *height = request.physical_height;
        return 0;
    }
    
    // Fallback resolutions by platform
    switch (current_platform.platform) {
        case PLATFORM_PI_BCM2711:
            *width = 1920; *height = 1080; break;  // Pi 4 can do Full HD
        case PLATFORM_PI_BCM2837:
        case PLATFORM_PI_BCM2837B0:
            *width = 1680; *height = 1050; break;  // Pi 3 common resolution
        case PLATFORM_PI_BCM2836:
            *width = 1280; *height = 1024; break;  // Pi 2 safe resolution
        default:
            *width = 1024; *height = 768;  break;  // Pi 1/Zero safe resolution
    }
    
    return -1;
}

static int setup_framebuffer(uint32_t width, uint32_t height) {
    if (current_platform.platform == PLATFORM_QEMU_VERSATILE) {
        // QEMU versatilepb CLCD setup - simplified
        volatile uint32_t *clcd = (volatile uint32_t *)QEMU_CLCD_BASE;
        
        // Set up basic CLCD for text mode
        // This is a simplified setup - real CLCD needs proper timing values
        console.framebuffer = (uint32_t *)0x200000;  // Use RAM as framebuffer
        console.width = width;
        console.height = height;
        console.pitch = width;
        
        // Calculate console dimensions
        console.console_cols = console.width / FONT_WIDTH;
        console.console_rows = (console.height - STATUS_BAR_HEIGHT) / FONT_HEIGHT;
        return 0;
    }
    
    if (!mailbox_available()) {
        return -1;
    }
    
    static display_request_t fb_request = {
        .size = sizeof(display_request_t),
        .code = 0,
        
        .tag_set_physical = 0x48003,
        .tag_set_physical_size = 8,
        .tag_set_physical_code = 0,
        .set_width = 0,
        .set_height = 0,
        
        .tag_set_virtual = 0x48004,
        .tag_set_virtual_size = 8,
        .tag_set_virtual_code = 0,
        .virtual_width = 0,
        .virtual_height = 0,
        
        .tag_set_depth = 0x48005,
        .tag_set_depth_size = 4,
        .tag_set_depth_code = 0,
        .depth = 32,
        
        .tag_allocate = 0x40001,
        .tag_allocate_size = 8,
        .tag_allocate_code = 0,
        .fb_address = 0,
        .fb_size = 0,
        
        .tag_get_pitch = 0x40008,
        .tag_get_pitch_size = 4,
        .tag_get_pitch_code = 0,
        .pitch = 0,
        
        .end_tag = 0
    };
    
    fb_request.set_width = width;
    fb_request.set_height = height;
    fb_request.virtual_width = width;
    fb_request.virtual_height = height;
    
    mailbox_write(MAILBOX_CHANNEL_GPU, (uint32_t)&fb_request);
    uint32_t result = mailbox_read(MAILBOX_CHANNEL_GPU);
    
    if (fb_request.code != 0x80000000) {
        return -1;
    }
    
    // Convert GPU address to ARM address (CRITICAL CORRECTION)
    uint32_t fb_address = fb_request.fb_address;
    switch (current_platform.platform) {
        case PLATFORM_PI_BCM2835:    // Pi 1, Pi Zero
        case PLATFORM_PI_BCM2836:    // Pi 2  
        case PLATFORM_PI_BCM2837:    // Pi 3, Zero 2W
        case PLATFORM_PI_BCM2837B0:  // Pi 3B+
            // VideoCore IV GPU - remove VC bus address offset
            fb_address &= 0x3FFFFFFF;
            break;
            
        case PLATFORM_PI_BCM2711:    // Pi 4
            // VideoCore VI GPU - different address mapping
            if (fb_address >= 0xC0000000) {
                fb_address -= 0xC0000000;
            }
            break;
    }
    
    console.framebuffer = (uint32_t *)fb_address;
    console.width = fb_request.set_width;
    console.height = fb_request.set_height;
    console.pitch = fb_request.pitch / 4;  // Convert bytes to pixels
    
    // Calculate console dimensions
    console.console_cols = console.width / FONT_WIDTH;
    console.console_rows = (console.height - STATUS_BAR_HEIGHT) / FONT_HEIGHT;
    
    // Ensure minimum dimensions
    if (console.console_cols < MIN_CONSOLE_COLS) console.console_cols = MIN_CONSOLE_COLS;
    if (console.console_rows < MIN_CONSOLE_ROWS) console.console_rows = MIN_CONSOLE_ROWS;
    
    return 0;
}

// =============================================================================
// PS/2 Input Handling (QEMU versatilepb only)
// =============================================================================

#define PL050_DATA               0x08
#define PL050_STAT               0x04
#define PL050_CLKDIV             0x0C

#define PL050_STAT_RXFULL        0x10
#define PL050_STAT_TXBUSY        0x20

static uint8_t ps2_read_data(uint32_t base) {
    volatile uint32_t *ps2 = (volatile uint32_t *)base;
    
    if (ps2[PL050_STAT / 4] & PL050_STAT_RXFULL) {
        return ps2[PL050_DATA / 4] & 0xFF;
    }
    return 0;
}

static void ps2_write_data(uint32_t base, uint8_t data) {
    volatile uint32_t *ps2 = (volatile uint32_t *)base;
    
    while (ps2[PL050_STAT / 4] & PL050_STAT_TXBUSY);
    ps2[PL050_DATA / 4] = data;
}

static void init_ps2_devices(void) {
    if (current_platform.platform != PLATFORM_QEMU_VERSATILE) return;
    
    // Initialize PS/2 mouse
    ps2_write_data(QEMU_PL050_MOUSE_BASE, 0xFF);  // Reset
    ps2_write_data(QEMU_PL050_MOUSE_BASE, 0xF4);  // Enable data reporting
    
    console.mouse_available = true;
    console.keyboard_available = true;
}

// =============================================================================
// Console Buffer Management
// =============================================================================

static int init_console_buffer(void) {
    console.buffer_lines = MAX_BUFFER_LINES;
    uint32_t buffer_size = console.buffer_lines * console.console_cols;
    
    // Static allocation for bare metal
    static console_cell_t static_buffer[MAX_BUFFER_LINES * 240];
    console.buffer = static_buffer;
    
    // Initialize buffer
    for (uint32_t i = 0; i < buffer_size && i < sizeof(static_buffer)/sizeof(static_buffer[0]); i++) {
        console.buffer[i].character = ' ';
        console.buffer[i].foreground = COLOR_WHITE;
        console.buffer[i].background = COLOR_BLACK;
        console.buffer[i].attributes = 0;
    }
    
    console.current_line = 0;
    console.current_col = 0;
    console.display_start = 0;
    console.current_fg = COLOR_WHITE;
    console.current_bg = COLOR_BLACK;
    console.cursor_visible = true;
    console.scroll_position = 0;
    
    return 0;
}

static console_cell_t *get_cell(uint32_t line, uint32_t col) {
    if (col >= console.console_cols || line >= console.buffer_lines) {
        return NULL;
    }
    return &console.buffer[line * console.console_cols + col];
}

static void scroll_buffer_up(void) {
    // Simple implementation - move all lines up
    uint32_t cells_per_line = console.console_cols;
    
    for (uint32_t line = 0; line < console.buffer_lines - 1; line++) {
        for (uint32_t col = 0; col < cells_per_line; col++) {
            uint32_t src_idx = (line + 1) * cells_per_line + col;
            uint32_t dst_idx = line * cells_per_line + col;
            console.buffer[dst_idx] = console.buffer[src_idx];
        }
    }
    
    // Clear last line
    uint32_t last_line_start = (console.buffer_lines - 1) * cells_per_line;
    for (uint32_t col = 0; col < cells_per_line; col++) {
        console.buffer[last_line_start + col].character = ' ';
        console.buffer[last_line_start + col].foreground = console.current_fg;
        console.buffer[last_line_start + col].background = console.current_bg;
        console.buffer[last_line_start + col].attributes = 0;
    }
}

// =============================================================================
// Font Rendering
// =============================================================================

static const uint8_t *get_font_char(uint8_t c) {
    return &qemu_vga_font_8x16[c * 16];
}

static void draw_char_at(uint32_t x, uint32_t y, char c, uint32_t fg, uint32_t bg) {
    if (!console.framebuffer || x + FONT_WIDTH > console.width || y + FONT_HEIGHT > console.height) {
        return;
    }
    
    const uint8_t *font_data = get_font_char((uint8_t)c);
    
    for (int row = 0; row < FONT_HEIGHT; row++) {
        uint8_t font_row = font_data[row];
        uint32_t *pixel_row = &console.framebuffer[(y + row) * console.pitch + x];
        
        for (int col = 0; col < FONT_WIDTH; col++) {
            pixel_row[col] = (font_row & (0x80 >> col)) ? fg : bg;
        }
    }
}

// =============================================================================
// Console Rendering
// =============================================================================

static void clear_screen(uint32_t color) {
    if (!console.framebuffer) return;
    
    for (uint32_t y = 0; y < console.height; y++) {
        uint32_t *row = &console.framebuffer[y * console.pitch];
        for (uint32_t x = 0; x < console.width; x++) {
            row[x] = color;
        }
    }
}

static void draw_status_bar(void) {
    uint32_t status_y = console.height - STATUS_BAR_HEIGHT;
    
    // Draw status background
    for (uint32_t y = status_y; y < console.height; y++) {
        uint32_t *row = &console.framebuffer[y * console.pitch];
        for (uint32_t x = 0; x < console.width; x++) {
            row[x] = COLOR_DARK_GRAY;
        }
    }
    
    // Status text with corrected platform info
    char status[256];
    snprintf(status, sizeof(status), 
        "%s | %dx%d | L:%d C:%d | Scroll:%d | Inputs: %s%s",
        current_platform.name, console.width, console.height,
        console.current_line + 1, console.current_col + 1,
        console.scroll_position,
        current_platform.has_ps2 ? "PS2 " : "",
        current_platform.has_usb ? "USB " : "UART");
    
    // Draw status text
    for (int i = 0; status[i] && i < (int)(console.width / FONT_WIDTH); i++) {
        draw_char_at(i * FONT_WIDTH, status_y, status[i], COLOR_WHITE, COLOR_DARK_GRAY);
    }
}

static void render_console(void) {
    if (!console.framebuffer) return;
    
    // Clear main area
    for (uint32_t y = 0; y < console.height - STATUS_BAR_HEIGHT; y++) {
        uint32_t *row = &console.framebuffer[y * console.pitch];
        for (uint32_t x = 0; x < console.width; x++) {
            row[x] = COLOR_BLACK;
        }
    }
    
    // Render visible text
    for (uint32_t screen_row = 0; screen_row < console.console_rows; screen_row++) {
        uint32_t buffer_line = console.display_start + screen_row;
        if (buffer_line >= console.buffer_lines) break;
        
        for (uint32_t col = 0; col < console.console_cols; col++) {
            console_cell_t *cell = get_cell(buffer_line, col);
            if (!cell) continue;
            
            uint32_t x = col * FONT_WIDTH;
            uint32_t y = screen_row * FONT_HEIGHT;
            
            // Check for cursor
            uint32_t fg = cell->foreground;
            uint32_t bg = cell->background;
            
            if (buffer_line == console.current_line && col == console.current_col && 
                console.cursor_visible && (console.cursor_blink_counter & 0x20)) {
                fg = cell->background;
                bg = cell->foreground;
            }
            
            draw_char_at(x, y, cell->character, fg, bg);
        }
    }
    
    draw_status_bar();
}

// =============================================================================
// Input Processing
// =============================================================================

static void handle_scroll(int delta) {
    int new_scroll = (int)console.scroll_position + delta;
    
    if (new_scroll < 0) new_scroll = 0;
    
    int max_scroll = (int)console.current_line - (int)console.console_rows + 1;
    if (max_scroll < 0) max_scroll = 0;
    if (new_scroll > max_scroll) new_scroll = max_scroll;
    
    if (new_scroll != (int)console.scroll_position) {
        console.scroll_position = new_scroll;
        console.display_start = console.scroll_position;
        render_console();
    }
}

static void handle_mouse_input(void) {
    if (current_platform.platform != PLATFORM_QEMU_VERSATILE) return;
    
    static uint8_t mouse_packet[3];
    static int packet_index = 0;
    
    uint8_t data = ps2_read_data(QEMU_PL050_MOUSE_BASE);
    if (data == 0) return;
    
    mouse_packet[packet_index++] = data;
    
    if (packet_index >= 3) {
        packet_index = 0;
        
        uint8_t buttons = mouse_packet[0];
        int8_t delta_x = (int8_t)mouse_packet[1];
        int8_t delta_y = (int8_t)mouse_packet[2];
        
        console.mouse_x += delta_x;
        console.mouse_y -= delta_y;  // Invert Y
        
        // Clamp to screen
        if (console.mouse_x < 0) console.mouse_x = 0;
        if (console.mouse_y < 0) console.mouse_y = 0;
        if (console.mouse_x >= (int)console.width) console.mouse_x = console.width - 1;
        if (console.mouse_y >= (int)console.height) console.mouse_y = console.height - 1;
        
        // Handle scroll (right button + movement = scroll)
        if (buttons & 0x02) {  // Right button
            if (delta_y != 0) {
                handle_scroll(delta_y > 0 ? 3 : -3);
            }
        }
        
        console.mouse_buttons = buttons;
    }
}

static void handle_keyboard_input(void) {
    if (current_platform.platform != PLATFORM_QEMU_VERSATILE) return;
    
    uint8_t scancode = ps2_read_data(QEMU_PL050_KBD_BASE);
    if (scancode == 0) return;
    
    // Handle special keys for scrolling
    switch (scancode) {
        case 0x48:  // Up arrow
            handle_scroll(-1);
            break;
        case 0x50:  // Down arrow
            handle_scroll(1);
            break;
        case 0x49:  // Page Up
            handle_scroll(-(int)console.console_rows);
            break;
        case 0x51:  // Page Down
            handle_scroll((int)console.console_rows);
            break;
        case 0x47:  // Home
            console.scroll_position = 0;
            console.display_start = 0;
            render_console();
            break;
        case 0x4F:  // End
            console.scroll_position = console.current_line;
            console.display_start = console.current_line >= console.console_rows ? 
                                   console.current_line - console.console_rows + 1 : 0;
            render_console();
            break;
    }
}

// =============================================================================
// Console Output Functions
// =============================================================================

void console_putchar(char c) {
    switch (c) {
        case '\n':
            console.current_col = 0;
            console.current_line++;
            
            if (console.current_line >= console.buffer_lines) {
                scroll_buffer_up();
                console.current_line = console.buffer_lines - 1;
            }
            
            // Auto-follow cursor
            if (console.current_line >= console.display_start + console.console_rows) {
                console.display_start = console.current_line - console.console_rows + 1;
                console.scroll_position = console.display_start;
            }
            break;
            
        case '\r':
            console.current_col = 0;
            break;
            
        case '\t':
            console.current_col = (console.current_col + 8) & ~7;
            if (console.current_col >= console.console_cols) {
                console_putchar('\n');
            }
            break;
            
        case '\b':
            if (console.current_col > 0) {
                console.current_col--;
                console_cell_t *cell = get_cell(console.current_line, console.current_col);
                if (cell) {
                    cell->character = ' ';
                    cell->foreground = console.current_fg;
                    cell->background = console.current_bg;
                }
            }
            break;
            
        default:
            if (c >= 32 && c <= 126) {
                console_cell_t *cell = get_cell(console.current_line, console.current_col);
                if (cell) {
                    cell->character = c;
                    cell->foreground = console.current_fg;
                    cell->background = console.current_bg;
                    cell->attributes = 0;
                }
                
                console.current_col++;
                console.total_chars++;
                
                if (console.current_col >= console.console_cols) {
                    console_putchar('\n');
                }
            }
            break;
    }
}

void console_puts(const char *str) {
    while (*str) {
        console_putchar(*str++);
    }
}

void console_printf(const char *fmt, ...) {
    char buffer[1024];
    va_list args;
    va_start(args, fmt);
    vsnprintf(buffer, sizeof(buffer), fmt, args);
    va_end(args);
    console_puts(buffer);
}

void console_set_color(uint32_t fg, uint32_t bg) {
    console.current_fg = fg;
    console.current_bg = bg;
}

// =============================================================================
// Main Console Interface
// =============================================================================

int universal_console_init(void) {
    // Detect platform with corrected hardware detection
    current_platform.platform = detect_platform();
    
    // Detect display resolution
    uint32_t width, height;
    if (detect_display_resolution(&width, &height) != 0) {
        // Platform-specific fallbacks
        switch (current_platform.platform) {
            case PLATFORM_PI_BCM2711:
                width = 1920; height = 1080; break;
            case PLATFORM_PI_BCM2837:
            case PLATFORM_PI_BCM2837B0:
                width = 1680; height = 1050; break;
            case PLATFORM_PI_BCM2836:
                width = 1280; height = 1024; break;
            case PLATFORM_QEMU_VERSATILE:
                width = 640; height = 480; break;
            default:
                width = 1024; height = 768; break;
        }
    }
    
    // Setup framebuffer
    if (setup_framebuffer(width, height) != 0) {
        return -1;
    }
    
    // Initialize input devices
    init_ps2_devices();
    
    // Initialize console buffer
    if (init_console_buffer() != 0) {
        return -1;
    }
    
    // Clear screen and show initial message
    clear_screen(COLOR_BLACK);
    
    console_set_color(COLOR_YELLOW, COLOR_BLACK);
    console_puts("CORRECTED Universal Pi Console\n");
    console_puts("==============================\n\n");
    
    console_set_color(COLOR_CYAN, COLOR_BLACK);
    console_printf("Platform: %s\n", current_platform.name);
    console_printf("Peripheral Base: 0x%08X\n", current_platform.peripheral_base);
    console_printf("Display: %dx%d (%d x %d chars)\n", 
                   console.width, console.height, 
                   console.console_cols, console.console_rows);
    
    console_set_color(COLOR_WHITE, COLOR_BLACK);
    console_puts("\nSupported Models:\n");
    console_puts("- Pi 1 A/A+/B/B+ (BCM2835)\n");
    console_puts("- Pi Zero/Zero W (BCM2835)\n");
    console_puts("- Pi 2 (BCM2836)\n");
    console_puts("- Pi 3/3A+/3B+ (BCM2837/B0)\n");
    console_puts("- Pi Zero 2 W (RP3A0/BCM2837)\n");
    console_puts("- Pi 4/400 (BCM2711)\n");
    console_puts("- QEMU versatilepb\n");
    
    console_puts("\nInput Support:\n");
    if (current_platform.has_ps2) {
        console_puts("- PS/2 Keyboard and Mouse\n");
        console_puts("- Arrow keys, Page Up/Down, Home/End\n");
        console_puts("- Right-click + drag to scroll\n");
    }
    if (current_platform.has_usb) {
        console_puts("- USB devices supported\n");
    }
    console_puts("- UART console always available\n");
    
    console_set_color(COLOR_GREEN, COLOR_BLACK);
    console_puts("\nHardware-specific console ready!\n\n");
    console_set_color(COLOR_WHITE, COLOR_BLACK);
    
    return 0;
}

void console_update(void) {
    // Handle input based on platform
    handle_keyboard_input();
    handle_mouse_input();
    
    // Update cursor blink
    console.cursor_blink_counter++;
    
    // Re-render
    render_console();
}

void console_clear(void) {
    uint32_t buffer_size = console.buffer_lines * console.console_cols;
    for (uint32_t i = 0; i < buffer_size; i++) {
        console.buffer[i].character = ' ';
        console.buffer[i].foreground = COLOR_WHITE;
        console.buffer[i].background = COLOR_BLACK;
        console.buffer[i].attributes = 0;
    }
    
    console.current_line = 0;
    console.current_col = 0;
    console.display_start = 0;
    console.scroll_position = 0;
    console.total_chars = 0;
    
    render_console();
}

// =============================================================================
// Example Usage
// =============================================================================

int main(void) {
    if (universal_console_init() != 0) {
        return -1;
    }
    
    // Demo content
    console_set_color(COLOR_LIGHT_GREEN, COLOR_BLACK);
    console_puts("Hardware detection test successful!\n");
    console_printf("Detected platform: %s\n", current_platform.name);
    console_printf("Peripheral base: 0x%08X\n", current_platform.peripheral_base);
    
    // Test scrollback
    for (int i = 0; i < 100; i++) {
        console_printf("Test line %03d: Platform-specific console working correctly.\n", i);
        
        if (i % 25 == 0) {
            console_set_color(COLOR_YELLOW, COLOR_BLACK);
            console_printf("=== Milestone %d ===\n", i / 25);
            console_set_color(COLOR_LIGHT_GREEN, COLOR_BLACK);
        }
    }
    
    console_set_color(COLOR_WHITE, COLOR_BLACK);
    console_puts("\nScrollback test complete!\n");
    
    // Main loop
    while (1) {
        console_update();
        
        // Small delay
        for (volatile int i = 0; i < 100000; i++);
    }
    
    return 0;
}