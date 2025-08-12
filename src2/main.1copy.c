#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#include "7379ab5047b143c0b6cfe5d8d79ad240b4b4f8cced55aa26f86d1d3d370c0d4c.gpg.h"
#include "passwordpasswordpasswordpasswordpasswordpasswordpasswordpassword.gpg.h"
#include "fwddecl.h"
#include "gpg.h"

// Helper function to verify memory is wiped
void verify_wiped(void *ptr, size_t len) {
    unsigned char *p = (unsigned char *)ptr;
    for (size_t i = 0; i < len; i++) {
        if (p[i] != 0) {
            printf("Memory not properly wiped at offset %zu: 0x%02x\n", i, p[i]);
            return;
        }
    }
    printf("Memory verification passed: all %zu bytes are zero\n", len);
}

// Custom strcpy implementation
void my_strcpy(char *dest, const char *src) {
    while (*src) {
        *dest++ = *src++;
    }
    *dest = '\0';
}

// // Mock decrypt_memory function - replace with actual implementation if available
// int decrypt_memory(ctrl_t ctrl, const unsigned char *encrypted_data, size_t data_len) {
//     printf("Mock decrypt_memory called:\n");
//     printf("  - Control structure at: %p\n", (void*)ctrl);
//     printf("  - Encrypted data length: %zu bytes\n", data_len);
    
//     if (ctrl->session_key) {
//         printf("  - Using session key (direct decryption)\n");
//         // Mock successful decryption with session key
//         printf("  - Mock: Successfully decrypted with session key\n");
//         return 0;  // Success
//     } else if (ctrl->passphrase) {
//         printf("  - Using passphrase (KDF-based decryption)\n");
//         printf("  - Passphrase: %s\n", ctrl->passphrase);
//         // Mock successful decryption with passphrase
//         printf("  - Mock: Successfully decrypted with passphrase\n");
//         return 0;  // Success
//     }
    
//     return 2;  // Failure
// }

// Unified decryption function
int unified_decrypt(ctrl_t ctrl, const unsigned char *session_key, size_t key_len,
                    const char *passphrase, const unsigned char *encrypted_data,
                    size_t data_len) {
    if (!ctrl || !encrypted_data || data_len == 0) {
        printf("Invalid arguments to decrypt_data\n");
        return -1;
    }

    // Clean up any existing keys/passphrases first
    if (ctrl->session_key) {
        wipememory(ctrl->session_key, 32);
        free(ctrl->session_key);
        ctrl->session_key = NULL;
    }
    if (ctrl->passphrase) {
        wipememory(ctrl->passphrase, strlen(ctrl->passphrase));
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
    }
    else if (passphrase) {
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
        printf("DEBUG: Passphrase pointer: %p\n", (void *)ctrl->passphrase);
        printf("Using KDF with passphrase\n");
    }
    else {
        printf("Error: Either session_key or passphrase must be provided\n");
        return -1;
    }

    // Add guard values for debugging
    uint32_t guard1 = 0xDEADBEEF;
    uint32_t guard2 = 0xBABECAFE;
    printf("Guard values before decrypt: 0x%08X 0x%08X\n", guard1, guard2);

    // Print function pointer address to detect any runtime changes
    printf("DEBUG: _gcry_cipher_cfb_decrypt address check\n");

    // Perform the decryption
    int rc = decrypt_memory(ctrl, encrypted_data, data_len);

    // Check guard values after decryption
    printf("Guard values after decrypt: 0x%08X 0x%08X\n", guard1, guard2);

    // Clean up allocated memory with secure wiping
    if (ctrl->session_key) {
        wipememory(ctrl->session_key, key_len);
        free(ctrl->session_key);
        ctrl->session_key = NULL;
    }
    if (ctrl->passphrase) {
        wipememory(ctrl->passphrase, strlen(ctrl->passphrase));
        free(ctrl->passphrase);
        ctrl->passphrase = NULL;
    }

    if (rc == 2) {
        printf("Decryption failed with code: %d\n", rc);
        return rc;
    }

    printf("Decryption successful!\n");
    return 0;
}

