# GDB Script Generated from Debug Information
# This script sets breakpoints on functions and watchpoints on global variables
# with dynamic monitoring for unexpected changes

# GDB Settings
set pagination off
set print pretty on
set print array on
set print elements 100
set confirm off

#============================================================
# MONITORING SETUP
#============================================================

python
import gdb
import struct

# Dictionary to store expected addresses and values
expected_functions = {}
expected_values = {}
watch_history = {}

def check_function_address(name, expected_addr):
    """Check if function is still at expected address."""
    try:
        # Try to get address using & operator
        actual = gdb.parse_and_eval(f'&{name}')
        actual_str = str(actual).split()[0]  # Get just the address part
        # Normalize addresses for comparison
        if '0x' in actual_str:
            actual_addr = actual_str
        else:
            actual_addr = hex(int(actual_str))
        # Compare normalized addresses
        if actual_addr.lower() != expected_addr.lower():
            # Check if it's just a formatting difference
            try:
                if int(actual_addr, 16) == int(expected_addr, 16):
                    return True  # Same address, different format
            except:
                pass
            print(f'\n*** WARNING: Function {name} moved!')
            print(f'    Expected: {expected_addr}')
            print(f'    Actual:   {actual}')
            return False
    except Exception as e:
        # If & doesn't work, try without it (for function pointers)
        try:
            actual = gdb.parse_and_eval(name)
            actual_str = str(actual).split()[0]
            if '0x' in actual_str:
                actual_addr = actual_str
            else:
                actual_addr = hex(int(actual_str))
            if actual_addr.lower() != expected_addr.lower():
                try:
                    if int(actual_addr, 16) == int(expected_addr, 16):
                        return True
                except:
                    pass
                print(f'\n*** WARNING: Function {name} moved!')
                print(f'    Expected: {expected_addr}')
                print(f'    Actual:   {actual}')
                return False
        except:
            print(f'\n*** WARNING: Cannot find function {name}')
            return False
    return True

def monitor_value_change(name, old_val, new_val, pc):
    """Alert on value changes with context."""
    frame = gdb.selected_frame()
    func_name = frame.name() if frame.name() else 'unknown'
    
    print(f'\n' + '='*60)
    print(f'*** WATCHPOINT HIT: {name} changed!')
    print(f'    Old value: {old_val}')
    print(f'    New value: {new_val}')
    print(f'    Changed by: {func_name} at {pc}')
    
    # Store in history
    if name not in watch_history:
        watch_history[name] = []
    watch_history[name].append({
        'old': old_val,
        'new': new_val,
        'function': func_name,
        'pc': str(pc)
    })
    
    # Check for suspicious patterns
    # Python 3 compatibility - no 'long' type
    try:
        old_int = int(old_val)
        new_int = int(new_val)
        if new_int == 0 and old_int != 0:
            print('    *** ALERT: Value zeroed out!')
        elif abs(new_int - old_int) > 0x10000:
            print('    *** ALERT: Large value jump detected!')
    except (ValueError, TypeError):
        pass  # Values aren't integers
    
    print('='*60 + '\n')

def show_watch_history():
    """Display history of all watched variable changes."""
    if not watch_history:
        print('No watchpoint hits recorded yet.')
        return
    
    for var, changes in watch_history.items():
        print(f'\nHistory for {var}:')
        for i, change in enumerate(changes, 1):
            print(f'  {i}. {change["old"]} -> {change["new"]} by {change["function"]} @ {change["pc"]}')

class WatchpointHandler(gdb.Command):
    """Custom watchpoint handler with notifications."""
    def __init__(self):
        super().__init__('monitor-watches', gdb.COMMAND_USER)
    
    def invoke(self, arg, from_tty):
        show_watch_history()

WatchpointHandler()
end

#============================================================
# FUNCTION BREAKPOINTS WITH VERIFICATION
#============================================================

# Function: decrypt_memory
break decrypt_memory
commands
  silent
  python check_function_address('decrypt_memory', '0x0000b82c')
  printf "\n[BREAK] Hit decrypt_memory at %s\n", $pc
  backtrace 3
end

python expected_functions['decrypt_memory'] = '0x0000b82c'

# Function: decrypt_data
break decrypt_data
commands
  silent
  python check_function_address('decrypt_data', '0x0000bb24')
  printf "\n[BREAK] Hit decrypt_data at %s\n", $pc
  backtrace 3
end

python expected_functions['decrypt_data'] = '0x0000bb24'

# Function: passphrase_to_dek
break passphrase_to_dek
commands
  silent
  python check_function_address('passphrase_to_dek', '0x000155f0')
  printf "\n[BREAK] Hit passphrase_to_dek at %s\n", $pc
  backtrace 3
end

python expected_functions['passphrase_to_dek'] = '0x000155f0'

# Function: proc_encrypted
break proc_encrypted
commands
  silent
  python check_function_address('proc_encrypted', '0x00015b5c')
  printf "\n[BREAK] Hit proc_encrypted at %s\n", $pc
  backtrace 3
end

python expected_functions['proc_encrypted'] = '0x00015b5c'

#============================================================
# GLOBAL VARIABLE WATCHPOINTS WITH MONITORING
#============================================================

# Global: heap @ 0x0001ac70 (size: 0x4)
watch *(int*)0x0001ac70
# Watching heap as int
commands
  silent
  set $old_val = *(int*)0x0001ac70
  set $new_val = *(int*)0x0001ac70
  python monitor_value_change('heap', gdb.parse_and_eval('$old_val'), gdb.parse_and_eval('$new_val'), gdb.parse_and_eval('$pc'))
  continue
