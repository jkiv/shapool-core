#!/usr/bin/env python3

import sys

if __name__ == '__main__':
    namebase = 'target'
    for n in range(0, 14):
        difficulty = 2**n
        target = 32+n
        filename = f'{namebase}-{difficulty}.vh'

        with open(filename, 'w') as f:
            print(f'Writing \'{filename}\'', file=sys.stderr)
            f.writelines(f'`define TARGET {target}\n')

    print('Done!', file=sys.stderr)
