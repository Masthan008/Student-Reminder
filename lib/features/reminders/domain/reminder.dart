import 'package:hive/hive.dart';

part 'reminder.g.dart';

@HiveType(typeId: 0)
enum RepeatOption {
  @HiveField(0)
  none,
  @HiveField(1)
  daily,
  @HiveField(2)
  weekly,
  @HiveField(3)
  monthly,
  @HiveField(4)
  yearly,
}

@HiveType(typeId: 1)
class Reminder extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final DateTime dateTime;

  @HiveField(4)
  final RepeatOption repeatOption;

  @HiveField(5)
  final bool isCompleted;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime updatedAt;

  @HiveField(8)
  final String userId;

  @HiveField(9)
  final String? soundUrl;

  @HiveField(10)
  final String? soundName;

  Reminder({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.repeatOption,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
    this.soundUrl,
    this.soundName,
  });

  // Factory constructor for creating a new reminder
  factory Reminder.create({
    required String title,
    required String description,
    required DateTime dateTime,
    required RepeatOption repeatOption,
    required String userId,
    String? soundUrl,
    String? soundName,
  }) {
    final now = DateTime.now();
    return Reminder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      dateTime: dateTime,
      repeatOption: repeatOption,
      isCompleted: false,
      createdAt: now,
      updatedAt: now,
      userId: userId,
      soundUrl: soundUrl,
      soundName: soundName,
    );
  }

  // Copy with method for updates
  Reminder copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dateTime,
    RepeatOption? repeatOption,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    String? soundUrl,
    String? soundName,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      repeatOption: repeatOption ?? this.repeatOption,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      userId: userId ?? this.userId,
      soundUrl: soundUrl ?? this.soundUrl,
      soundName: soundName ?? this.soundName,
    );
  }

  // JSON serialization for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dateTime': dateTime.toIso8601String(),
      'repeatOption': repeatOption.name,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'userId': userId,
      'soundUrl': soundUrl,
      'soundName': soundName,
    };
  }

  // JSON deserialization from Firebase
  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      dateTime: DateTime.parse(json['dateTime'] as String),
      repeatOption: RepeatOption.values.firstWhere(
        (e) => e.name == json['repeatOption'],
        orElse: () => RepeatOption.none,
      ),
      isCompleted: json['isCompleted'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      userId: json['userId'] as String,
      soundUrl: json['soundUrl'] as String?,
      soundName: json['soundName'] as String?,
    );
  }

  // Validation
  bool get isValid {
    return title.trim().isNotEmpty && 
           dateTime.isAfter(DateTime.now().subtract(const Duration(days: 1))) &&
           userId.isNotEmpty;
  }

  // Helper methods
  bool get isOverdue {
    return !isCompleted && dateTime.isBefore(DateTime.now());
  }

  bool get isDueToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final reminderDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    return reminderDate.isAtSameMomentAs(today);
  }

  bool get isDueTomorrow {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final reminderDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    return reminderDate.isAtSameMomentAs(tomorrow);
  }

  @override
  String toString() {
    return 'Reminder(id: $id, title: $title, dateTime: $dateTime, isCompleted: $isCompleted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Reminder && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}