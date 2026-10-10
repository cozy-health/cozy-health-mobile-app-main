import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<bool> hasLocalHiveFiles() async {
  final directory = await getApplicationDocumentsDirectory();
  await for (final entry in directory.list(recursive: true)) {
    if (entry is File && entry.path.toLowerCase().endsWith('.hive'))
      return true;
  }
  return false;
}

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
