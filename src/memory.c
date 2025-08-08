#include "memory.h"
#include "printf.h"

// External symbols from linker script
extern char __heap_start[], __heap_end[];

// Memory allocator definitions
#define HEAP_SIZE (__heap_end - __heap_start)  // Use linker-defined heap (2MB)
#define BLOCK_SIZE 16          // Minimum block size
#define MAX_BLOCKS (HEAP_SIZE / BLOCK_SIZE)

// Block header structure
typedef struct block_header {
    size_t size;  // Size including header
    uint8_t is_free;
    struct block_header* next;
} block_header_t;

// Use linker-defined heap instead of static array
static uint8_t* heap = (uint8_t*)__heap_start;
static block_header_t* free_list = NULL;
static uint8_t heap_initialized = 0;

// Debug function to print heap state
void print_heap_debug(void) {
    if (!heap_initialized) {
        printf("Heap not initialized\n");
        return;
    }
    
    printf("=== Heap Debug ===\n");
    block_header_t* curr = free_list;
    size_t total_free = 0;
    size_t largest_free = 0;
    int block_count = 0;
    
    while (curr) {
        printf("Block %d: addr=%p, size=%zu, free=%d\n", 
               block_count, (void*)curr, curr->size, curr->is_free);
        
        if (curr->is_free) {
            total_free += curr->size;
            if (curr->size > largest_free) {
                largest_free = curr->size;
            }
        }
        
        curr = curr->next;
        block_count++;
        
        // Safety check to prevent infinite loops
        if (block_count > 1000) {
            printf("ERROR: Too many blocks, possible corruption\n");
            break;
        }
    }
    
    printf("Total free: %zu bytes, Largest free block: %zu bytes\n", 
           total_free, largest_free);
    printf("==================\n");
}

// Initialize heap
static void init_heap(void) {
    if (heap_initialized) return;
    
    free_list = (block_header_t*)heap;
    free_list->size = HEAP_SIZE;
    free_list->is_free = 1;
    free_list->next = NULL;
    
    heap_initialized = 1;
    printf("Heap initialized: %zu KB at %p\n", HEAP_SIZE/1024, (void*)heap);
}

// Memory allocation
void* malloc(size_t size) {
    if (!heap_initialized) init_heap();
    if (size == 0) return NULL;
    
    // Align size to BLOCK_SIZE
    size_t total_size = (size + sizeof(block_header_t) + (BLOCK_SIZE-1)) & ~(BLOCK_SIZE-1);
    
    block_header_t *curr = free_list;
    
    // Find first fit
    while (curr) {
        if (curr->is_free && curr->size >= total_size) {
            // Split block if too large
            if (curr->size >= total_size + BLOCK_SIZE + sizeof(block_header_t)) {
                block_header_t* next = (block_header_t*)((uint8_t*)curr + total_size);
                next->size = curr->size - total_size;
                next->is_free = 1;
                next->next = curr->next;
                curr->size = total_size;
                curr->next = next;
            }
            
            curr->is_free = 0;
            void* ptr = (void*)((uint8_t*)curr + sizeof(block_header_t));
            printf("malloc(%zu) -> %p (total_size=%zu)\n", size, ptr, total_size);
            return ptr;
        }
        curr = curr->next;
    }
    
    printf("malloc(%zu) FAILED - no space available\n", size);
    print_heap_debug();
    return NULL;  // No space found
}

// Fixed memory deallocation
void free(void* ptr) {
    if (!ptr) return;
    
    block_header_t* header = (block_header_t*)((uint8_t*)ptr - sizeof(block_header_t));
    
    // Sanity check - make sure this looks like a valid header
    if ((uint8_t*)header < heap || (uint8_t*)header >= heap + HEAP_SIZE) {
        printf("free(%p) - invalid pointer, header at %p outside heap\n", ptr, (void*)header);
        return;
    }
    
    printf("free(%p) - freeing block of size %zu\n", ptr, header->size);
    header->is_free = 1;
    
    // Forward coalescing - merge with next block if it's free
    if (header->next && header->next->is_free && 
        (uint8_t*)header + header->size == (uint8_t*)header->next) {
        printf("Coalescing forward: %zu + %zu = %zu\n", 
               header->size, header->next->size, header->size + header->next->size);
        header->size += header->next->size;
        header->next = header->next->next;
    }
    
    // Backward coalescing - find previous block and merge if possible
    block_header_t* prev = NULL;
    block_header_t* curr = free_list;
    
    // Find the previous block
    while (curr && curr != header) {
        if (curr->is_free && (uint8_t*)curr + curr->size == (uint8_t*)header) {
            // Found previous block that can be coalesced
            printf("Coalescing backward: %zu + %zu = %zu\n", 
                   curr->size, header->size, curr->size + header->size);
            curr->size += header->size;
            curr->next = header->next;
            return; // We're done
        }
        prev = curr;
        curr = curr->next;
    }
    
    // If we get here, no backward coalescing was possible
    // The block is already marked as free and forward coalescing is done
}

