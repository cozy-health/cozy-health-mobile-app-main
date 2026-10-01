import 'package:hive/hive.dart';

@HiveType(typeId: 8)
class SavedArticle extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String articleId;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String excerpt;

  @HiveField(4)
  final String imageUrl;

  @HiveField(5)
  final DateTime savedAt;

  final String? articleSlug;
  final String? category;
  final int? readTimeMinutes;

  SavedArticle({
    required this.id,
    required this.articleId,
    required this.title,
    required this.excerpt,
    required this.imageUrl,
    required this.savedAt,
    this.articleSlug,
    this.category,
    this.readTimeMinutes,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'article_id': articleId,
      'title': title,
      'excerpt': excerpt,
      'image_url': imageUrl,
      'saved_at': savedAt.toUtc().toIso8601String(),
    };
    if (articleSlug != null) json['article_slug'] = articleSlug;
    if (category != null) json['category'] = category;
    if (readTimeMinutes != null) json['read_time_minutes'] = readTimeMinutes;
    return json;
  }

  factory SavedArticle.fromJson(Map<String, dynamic> json) {
    return SavedArticle(
      id: json['id'].toString(),
      articleId: json['article_id']?.toString() ?? json['id'].toString(),
      articleSlug: json['article_slug']?.toString(),
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString(),
      readTimeMinutes: json['read_time_minutes'] as int?,
      excerpt: json['excerpt'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      savedAt: json['saved_at'] != null
          ? DateTime.parse(json['saved_at'])
          : DateTime.now(),
    );
  }
}

class SavedArticleAdapter extends TypeAdapter<SavedArticle> {
  @override
  final int typeId = 8;

  @override
  SavedArticle read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavedArticle(
      id: fields[0] as String,
      articleId: fields[1] as String,
      title: fields[2] as String,
      excerpt: fields[3] as String,
      imageUrl: fields[4] as String,
      savedAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, SavedArticle obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.articleId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.excerpt)
      ..writeByte(4)
      ..write(obj.imageUrl)
      ..writeByte(5)
      ..write(obj.savedAt);
  }
}
