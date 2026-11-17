import 'package:hive/hive.dart';

class UserPreferences {
  UserPreferences({
    required List<String> focusAreas,
    required List<String> currentChallenges,
    required this.checkInFrequency,
    this.attribution,
    required this.completedAt,
    required this.skipped,
  }) : focusAreas = List.unmodifiable(focusAreas),
       currentChallenges = List.unmodifiable(currentChallenges);

  final List<String> focusAreas;
  final List<String> currentChallenges;
  final String checkInFrequency;
  final String? attribution;
  final DateTime completedAt;
  final bool skipped;

  Map<String, dynamic> toJson() => {
    'focus_areas': focusAreas,
    'current_challenges': currentChallenges,
    'check_in_frequency': checkInFrequency,
    'attribution': attribution,
    'completed_at': completedAt.toUtc().toIso8601String(),
    'skipped': skipped,
  };

  factory UserPreferences.fromJson(Map<String, dynamic> json) =>
      UserPreferences(
        focusAreas: List<String>.from(json['focus_areas'] as List? ?? []),
        currentChallenges: List<String>.from(
          json['current_challenges'] as List? ?? [],
        ),
        checkInFrequency:
            json['check_in_frequency'] as String? ?? 'A few times a week',
        attribution: json['attribution'] as String?,
        completedAt: DateTime.parse(json['completed_at'] as String),
        skipped: json['skipped'] as bool? ?? false,
      );
}

class UserPreferencesAdapter extends TypeAdapter<UserPreferences> {
  @override
  final int typeId = 11;
  @override
  UserPreferences read(BinaryReader reader) =>
      UserPreferences.fromJson(Map<String, dynamic>.from(reader.readMap()));
  @override
  void write(BinaryWriter writer, UserPreferences obj) =>
      writer.writeMap(obj.toJson());
}
