class NextOfKinContact {
  const NextOfKinContact({
    required this.name,
    required this.phone,
    this.relationship = '',
  });

  final String name;
  final String phone;
  final String relationship;

  static String normalizePhone(String value) =>
      value.replaceAll(RegExp(r'[\s().-]'), '');
  static bool validPhone(String value) =>
      RegExp(r'^\+[1-9]\d{6,14}$').hasMatch(normalizePhone(value));

  factory NextOfKinContact.fromJson(Map<String, dynamic> value) =>
      NextOfKinContact(
        name: value['name'] as String,
        phone: value['phone'] as String,
        relationship: value['relationship'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'relationship': relationship,
  };
}
