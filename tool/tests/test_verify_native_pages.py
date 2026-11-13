import importlib.util
from pathlib import Path
import struct
import tempfile
import unittest
import zipfile

spec = importlib.util.spec_from_file_location('pages', Path(__file__).parents[1] / 'verify_native_pages.py')
pages = importlib.util.module_from_spec(spec)
spec.loader.exec_module(pages)


def elf(alignment, address=0):
    data = bytearray(120)
    data[:6] = b'\x7fELF\x02\x01'
    struct.pack_into('<Q', data, 32, 64)
    struct.pack_into('<HH', data, 54, 56, 1)
    struct.pack_into('<I', data, 64, 1)
    struct.pack_into('<QQ', data, 72, 0, address)
    struct.pack_into('<Q', data, 112, alignment)
    return data


class NativePagesTest(unittest.TestCase):
    def test_checks_load_alignment_and_offsets(self):
        pages.verify_elf(elf(16384))
        pages.verify_elf(elf(65536))
        for data in (elf(4096), elf(16384, 4096), elf(24576), b'bad'):
            with self.subTest(data=data[:6]), self.assertRaises(ValueError):
                pages.verify_elf(data)

    def test_bundle_reports_bad_library_and_rejects_empty_bundle(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'test.aab'
            with zipfile.ZipFile(path, 'w') as archive:
                archive.writestr('base/lib/arm64-v8a/libtoolChecker.so', elf(4096))
                archive.writestr('base/lib/x86_64/libgood.so', elf(16384))
            with self.assertRaisesRegex(ValueError, 'libtoolChecker.so'):
                pages.verify_bundle(path)
            with zipfile.ZipFile(path, 'w') as archive:
                archive.writestr('base/lib/arm64-v8a/libgood.so', elf(16384))
            self.assertEqual(pages.verify_bundle(path), 1)
            with zipfile.ZipFile(path, 'w'):
                pass
            with self.assertRaisesRegex(ValueError, 'No 64-bit'):
                pages.verify_bundle(path)
