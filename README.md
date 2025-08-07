# JohnOfPatmos
An experimental bare metal raspberry pi kernel test


The Ghidra workflow should be:

Import kernel1.elf
Click "Yes" to analyze
Wait for analysis to complete
File → Configure → Debugger → Enable ARM GDB
Debugger → Debug kernel1.elf
Select "gdb via SSH" connector
Connect to localhost:1234
