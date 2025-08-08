#include <stdint.h>
#include <stddef.h>
#include "printf.h"
#include <string.h>
#include "7379ab5047b143c0b6cfe5d8d79ad240b4b4f8cced55aa26f86d1d3d370c0d4c.gpg.h"
#include "passwordpasswordpasswordpasswordpasswordpasswordpasswordpassword.gpg.h"
#include "fwddecl.h"
#include "gpg.h"

// QEMU Versatile PB UART0 address
#define UART0_DR *((volatile uint32_t *)0x101f1000)

extern char __text_start[], __text_end[];
extern char __data_start[], __data_end[];
extern char __rodata_start[], __rodata_end[];
extern char __bss_start[], __bss_end[];

// Function prototypes
void uart_putc(char c);
void putc_uart(void *p, char c);
void putc_uart2(void *p, char c);
void print_memory_map(void);
int unified_decrypt(ctrl_t ctrl, const unsigned char *session_key, size_t key_len, 
                    const char *passphrase, const unsigned char *encrypted_data, 
                    size_t data_len);

size_t strlen(const char *str)
{
    const char *s;
    for (s = str; *s; ++s);
    return (s - str);
}

void uart_putc(char c)
{
    UART0_DR = c;
}

void putc_uart(void *p, char c)
{
    (void)p;
    uart_putc(c);
}

void putc_uart2(void *p, char c)
{
    (void)p;
    uart_putc(c);
}

/**
 * Unified decryption function
 * @param ctrl Control structure
 * @param session_key Pre-computed session key (can be NULL to force KDF)
 * @param key_len Length of session key (ignored if session_key is NULL)
 * @param passphrase Passphrase for KDF (can be NULL if session_key provided)
 * @param encrypted_data The encrypted data to decrypt
 * @param data_len Length of encrypted data
 * @return 0 on success, negative on error
 */
int unified_decrypt(ctrl_t ctrl, const unsigned char *session_key, size_t key_len, 
                    const char *passphrase, const unsigned char *encrypted_data, 
                    size_t data_len)
{
    if (!ctrl || !encrypted_data || data_len == 0) {
        printf("Invalid arguments to decrypt_data\n");
        return -1;
    }

    // Clean up any existing keys/passphrases first
    if (ctrl->session_key) {
        free(ctrl->session_key);
        ctrl->session_key = NULL;
    }
    if (ctrl->passphrase) {
        free(ctrl->passphrase);
        ctrl->passphrase = NULL;
    }

    // Determine decryption method based on provided arguments
    if (session_key && key_len > 0) {
        printf("=== Attempting decryption with provided session key ===\n");
        
        // Allocate and set session key
        ctrl->session_key = malloc(key_len);
        if (!ctrl->session_key) {
            printf("Failed to allocate session_key\n");
            return -1;
        }
        
        memcpy(ctrl->session_key, session_key, key_len);
        printf("Session key set, length: %zu bytes\n", key_len);
        
    } else if (passphrase) {
        printf("=== Attempting decryption with KDF passphrase ===\n");
        
        size_t pass_len = strlen(passphrase);
        
        // Allocate and set passphrase
        ctrl->passphrase = malloc(pass_len + 1);
        if (!ctrl->passphrase) {
            printf("Failed to allocate passphrase\n");
            return -1;
        }
        
        my_strcpy(ctrl->passphrase, passphrase);
        printf("DEBUG: Passphrase set: %s (len: %zu)\n", ctrl->passphrase, strlen(ctrl->passphrase));
        printf("DEBUG: Passphrase pointer: %p\n", (void*)ctrl->passphrase);
        printf("Using KDF with passphrase\n");
        
    } else {
        printf("Error: Either session_key or passphrase must be provided\n");
        return -1;
    }
    
    // Add guard values for debugging
    uint32_t guard1 = 0xDEADBEEF;
    uint32_t guard2 = 0xBABECAFE;
    printf("Guard values before decrypt: 0x%08X 0x%08X\n", guard1, guard2);
    
    // Perform the decryption
    int rc = decrypt_memory(ctrl, encrypted_data, data_len);
    
    // Check guard values after decryption
    printf("Guard values after decrypt: 0x%08X 0x%08X\n", guard1, guard2);
    
    // Clean up allocated memory
    if (ctrl->session_key) {
        free(ctrl->session_key);
        ctrl->session_key = NULL;
    }
    if (ctrl->passphrase) {
        free(ctrl->passphrase);
        ctrl->passphrase = NULL;
    }
    
    if (rc) {
        printf("Decryption failed with code: %d\n", rc);
        return rc;
    }
    
    printf("Decryption successful!\n");
    return 0;
}

void main()
{
    init_printf(0, putc_uart);
    
    printf("Starting decryption tests...\n\n");
    
    // Define the session key
    const unsigned char key_bytes[] = {
        0xaa, 0x26, 0x54, 0x2a, 0xfd, 0x6f, 0x97, 0x09,
        0x82, 0xee, 0xdb, 0x0c, 0xa8, 0x47, 0x7f, 0xd7
    };
    
    const char *test_passphrase = "passwordpasswordpasswordpasswordpasswordpasswordpasswordpassword";
    
    // Test 1: Try decryption with session key
    ctrl_t ctrl1 = malloc(sizeof(struct server_control_s));
    if (!ctrl1) {
        printf("Failed to allocate control structure for test 1\n");
        goto cleanup;
    }
    memset(ctrl1, 0, sizeof(struct server_control_s));
    
    int rc1 = unified_decrypt(ctrl1, key_bytes, sizeof(key_bytes), NULL,
                          __passwordpasswordpasswordpasswordpasswordpasswordpasswordpassword_gpg,
                          __passwordpasswordpasswordpasswordpasswordpasswordpasswordpassword_gpg_len);
    
    free(ctrl1);
    ctrl1 = NULL;
    
    printf("Cleaned up first test, freed control structure\n\n");
    
    // Test 2: Try decryption with KDF passphrase
    ctrl_t ctrl2 = malloc(sizeof(struct server_control_s));
    if (!ctrl2) {
        printf("Failed to allocate control structure for test 2\n");
        goto cleanup;
    }
    memset(ctrl2, 0, sizeof(struct server_control_s));
    
    int rc2 = unified_decrypt(ctrl2, NULL, 0, test_passphrase,
                          __passwordpasswordpasswordpasswordpasswordpasswordpasswordpassword_gpg,
                          __passwordpasswordpasswordpasswordpasswordpasswordpasswordpassword_gpg_len);
    
    printf("\n=== Results Summary ===\n");
    printf("Session key decryption: %s\n", rc1 == 0 ? "SUCCESS" : "FAILED");
    printf("KDF decryption: %s\n", rc2 == 0 ? "SUCCESS" : "FAILED");
    
    printf("Hello World!\nCTRL-A + X\n");

cleanup:
    // Clean up control structure if it exists
    if (ctrl2) {
        free(ctrl2);
    }
    
    while (1) {
        __asm__("wfi");
    }
}