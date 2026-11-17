"""Reject 64-bit ELF libraries whose LOAD segments cannot support 16 KB pages."""
import argparse
from pathlib import Path
import struct
import zipfile


def verify_elf(data):
    if data[:6] != b'\x7fELF\x02\x01':
        raise ValueError('Expected a little-endian 64-bit ELF library')
    offset = struct.unpack_from('<Q', data, 32)[0]
    entry_size, count = struct.unpack_from('<HH', data, 54)
    if entry_size < 56 or not count:
        raise ValueError('Missing ELF program headers')
    loads = 0
    for index in range(count):
        header = offset + index * entry_size
        kind = struct.unpack_from('<I', data, header)[0]
        if kind == 1:
            loads += 1
            file_offset, address = struct.unpack_from('<QQ', data, header + 8)
            alignment = struct.unpack_from('<Q', data, header + 48)[0]
            if alignment < 16384 or alignment & (alignment - 1) or (address - file_offset) % 16384:
                raise ValueError('ELF LOAD segment is not aligned for 16 KB pages')
    if not loads:
        raise ValueError('Missing ELF LOAD segments')


def verify_bundle(path):
    failures = []
    checked = 0
    with zipfile.ZipFile(path) as archive:
        for name in archive.namelist():
            if name.endswith('.so') and any('/lib/' + abi + '/' in name for abi in ('arm64-v8a', 'x86_64')):
                checked += 1
                try:
                    verify_elf(archive.read(name))
                except (ValueError, struct.error) as error:
                    failures.append(f'{name}: {error}')
    if not checked:
        raise ValueError('No 64-bit native libraries found')
    if failures:
        raise ValueError('\n'.join(failures))
    return checked


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('bundle', type=Path)
    args = parser.parse_args()
    print(f'PASS: {verify_bundle(args.bundle)} native 64-bit libraries support 16 KB ELF alignment.')
