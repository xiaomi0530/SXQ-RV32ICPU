#!/usr/bin/env python3
"""
gen_mem.py — 将 RV32I ELF 转换为 Verilog $readmemh 格式的 imem.mem

用法:
    python3 gen_mem.py <input.elf> <output.mem>

输出格式:
    每行一个 32-bit 大端十六进制字（8位），对应 imem.v 中 32-bit 块 RAM。
    共 8192 行（32KB / 4）。

说明:
    - 仅提取 LMA（物理地址）在 IMEM 范围 [0x00000000, 0x00008000) 的段
    - .data 段的 LMA 也在 IMEM 中，会被正确放置（VMA 在 DMEM 但存储在 IMEM）
    - 其余地址的段（如 .bss VMA 在 DMEM）不占 IMEM 空间，被忽略
"""

import sys
import struct
import os


IMEM_BASE = 0x00000000
IMEM_SIZE = 32 * 1024          # 32 KB = 8192 × 4-byte words
IMEM_WORDS = IMEM_SIZE // 4    # 8192


def parse_elf32_le(data: bytes):
    """
    解析 32-bit little-endian ELF，返回 PT_LOAD 段列表:
        [(p_paddr, p_filesz, p_memsz, segment_bytes), ...]
    """
    magic = data[0:4]
    if magic != b'\x7fELF':
        raise ValueError(f"不是 ELF 文件 (magic={magic.hex()})")

    ei_class = data[4]
    if ei_class != 1:
        raise ValueError(f"需要 32-bit ELF (ELFCLASS32=1), 实际 ei_class={ei_class}")

    ei_data = data[5]
    if ei_data != 1:
        raise ValueError(f"需要小端 ELF (ELFDATA2LSB=1), 实际 ei_data={ei_data}")

    # ELF32 头偏移
    e_phoff    = struct.unpack_from('<I', data, 28)[0]   # Program header offset
    e_phentsize = struct.unpack_from('<H', data, 42)[0]  # Entry size
    e_phnum    = struct.unpack_from('<H', data, 44)[0]   # Entry count

    segments = []
    for i in range(e_phnum):
        base = e_phoff + i * e_phentsize
        p_type   = struct.unpack_from('<I', data, base +  0)[0]
        p_offset = struct.unpack_from('<I', data, base +  4)[0]
        p_vaddr  = struct.unpack_from('<I', data, base +  8)[0]
        p_paddr  = struct.unpack_from('<I', data, base + 12)[0]
        p_filesz = struct.unpack_from('<I', data, base + 16)[0]
        p_memsz  = struct.unpack_from('<I', data, base + 20)[0]

        if p_type == 1:  # PT_LOAD
            seg_bytes = data[p_offset : p_offset + p_filesz]
            segments.append((p_paddr, p_filesz, p_memsz, seg_bytes))
            print(f"  PT_LOAD  paddr=0x{p_paddr:08x}  vaddr=0x{p_vaddr:08x}"
                  f"  filesz={p_filesz:6d}  memsz={p_memsz:6d}")

    return segments


def build_imem_image(segments) -> bytearray:
    """将所有 LMA 在 IMEM 窗口内的段填充到 32KB 镜像。"""
    image = bytearray(IMEM_SIZE)

    for paddr, filesz, memsz, seg_bytes in segments:
        # 只处理 LMA 落在 IMEM 范围内的段
        if paddr < IMEM_BASE or paddr >= IMEM_BASE + IMEM_SIZE:
            print(f"  跳过段 paddr=0x{paddr:08x}（不在 IMEM 范围）")
            continue

        offset = paddr - IMEM_BASE
        avail  = IMEM_SIZE - offset
        copy_n = min(filesz, avail)

        if copy_n < filesz:
            print(f"  警告: 段 paddr=0x{paddr:08x} 超出 IMEM 末端，已截断"
                  f" ({filesz} → {copy_n} 字节)")

        image[offset : offset + copy_n] = seg_bytes[:copy_n]
        print(f"  已加载  paddr=0x{paddr:08x}  {copy_n} 字节"
              f"  → imem[0x{offset:04x}..0x{offset+copy_n-1:04x}]")

    return image


def write_memh(image: bytearray, out_path: str):
    """按 $readmemh 格式写出：每行一个 8 位十六进制 32-bit 字（小端存储→自然顺序）。"""
    with open(out_path, 'w') as f:
        for i in range(IMEM_WORDS):
            word = struct.unpack_from('<I', image, i * 4)[0]
            f.write(f"{word:08x}\n")


def check_size(image: bytearray, segments):
    """统计并打印 IMEM 使用量。"""
    used = 0
    for paddr, filesz, _, _ in segments:
        if IMEM_BASE <= paddr < IMEM_BASE + IMEM_SIZE:
            used += filesz
    pct = used * 100 // IMEM_SIZE
    print(f"\nIMEM 使用: {used} / {IMEM_SIZE} 字节 ({pct}%)")
    if used > IMEM_SIZE:
        print("!! 错误: IMEM 超出 32KB 限制 !!")
        sys.exit(1)
    elif pct > 90:
        print("!! 警告: IMEM 使用率 > 90%，空间紧张 !!")


def main():
    if len(sys.argv) != 3:
        print(f"用法: {sys.argv[0]} <input.elf> <output.mem>")
        sys.exit(1)

    elf_path = sys.argv[1]
    mem_path = sys.argv[2]

    if not os.path.isfile(elf_path):
        print(f"错误: 找不到 ELF 文件 '{elf_path}'")
        sys.exit(1)

    with open(elf_path, 'rb') as f:
        elf_data = f.read()

    print(f"解析 ELF: {elf_path}  ({len(elf_data)} 字节)")
    print("PT_LOAD 段:")
    segments = parse_elf32_le(elf_data)

    print("\n构建 IMEM 镜像:")
    image = build_imem_image(segments)

    check_size(image, segments)

    write_memh(image, mem_path)
    print(f"\n已写出 {IMEM_WORDS} 行到: {mem_path}")
    print("请将 imem.mem 放入 Vivado 仿真工作目录（sim/ 或项目根目录）。")


if __name__ == '__main__':
    main()
