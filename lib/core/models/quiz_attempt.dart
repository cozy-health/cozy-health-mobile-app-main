import 'package:hive/hive.dart';

@HiveType(typeId: 7)
class QuizAttempt extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String quizId;

  @HiveField(2)
  final String quizSlug;

  @HiveField(3)
  final String quizTitle;

  @HiveField(4)
  final List<int> answers;

  @HiveField(5)
  final int score;

  @HiveField(6)
  final String interpretation;

  @HiveField(7)
  final bool isCrisisFlagged;

  @HiveField(8)
  final DateTime completedAt;

  @HiveField(9)
  final String severityLabel;
  String get assessmentId => quizId;
  int get totalScore => score;

  QuizAttempt({
    required this.id,
    required this.quizId,
    required this.quizSlug,
    required this.quizTitle,
    required this.answers,
    required this.score,
    required this.interpretation,
    required this.isCrisisFlagged,
    required this.completedAt,
    this.severityLabel = '',
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'quiz_slug': quizSlug,
      'quiz_title': quizTitle,
      'answers': answers,
      'score': score,
      'is_crisis_flagged': isCrisisFlagged,
      'completed_at': completedAt.toUtc().toIso8601String(),
    };
    // Existing backend/provider API names are retained alongside explicit aliases.
    json['interpretation'] = severityLabel.isEmpty
        ? interpretation
        : severityLabel;
    json['assessment_id'] = assessmentId;
    json['total_score'] = totalScore;
    json['severity_label'] = severityLabel;
    return json;
  }

  factory QuizAttempt.fromJson(Map<String, dynamic> json) {
    return QuizAttempt(
      id: json['id'].toString(),
      quizId:
          (json['assessment_id'] ?? json['quiz_id'] ?? json['quiz_slug'])
              ?.toString() ??
          '',
      quizSlug: json['quiz_slug']?.toString() ?? '',
      quizTitle: json['quiz_title']?.toString() ?? '',
      answers:
          (json['answers'] as List<dynamic>?)?.map((e) => e as int).toList() ??
          [],
      score: (json['total_score'] ?? json['score']) as int? ?? 0,
      interpretation: json['interpretation'] as String? ?? '',
      severityLabel:
          json['severity_label'] as String? ??
          (const [
                'Minimal',
                'Mild',
                'Moderate',
                'Moderately Severe',
                'Severe',
              ].contains(json['interpretation'])
              ? json['interpretation'] as String
              : ''),
      isCrisisFlagged: json['is_crisis_flagged'] as bool? ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : DateTime.now(),
    );
  }
}

class QuizAttemptAdapter extends TypeAdapter<QuizAttempt> {
  @override
  final int typeId = 7;

  @override
  QuizAttempt read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QuizAttempt(
      id: fields[0] as String,
      quizId: fields[1] as String,
      quizSlug: fields[2] as String,
      quizTitle: fields[3] as String,
      answers: (fields[4] as List).cast<int>(),
      score: fields[5] as int,
      interpretation: fields[6] as String,
      isCrisisFlagged: fields[7] as bool,
      completedAt: fields[8] as DateTime,
      severityLabel: fields[9] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, QuizAttempt obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.quizId)
      ..writeByte(2)
      ..write(obj.quizSlug)
      ..writeByte(3)
      ..write(obj.quizTitle)
      ..writeByte(4)
      ..write(obj.answers)
      ..writeByte(5)
      ..write(obj.score)
      ..writeByte(6)
      ..write(obj.interpretation)
      ..writeByte(7)
      ..write(obj.isCrisisFlagged)
      ..writeByte(8)
      ..write(obj.completedAt)
      ..writeByte(9)
      ..write(obj.severityLabel);
  }
}
