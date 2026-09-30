import 'package:hive/hive.dart';



@HiveType(typeId: 2)
class JournalEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String type; // 'free', 'guided', 'voice'

  @HiveField(2)
  final String? title;

  @HiveField(3)
  final String body;

  @HiveField(4)
  final String? voiceUrl;

  @HiveField(5)
  final int? voiceDuration; // seconds

  @HiveField(6)
  final String? transcription;

  @HiveField(7)
  final String? promptId;

  @HiveField(8)
  final String? promptText;

  @HiveField(9)
  final List<String>? tags;

  @HiveField(10)
  final String? linkedMoodEntryId;

  @HiveField(11)
  final int wordCount;

  @HiveField(12)
  final DateTime createdAt;

  @HiveField(13)
  final DateTime updatedAt;

  @HiveField(14)
  final bool isDraft;

  JournalEntry({
    required this.id,
    required this.type,
    this.title,
    required this.body,
    this.voiceUrl,
    this.voiceDuration,
    this.transcription,
    this.promptId,
    this.promptText,
    this.tags,
    this.linkedMoodEntryId,
    required this.wordCount,
    required this.createdAt,
    required this.updatedAt,
    this.isDraft = false,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'type': type,
      'body': body,
      'word_count': wordCount,
      'is_crisis_flagged': isCrisisFlagged,
      'client_created_at': createdAt.toUtc().toIso8601String(),
    };
    if (title != null) json['title'] = title;
    if (voiceUrl != null) json['voice_url'] = voiceUrl;
    if (voiceDuration != null) json['voice_duration'] = voiceDuration;
    if (transcription != null) json['transcription'] = transcription;
    if (promptId != null) json['prompt_id'] = promptId;
    if (promptText != null) json['prompt_text'] = promptText;
    if (tags != null) json['tags'] = tags;
    if (linkedMoodEntryId != null) json['linked_mood_entry_id'] = linkedMoodEntryId;
    if (updatedAt != null) json['client_updated_at'] = updatedAt!.toUtc().toIso8601String();
    return json;
  }

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'free',
      title: json['title'] as String?,
      body: json['body'] as String? ?? '',
      voiceUrl: json['voice_url'] as String?,
      voiceDuration: json['voice_duration'] as int?,
      transcription: json['transcription'] as String?,
      promptId: json['prompt_id'] as String?,
      promptText: json['prompt_text'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      linkedMoodEntryId: json['linked_mood_entry_id'] as String?,
      wordCount: json['word_count'] as int? ?? 0,
      isCrisisFlagged: json['is_crisis_flagged'] as bool? ?? false,
      isFavorite: json['is_favorite'] as bool? ?? false,
      createdAt: json['client_created_at'] != null ? DateTime.parse(json['client_created_at']) : DateTime.now(),
      updatedAt: json['client_updated_at'] != null ? DateTime.parse(json['client_updated_at']) : null,
    );
  }
}

class JournalEntryAdapter extends TypeAdapter<JournalEntry> {
  @override
  final int typeId = 2;

  @override
  JournalEntry read(BinaryReader reader) {
    return JournalEntry(
      id: reader.readString(),
      type: reader.readString(),
      title: reader.readString(),
      body: reader.readString(),
      voiceUrl: reader.readString(),
      voiceDuration: reader.readInt(),
      transcription: reader.readString(),
      promptId: reader.readString(),
      promptText: reader.readString(),
      tags: reader.readList().cast<String>(),
      linkedMoodEntryId: reader.readString(),
      wordCount: reader.readInt(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      isDraft: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, JournalEntry obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.type);
    writer.writeString(obj.title ?? '');
    writer.writeString(obj.body);
    writer.writeString(obj.voiceUrl ?? '');
    writer.writeInt(obj.voiceDuration ?? -1);
    writer.writeString(obj.transcription ?? '');
    writer.writeString(obj.promptId ?? '');
    writer.writeString(obj.promptText ?? '');
    writer.writeList(obj.tags ?? []);
    writer.writeString(obj.linkedMoodEntryId ?? '');
    writer.writeInt(obj.wordCount);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeInt(obj.updatedAt.millisecondsSinceEpoch);
    writer.writeBool(obj.isDraft);
  }




}
