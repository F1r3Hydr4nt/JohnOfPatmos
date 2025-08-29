#include <stdint.h>
#include <stddef.h>
#include "printf.h"
#include <string.h>
#ifdef SUCCESS
    #include "passwordpasswordpasswordpasswordpasswordpasswordpasswordpassword.gpg.h"
#else
    #include "7379ab5047b143c0b6cfe5d8d79ad240b4b4f8cced55aa26f86d1d3d370c0d4c.gpg.h"
#endif
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
void print_memory_map(void);
void wipememory(void *ptr, size_t len);
int decrypt_gpg(ctrl_t ctrl, const unsigned char *session_key, size_t key_len, const unsigned char *encrypted_data,
                    size_t data_len);

size_t strlen(const char *str)
{
    const char *s;
    for (s = str; *s; ++s)
        ;
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


/**
 * Unified decryption function
 * @param ctrl Control structure
 * @param session_key Pre-computed session key (can be NULL to force KDF)
 * @param key_len Length of session key (ignored if session_key is NULL)
 * @param encrypted_data The encrypted data to decrypt
 * @param data_len Length of encrypted data
 * @return 0 on success, negative on error
 */
int decrypt_gpg(ctrl_t ctrl, const unsigned char *session_key, size_t key_len, const unsigned char *encrypted_data,
                    size_t data_len)
{
    // Force memory synchronization at function entry
    __asm__ __volatile__("dmb" ::: "memory");
    // Allocate and set session key
    ctrl->session_key = malloc(key_len);
    memcpy(ctrl->session_key, session_key, key_len);
    // Add guard values for debugging
    uint32_t guard1 = 0xDEADBEEF;
    uint32_t guard2 = 0xBABECAFE;
    printf("Guard values before decrypt: 0x%08X 0x%08X\n", guard1, guard2);
    // void *decrypt_mem_fn = (void*) decrypt_memory;
    // Memory barrier before the critical call
    __asm__ __volatile__("dmb" ::: "memory");
    __asm__ __volatile__("dsb" ::: "memory");
    // Perform the decryption
    int rc = decrypt_memory(ctrl, encrypted_data, data_len);

    // Check guard values after decryption
    printf("Guard values after decrypt: 0x%08X 0x%08X\n", guard1, guard2);

    // Clean up allocated memory with secure wiping
    if (ctrl->session_key)
    {
        wipememory(ctrl->session_key, key_len);
        free(ctrl->session_key);
        ctrl->session_key = NULL;
    }
    
    if (rc == 2)
    {
        printf("Decryption failed with code: %d\n", rc);
        return rc;
    }

    printf("Decryption successful!\n");
    return 0;
}

void main()
{
    init_printf(0, putc_uart);
    ctrl_t ctrl1 = malloc(sizeof(struct server_control_s));
    memset(ctrl1, 0, sizeof(struct server_control_s));
    unsigned char *key_buffer1 = malloc(32);
    memcpy(key_buffer1, gpg_key_bytes, sizeof(gpg_key_bytes));
    int rc1 = decrypt_gpg(ctrl1, key_buffer1, sizeof(gpg_key_bytes),gpg_file,gpg_file_len);
    printf("Exit via: CTRL-A + X\n");

cleanup:
    // Clean up with secure wiping
    if (ctrl1)
    {
        wipememory(ctrl1, sizeof(struct server_control_s));
        free(ctrl1);
    }
    
    while (1)
    {
        __asm__("wfi");
    }
}