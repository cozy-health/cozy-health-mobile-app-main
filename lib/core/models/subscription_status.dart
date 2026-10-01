import 'package:hive/hive.dart';

@HiveType(typeId: 10)
class SubscriptionStatus extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final bool isActive;

  @HiveField(2)
  final String tier;

  @HiveField(3)
  final DateTime? expiresAt;

  @HiveField(4)
  final bool cancelAtPeriodEnd;

  SubscriptionStatus({
    required this.id,
    required this.isActive,
    required this.tier,
    this.expiresAt,
    required this.cancelAtPeriodEnd,
  });

  SubscriptionStatus copyWith({
    String? id,
    bool? isActive,
    String? tier,
    DateTime? expiresAt,
    bool? cancelAtPeriodEnd,
  }) {
    return SubscriptionStatus(
      id: id ?? this.id,
      isActive: isActive ?? this.isActive,
      tier: tier ?? this.tier,
      expiresAt: expiresAt ?? this.expiresAt,
      cancelAtPeriodEnd: cancelAtPeriodEnd ?? this.cancelAtPeriodEnd,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'plan': tier,
      'status': isActive ? 'active' : 'inactive',
    };
    if (expiresAt != null) {
      json['expires_at'] = expiresAt!.toUtc().toIso8601String();
    }
    return json;
  }

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      id: json['id']?.toString() ?? 'subscription',
      isActive: json['status'] == 'active',
      tier: json['plan'] as String? ?? 'free',
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      cancelAtPeriodEnd: false,
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
    );
  }

  @override
  void write(BinaryWriter writer, SubscriptionStatus obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.isActive)
      ..writeByte(2)
      ..write(obj.tier)
      ..writeByte(3)
      ..write(obj.expiresAt)
      ..writeByte(4)
      ..write(obj.cancelAtPeriodEnd);
  }
}
