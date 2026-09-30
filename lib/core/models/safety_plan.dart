import 'package:hive/hive.dart';



@HiveType(typeId: 5)
class SafetyPlan extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final List<String>? warningSigns;

  @HiveField(2)
  final List<String>? copingStrategies;

  @HiveField(3)
  final List<String>? distractions;

  @HiveField(4)
  final List<Map<String, String>>? peopleToCall;

  @HiveField(5)
  final List<Map<String, String>>? professionals;

  @HiveField(6)
  final List<String>? environmentSteps;

  @HiveField(7)
  final bool isComplete;

  @HiveField(8)
  final DateTime lastUpdatedAt;

  SafetyPlan({
    required this.id,
    this.warningSigns,
    this.copingStrategies,
    this.distractions,
    this.peopleToCall,
    this.professionals,
    this.environmentSteps,
    required this.isComplete,
    required this.lastUpdatedAt,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'is_complete': isComplete,
      'last_updated_at': lastUpdatedAt.toUtc().toIso8601String(),
    };
    if (warningSigns != null) json['warning_signs'] = warningSigns;
    if (copingStrategies != null) json['coping_strategies'] = copingStrategies;
    if (distractions != null) json['distractions'] = distractions;
    if (people != null) json['people'] = people;
    if (professionals != null) json['professionals'] = professionals;
    if (environmentSteps != null) json['environment_steps'] = environmentSteps;
    return json;
  }

  factory SafetyPlan.fromJson(Map<String, dynamic> json) {
    return SafetyPlan(
      id: json['id'] as String,
      warningSigns: (json['warning_signs'] as List<dynamic>?)?.map((e) => e as String).toList(),
      copingStrategies: (json['coping_strategies'] as List<dynamic>?)?.map((e) => e as String).toList(),
      distractions: (json['distractions'] as List<dynamic>?)?.map((e) => e as String).toList(),
      people: (json['people'] as List<dynamic>?)?.map((e) => Map<String, String>.from(e)).toList(),
      professionals: (json['professionals'] as List<dynamic>?)?.map((e) => Map<String, String>.from(e)).toList(),
      environmentSteps: (json['environment_steps'] as List<dynamic>?)?.map((e) => e as String).toList(),
      isComplete: json['is_complete'] as bool? ?? false,
      lastUpdatedAt: json['last_updated_at'] != null ? DateTime.parse(json['last_updated_at']) : DateTime.now(),
    );
  }
}

class SafetyPlanAdapter extends TypeAdapter<SafetyPlan> {
  @override
  final int typeId = 5;

  @override
  SafetyPlan read(BinaryReader reader) {
    return SafetyPlan(
      id: reader.readString(),
      warningSigns: reader.readList().cast<String>(),
      copingStrategies: reader.readList().cast<String>(),
      distractions: reader.readList().cast<String>(),
      peopleToCall: reader.readList().map((e) => Map<String, String>.from(e as Map)).toList(),
      professionals: reader.readList().map((e) => Map<String, String>.from(e as Map)).toList(),
      environmentSteps: reader.readList().cast<String>(),
      isComplete: reader.readBool(),
      lastUpdatedAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    );
  }

  @override
  void write(BinaryWriter writer, SafetyPlan obj) {
    writer.writeString(obj.id);
    writer.writeList(obj.warningSigns ?? []);
    writer.writeList(obj.copingStrategies ?? []);
    writer.writeList(obj.distractions ?? []);
    writer.writeList(obj.peopleToCall ?? []);
    writer.writeList(obj.professionals ?? []);
    writer.writeList(obj.environmentSteps ?? []);
    writer.writeBool(obj.isComplete);
    writer.writeInt(obj.lastUpdatedAt.millisecondsSinceEpoch);
  }




}
