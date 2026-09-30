import 'package:hive/hive.dart';



@HiveType(typeId: 1)
class MoodEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String mood; // 'good', 'calm', 'okay', 'low', 'anxious', 'angry'

  @HiveField(2)
  final int intensity; // 1-10

  @HiveField(3)
  final List<String>? bodySensations;

  @HiveField(4)
  final List<String>? triggers;

  @HiveField(5)
  final String? customTrigger;

  @HiveField(6)
  final int? sleepQuality; // 1-5

  @HiveField(7)
  final int? energyLevel; // 1-10

  @HiveField(8)
  final String? note;

  @HiveField(9)
  final List<String>? copingStrategies;

  @HiveField(10)
  final String? copingHelped; // 'yes', 'somewhat', 'no'

  @HiveField(11)
  final DateTime createdAt;

  @HiveField(12)
  final DateTime updatedAt;

  @HiveField(13)
  final bool isCrisisFlagged;

  MoodEntry({
    required this.id,
    required this.mood,
    required this.intensity,
    this.bodySensations,
    this.triggers,
    this.customTrigger,
    this.sleepQuality,
    this.energyLevel,
    this.note,
    this.copingStrategies,
    this.copingHelped,
    this.isCrisisFlagged = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'mood': mood,
      'intensity': intensity,
    };
    if (energyLevel != null) json['energy_level'] = energyLevel;
    if (bodySensations != null) json['body_sensations'] = bodySensations;
    if (triggers != null) json['triggers'] = triggers;
    if (customTrigger != null) json['custom_trigger'] = customTrigger;
    if (sleepQuality != null) json['sleep_quality'] = sleepQuality;
    if (note != null) json['note'] = note;
    if (copingStrategies != null) json['coping_strategies'] = copingStrategies;
    if (copingHelped != null) json['coping_helped'] = copingHelped;
    json['is_crisis_flagged'] = isCrisisFlagged;
    json['client_created_at'] = createdAt.toUtc().toIso8601String();
    if (updatedAt != null) json['client_updated_at'] = updatedAt!.toUtc().toIso8601String();
    return json;
  }

  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    return MoodEntry(
      id: json['id'] as String,
      mood: json['mood'] as String,
      intensity: json['intensity'] as int? ?? 5,
      energyLevel: json['energy_level'] as int?,
      bodySensations: (json['body_sensations'] as List<dynamic>?)?.map((e) => e as String).toList(),
      triggers: (json['triggers'] as List<dynamic>?)?.map((e) => e as String).toList(),
      customTrigger: json['custom_trigger'] as String?,
      sleepQuality: json['sleep_quality'] as int?,
      note: json['note'] as String?,
      copingStrategies: (json['coping_strategies'] as List<dynamic>?)?.map((e) => e as String).toList(),
      copingHelped: json['coping_helped'] as String?,
      isCrisisFlagged: json['is_crisis_flagged'] as bool? ?? false,
      createdAt: json['client_created_at'] != null ? DateTime.parse(json['client_created_at']) : DateTime.now(),
      updatedAt: json['client_updated_at'] != null ? DateTime.parse(json['client_updated_at']) : DateTime.now(),
    );
  }
}

class MoodEntryAdapter extends TypeAdapter<MoodEntry> {
  @override
  final int typeId = 1;

  @override
  MoodEntry read(BinaryReader reader) {
    return MoodEntry(
      id: reader.readString(),
      mood: reader.readString(),
      intensity: reader.readInt(),
      bodySensations: reader.readList().cast<String>(),
      triggers: reader.readList().cast<String>(),
      customTrigger: reader.readString(),
      sleepQuality: reader.readInt(),
      energyLevel: reader.readInt(),
      note: reader.readString(),
      copingStrategies: reader.readList().cast<String>(),
      copingHelped: reader.readString(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    );
  }

  @override
  void write(BinaryWriter writer, MoodEntry obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.mood);
    writer.writeInt(obj.intensity);
    writer.writeList(obj.bodySensations ?? []);
    writer.writeList(obj.triggers ?? []);
    writer.writeString(obj.customTrigger ?? '');
    writer.writeInt(obj.sleepQuality ?? -1);
    writer.writeInt(obj.energyLevel ?? -1);
    writer.writeString(obj.note ?? '');
    writer.writeList(obj.copingStrategies ?? []);
    writer.writeString(obj.copingHelped ?? '');
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeInt(obj.updatedAt.millisecondsSinceEpoch);
  }




}
