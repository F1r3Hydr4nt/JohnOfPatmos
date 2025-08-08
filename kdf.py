import hashlib
import os
import argparse
import sys
from typing import Optional, Tuple, Union
from enum import IntEnum

class S2KMode(IntEnum):
    SIMPLE = 0      # Simple S2K
    SALTED = 1      # Salted S2K
    ITER_SALTED = 3 # Iterated Salted S2K

class OpenPGPKDF:
    def __init__(self, hash_algo: str = 'sha1'):
        """Initialize the KDF with specified hash algorithm."""
        self.hash_algo = hash_algo
    
    def _hash_function(self, data: bytes) -> bytes:
        """Create a new hash object and return the digest of data."""
        h = hashlib.new(self.hash_algo)
        h.update(data)
        return h.digest()
    
    def decode_count(self, encoded_count: int) -> int:
        """
        Decode the S2K iteration count from its encoded form.
        The count is encoded in a single octet using a sliding scale.
        Count = (16 + (encoded_count & 15)) << ((encoded_count >> 4) + 6)
        """
        if encoded_count < 0 or encoded_count > 255:
            raise ValueError("Invalid encoded count")
            
        # RFC 4880 specifies that count = (16 + (encoded_count & 15)) << ((encoded_count >> 4) + 6)
        count = (16 + (encoded_count & 15)) << ((encoded_count >> 4) + 6)
        return count
    
    def derive_key(self, 
                  passphrase: str,
                  key_length: int,
                  mode: S2KMode = S2KMode.ITER_SALTED,
                  salt: Optional[bytes] = None,
                  count: Optional[int] = None) -> Tuple[bytes, bytes]:
        """
        Derive a key using OpenPGP S2K specification.
        
        Args:
            passphrase: The passphrase to derive the key from
            key_length: The desired length of the output key in bytes
            mode: S2K mode (0 = Simple, 1 = Salted, 3 = Iterated+Salted)
            salt: 8-byte salt (required for modes 1 and 3)
            count: Iteration count (required for mode 3)
            
        Returns:
            Tuple of (derived_key, salt)
        """
        if not isinstance(passphrase, str):
            raise TypeError("Passphrase must be a string")
            
        passphrase_bytes = passphrase.encode('utf-8')
        
        if mode in (S2KMode.SALTED, S2KMode.ITER_SALTED):
            if salt is None:
                salt = os.urandom(8)  # Generate random 8-byte salt
            elif len(salt) != 8:
                raise ValueError("Salt must be exactly 8 bytes")
        
        # Buffer to accumulate the derived key material
        derived_key = bytearray()
        
        # Counter for the hash prefix (OpenPGP specification)
        prefix_counter = 0
        
        while len(derived_key) < key_length:
            if mode == S2KMode.SIMPLE:
                # Simple S2K: just hash the passphrase
                prefix = bytes([prefix_counter]) if prefix_counter > 0 else b''
                hash_input = prefix + passphrase_bytes
                derived_key.extend(self._hash_function(hash_input))
                
            elif mode == S2KMode.SALTED:
                # Salted S2K: hash(salt + passphrase)
                prefix = bytes([prefix_counter]) if prefix_counter > 0 else b''
                hash_input = prefix + salt + passphrase_bytes
                derived_key.extend(self._hash_function(hash_input))
                
            elif mode == S2KMode.ITER_SALTED:
                if count is None:
                    raise ValueError("Iteration count required for mode 3")
                
                # Iterated Salted S2K
                prefix = bytes([prefix_counter]) if prefix_counter > 0 else b''
                base_data = prefix + salt + passphrase_bytes
                
                # Create an extended buffer for iteration
                data_to_hash = bytearray()
                remaining_bytes = count
                
                while remaining_bytes > 0:
                    if remaining_bytes > len(base_data):
                        data_to_hash.extend(base_data)
                        remaining_bytes -= len(base_data)
                    else:
                        data_to_hash.extend(base_data[:remaining_bytes])
                        remaining_bytes = 0
                
                derived_key.extend(self._hash_function(bytes(data_to_hash)))
            
            prefix_counter += 1
        
        # Trim to the requested key length
        return bytes(derived_key[:key_length]), salt if salt else b''

