/* build-packet.c - minimal version with only used functions */

#include <stdio.h>
#include <stdint.h>
#include "printf.h"

void log_hexdump(const uint8_t *buffer, int length) {
    char text[17];
    int written = 0;
    
    printf("%d bytes:\n", length);
    while (length > 0) {
        int have = (length > 16) ? 16 : length;
        
        printf("%-8d ", written);
        
        for (int i = 0; i < 16; i++) {
            if (i % 2 == 0) printf(" ");
            if (i % 8 == 0) printf(" ");
            
            if (i < have) {
                printf("%02x", buffer[i]);
            } else {
                printf("  ");
            }
        }
        
        printf("  ");
        for (int i = 0; i < have; i++) {
            text[i] = (buffer[i] >= 32 && buffer[i] <= 126) ? buffer[i] : '.';
        }
        text[have] = '\0';
        printf("%s\n", text);
        
        buffer += have;
        length -= have;
        written += have;
    }
}