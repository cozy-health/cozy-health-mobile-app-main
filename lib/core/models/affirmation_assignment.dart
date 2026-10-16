class AffirmationAssignment {
  const AffirmationAssignment({
    required this.id,
    required this.body,
    required this.assignedAt,
    required this.expiresAt,
  });
  final int id;
  final String body;
  final DateTime assignedAt;
  final DateTime expiresAt;

  factory AffirmationAssignment.fromJson(dynamic data) {
    if (data is! Map ||
        data['id'] is! int ||
        data['id'] <= 0 ||
        data['body'] is! String ||
        (data['body'] as String).trim().isEmpty ||
        data['assigned_at'] is! String ||
        data['expires_at'] is! String) {
      throw const FormatException('Invalid affirmation assignment');
    }
    final assigned = DateTime.tryParse(data['assigned_at']);
    final expires = DateTime.tryParse(data['expires_at']);
    if (assigned == null ||
        expires == null ||
        !assigned.isUtc ||
        !expires.isUtc ||
        expires.difference(assigned) != const Duration(hours: 24)) {
      throw const FormatException('Invalid affirmation expiry');
    }
    return AffirmationAssignment(
      id: data['id'],
      body: data['body'],
      assignedAt: assigned,
      expiresAt: expires,
    );
  }

  bool isExpired(DateTime now) => !now.toUtc().isBefore(expiresAt);
  Map<String, dynamic> toJson() => {
    'id': id,
    'body': body,
    'assigned_at': assignedAt.toIso8601String(),
    'expires_at': expiresAt.toIso8601String(),
  };
}
