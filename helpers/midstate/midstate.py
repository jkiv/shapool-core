import argparse
import binascii
import ctypes
from os import path
import sys

_midstate = ctypes.CDLL(path.abspath(path.join(path.dirname(__file__), "midstate_sha256.so")))

def _ffi(ffi, function_name, return_type, arg_types):
    fn = ffi.__getattr__(function_name)
    fn.restype = return_type
    fn.argtypes = arg_types
    return fn

class ShaState:
    def __init__(self):
        self._state = ctypes.create_string_buffer(32)
        _init_state = _ffi(_midstate, 'init_state', None, [ctypes.c_char_p,])
        _init_state(self._state)

    def __del__(self):
        del self._state

    def update(self, block):
        _update_state = _ffi(_midstate, 'update_state', None, [ctypes.c_char_p, ctypes.c_char_p,])
        _update_state(self._state, block)

    def as_b64(self, byte_swap=False):
        return binascii.b2a_base64(self.as_bin(byte_swap)).decode('utf-8')

    def as_hex(self, byte_swap=False):
        return binascii.b2a_hex(self.as_bin(byte_swap)).decode('utf-8')

    def as_bin(self, byte_swap=False):
        result = bytes(self._state)
        if byte_swap:
            return result[3::-1] + result[7:3:-1] + \
                   result[11:7:-1] + result[15:11:-1] + \
                   result[19:15:-1] + result[23:19:-1] + \
                   result[27:23:-1] + result[31:27:-1]
        else:
            return result

def stream_blocks(stream, block_size=64):
    while True:
        block_data = stream.read(block_size)

        if not block_data or block_size != len(block_data):
            return

        yield block_data

def get_midstate(stream, last_block=None):

    state = ShaState()

    for n, block_data in enumerate(stream_blocks(stream)):
        state.update(block_data)

        if n == last_block:
            return state

    if last_block:
        raise RuntimeError(f'Stream closed before reaching block {last_block}. Last block was {n}.')
    
    return state

if __name__ == '__main__':

    parser = argparse.ArgumentParser(description='Compute intermediate states of a SHA256 hash.')

    parser.add_argument('-i', '--input-file', type=str, help='input file (default: stdin)', default=None)
    parser.add_argument('-o', '--output-file', type=str, help='output file (default: stdout)', default=None)
    parser.add_argument('-b', '--block', type=int, help='return the state after specified block number (zero-indexed, default: last full block).')

    output_format = parser.add_mutually_exclusive_group(required=False)
    output_format.add_argument('--hex', help='Output as hexadecimal.', action='store_true', default=True)
    output_format.add_argument('--base64', help='Output as Base64.', action='store_true', default=False)
    output_format.add_argument('--bin', help='Output as binary.', action='store_true', default=False)

    args = parser.parse_args()

    if args.block and args.block < 0:
        raise ValueError("Block number must be >= 0.")

    if args.input_file is None:
        state = get_midstate(sys.stdin.buffer, args.block)
    else:
        with open(args.input_file, 'rb') as s:
            state = get_midstate(s, args.block)

    if args.output_file is None:
        s = sys.stdout

        if args.bin:
            s.buffer.write(state.as_bin())
        elif args.base64:
            s.write(state.as_b64())
        elif args.hex:
            s.write(state.as_hex() + u'\n')

    else:
        with open(args.output_file, 'wb') as s:
            if args.bin:
                s.write(state.as_bin())
            elif args.base64:
                s.write(state.as_b64().rstrip(u'\n'))
            elif args.hex:
                s.write(state.as_hex())
