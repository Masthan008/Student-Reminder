import 'package:hive/hive.dart';

part 'offline_action.g.dart';

@HiveType(typeId: 3)
enum ActionType {
  @HiveField(0)
  create,
  @HiveField(1)
  update,
  @HiveField(2)
  delete,
}

@HiveType(typeId: 4)
class OfflineAction extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final ActionType type;

  @HiveField(2)
  final Map<String, dynamic> data;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final String entityType; // 'reminder', 'user', etc.

  @HiveField(5)
  final String entityId;

  OfflineAction({
    required this.id,
    required this.type,
    required this.data,
    required this.timestamp,
    required this.entityType,
    required this.entityId,
  });

  // Factory constructor for creating a new offline action
  factory OfflineAction.create({
    required ActionType type,
    required Map<String, dynamic> data,
    required String entityType,
    required String entityId,
  }) {
    return OfflineAction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      data: Map<String, dynamic>.from(data),
      timestamp: DateTime.now(),
      entityType: entityType,
      entityId: entityId,
    );
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'entityType': entityType,
      'entityId': entityId,
    };
  }

  // JSON deserialization
  factory OfflineAction.fromJson(Map<String, dynamic> json) {
    return OfflineAction(
      id: json['id'] as String,
      type: ActionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ActionType.create,
      ),
      data: Map<String, dynamic>.from(json['data'] as Map),
      timestamp: DateTime.parse(json['timestamp'] as String),
      entityType: json['entityType'] as String,
      entityId: json['entityId'] as String,
    );
  }

  @override
  String toString() {
    return 'OfflineAction(id: $id, type: $type, entityType: $entityType, entityId: $entityId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OfflineAction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}