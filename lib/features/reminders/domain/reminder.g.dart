// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReminderAdapter extends TypeAdapter<Reminder> {
  @override
  final int typeId = 1;

  @override
  Reminder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Reminder(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      dateTime: fields[3] as DateTime,
      repeatOption: fields[4] as RepeatOption,
      isCompleted: fields[5] as bool,
      createdAt: fields[6] as DateTime,
      updatedAt: fields[7] as DateTime,
      userId: fields[8] as String,
      soundUrl: fields[9] as String?,
      soundName: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Reminder obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.dateTime)
      ..writeByte(4)
      ..write(obj.repeatOption)
      ..writeByte(5)
      ..write(obj.isCompleted)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt)
      ..writeByte(8)
      ..write(obj.userId)
      ..writeByte(9)
      ..write(obj.soundUrl)
      ..writeByte(10)
      ..write(obj.soundName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReminderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RepeatOptionAdapter extends TypeAdapter<RepeatOption> {
  @override
  final int typeId = 0;

  @override
  RepeatOption read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RepeatOption.none;
      case 1:
        return RepeatOption.daily;
      case 2:
        return RepeatOption.weekly;
      case 3:
        return RepeatOption.monthly;
      case 4:
        return RepeatOption.yearly;
      default:
        return RepeatOption.none;
    }
  }

  @override
  void write(BinaryWriter writer, RepeatOption obj) {
    switch (obj) {
      case RepeatOption.none:
        writer.writeByte(0);
        break;
      case RepeatOption.daily:
        writer.writeByte(1);
        break;
      case RepeatOption.weekly:
        writer.writeByte(2);
        break;
      case RepeatOption.monthly:
        writer.writeByte(3);
        break;
      case RepeatOption.yearly:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepeatOptionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
