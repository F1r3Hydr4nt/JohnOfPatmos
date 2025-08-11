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