int main() {
    printf("=== Starting dual decryption test with SEPARATE control structures ===\n\n");

    // Allocate TWO SEPARATE control structures from the start
    ctrl_t ctrl1 = malloc(sizeof(struct server_control_s));
    ctrl_t ctrl2 = malloc(sizeof(struct server_control_s));
    
    if (!ctrl1 || !ctrl2) {
        printf("Failed to allocate control structures\n");
        goto cleanup;
    }
    
    // Initialize BOTH control structures to zero
    memset(ctrl1, 0, sizeof(struct server_control_s));
    memset(ctrl2, 0, sizeof(struct server_control_s));
    
    printf("ctrl1 allocated at: %p\n", (void*)ctrl1);
    printf("ctrl2 allocated at: %p\n", (void*)ctrl2);
    printf("Distance between ctrl1 and ctrl2: %ld bytes\n", 
           (char*)ctrl2 - (char*)ctrl1);

    // Allocate TWO SEPARATE key buffers as well
    unsigned char *key_buffer1 = malloc(32);
    unsigned char *key_buffer2 = malloc(32);
    
    if (!key_buffer1 || !key_buffer2) {
        printf("Failed to allocate key buffers\n");
        goto cleanup;
    }

    // ========== First Decryption with ctrl1 ==========
    printf("\n--- Test 1: Password-based file decryption (using ctrl1) ---\n");

    // Set up first key in key_buffer1
    const unsigned char key_bytes_password[] = {
        0xaa, 0x26, 0x54, 0x2a, 0xfd, 0x6f, 0x97, 0x09,
        0x82, 0xee, 0xdb, 0x0c, 0xa8, 0x47, 0x7f, 0xd7
    };
    memcpy(key_buffer1, key_bytes_password, sizeof(key_bytes_password));

    int rc1 = unified_decrypt(ctrl1, key_buffer1, sizeof(key_bytes_password), NULL,
                              __passwordpasswordpasswordpasswordpasswordpasswordpasswordpassword_gpg,
                              __passwordpasswordpasswordpasswordpasswordpasswordpasswordpassword_gpg_len);

    printf("First decryption result: %d\n", rc1);

    // ========== Second Decryption with ctrl2 (COMPLETELY SEPARATE) ==========
    printf("\n--- Test 2: WikiLeaks file decryption (using ctrl2) ---\n");

    // Set up second key in key_buffer2
    const unsigned char key_bytes_wikileaks[] = {
        0x42, 0x7c, 0x02, 0x8e, 0x28, 0xee, 0xb1, 0x54,
        0x64, 0xc3, 0x76, 0xd7, 0xdc, 0xca, 0x6c, 0xa2
    };
    memcpy(key_buffer2, key_bytes_wikileaks, sizeof(key_bytes_wikileaks));

    int rc2 = unified_decrypt(ctrl2, key_buffer2, sizeof(key_bytes_wikileaks), NULL,
                              __7379ab5047b143c0b6cfe5d8d79ad240b4b4f8cced55aa26f86d1d3d370c0d4c_gpg,
                              __7379ab5047b143c0b6cfe5d8d79ad240b4b4f8cced55aa26f86d1d3d370c0d4c_gpg_len);

    printf("Second decryption result: %d\n", rc2);

    printf("\n=== All decryption tests completed ===\n");
    printf("Both decryptions should have succeeded with same code paths\n");
    printf("Press Enter to exit...\n");
    getchar();  // Wait for user input before closing console window

cleanup:
    // Clean up with secure wiping
    if (ctrl1) {
        printf("Cleaning ctrl1\n");
        wipememory(ctrl1, sizeof(struct server_control_s));
        free(ctrl1);
    }
    
    if (ctrl2) {
        printf("Cleaning ctrl2\n");
        wipememory(ctrl2, sizeof(struct server_control_s));
        free(ctrl2);
    }

    if (key_buffer1) {
        wipememory(key_buffer1, 32);
        free(key_buffer1);
    }
    
    if (key_buffer2) {
        wipememory(key_buffer2, 32);
        free(key_buffer2);
    }

    return 0;
}