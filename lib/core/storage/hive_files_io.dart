import 'dart:io';

Future<List<String>> legacyHiveNames(String? boxPath) async {
  if (boxPath == null) return const [];
  final files = await File(boxPath).parent.list().toList();
  return files
      .whereType<File>()
      .map((file) => file.uri.pathSegments.last)
      .where(
        (name) => name.endsWith('.hive') && !name.endsWith('_aes256_v1.hive'),
      )
      .map((name) => name.substring(0, name.length - 5))
      .toList();
}
