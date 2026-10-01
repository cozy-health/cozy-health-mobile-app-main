import 'package:hive/hive.dart';

@HiveType(typeId: 6)
class UserProfile extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? username;

  @HiveField(3)
  final String email;

  @HiveField(4)
  final String? avatarUrl;

  @HiveField(5)
  final String? bio;

  @HiveField(6)
  final String theme; // 'light', 'dark', 'system'

  @HiveField(7)
  final String accentColor;

  @HiveField(8)
  final String language;

  @HiveField(9)
  final bool reduceMotion;

  @HiveField(10)
  final bool highContrast;

  @HiveField(11)
  final bool hapticsEnabled;

  @HiveField(12)
  final double textSize;

  @HiveField(13)
  final bool showStats;

  @HiveField(14)
  final bool showUsername;

  @HiveField(15)
  final bool notificationsMaster;

  @HiveField(16)
  final bool dailyCheckinEnabled;

  @HiveField(17)
  final String dailyCheckinTime;

  @HiveField(18)
  final bool journalReminderEnabled;

  @HiveField(19)
  final bool commentsNotifications;

  @HiveField(20)
  final bool achievementsNotifications;

  @HiveField(21)
  final bool marketingNotifications;

  @HiveField(22)
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.name,
    this.username,
    required this.email,
    this.avatarUrl,
    this.bio,
    this.theme = 'system',
    this.accentColor = 'lavender',
    this.language = 'en',
    this.reduceMotion = false,
    this.highContrast = false,
    this.hapticsEnabled = true,
    this.textSize = 1.0,
    this.showStats = true,
    this.showUsername = true,
    this.notificationsMaster = true,
    this.dailyCheckinEnabled = true,
    this.dailyCheckinTime = '20:00',
    this.journalReminderEnabled = true,
    this.commentsNotifications = true,
    this.achievementsNotifications = true,
    this.marketingNotifications = false,
    required this.updatedAt,
  });

  UserProfile copyWith({
    String? name,
    String? username,
    String? email,
    String? avatarUrl,
    String? bio,
    String? theme,
    String? accentColor,
    String? language,
    bool? reduceMotion,
    bool? highContrast,
    bool? hapticsEnabled,
    double? textSize,
    bool? showStats,
    bool? showUsername,
    bool? notificationsMaster,
    bool? dailyCheckinEnabled,
    String? dailyCheckinTime,
    bool? journalReminderEnabled,
    bool? commentsNotifications,
    bool? achievementsNotifications,
    bool? marketingNotifications,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      theme: theme ?? this.theme,
      accentColor: accentColor ?? this.accentColor,
      language: language ?? this.language,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      highContrast: highContrast ?? this.highContrast,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      textSize: textSize ?? this.textSize,
      showStats: showStats ?? this.showStats,
      showUsername: showUsername ?? this.showUsername,
      notificationsMaster: notificationsMaster ?? this.notificationsMaster,
      dailyCheckinEnabled: dailyCheckinEnabled ?? this.dailyCheckinEnabled,
      dailyCheckinTime: dailyCheckinTime ?? this.dailyCheckinTime,
      journalReminderEnabled:
          journalReminderEnabled ?? this.journalReminderEnabled,
      commentsNotifications:
          commentsNotifications ?? this.commentsNotifications,
      achievementsNotifications:
          achievementsNotifications ?? this.achievementsNotifications,
      marketingNotifications:
          marketingNotifications ?? this.marketingNotifications,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  UserProfile copyWithField(String key, dynamic value) {
    switch (key) {
      case 'theme':
        return copyWith(theme: value as String);
      case 'accentColor':
        return copyWith(accentColor: value as String);
      case 'accent_color':
        return copyWith(accentColor: value as String);
      case 'language':
        return copyWith(language: value as String);
      case 'reduceMotion':
        return copyWith(reduceMotion: value as bool);
      case 'reduce_motion':
        return copyWith(reduceMotion: value as bool);
      case 'highContrast':
        return copyWith(highContrast: value as bool);
      case 'high_contrast':
        return copyWith(highContrast: value as bool);
      case 'hapticsEnabled':
        return copyWith(hapticsEnabled: value as bool);
      case 'haptics_enabled':
        return copyWith(hapticsEnabled: value as bool);
      case 'textSize':
        return copyWith(textSize: (value as num).toDouble());
      case 'text_size':
        return copyWith(textSize: (value as num).toDouble());
      case 'showStats':
        return copyWith(showStats: value as bool);
      case 'show_stats':
        return copyWith(showStats: value as bool);
      case 'showUsername':
        return copyWith(showUsername: value as bool);
      case 'show_username':
        return copyWith(showUsername: value as bool);
      case 'notificationsMaster':
        return copyWith(notificationsMaster: value as bool);
      case 'notifications_master':
        return copyWith(notificationsMaster: value as bool);
      case 'dailyCheckinEnabled':
        return copyWith(dailyCheckinEnabled: value as bool);
      case 'daily_checkin_enabled':
        return copyWith(dailyCheckinEnabled: value as bool);
      case 'dailyCheckinTime':
        return copyWith(dailyCheckinTime: value as String);
      case 'daily_checkin_time':
        return copyWith(dailyCheckinTime: value as String);
      case 'journalReminderEnabled':
        return copyWith(journalReminderEnabled: value as bool);
      case 'journal_reminder_enabled':
        return copyWith(journalReminderEnabled: value as bool);
      case 'commentsNotifications':
        return copyWith(commentsNotifications: value as bool);
      case 'comments_notifications':
        return copyWith(commentsNotifications: value as bool);
      case 'achievementsNotifications':
        return copyWith(achievementsNotifications: value as bool);
      case 'achievements_notifications':
        return copyWith(achievementsNotifications: value as bool);
      case 'marketingNotifications':
        return copyWith(marketingNotifications: value as bool);
      case 'marketing_notifications':
        return copyWith(marketingNotifications: value as bool);
      default:
        return this;
    }
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'name': name,
      'email': email,
      'theme': theme,
      'accent_color': accentColor,
      'language': language,
      'reduce_motion': reduceMotion,
      'high_contrast': highContrast,
      'haptics_enabled': hapticsEnabled,
      'text_size': textSize,
      'show_stats': showStats,
      'show_username': showUsername,
      'notifications_master': notificationsMaster,
      'daily_checkin_enabled': dailyCheckinEnabled,
      'daily_checkin_time': dailyCheckinTime,
      'journal_reminder_enabled': journalReminderEnabled,
      'comments_notifications': commentsNotifications,
      'achievements_notifications': achievementsNotifications,
      'marketing_notifications': marketingNotifications,
      'client_updated_at': updatedAt.toUtc().toIso8601String(),
    };
    if (username != null) json['username'] = username;
    if (avatarUrl != null) json['avatar_url'] = avatarUrl;
    if (bio != null) json['bio'] = bio;
    return json;
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'].toString(),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      username: json['username']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
      bio: json['bio']?.toString(),
      theme: json['theme'] as String? ?? 'system',
      accentColor: json['accent_color'] as String? ?? '#0460D8',
      language: json['language'] as String? ?? 'en',
      reduceMotion: json['reduce_motion'] as bool? ?? false,
      highContrast: json['high_contrast'] as bool? ?? false,
      hapticsEnabled: json['haptics_enabled'] as bool? ?? true,
      textSize: (json['text_size'] as num?)?.toDouble() ?? 1.0,
      showStats: json['show_stats'] as bool? ?? false,
      showUsername: json['show_username'] as bool? ?? true,
      notificationsMaster: json['notifications_master'] as bool? ?? true,
      dailyCheckinEnabled: json['daily_checkin_enabled'] as bool? ?? true,
      dailyCheckinTime: json['daily_checkin_time'] as String? ?? '09:00',
      journalReminderEnabled:
          json['journal_reminder_enabled'] as bool? ?? false,
      commentsNotifications: json['comments_notifications'] as bool? ?? true,
      achievementsNotifications:
          json['achievements_notifications'] as bool? ?? true,
      marketingNotifications: json['marketing_notifications'] as bool? ?? false,
      updatedAt: json['client_updated_at'] != null
          ? DateTime.parse(json['client_updated_at'])
          : DateTime.now(),
    );
  }
}

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 6;

  @override
  UserProfile read(BinaryReader reader) {
    return UserProfile(
      id: reader.readString(),
      name: reader.readString(),
      username: reader.readString(),
      email: reader.readString(),
      avatarUrl: reader.readString(),
      bio: reader.readString(),
      theme: reader.readString(),
      accentColor: reader.readString(),
      language: reader.readString(),
      reduceMotion: reader.readBool(),
      highContrast: reader.readBool(),
      hapticsEnabled: reader.readBool(),
      textSize: reader.readDouble(),
      showStats: reader.readBool(),
      showUsername: reader.readBool(),
      notificationsMaster: reader.readBool(),
      dailyCheckinEnabled: reader.readBool(),
      dailyCheckinTime: reader.readString(),
      journalReminderEnabled: reader.readBool(),
      commentsNotifications: reader.readBool(),
      achievementsNotifications: reader.readBool(),
      marketingNotifications: reader.readBool(),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.username ?? '');
    writer.writeString(obj.email);
    writer.writeString(obj.avatarUrl ?? '');
    writer.writeString(obj.bio ?? '');
    writer.writeString(obj.theme);
    writer.writeString(obj.accentColor);
    writer.writeString(obj.language);
    writer.writeBool(obj.reduceMotion);
    writer.writeBool(obj.highContrast);
    writer.writeBool(obj.hapticsEnabled);
    writer.writeDouble(obj.textSize);
    writer.writeBool(obj.showStats);
    writer.writeBool(obj.showUsername);
    writer.writeBool(obj.notificationsMaster);
    writer.writeBool(obj.dailyCheckinEnabled);
    writer.writeString(obj.dailyCheckinTime);
    writer.writeBool(obj.journalReminderEnabled);
    writer.writeBool(obj.commentsNotifications);
    writer.writeBool(obj.achievementsNotifications);
    writer.writeBool(obj.marketingNotifications);
    writer.writeInt(obj.updatedAt.millisecondsSinceEpoch);
  }
}
