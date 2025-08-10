# GDB Script Generated from Debug Information
# This script sets breakpoints on functions and watchpoints on global variables

# GDB Settings
set pagination off
set print pretty on
set print array on
set print elements 100

#============================================================
# FUNCTION BREAKPOINTS
#============================================================

# Text segment functions (T/t)
# Skipping startup function: _start
# Skipping startup function: __text_start
break init_heap  # Size: 0xd8
break init_printf  # Size: 0x4c
break gpg_error_from_syserror  # Size: 0x1c
break fd_cache_strcmp  # Size: 0xd0
break fd_cache_invalidate  # Size: 0x10c
break fd_cache_synchronize  # Size: 0x10c
break direct_open  # Size: 0x104
break fd_cache_open  # Size: 0x11c
break block_filter  # Size: 0xcc8
break iobuf_desc  # Size: 0x90
break print_chain  # Size: 0xc8
break iobuf_alloc  # Size: 0x138
break iobuf_temp_with_content  # Size: 0xac
break do_iobuf_fdopen  # Size: 0x188
break iobuf_fdopen  # Size: 0x34
break iobuf_ioctl  # Size: 0x488
break iobuf_push_filter  # Size: 0x3c
break iobuf_push_filter2  # Size: 0x2ac
break iobuf_pop_filter  # Size: 0x3d8
break underflow  # Size: 0x34
break underflow_target  # Size: 0x3e8
break filter_flush  # Size: 0x1b0
break iobuf_readbyte  # Size: 0x108
break iobuf_read  # Size: 0x278
break iobuf_writebyte  # Size: 0x11c
break iobuf_write  # Size: 0x184
break iobuf_tell  # Size: 0x34
break iobuf_set_partial_body_length_mode  # Size: 0x118
break translate_file_handle  # Size: 0x28
break iobuf_skip_rest  # Size: 0x1a0
break file_filter  # Size: 0x380
break log_hexdump  # Size: 0x234
break gpg_error_from_syserror  # Size: 0x1c
break decrypt_memory  # Size: 0x1bc
break gpg_err_make  # Size: 0x54
break gpg_error  # Size: 0x2c
break gpg_error_from_syserror  # Size: 0x1c
break release_dfx_context  # Size: 0xa0
break decrypt_data  # Size: 0x62c
break fill_buffer  # Size: 0x1d4
break decode_filter  # Size: 0x1a8
break free_packet  # Size: 0xac
break free_packet  # Size: 0xac
break buf_get_le32  # Size: 0xb8
break buf_put_le32  # Size: 0x84
break cipher_block_cpy  # Size: 0x144
break cipher_block_xor_n_copy_2  # Size: 0x270
break buf_xor_n_copy_2  # Size: 0x14c
break buf_xor_n_copy  # Size: 0x44
break cipher_block_xor_n_copy  # Size: 0x44
break buf_xor  # Size: 0x1a4
break _gcry_cipher_setkey  # Size: 0xf4
break _gcry_cipher_setiv  # Size: 0x6c
break cipher_sync  # Size: 0x8c
break _gcry_cipher_decrypt  # Size: 0xb0
break ascii_dump  # Size: 0x74
break _gcry_cast5_cfb_dec  # Size: 0x284
break _gcry_blocksize_shift  # Size: 0x24
break _gcry_cipher_cfb_decrypt  # Size: 0x5a0
break bytesFromBlock  # Size: 0xdc
break g  # Size: 0x4c
break splitI  # Size: 0x78
break printBlock  # Size: 0x40
break sumMod2_32b  # Size: 0x30
break subtractMod2_32b  # Size: 0x5c
break cyclicShift  # Size: 0x44
break run  # Size: 0x2cc8
break encrypt  # Size: 0x4c
break blockFromBytes  # Size: 0xbc
break print_heap_debug  # Size: 0x100
break malloc  # Size: 0x14c
break free  # Size: 0x1dc
break xmalloc  # Size: 0x80
break xmalloc_clear  # Size: 0x74
break xcalloc  # Size: 0x88
break xfree  # Size: 0x30
break xrealloc  # Size: 0xc8
break memset  # Size: 0x64
break memcpy  # Size: 0x74
break memmove  # Size: 0xfc
break wipememory  # Size: 0x5c
break strcpy  # Size: 0x58
break xtrycalloc  # Size: 0x9c
break open  # Size: 0x84
break strchr  # Size: 0x64
break strcmp  # Size: 0x80
break strdup  # Size: 0x5c
break xstrdup  # Size: 0x3c
break gpg_err_make  # Size: 0x54
break gpg_error  # Size: 0x2c
break gpg_err_code  # Size: 0x28
break buf32_to_ulong  # Size: 0x6c
break read_32  # Size: 0x238
break dbg_parse_packet  # Size: 0x94
break parse  # Size: 0xba0
break copy_packet  # Size: 0x1a4
break parse_marker  # Size: 0x2b4
break parse_symkeyenc  # Size: 0x9b8
break parse_plaintext  # Size: 0x5f8
break parse_encrypted  # Size: 0x3c8
break parse_mdc  # Size: 0x184
break size2a  # Size: 0x10c
break uli2a  # Size: 0x13c
break li2a  # Size: 0x60
break ui2a  # Size: 0x13c
break i2a  # Size: 0x60
break a2d  # Size: 0x94
break a2i  # Size: 0xc0
break ptr2a  # Size: 0x3c
break putchw  # Size: 0xe8
break size_t2a  # Size: 0x13c
break tfp_format  # Size: 0x530
break tfp_printf  # Size: 0x58
break putcp  # Size: 0x44
break tfp_sprintf  # Size: 0x5c
break SHA1Transform  # Size: 0x2664
break SHA1Init  # Size: 0x8c
break SHA1Update  # Size: 0x17c
break SHA1Final  # Size: 0x17c
break my_strcpy  # Size: 0x58
break strlen  # Size: 0x54
break uart_putc  # Size: 0x34
break putc_uart  # Size: 0x30
break unified_decrypt  # Size: 0x408
break main  # Size: 0x36c
break gpg_err_make  # Size: 0x54
break gpg_error  # Size: 0x2c
break gpg_err_code  # Size: 0x28
break my_strcpy  # Size: 0x58
break derive_key  # Size: 0x1c0
break passphrase_to_dek  # Size: 0x37c
break proc_symkey_enc  # Size: 0x224
break proc_encrypted  # Size: 0x314
break proc_packets  # Size: 0x80
break proc_encryption_packets  # Size: 0x78
break check_nesting  # Size: 0x90
break do_proc_packets  # Size: 0x438
break *0x0001900c
break *0x0001900c

#============================================================
# GLOBAL VARIABLE WATCHPOINTS
#============================================================

# Initialized data (D/d)
watch heap  # Size: 0x4 bytes
# Large variable (>8 bytes): watch *0x0001d8a4  # Size: 0x100 bytes
# Skipping special symbol: __7379ab5047b143c0b6cfe5d8d79ad240b4b4f8cced55aa26f86d1d3d370c0d4c_gpg
# Skipping special symbol: __7379ab5047b143c0b6cfe5d8d79ad240b4b4f8cced55aa26f86d1d3d370c0d4c_gpg_len

# Uninitialized data (B/b)
# Skipping special symbol: __bss_start
watch close_cache  # Size: 0x4 bytes
watch iobuf_debug_mode  # Size: 0x4 bytes


#============================================================
# CONVENIENCE COMMANDS
#============================================================

# Define a command to print all watched variables
define print-watched
  printf "\nheap: "
  p/x heap
  printf "\npkt_type_str.0: "
  p/x pkt_type_str
end

# Define a command to show current function
define where-am-i
  info frame
  list
end

