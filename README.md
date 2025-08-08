# JohnOfPatmos
An experimental bare metal raspberry pi kernel test


====== PREPARING KERNEL1 FOR GHIDRA DEBUGGING ======
# Generate symbol information and analysis files
Generating symbol tables and analysis files...
arm-none-eabi-nm -n build/kernel1.elf > results/kernel1_symbols.txt
arm-none-eabi-objdump -t build/kernel1.elf > results/kernel1_symbol_table.txt
arm-none-eabi-readelf -a build/kernel1.elf > results/kernel1_elf_info.txt
arm-none-eabi-objdump -D build/kernel1.elf > results/kernel1_full_disasm.txt

====== FILES READY FOR GHIDRA ======
  Kernel Binary: build/kernel1.img
  Kernel ELF:    build/kernel1.elf (import this for best symbol support)
  Symbols:       results/kernel1_symbols.txt
  Disassembly:   results/kernel1_full_disasm.txt

🔧 GHIDRA SETUP STEPS:
  1. Import: build/kernel1.elf into Ghidra (analyze when prompted)
  2. Debugger → Launch kernel1.elf using → qemu-system + gdb
  3. Configuration:
     - Image: build/kernel1.img
     - QEMU command: qemu-system-arm
     - Extra qemu arguments: -M versatilepb -cpu cortex-a7 -nographic -serial mon:stdio -kernel /home/freddie/JohnOfPatmos/build/kernel1.img -d int,guest_errors,mmu -D /home/freddie/JohnOfPatmos/results/ghidra_debug.txt
     - gdb command: gdb-multiarch
     - Architecture: arm (not auto)
     - Port: 1234
  4. Click Launch

📋 IN GDB CONSOLE (for symbols):
  symbol-file build/kernel1.elf
  # Or use addresses from results/kernel1_symbols.txt:
  break *0x800c    # main function
  continue


# PROOF
  $fuckyou$fuckyou #SmokingGun #DefinitiveProof of Compiler Backdoor or Runtime Sabotage

