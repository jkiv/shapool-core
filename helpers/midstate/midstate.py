import argparse
import binascii
import ctypes
import fileinput
from os import path
import sys

_midstate_so_name = "midstate.so"
_midstate_so_path = path.abspath(path.join(path.dirname(__file__), _midstate_so_name))
_midstate = ctypes.CDLL(_midstate_so_path)

def _ffi(ffi, function_name, return_type, arg_types):
    fn = ffi.__getattr__(function_name)
    fn.restype = return_type
    fn.argtypes = arg_types
    return fn

class ShaState:
    def __init__(self):
        new_state = _ffi(_midstate, 'new_state', ctypes.POINTER(ctypes.c_uint32), None)
        self._state = new_state()
    
    def __del__(self):
        free_state = _ffi(_midstate, 'free_state', None, [ctypes.POINTER(ctypes.c_uint32),])
        free_state(self._state)

    def update(self, block):
        if len(block) < 32:
            block = block + b'\0'*(32-len(block))

        assert(len(block) == 32)
        update_state = _ffi(_midstate, 'update_state', None, [ctypes.POINTER(ctypes.c_uint32), ctypes.c_char_p,])
        update_state(self._state, block)

    def as_b64(self):
        return binascii.b2a_base64(self.as_bin()).decode('utf-8')

    def as_hex(self):
        return binascii.b2a_hex(self.as_bin()).decode('utf-8')

    def as_bin(self):
        return bytes(self._state)


def stream_blocks(stream, block_size=32):
    while True:
        block_data = stream.read(block_size)

        yield block_data

        if not block_data:
            return

def get_midstate(stream, last_block=None):

    state = ShaState()

    for n, block_data in enumerate(stream_blocks(stream)):
        # Inject block data into hash function
        if block_data is not None:
            state.update(block_data)

        if last_block is None:
            if block_data is None:
                # Return hash function state
                return state
        else:
            if n == last_block:
                # Return hash function state
                return state

    return state
    raise ValueError("Stream ended before reaching block {last_block}.")

if __name__ == '__main__':

    parser = argparse.ArgumentParser(description='Compute the internal state of a SHA256 hash.')

    parser.add_argument('-i', '--input-file', type=str, help='input file (default: stdin)', default=None)
    parser.add_argument('-o', '--output-file', type=str, help='output file (default: stdout)', default=None)
    parser.add_argument('-b', '--block', type=int, help='return the state after specified block number (zero-indexed, default: last block).')

    output_format = parser.add_mutually_exclusive_group(required=False)
    output_format.add_argument('--bin', help='Output as binary.', action='store_true', default=True)
    output_format.add_argument('--hex', help='Output as ASCII in hexadecimal.', action='store_true', default=False)
    output_format.add_argument('--b64', help='Output as ASCII in base-64.', action='store_true', default=False)

    args = parser.parse_args()

    print(args)

    if args.block and args.block < 0:
        raise ValueError("Block number must be >= 0.")

    state = None

    if args.input_file is None:
        state = get_midstate(sys.stdin.buffer, args.block)
    else:
        with open(args.input_file, 'rb') as s:
            state = get_midstate(s, args.block)

    if args.output_file is None:
        s = sys.stdout

        if args.bin:
            s.buffer.write(state.as_bin())
        elif args.hex:
            s.write(state.as_hex())
        elif args.b64:
            s.write(state.as_b64())

    else:
        with open(args.output_file, 'wb') as s:
            if args.bin:
                s.write(state.as_bin())
            elif args.hex:
                s.write(state.as_hex())
            elif args.b64:
                s.write(state.as_b64())
