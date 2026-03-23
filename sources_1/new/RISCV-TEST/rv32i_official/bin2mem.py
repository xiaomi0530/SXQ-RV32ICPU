#!/usr/bin/env python3
"""
bin2mem.py — 将 .bin 转为 Vivado $readmemh 格式的 .mem 文件
用法: python3 bin2mem.py input.bin output.mem [depth]
  depth: IMEM 深度(字数), 默认 4096 (=16KB)
"""
import sys

def main():
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} input.bin output.mem [depth]")
        sys.exit(1)

    bin_path = sys.argv[1]
    mem_path = sys.argv[2]
    depth    = int(sys.argv[3]) if len(sys.argv) > 3 else 4096

    with open(bin_path, 'rb') as f:
        data = f.read()

    # 补齐到 4 字节对齐
    while len(data) % 4 != 0:
        data += b'\x00'

    num_words = len(data) // 4
    if num_words > depth:
        print(f"WARNING: binary has {num_words} words, exceeds depth {depth}")

    with open(mem_path, 'w') as f:
        for i in range(depth):
            if i < num_words:
                word = int.from_bytes(data[i*4:(i+1)*4], 'little')
            else:
                word = 0
            f.write(f"{word:08X}\n")

    print(f"Generated {mem_path}: {num_words} words used / {depth} total")

if __name__ == '__main__':
    main()
