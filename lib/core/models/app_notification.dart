import 'package:hive/hive.dart';

@HiveType(typeId: 9)
class AppNotification extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String body;

  @HiveField(3)
  final String type;

  @HiveField(4)
  final bool read;

  @HiveField(5)
  final Map<String, dynamic>? payload;

  @HiveField(6)
  final DateTime createdAt;

  final String? deepLink;
  final DateTime? readAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.read,
    this.payload,
    required this.createdAt,
    this.deepLink,
    this.readAt,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    bool? read,
    Map<String, dynamic>? payload,
    DateTime? createdAt,
    String? deepLink,
    DateTime? readAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      read: read ?? this.read,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      deepLink: deepLink ?? this.deepLink,
      readAt: readAt ?? this.readAt,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'type': type,
      'title': title,
      'body': body,
      'is_read': read,
      'client_created_at': createdAt.toUtc().toIso8601String(),
    };
    if (deepLink != null) json['deep_link'] = deepLink;
    if (payload != null) json['data'] = payload;
    if (readAt != null) json['read_at'] = readAt!.toUtc().toIso8601String();
    return json;
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      deepLink: json['deep_link'] as String?,
      payload: json['data'] != null ? Map<String, dynamic>.from(json['data'] as Map) : null,
      read: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      createdAt: json['client_created_at'] != null ? DateTime.parse(json['client_created_at']) : DateTime.now(),
    );
  }
}

class AppNotificationAdapter extends TypeAdapter<AppNotification> {
  @override
  final int typeId = 9;

  @override
  AppNotification read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppNotification(
      id: fields[0] as String,
      title: fields[1] as String,
      body: fields[2] as String,
      type: fields[3] as String,
      read: fields[4] as bool,
      payload: (fields[5] as Map?)?.cast<String, dynamic>(),
      createdAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, AppNotification obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.body)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.read)
      ..writeByte(5)
      ..write(obj.payload)
      ..writeByte(6)
      ..write(obj.createdAt);
  }




}
