import 'package:crypto/crypto.dart';

class LeafPinPolicy {
  LeafPinPolicy({
    required this.host,
    this.port = 443,
    required String current,
    required String next,
  }) : pins = {current.toLowerCase(), next.toLowerCase()};
  final String host;
  final int port;
  final Set<String> pins;
  bool get ready =>
      pins.length == 2 &&
      pins.every((pin) => RegExp(r'^[a-f0-9]{64}$').hasMatch(pin));
  bool permits(Uri uri) =>
      uri.scheme == 'https' &&
      uri.host == host &&
      uri.port == port &&
      uri.userInfo.isEmpty;
  bool accepts(List<int>? leafDer, String peerHost, int peerPort) =>
      ready &&
      peerHost == host &&
      peerPort == port &&
      leafDer != null &&
      pins.contains(sha256.convert(leafDer).toString());
}