def parse_salt(salt_str: str) -> bytes:
    """Parse salt from hex string or comma-separated integers."""
    salt_str = salt_str.strip()
    
    # Try hex format first
    if salt_str.startswith('0x'):
        salt_str = salt_str[2:]
    
    # Check if it's hex format
    try:
        salt_bytes = bytes.fromhex(salt_str)
        if len(salt_bytes) == 8:
            return salt_bytes
    except ValueError:
        pass
    
    # Try comma-separated format
    try:
        salt_list = [int(x.strip()) for x in salt_str.split(',')]
        if len(salt_list) == 8 and all(0 <= x <= 255 for x in salt_list):
            return bytes(salt_list)
    except ValueError:
        pass
    
    raise ValueError("Salt must be 8 bytes in hex format (e.g., '0a0b0c0d0e0f1011') or comma-separated integers (e.g., '10,11,12,13,14,15,16,17')")

def main():
    parser = argparse.ArgumentParser(
        description="OpenPGP Key Derivation Function (S2K)",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Basic usage with password, coded count, and salt
  python %(prog)s -p "passwordpasswordpasswordpasswordpasswordpasswordpasswordpassword" -c 255 -s "0a0b0c0d0e0f1011"
  
  # Using comma-separated salt values
  python %(prog)s -p "mypassword" -c 255 -s "10,11,12,13,14,15,16,17"
  
  # Specify key length and hash algorithm
  python %(prog)s -p "mypassword" -c 255 -s "0a0b0c0d0e0f1011" -l 32 --hash sha256
  
  # Use different S2K mode
  python %(prog)s -p "mypassword" -c 255 -s "0a0b0c0d0e0f1011" -m 1
        """
    )
    
    parser.add_argument(
        '-p', '--password',
        required=True,
        help='Password/passphrase for key derivation'
    )
    
    parser.add_argument(
        '-c', '--coded-count',
        type=int,
        required=True,
        help='Coded iteration count (0-255)'
    )
    
    parser.add_argument(
        '-s', '--salt',
        required=True,
        help='8-byte salt in hex format (e.g., "0a0b0c0d0e0f1011") or comma-separated integers (e.g., "10,11,12,13,14,15,16,17")'
    )
    
    parser.add_argument(
        '-l', '--key-length',
        type=int,
        default=16,
        help='Desired key length in bytes (default: 16)'
    )
    
    parser.add_argument(
        '-m', '--mode',
        type=int,
        choices=[0, 1, 3],
        default=3,
        help='S2K mode: 0=Simple, 1=Salted, 3=Iterated+Salted (default: 3)'
    )
    
    parser.add_argument(
        '--hash',
        default='sha1',
        help='Hash algorithm (default: sha1)'
    )
    
    parser.add_argument(
        '-v', '--verbose',
        action='store_true',
        help='Show detailed output'
    )
    
    args = parser.parse_args()
    
    try:
        # Validate and parse inputs
        if args.coded_count < 0 or args.coded_count > 255:
            raise ValueError("Coded count must be between 0 and 255")
        
        salt_bytes = parse_salt(args.salt)
        
        if args.key_length <= 0:
            raise ValueError("Key length must be positive")
        
        # Create KDF instance
        kdf = OpenPGPKDF(hash_algo=args.hash)
        
        # Get actual iteration count from coded count
        iteration_count = kdf.decode_count(args.coded_count)
        
        # Derive the key
        mode = S2KMode(args.mode)
        key, used_salt = kdf.derive_key(
            passphrase=args.password,
            key_length=args.key_length,
            mode=mode,
            salt=salt_bytes,
            count=iteration_count if mode == S2KMode.ITER_SALTED else None
        )
        
        # Output results
        if args.verbose:
            print(f"Parameters:")
            print(f"  Password: '{args.password}'")
            print(f"  Coded count: {args.coded_count}")
            print(f"  Actual iteration count: {iteration_count:,}")
            print(f"  Salt (hex): {used_salt.hex()}")
            print(f"  Key length: {args.key_length} bytes")
            print(f"  S2K mode: {mode.name}")
            print(f"  Hash algorithm: {args.hash}")
            print(f"")
            print(f"Derived key (hex): {key.hex()}")
            print(f"Derived key (bytes): {list(key)}")
        else:
            print(key.hex())
    
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()