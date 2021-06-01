import argparse
import binascii
import functools
import hashlib
import struct
import sys
from collections.abc import Iterator
import toml
 
def _wat_get_difficulty(bits: int) -> str:
    # https://en.bitcoin.it/wiki/Difficulty
    exp = bits >> 24
    mant = bits & 0xffffff
    target_hexstr = '%064x' % (mant * (1<<(8*(exp - 3))))
    target_str = target_hexstr.decode('hex')

@functools.lru_cache
def get_difficulty_bm(size: int) -> bytes:
    assert(size >= 0 and size <= 32*8)

    bin_mask = ('1' * size) + ('0' * (32*8-size))

    return bytes(int(bin_mask[i:i+8], 2) for i in range(0, 32*8, 8))


def make_header(version: int, previous_block: bytes, merkel_root: bytes, time: int, bits: int) -> bytes:
    return struct.pack("<L", version) + \
           previous_block + \
           merkel_root + \
           struct.pack("<LL", time, bits)

def break_header(header: bytes, has_nonce: bool=False) -> dict:
    version = slice(0,4)
    previous_block = slice(4,36)
    merkel_root = slice(36,68)
    time = slice(68,72)
    bits = slice(72,76)
    nonce = slice(76,80)

    return {
        "version": header[version],
        "previous_block": header[previous_block],
        "merkel_root": header[merkel_root],
        "time": header[time],
        "bits": header[bits],
        "nonce": header[nonce] if has_nonce else None
    }

def test_hash_leading_zeroes(hash: bytes, target_zeroes: int = 64) -> bool:
    zero_mask = get_difficulty_bm(target_zeroes)
    return all(b & byte_mask == 0 for b, byte_mask in zip(hash, zero_mask))

def compute_hash(header: bytes) -> bytes:
    return hashlib.sha256(hashlib.sha256(header).digest()).digest()

def compute_nonce(header: bytes, leading_zeroes: int = 64, nonce_gen: Iterator = None) -> int:

    assert(len(header) == 76)

    if nonce_gen is None:
        nonce_gen = range(2**32)

    for nonce in nonce_gen:
        hash = compute_hash(header + struct.pack("<L", nonce))

        if test_hash_leading_zeroes(hash[::-1], leading_zeroes):
            return nonce

    return None

def verify_nonce(header: bytes, nonce: int, leading_zeroes: int = 64) -> bytes:
    assert(len(header) == 76)

    header = header + struct.pack("<L", nonce)
    hash = compute_hash(header)

    return test_hash_leading_zeroes(hash[::-1], leading_zeroes)

# TODO
# Compute nonce given data and difficulty
# Check given data, nonce, and difficulty
# -- read from file
# -- read from stdin

#   verify [-f <case>] <DIFFICULTY> --> compute nonce
#   verify [-f <case>] <DIFFICULTY> <NONCE> --> check nonce
#   verify [-f <case>] --> print case in blocks
#   verify [-f <case>] -- <VERSION> <PREV_BLOCK> <MRKL_ROOT>

EXAMPLE_TOML = '''# Example TOML
version = 2
previous_block = "000000000000000117c80378b8da0e33559b5997f2ad55e2f7d18ec1975b9717"
merkel_root = "871714dcbae6c8193a2bb9b2a69fe1c0440399f38d94b3a0f1b447275a29978a"
time = 0x53058b35
bits = 0x19015f53
'''

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="")

    parser.add_argument("difficulty", type=int, help="number of leading zeroes to check hash against")
    parser.add_argument("-c", "--case", type=str, required=False, help="path to toml file containing case data (default: stdin)")

    group = parser.add_mutually_exclusive_group()
    group.add_argument("-n", "--nonce", type=int, required=False, help="nonce to verify")
    group.add_argument("-r", "--range", type=str, required=False, help="set of nonce values to check (comma-separated values or start:end)")

    args = parser.parse_args()

    # Load case
    case = None

    if args.case and args.case != '-':
        case = toml.load(args.case)
    else:
        case = toml.load(sys.stdin)

    # TODO validate `case`
    
    case["previous_block"] = binascii.a2b_hex(case["previous_block"])[::-1]
    case["merkel_root"]    = binascii.a2b_hex(case["merkel_root"])[::-1]

    header = make_header(**case)

    # Run case
    if args.nonce:
        # Verify nonce
        valid = verify_nonce(header, args.nonce, args.difficulty)

        if not valid:
            print(f"Invalid nonce: {args.nonce}", file=sys.stderr)
            sys.exit(1)
        else:
            sys.exit(0)

    else:

        # Interpret nonce range
        nonce_gen = None
        if args.range:
            if ',' in args.range:
                nonce_gen = [int(n.strip()) for n in args.range.split(',')]
            elif ':' in args.range:
                start, end = (int(x) for x in args.range.split(':', 1))
                nonce_gen = range(start, end)

        # Compute nonce
        nonce = compute_nonce(header, args.difficulty, nonce_gen)

        if nonce is None:
            print("No solution found.", file=sys.stderr)
            sys.exit(1)
        else:
            print(nonce)
            sys.exit(0)