end

# Global: __7379ab5047b143c0b6cfe5d8d79ad240b4b4f8cced55aa26f86d1d3d370c0d4c_gpg @ 0x0001ad74 (size: 0x154f2)
rwatch *(char*)0x0001ad74
# Read watchpoint on large variable __7379ab5047b143c0b6cfe5d8d79ad240b4b4f8cced55aa26f86d1d3d370c0d4c_gpg
commands
  silent
  set $old_val = *(long*)0x0001ad74
  set $new_val = *(long*)0x0001ad74
  python monitor_value_change('__7379ab5047b143c0b6cfe5d8d79ad240b4b4f8cced55aa26f86d1d3d370c0d4c_gpg', gdb.parse_and_eval('$old_val'), gdb.parse_and_eval('$new_val'), gdb.parse_and_eval('$pc'))
  continue
end

# Global: __7379ab5047b143c0b6cfe5d8d79ad240b4b4f8cced55aa26f86d1d3d370c0d4c_gpg_len @ 0x00030268 (size: 0x4)
watch *(int*)0x00030268
# Watching __7379ab5047b143c0b6cfe5d8d79ad240b4b4f8cced55aa26f86d1d3d370c0d4c_gpg_len as int
commands
  silent
  set $old_val = *(int*)0x00030268
  set $new_val = *(int*)0x00030268
  python monitor_value_change('__7379ab5047b143c0b6cfe5d8d79ad240b4b4f8cced55aa26f86d1d3d370c0d4c_gpg_len', gdb.parse_and_eval('$old_val'), gdb.parse_and_eval('$new_val'), gdb.parse_and_eval('$pc'))
  continue
end

# Global: __passwordpasswordpasswordpasswordpasswordpasswordpasswordpassword_gpg @ 0x0003026c (size: 0x154f2)
rwatch *(char*)0x0003026c
# Read watchpoint on large variable __passwordpasswordpasswordpasswordpasswordpasswordpasswordpassword_gpg
commands
  silent
  set $old_val = *(long*)0x0003026c
  set $new_val = *(long*)0x0003026c
  python monitor_value_change('__passwordpasswordpasswordpasswordpasswordpasswordpasswordpassword_gpg', gdb.parse_and_eval('$old_val'), gdb.parse_and_eval('$new_val'), gdb.parse_and_eval('$pc'))
  continue
end

# Global: __passwordpasswordpasswordpasswordpasswordpasswordpasswordpassword_gpg_len @ 0x00045760 (size: 0x4)
watch *(int*)0x00045760
# Watching __passwordpasswordpasswordpasswordpasswordpasswordpasswordpassword_gpg_len as int
commands
  silent
  set $old_val = *(int*)0x00045760
  set $new_val = *(int*)0x00045760
  python monitor_value_change('__passwordpasswordpasswordpasswordpasswordpasswordpasswordpassword_gpg_len', gdb.parse_and_eval('$old_val'), gdb.parse_and_eval('$new_val'), gdb.parse_and_eval('$pc'))
  continue
end

#============================================================
# CONVENIENCE COMMANDS
#============================================================

# Show all monitored variables
define show-monitored
  printf "\n=== Monitored Variables ===\n"
  printf "heap: "
  p/x *(int*)0x0001ac70
  printf "__7379ab5047b143c0b6cfe5d8d79ad240b4b4f8cced55aa26f86d1d3d370c0d4c_gpg: "
  p/x *(long*)0x0001ad74
  printf "__7379ab5047b143c0b6cfe5d8d79ad240b4b4f8cced55aa26f86d1d3d370c0d4c_gpg_len: "
  p/x *(int*)0x00030268
  printf "__passwordpasswordpasswordpasswordpasswordpasswordpasswordpassword_gpg: "
  p/x *(long*)0x0003026c
  printf "__passwordpasswordpasswordpasswordpasswordpasswordpasswordpassword_gpg_len: "
  p/x *(int*)0x00045760
  printf "\n=== Function Addresses ===\n"
  printf "decrypt_memory: "
  p/a &decrypt_memory
  printf "decrypt_data: "
  p/a &decrypt_data
  printf "passphrase_to_dek: "
  p/a &passphrase_to_dek
  printf "proc_encrypted: "
  p/a &proc_encrypted
end

# Show watchpoint history
define show-history
  python show_watch_history()
end

# Verify all function addresses
define verify-functions
  printf "\n=== Verifying Function Addresses ===\n"
  python
for name, addr in expected_functions.items():
    if check_function_address(name, addr):
        print(f'{name}: OK')
  end
end

# Summary command
define debug-status
  printf "\n=== Debug Status ===\n"
  printf "Breakpoints set: 4\n"
  printf "Watchpoints set: 5\n"
  printf "\nType 'show-monitored' to see current values\n"
  printf "Type 'show-history' to see change history\n"
  printf "Type 'verify-functions' to check function addresses\n"
end

# Initial setup message
printf "\n"
printf "========================================\n"
printf "   GDB Debug Script Loaded\n"
printf "   Monitoring 4 functions\n"
printf "   Watching 5 variables\n"
printf "========================================\n"
printf "\n"
printf "Commands available:\n"
printf "  debug-status    - Show monitoring status\n"
printf "  show-monitored  - Display all monitored values\n"
printf "  show-history    - Show change history\n"
printf "  verify-functions - Verify function addresses\n"
printf "  check-integrity - Manual integrity check\n"
printf "\n"

