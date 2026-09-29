class SafetyPlan {
  final List<String> warningSigns;
  final List<String> copingStrategies;
  final List<String> distractions;
  final List<PlanContact> people;
  final List<PlanProfessional> professionals;
  final List<String> environmentSteps;
  final DateTime lastUpdated;
  final bool isComplete;
  final int version;
  final int currentStep;

  const SafetyPlan({
    this.warningSigns = const [],
    this.copingStrategies = const [],
    this.distractions = const [],
    this.people = const [],
    this.professionals = const [],
    this.environmentSteps = const [],
    required this.lastUpdated,
    this.isComplete = false,
    this.version = 1,
    this.currentStep = 0,
  });

  factory SafetyPlan.empty() => SafetyPlan(lastUpdated: DateTime.now());

  SafetyPlan copyWith({
    List<String>? warningSigns,
    List<String>? copingStrategies,
    List<String>? distractions,
    List<PlanContact>? people,
    List<PlanProfessional>? professionals,
    List<String>? environmentSteps,
    DateTime? lastUpdated,
    bool? isComplete,
    int? version,
    int? currentStep,
  }) {
    return SafetyPlan(
      warningSigns: warningSigns ?? this.warningSigns,
      copingStrategies: copingStrategies ?? this.copingStrategies,
      distractions: distractions ?? this.distractions,
      people: people ?? this.people,
      professionals: professionals ?? this.professionals,
      environmentSteps: environmentSteps ?? this.environmentSteps,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isComplete: isComplete ?? this.isComplete,
      version: version ?? this.version,
      currentStep: currentStep ?? this.currentStep,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'warningSigns': warningSigns,
      'copingStrategies': copingStrategies,
      'distractions': distractions,
      'people': people.map((contact) => contact.toJson()).toList(),
      'professionals': professionals.map((item) => item.toJson()).toList(),
      'environmentSteps': environmentSteps,
      'lastUpdated': lastUpdated.toIso8601String(),
      'isComplete': isComplete,
      'version': version,
      'currentStep': currentStep,
    };
  }

  factory SafetyPlan.fromJson(Map<String, dynamic> json) {
    return SafetyPlan(
      warningSigns: List<String>.from(json['warningSigns'] ?? const []),
      copingStrategies: List<String>.from(json['copingStrategies'] ?? const []),
      distractions: List<String>.from(json['distractions'] ?? const []),
      people: (json['people'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(PlanContact.fromJson)
          .toList(),
      professionals: (json['professionals'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(PlanProfessional.fromJson)
          .toList(),
      environmentSteps: List<String>.from(json['environmentSteps'] ?? const []),
      lastUpdated:
          DateTime.tryParse(json['lastUpdated']?.toString() ?? '') ??
          DateTime.now(),
      isComplete: json['isComplete'] == true,
      version: (json['version'] as num?)?.toInt() ?? 1,
      currentStep: (json['currentStep'] as num?)?.toInt() ?? 0,
    );
  }
}

class PlanContact {
  final String name;
  final String phone;
  final String relationship;

  const PlanContact({
    required this.name,
    required this.phone,
    required this.relationship,
  });

  Map<String, dynamic> toJson() {
    return {'name': name, 'phone': phone, 'relationship': relationship};
  }

  factory PlanContact.fromJson(Map<String, dynamic> json) {
    return PlanContact(
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      relationship: json['relationship']?.toString() ?? '',
    );
  }
}

class PlanProfessional {
  final String name;
  final String role;
  final String phone;

  const PlanProfessional({
    required this.name,
    required this.role,
    required this.phone,
  });

  Map<String, dynamic> toJson() {
    return {'name': name, 'role': role, 'phone': phone};
  }

  factory PlanProfessional.fromJson(Map<String, dynamic> json) {
    return PlanProfessional(
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
    );
  }
}
