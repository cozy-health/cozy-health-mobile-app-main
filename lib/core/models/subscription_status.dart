import 'package:hive/hive.dart';

@HiveType(typeId: 10)
class SubscriptionStatus extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final bool _isActive;
  bool get isActive =>
      _isActive && (expiresAt == null || expiresAt!.isAfter(DateTime.now()));

  @HiveField(2)
  final String tier;

  @HiveField(3)
  final DateTime? expiresAt;

  @HiveField(4)
  final bool cancelAtPeriodEnd;

  @HiveField(5)
  final String? source;
  bool get isDevelopmentTest => source == 'development_test';

  @HiveField(6)
  final String? storePlatform;
  @HiveField(7)
  final String? storeState;
  @HiveField(8)
  final bool? autoRenews;
  @HiveField(9)
  final bool? isTrial;

  bool get isStoreManaged =>
      !isDevelopmentTest && const ['apple', 'google'].contains(storePlatform);
  String? get storeName => switch (storePlatform) {
    'apple' => 'Apple App Store',
    'google' => 'Google Play',
    _ => null,
  };

  SubscriptionStatus({
    required this.id,
    required bool isActive,
    required this.tier,
    this.expiresAt,
    required this.cancelAtPeriodEnd,
    this.source,
    this.storePlatform,
    this.storeState,
    this.autoRenews,
    this.isTrial,
  }) : _isActive = isActive;

  SubscriptionStatus copyWith({
    String? id,
    bool? isActive,
    String? tier,
    DateTime? expiresAt,
    bool? cancelAtPeriodEnd,
    String? source,
    String? storePlatform,
    String? storeState,
    bool? autoRenews,
    bool? isTrial,
  }) {
    return SubscriptionStatus(
      id: id ?? this.id,
      isActive: isActive ?? this.isActive,
      tier: tier ?? this.tier,
      expiresAt: expiresAt ?? this.expiresAt,
      cancelAtPeriodEnd: cancelAtPeriodEnd ?? this.cancelAtPeriodEnd,
      source: source ?? this.source,
      storePlatform: storePlatform ?? this.storePlatform,
      storeState: storeState ?? this.storeState,
      autoRenews: autoRenews ?? this.autoRenews,
      isTrial: isTrial ?? this.isTrial,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'plan': tier,
      'status': isActive ? 'active' : 'inactive',
      if (source != null) 'source': source,
      if (isStoreManaged) ...{
        'platform': storePlatform,
        'store_management': {'store': storeName},
        'store_state': storeState,
        'auto_renews': autoRenews,
        'is_trial': isTrial,
      },
    };
    if (expiresAt != null) {
      json['expires_at'] = expiresAt!.toUtc().toIso8601String();
    }
    return json;
  }

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    final platform =
        json['source'] != 'development_test' &&
            json['store_management'] is Map &&
            const ['apple', 'google'].contains(json['platform'])
        ? json['platform'] as String
        : null;
    return SubscriptionStatus(
      id: json['id']?.toString() ?? 'subscription',
      isActive: json['status'] == 'active',
      tier: json['plan'] as String? ?? 'free',
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      cancelAtPeriodEnd:
          platform != null &&
          json['status'] == 'active' &&
          json['auto_renews'] == false,
      source: json['source'] as String?,
      storePlatform: platform,
      storeState: platform != null ? json['store_state'] as String? : null,
      autoRenews: platform != null && json['auto_renews'] is bool
          ? json['auto_renews'] as bool
          : null,
      isTrial: platform != null && json['is_trial'] is bool
          ? json['is_trial'] as bool
          : null,
    );
  }
}

class SubscriptionStatusAdapter extends TypeAdapter<SubscriptionStatus> {
  @override
  final int typeId = 10;

  @override
  SubscriptionStatus read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SubscriptionStatus(
      id: fields[0] as String,
      isActive: fields[1] as bool,
      tier: fields[2] as String,
      expiresAt: fields[3] as DateTime?,
      cancelAtPeriodEnd: fields[4] as bool,
      source: fields[5] as String?,
      storePlatform: fields[6] as String?,
      storeState: fields[7] as String?,
      autoRenews: fields[8] as bool?,
      isTrial: fields[9] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, SubscriptionStatus obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.isActive)
      ..writeByte(2)
      ..write(obj.tier)
      ..writeByte(3)
      ..write(obj.expiresAt)
      ..writeByte(4)
      ..write(obj.cancelAtPeriodEnd)
      ..writeByte(5)
      ..write(obj.source)
      ..writeByte(6)
      ..write(obj.storePlatform)
      ..writeByte(7)
      ..write(obj.storeState)
      ..writeByte(8)
      ..write(obj.autoRenews)
      ..writeByte(9)
      ..write(obj.isTrial);
  }
}
