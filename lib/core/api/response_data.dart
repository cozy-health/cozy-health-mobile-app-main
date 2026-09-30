Map<String, dynamic> responseMap(dynamic response) {
  final data = response.data;
  return data is Map<String, dynamic> ? data : {'data': data};
}