// Rest of the memory functions remain the same...
void* xmalloc(size_t n) {
    void* ptr;

    if (n == 0)
        n = 1;
        
    ptr = malloc(n);
    
    if (!ptr) {
        printf("xmalloc failed to allocate %zu bytes\n", n);
        print_heap_debug();
        return NULL;
    }
    
    memset(ptr, 0, n);
    return ptr;
}

void* xmalloc_clear(size_t n) {
    void* ptr = malloc(n);
    if (ptr) {
        memset(ptr, 0, n);
    } else if (n != 0) {
        printf("xmalloc_clear failed to allocate %zu bytes\n", n);
        print_heap_debug();
    }
    return ptr;
}

void* xcalloc(size_t n, size_t m) {
    size_t total;
    void* ptr;
    
    if (n && m > SIZE_MAX / n) {
        return NULL;
    }
    
    total = n * m;
    ptr = malloc(total);
    
    if (ptr) {
        memset(ptr, 0, total);
    }
    
    return ptr;
}

void xfree(void* p) {
    if (p) {
        free(p);
    }
}

void* xrealloc(void* p, size_t n) {
    void* new_ptr;
    
    if (!p) {
        return malloc(n);
    }
    
    if (n == 0) {
        free(p);
        return NULL;
    }
    
    block_header_t* header = (block_header_t*)((uint8_t*)p - sizeof(block_header_t));
    size_t old_size = header->size - sizeof(block_header_t);
    
    if (n <= old_size) {
        return p;
    }
    
    new_ptr = malloc(n);
    if (!new_ptr) {
        return NULL;
    }
    
    memcpy(new_ptr, p, old_size);
    free(p);
    
    return new_ptr;
}

// Rest of the functions remain the same...
void* memset(void* dest, int c, size_t n) {
    unsigned char* p = dest;
    while (n--) {
        *p++ = (unsigned char)c;
    }
    return dest;
}

void* memcpy(void* dest, const void* src, size_t n) {
    unsigned char* d = dest;
    const unsigned char* s = src;
    while (n--) {
        *d++ = *s++;
    }
    return dest;
}

void* memmove(void* dest, const void* src, size_t n) {
    unsigned char* d = (unsigned char*)dest;
    const unsigned char* s = (const unsigned char*)src;
    if (d > s && d < s + n) {
        d += n;
        s += n;
        while (n--) {
            *--d = *--s;
        }
    } else {
        while (n--) {
            *d++ = *s++;
        }
    }
    return dest;
}

void wipememory(void *ptr, size_t len) {
    volatile char *p = (volatile char *)ptr;
    while (len--)
        *p++ = 0;
}

void strcpy(char *dest, const char *src) {
    while ((*dest++ = *src++) != '\0');
}

void *xtrycalloc(size_t nmemb, size_t size) {
    if (nmemb && size && (nmemb * size) / nmemb != size) {
        return NULL;
    }
    
    size_t total = nmemb * size;
    void *ptr = malloc(total);
    
    if (ptr) {
        memset(ptr, 0, total);
    }
    
    return ptr;
}

int open(const char *pathname, int flags, ...) {
    if (strcmp(pathname, "stdout") == 0) return 1;
    if (strcmp(pathname, "stdin") == 0) return 0;
    return -1;
}

char *strchr(const char *s, int c) {
    while (*s != (char)c) {
        if (!*s++)
            return NULL;
    }
    return (char *)s;
}

int strcmp(const char *s1, const char *s2) {
    while (*s1 && (*s1 == *s2)) {
        s1++;
        s2++;
    }
    return *(const unsigned char*)s1 - *(const unsigned char*)s2;
}

char *strdup(const char *s) {
    size_t len = strlen(s) + 1;
    char *new = malloc(len);
    if (new) {
        memcpy(new, s, len);
    }
    return new;
}

char *xstrdup(const char *string) {
    char *p = strdup(string);
    if (!p) {
        while(1); // Hang
    }
    return p;
}
