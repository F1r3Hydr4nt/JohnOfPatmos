set pagination off
target remote :1234
break unified_decrypt
commands
  silent
  if $decrypt_count == 0
    dump memory results/memory_before.bin 0x8000 0x20000
    set $decrypt_count = 1
  else
    dump memory results/memory_after.bin 0x8000 0x20000
  end
  continue
end
set $decrypt_count = 0
continue
