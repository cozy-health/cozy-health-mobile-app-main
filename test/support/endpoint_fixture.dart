import 'package:hive/hive.dart';
import 'package:cozy_health/core/storage/token_storage.dart';
import 'package:cozy_health/core/repositories/endpoint_cache.dart';
import 'repository_fixture.dart';

class EndpointFixture extends RepositoryFixture<String> {
  EndpointFixture() : super(EndpointCache.boxName, _StringAdapter());
  @override
  Future<void> reset() async {
    await super.reset();
    await TokenStorage().saveToken('1|test-session');
  }
}

class _StringAdapter extends TypeAdapter<String> {
  @override
  final typeId = 99;
  @override
  String read(BinaryReader reader) => reader.readString();
  @override
  void write(BinaryWriter writer, String obj) => writer.writeString(obj);
}
