class ApiDestinationPolicy {
  const ApiDestinationPolicy({required this.host, this.port = 443});

  final String host;
  final int port;

  bool permits(Uri uri) =>
      host.isNotEmpty &&
      uri.scheme == 'https' &&
      uri.host == host &&
      uri.port == port &&
      uri.userInfo.isEmpty;
}
